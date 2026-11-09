use strict;
use warnings;
use Test::More;

use DBIO::Test;
use DBIO::Test::Storage;
use DBIO::Test::Future ();
use DBIO::SQLMaker;
use DBIO::Storage::Async;
use DBIO::Storage::DBI;

# karr k331 (measurement, finding 8 of the 2026-10-08 async review, k275).
# This file records what the 'immediate' mode does at three places where it
# differs from a real backend. (8a) is decided and asserts the decided claim;
# (8b) and (8c) still state the present behaviour, marked "IST-STAND k331
# (8x)"; none of those is a claim about what the behaviour ought to be. When one of them turns red, the behaviour
# was decided and changed -- rewrite the assertion to the decided claim.
#
#   (8a) DECIDED (maintainer, option A1 of k331 question 1): an UNBOUND
#        *_async (a row or resultset with no with_context) that fails inside
#        an immediate txn_do_async and is dropped belongs to the transaction,
#        as on a real backend: its error goes into the failed-statement
#        ledger ($storage->{_immediate_txn_failures}, karr k236), the
#        transaction ends in ROLLBACK and its Future fails. The unbound paths
#        Row::_row_run_async and ResultSet::_rs_run_async build their failed
#        Future themselves and write the ledger like Storage::_run_async.
#
#   (8b) The storage's own *_async methods are not guarded by the context
#        lifetime. A bound object held past the transaction is refused
#        ('no longer active', ResultSet::_assert_async_context_active /
#        Row::_assert_async_context_active, answered by
#        Storage::DBI::_context_active); the context itself IS the storage
#        in this mode, so $ctx->insert_async after the transaction just runs,
#        outside any transaction. The POD of Storage::txn_do_async says so
#        ("called after the transaction they simply run outside it").
#
#   (8c) with_context refuses the pooled backend itself: it is not a pinned
#        context, one comes out of txn_do_async / pipeline. It used to pass
#        both checks (->can('select_async'), the owner token the backend
#        carries by construction) and the bound resultset ran on the pool.
#        Storage::DBI::_assert_async_context_owner now refuses it.
#        NOTE: (8c) needs a real backend and so is not 'immediate' proper; it
#        is here because it is the third hole in the same context contract.
#
# Mock only. The fake storage of DBIO::Test is in the 'immediate' mode; the
# real backend of (8c) is a synchronous fake transport, as in
# t/resultset/with_context_immediate.t.

{
  package K331I::SyncPool;
  sub new { bless { txns => 0 }, shift }
  sub acquire     { DBIO::Test::Future->done('POOL') }
  sub acquire_txn { DBIO::Test::Future->done('TXN' . ++$_[0]->{txns}) }
  sub release     { 1 }
  sub shutdown    { 1 }
}
{
  package K331I::Backend;
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
  sub pool { $_[0]->{pool} ||= K331I::SyncPool->new }

  sub _answer {
    my ($self, $sql, $on) = @_;
    push @{ $self->{captured} }, { sql => $sql, on => $on };
    return $self->future_class->done(
        $sql =~ /^INSERT/            ? { artistid => 1 }
      : $sql =~ /^(?:UPDATE|DELETE)/ ? 1
      :                                ()
    );
  }
  sub _query_async        { $_[0]->_answer($_[1], 'the pool') }
  sub _query_async_pinned { $_[0]->_answer($_[2], $_[1]) }
}

DBIO::Storage::DBI->register_async_mode( k331_immediate_gaps_backend => 'K331I::Backend' );

sub immediate_schema {
  my $schema = DBIO::Test->init_schema;
  $schema->storage->reset_captured;
  return $schema;
}

sub backend_schema {
  my $schema = DBIO::Test->init_schema;
  $schema->storage->_async_mode('k331_immediate_gaps_backend');
  delete $schema->storage->{_async_storage_obj};
  $schema->storage->reset_captured;
  return ($schema, $schema->storage->_async_storage);
}

# What went through the synchronous storage, in order: first words.
sub synced {
  my ($schema) = @_;
  return [ map { ($_->{sql} =~ /(\w+)/)[0] } $schema->storage->captured_queries ];
}

sub failure_of {
  my ($future) = @_;
  return undef if eval { $future->get; 1 };
  return "$@";
}

# A row that is "in the database" without a statement having been sent.
sub stored {
  my ($schema, $source, $cols) = @_;
  my $row = $schema->resultset($source)->new_result($cols);
  $row->in_storage(1);
  return $row;
}

is immediate_schema()->storage->_async_mode, 'immediate',
  'the fake storage is in the immediate mode';

# The statement that fails: the storage's insert path dies for 'Duplicate',
# the way a unique constraint would.
no warnings 'redefine';
my $execute = \&DBIO::Test::Storage::_execute;
local *DBIO::Test::Storage::_execute = sub {
  my ($self, $op, $ident, @args) = @_;
  die qq{ERROR:  duplicate key value violates unique constraint "artist_name"\n}
    if $op eq 'insert' && ($args[0]{name} // '') eq 'Duplicate';
  return $self->$execute($op, $ident, @args);
};
use warnings 'redefine';

# ---------------------------------------------------------------------------
# (8a) a failed, dropped statement inside txn_do_async
# ---------------------------------------------------------------------------
my $dup = qr/duplicate key value/;
for my $case (
  [ 'the storage-level insert_async (the context itself)', sub {
      my ($ctx, $schema) = @_;
      $ctx->insert_async($schema->source('Artist'), { name => 'Duplicate' });
    }, $dup ],
  [ 'a ResultSet bound with with_context', sub {
      my ($ctx, $schema) = @_;
      $schema->resultset('Artist')->with_context($ctx)->create_async({ name => 'Duplicate' });
    }, $dup ],
  [ 'an UNBOUND ResultSet create_async', sub {
      my ($ctx, $schema) = @_;
      $schema->resultset('Artist')->create_async({ name => 'Duplicate' });
    }, $dup ],
  [ 'an UNBOUND Row insert_async', sub {
      my ($ctx, $schema) = @_;
      $schema->resultset('Artist')->new_result({ name => 'Duplicate' })->insert_async;
    }, $dup ],
  [ 'an UNBOUND Row update_async that fails (row not in storage)', sub {
      my ($ctx, $schema) = @_;
      $schema->resultset('Artist')->new_result({ name => 'Fine' })
             ->update_async({ name => 'Other' });
    }, qr/\S/ ],
) {
  my ($label, $statement, $error_re) = @$case;
  my $schema = immediate_schema();

  my $txn = $schema->storage->txn_do_async(sub {
    my ($ctx) = @_;
    my $dropped = $statement->($ctx, $schema);   # failed Future, never looked at
    return 'queued';
  });

  # (8a) DECIDED k331 (A1): a failed statement Future of the transaction fails
  # it, awaited or not -- bound or unbound, as on a real backend.
  like failure_of($txn), $error_re,
    "(8a) $label, dropped: the transaction fails with its error";
  is_deeply synced($schema), [ qw( BEGIN ROLLBACK ) ],
    "(8a) $label, dropped: BEGIN, ROLLBACK, no COMMIT";
}

# The same unbound failed statement, awaited and returned: the failed Future
# is adopted, so the transaction rolls back. The gap is only the DROPPED one.
{
  my $schema = immediate_schema();
  my $txn = $schema->storage->txn_do_async(sub {
    $schema->resultset('Artist')->create_async({ name => 'Duplicate' });
  });
  like failure_of($txn), qr/duplicate key value/,
    '(8a) control: an unbound failed statement that is RETURNED fails the transaction';
  is_deeply synced($schema), [ qw( BEGIN ROLLBACK ) ],
    '(8a) control: ... and is rolled back (the INSERT died before it was logged)';
}

# ---------------------------------------------------------------------------
# (8b) after the transaction: bound objects refused, the storage itself not
# ---------------------------------------------------------------------------
{
  my $schema = immediate_schema();
  my $storage = $schema->storage;
  my ($held_ctx, $held_rs, $held_row);

  $storage->txn_do_async(sub {
    my ($ctx) = @_;
    $held_ctx = $ctx;
    $held_rs  = $schema->resultset('Artist')->with_context($ctx);
    $held_row = stored($schema, Artist => { artistid => 1, name => 'Miles' })
                  ->with_context($ctx);
    return 1;
  })->get;
  $storage->reset_captured;

  is $held_ctx, $storage, '(8b) the context handed to the coderef IS the storage';

  # The guard that exists: a bound object is refused.
  like( do { eval { $held_rs->all_async }; "$@" },
    qr/no longer active/, '(8b) a ResultSet bound in the finished transaction is refused' );
  like( do { eval { $held_row->update_async({ name => 'x' }) }; "$@" },
    qr/no longer active/, '(8b) a Row bound in the finished transaction is refused' );
  is_deeply synced($schema), [],
    '(8b) the refused bound objects sent nothing';

  # IST-STAND k331 (8b): the context object itself has no such guard. It runs,
  # outside any transaction, on the one connection (ADR 0055 POD: "called
  # after the transaction they simply run outside it"). A real backend's
  # TransactionContext refuses here. Maintainer decision open: guard the
  # storage's own *_async by "a txn is running"? That would also refuse every
  # plain $storage->insert_async outside a txn, so it cannot be the storage.
  my $f = $held_ctx->insert_async($schema->source('Artist'), { name => 'Late' });
  ok !$f->is_failed,
    'IST-STAND k331 (8b): the held context\'s insert_async after the transaction is accepted';
  is_deeply synced($schema), [ 'INSERT' ],
    'IST-STAND k331 (8b): ... and runs as one bare INSERT, no BEGIN/COMMIT';

  $storage->reset_captured;
  my $s = $held_ctx->select_async($schema->source('Artist'), [ 'me.name' ], {}, {});
  ok !$s->is_failed,
    'IST-STAND k331 (8b): select_async on the held context after the transaction is accepted';
  is_deeply synced($schema), [ 'SELECT' ],
    'IST-STAND k331 (8b): ... and runs as one bare SELECT';

  # And: a later transaction on the same storage re-activates the same
  # context (it is the storage), so an object bound in transaction 1 is
  # accepted in transaction 2 and runs there.
  $storage->reset_captured;
  my $again = $storage->txn_do_async(sub { $held_rs->all_async });
  ok !$again->is_failed,
    'IST-STAND k331 (8b): a ResultSet bound in transaction 1 is accepted inside transaction 2';
  is_deeply synced($schema), [ qw( BEGIN SELECT COMMIT ) ],
    'IST-STAND k331 (8b): ... and runs there';
}

# ---------------------------------------------------------------------------
# (8c) with_context with the pooled backend itself
# ---------------------------------------------------------------------------
{
  my ($schema, $backend) = backend_schema();
  isa_ok $backend, 'K331I::Backend', '(8c) the real backend';

  my $bound = eval { $schema->resultset('Artist')->with_context($backend) };
  my $err   = $@;
  # SOLL k331 (8c): the pooled backend is not a pinned context -- one comes
  # out of txn_do_async or a pipeline coderef -- so with_context refuses it,
  # naming that, instead of running the statements on whatever pool
  # connection is free while the caller believes them pinned.
  ok !$bound, 'SOLL k331 (8c): with_context($pooled_backend) is refused';
  like $err, qr/pooled async backend is not a pinned context/,
    'SOLL k331 (8c): ... naming the backend and where a context comes from';
  like $err, qr/txn_do_async/, 'SOLL k331 (8c): ... and txn_do_async';
  is scalar @{ $backend->{captured} }, 0,
    'SOLL k331 (8c): ... and nothing went to the pool';

  # A Row too.
  my $row = eval {
    stored($schema, Artist => { artistid => 1, name => 'Miles' })->with_context($backend)
  };
  ok !$row, 'SOLL k331 (8c): Row->with_context($pooled_backend) is refused';
  like $@, qr/not a pinned context/, 'SOLL k331 (8c): ... with the same message';
}

done_testing;
