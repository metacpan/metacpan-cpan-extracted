use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::Test;
use DBIO::Test::Storage;
use DBIO::Test::Future ();
use DBIO::SQLMaker;
use DBIO::Storage::Async;
use DBIO::Storage::DBI;

# karr k282, point 1: with_context in the 'immediate' mode.
#
# ADR 0045 has with_context take "the object passed to a txn_do_async /
# pipeline coderef"; ADR 0055 makes txn_do_async's callback contract the same
# in every async mode and, in the 'immediate' mode, hands the coderef the
# storage itself. Put together, the portable pattern
#
#     $storage->txn_do_async(sub {
#       my ($ctx) = @_;
#       return $rs->with_context($ctx)->create_async(...);
#     });
#
# has to work there. It did not: with_context refused the storage ('async
# context ownership cannot be proven') and the transaction rolled back.
#
# What is asserted:
#   - with_context on a ResultSet, a Row and a ResultSetColumn takes what the
#     immediate txn_do_async hands in, and the bound object's *_async run
#     INSIDE that transaction -- between BEGIN and COMMIT, the same statements
#     a real backend sends on its transaction connection for the same coderef;
#   - a failed statement of a bound object rolls the transaction back, also
#     when nothing awaited it and when the coderef recovered from it;
#   - what a bound context refuses on a real backend it refuses here;
#   - after the transaction a bound object is refused, as on a real backend;
#   - nothing else passes for a context: not another storage, not a storage
#     without an async mode, not the storage of a real backend.
#
# The fake synchronous storage of DBIO::Test is in the 'immediate' mode by
# default; the real backend is the synchronous fake transport of
# t/resultset/with_context_fresh_derivations.t.

{
  package Test::SyncPool;
  sub new { bless { txns => 0 }, shift }
  sub acquire     { DBIO::Test::Future->done('POOL') }
  sub acquire_txn { DBIO::Test::Future->done('TXN' . ++$_[0]->{txns}) }
  sub release     { 1 }
  sub shutdown    { 1 }
}
{
  package Test::CtxBackend;
  use base 'DBIO::Storage::Async';

  sub new {
    my ($class, $schema) = @_;
    my $self = $class->SUPER::new($schema);
    $self->{captured} = [];
    return $self;
  }
  sub future_class     { 'DBIO::Test::Future' }
  sub sql_maker_class  { 'DBIO::SQLMaker' }
  sub _sql_maker_args  { (quote_char => '"', name_sep => '.') }
  sub _transform_sql   { $_[1] }
  sub _post_insert_sql { ' RETURNING *' }
  sub pool { $_[0]->{pool} ||= Test::SyncPool->new }

  # An INSERT is answered with the key RETURNING would add, an UPDATE or
  # DELETE with "one row", a SELECT with no rows.
  sub _answer {
    my ($self, $sql, $on) = @_;
    push @{ $self->{captured} }, { sql => $sql, on => $on };
    return $self->future_class->done(
        $sql =~ /^INSERT/           ? { artistid => 1 }
      : $sql =~ /^(?:UPDATE|DELETE)/ ? 1
      :                               ()
    );
  }
  sub _query_async        { $_[0]->_answer($_[1], 'the pool') }
  sub _query_async_pinned { $_[0]->_answer($_[2], $_[1]) }
}

DBIO::Storage::DBI->register_async_mode( with_context_immediate_backend => 'Test::CtxBackend' );

sub immediate_schema {
  my $schema = DBIO::Test->init_schema;
  $schema->storage->reset_captured;
  return $schema;
}

sub backend_schema {
  my $schema = DBIO::Test->init_schema;
  $schema->storage->_async_mode('with_context_immediate_backend');
  delete $schema->storage->{_async_storage_obj};
  $schema->storage->reset_captured;
  return ($schema, $schema->storage->_async_storage);
}

# What went through the synchronous storage, in order: first words.
sub synced {
  my ($schema) = @_;
  return [ map { ($_->{sql} =~ /(\w+)/)[0] } $schema->storage->captured_queries ];
}

# What went over the async wire, in order: [ first word, where ].
sub wire {
  my ($backend) = @_;
  return [ map { [ ($_->{sql} =~ /(\w+)/)[0], $_->{on} ] } @{ $backend->{captured} } ];
}

# What a Future failed with, or undef if it did not.
sub failure_of {
  my ($future) = @_;
  return undef if eval { $future->get; 1 };
  return "$@";
}

sub stored {
  my ($schema, $source, $cols) = @_;
  my $row = $schema->resultset($source)->new_result($cols);
  $row->in_storage(1);
  return $row;
}

is immediate_schema()->storage->_async_mode, 'immediate',
  'the fake storage is in the immediate mode';

# ---------------------------------------------------------------------------
# The portable pattern. Each coderef is written once and run in both modes; it
# gets the context and the schema and binds with with_context.
# ---------------------------------------------------------------------------
my @portable = (
  {
    name  => 'ResultSet all_async',
    code  => sub { $_[1]->resultset('Artist')->with_context($_[0])->all_async },
    sends => [ 'SELECT' ],
  },
  {
    name  => 'ResultSet create_async, then a search on the same context',
    code  => sub {
      my ($ctx, $schema) = @_;
      my $artists = $schema->resultset('Artist')->with_context($ctx);
      return $artists->create_async({ name => 'Miles Davis' })->then(sub {
        $artists->search({ rank => 13 })->all_async;
      });
    },
    sends => [ 'INSERT', 'SELECT' ],
  },
  {
    name  => 'ResultSet count_async',
    code  => sub { $_[1]->resultset('Artist')->with_context($_[0])->count_async },
    sends => [ 'SELECT' ],
  },
  {
    name  => 'ResultSet results_exist_async (the raw-SQL seam)',
    code  => sub { $_[1]->resultset('Artist')->with_context($_[0])->results_exist_async },
    sends => [ 'SELECT' ],
  },
  {
    name  => 'Row update_async',
    code  => sub {
      stored($_[1], Artist => { artistid => 1, name => 'Miles Davis' })
        ->with_context($_[0])->update_async({ name => 'Miles' });
    },
    sends => [ 'UPDATE' ],
  },
  {
    name  => 'Row delete_async',
    code  => sub {
      stored($_[1], Money => { id => 5, amount => '1.00' })->with_context($_[0])->delete_async;
    },
    sends => [ 'DELETE' ],
  },
  {
    name  => 'a row of a bound ResultSet, written back',
    code  => sub {
      $_[1]->resultset('Artist')->with_context($_[0])
           ->new_result({ name => 'Miles Davis' })->insert_async;
    },
    sends => [ 'INSERT' ],
  },
  {
    name  => 'ResultSetColumn max_async',
    code  => sub { $_[1]->resultset('Artist')->get_column('rank')->with_context($_[0])->max_async },
    sends => [ 'SELECT' ],
  },
  {
    name  => 'the column of a bound ResultSet, all_async',
    code  => sub { $_[1]->resultset('Artist')->with_context($_[0])->get_column('rank')->all_async },
    sends => [ 'SELECT' ],
  },
);

for my $case (@portable) {
  my ($name, $code, @sends) = ( $case->{name}, $case->{code}, @{ $case->{sends} } );

  {
    my $schema = immediate_schema();

    my $txn = $schema->storage->txn_do_async($code, $schema);

    is failure_of($txn), undef, "$name, immediate: the transaction resolves";
    is_deeply synced($schema), [ 'BEGIN', @sends, 'COMMIT' ],
      "$name, immediate: it ran inside the transaction";
  }

  # The same coderef on a real backend: the same statements, in its transaction.
  {
    my ($schema, $backend) = backend_schema();

    my $txn = $schema->storage->txn_do_async($code, $schema);

    is failure_of($txn), undef, "$name, real backend: the transaction resolves";
    is_deeply wire($backend), [ map { [ $_ => 'TXN1' ] } 'BEGIN', @sends, 'COMMIT' ],
      "$name, real backend: the same statements, on the transaction's connection";
  }
}

# ---------------------------------------------------------------------------
# A failed statement of a bound object fails the transaction and rolls it back
# (ADR 0055, addendum karr k236) -- returned, dropped or recovered from. The
# statement before it is inside what is rolled back.
# ---------------------------------------------------------------------------
{
  no warnings 'redefine';
  my $execute = \&DBIO::Test::Storage::_execute;
  local *DBIO::Test::Storage::_execute = sub {
    my ($self, $op, $ident, @args) = @_;
    die qq{ERROR:  duplicate key value violates unique constraint "artist_name"\n}
      if $op eq 'insert' && ($args[0]{name} // '') eq 'Duplicate';
    return $self->$execute($op, $ident, @args);
  };

  for my $case (
    [ 'returned' => sub {
        $_[1]->create_async({ name => 'Duplicate' });
      } ],
    [ 'dropped' => sub {
        $_[1]->create_async({ name => 'Duplicate' });
        return 'queued';
      } ],
    [ 'recovered from' => sub {
        $_[1]->create_async({ name => 'Duplicate' })->catch(sub { 'recovered' });
      } ],
  ) {
    my ($label, $then) = @$case;
    my $schema = immediate_schema();

    my $txn = $schema->storage->txn_do_async(sub {
      my ($ctx) = @_;
      my $artists = $schema->resultset('Artist')->with_context($ctx);
      $artists->create_async({ name => 'Fine' });
      return $then->($ctx, $artists);
    });

    like failure_of($txn), qr/duplicate key value/,
      "a bound statement that failed, $label: the transaction fails with its error";
    is_deeply synced($schema), [ qw( BEGIN INSERT ROLLBACK ) ],
      "a bound statement that failed, $label: ROLLBACK, and the statement before it with it";
  }
}

# ---------------------------------------------------------------------------
# What is not one statement is refused on a bound object in every mode (ADR
# 0045 section 6). In the immediate mode the synchronous fallback would run
# inside the transaction, so the refusal gives another reason there -- but it
# is the same refusal, so that a coderef written against one mode does not
# break on the other.
# ---------------------------------------------------------------------------
for my $case (
  [ 'a multi-create on a bound resultset', 'insert', sub {
      my ($ctx, $schema) = @_;
      return $schema->resultset('Artist')->with_context($ctx)->create_async({
        name => 'Miles Davis',
        cds  => [ { title => 'Kind of Blue', year => 1959 } ],
      });
    } ],
  [ 'a fallback upsert on a bound resultset', 'upsert', sub {
      my ($ctx, $schema) = @_;
      return $schema->resultset('Artist')->with_context($ctx)->upsert_async(
        { artistid => 1, name => 'Miles Davis' }, { fallback => 'update_or_create' },
      );
    } ],
) {
  my ($name, $op, $code) = @$case;

  my $schema = immediate_schema();
  my $error  = failure_of( $schema->storage->txn_do_async($code, $schema) );

  like $error, qr/${op}_async cannot run on a bound async context/,
    "$name, immediate: refused";
  like $error, qr/In the 'immediate' mode the synchronous fallback would run inside the transaction/,
    "$name, immediate: with the reason that holds there";
  unlike $error, qr/outside the pinned/,
    "$name, immediate: not with the one that does not";
  is_deeply synced($schema), [ qw( BEGIN ROLLBACK ) ],
    "$name, immediate: nothing written, rolled back";

  my ($real_schema, $backend) = backend_schema();
  my $real_error = failure_of( $real_schema->storage->txn_do_async($code, $real_schema) );

  like $real_error, qr/${op}_async cannot run on a bound async context/,
    "$name, real backend: refused";
  like $real_error, qr/would run outside the pinned transaction/,
    "$name, real backend: its reason is unchanged";
  is_deeply wire($backend), [ [ BEGIN => 'TXN1' ], [ ROLLBACK => 'TXN1' ] ],
    "$name, real backend: nothing written, rolled back";
}

# ---------------------------------------------------------------------------
# After the transaction. The storage knows whether an immediate txn_do_async
# is running on it, and that is what "active" means for it as a context: a
# bound object held past the transaction is refused, as on a real backend.
# ---------------------------------------------------------------------------
for my $case (
  [ 'ResultSet'       => sub { $_[1]->resultset('Artist')->with_context($_[0]) },
                         sub { $_[0]->all_async } ],
  [ 'Row'             => sub { stored($_[1], Artist => { artistid => 1, name => 'a' })->with_context($_[0]) },
                         sub { $_[0]->update_async({ name => 'b' }) } ],
  [ 'ResultSetColumn' => sub { $_[1]->resultset('Artist')->get_column('rank')->with_context($_[0]) },
                         sub { $_[0]->max_async } ],
) {
  my ($what, $bind, $use) = @$case;
  my $schema = immediate_schema();

  my $held;
  $schema->storage->txn_do_async(sub {
    $held = $bind->(@_);
    return 'done';
  }, $schema);

  throws_ok { $use->($held) } qr/no longer active/,
    "a bound $what held past the immediate transaction is refused";
  is_deeply synced($schema), [ qw( BEGIN COMMIT ) ],
    "a bound $what held past the immediate transaction: and nothing was sent in its place";
}

# Bound to the storage with no transaction open at all: with_context takes the
# storage -- it asks whose context this is, not whether it is active, as it
# does for a real context -- and the first *_async is refused.
{
  my $schema = immediate_schema();
  my $bound;

  lives_ok { $bound = $schema->resultset('Artist')->with_context($schema->storage) }
    'outside any transaction, with_context takes the immediate storage';
  throws_ok { $bound->all_async } qr/no longer active/,
    'outside any transaction, a *_async on what was bound is refused';
  is_deeply synced($schema), [], 'outside any transaction: and nothing was sent';
}

# The context of every immediate transaction on a storage is that one storage.
# So an object bound in one transaction and used inside a LATER one is bound
# to the later one's context too, and runs in it -- where a real backend, whose
# contexts are one object per transaction, refuses. There is one connection
# here and no pool: inside the later transaction is the only place the
# statement can run. The assertion marked IST holds what happens today and is
# no promise (ADR 0055, addendum 2026-10-08).
{
  my $schema = immediate_schema();

  my $held;
  $schema->storage->txn_do_async(sub {
    $held = $schema->resultset('Artist')->with_context($_[0]);
    return 'done';
  });

  my $txn = $schema->storage->txn_do_async(sub { $held->all_async });

  # IST, no promise.
  is failure_of($txn), undef,
    'IST bound in one immediate transaction, used inside a later one: accepted';
  is_deeply synced($schema), [ qw( BEGIN COMMIT BEGIN SELECT COMMIT ) ],
    'IST bound in one immediate transaction, used inside a later one: it runs in the later one';
}

# ---------------------------------------------------------------------------
# Nothing else passes for a context. The storage is taken only as its OWN
# context and only while its mode is 'immediate'; everything else is still
# proven by the token of ADR 0045 section 4, or refused.
# ---------------------------------------------------------------------------
{
  my $schema = immediate_schema();
  my $other  = immediate_schema();

  throws_ok { $schema->resultset('Artist')->with_context($other->storage) }
    qr/ownership cannot be proven/,
    'another storage in the immediate mode is not this resultset\'s context';
  throws_ok { stored($schema, Artist => { artistid => 1, name => 'a' })->with_context($other->storage) }
    qr/ownership cannot be proven/,
    'nor a row\'s';
  throws_ok { $schema->resultset('Artist')->get_column('rank')->with_context($other->storage) }
    qr/ownership cannot be proven/,
    'nor a column\'s';
}

{
  my $schema = immediate_schema();
  $schema->storage->_async_mode(undef);

  throws_ok { $schema->resultset('Artist')->with_context($schema->storage) }
    qr/ownership cannot be proven/,
    'a storage with no async mode is not a context, not even its own';
}

{
  my ($schema, $backend) = backend_schema();
  my $other = immediate_schema();

  throws_ok { $schema->resultset('Artist')->with_context($schema->storage) }
    qr/ownership cannot be proven/,
    'the storage of a real backend is not a context: there it is the TransactionContext';
  throws_ok { $schema->resultset('Artist')->with_context($other->storage) }
    qr/ownership cannot be proven/,
    'nor is an immediate storage a context for a resultset of a real backend';

  my ($foreign_schema, $foreign_backend) = backend_schema();
  my $gate = DBIO::Test::Future->new;
  my $foreign_ctx;
  my $foreign_txn = $foreign_backend->txn_do_async(sub { ($foreign_ctx) = @_; $gate });

  throws_ok { $schema->resultset('Artist')->with_context($foreign_ctx) }
    qr/does not belong to this storage generation/,
    'a real backend still refuses the transaction context of another backend';
  throws_ok { $other->resultset('Artist')->with_context($foreign_ctx) }
    qr/does not belong to this storage generation/,
    'and an immediate storage refuses the transaction context of a real backend';

  $gate->done;
  $foreign_txn->get;
  is_deeply wire($backend), [], 'none of the refused bindings sent anything';
}

# ---------------------------------------------------------------------------
# pipeline: the immediate mode has none. It is a method of an async backend
# (DBIO::Storage::Async), and the immediate mode has no backend -- so there is
# no pipeline coderef and no pipeline context to bind to.
# ---------------------------------------------------------------------------
ok !immediate_schema()->storage->can('pipeline'),
  'the immediate storage has no pipeline, so there is no pipeline context to bind';

done_testing;
