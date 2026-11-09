use strict;
use warnings;
use Test::More;

use DBIO::Test;
use DBIO::Test::Future ();
use DBIO::SQLMaker;
use DBIO::Storage::Async;
use DBIO::Storage::PoolBase;

# karr k228. txn_do_async decided whether the coderef's return value was a
# Future with `ref($inner) && $inner->can('then')`. An UNBLESSED reference
# passes `ref` and then dies in `->can` -- and returning one is the ordinary
# case: $ctx->insert resolves the returned-columns hashref. The die happened
# inside the BEGIN continuation, so the Future implementation turned it into a
# failed Future and the finalizer released the connection: neither COMMIT nor
# ROLLBACK was ever sent, and the connection went back into the pool with the
# transaction still open, for the next borrower to write into.
#
# The fixture makes that state observable. The fake wire opens a transaction
# on the connection object at BEGIN and closes it at COMMIT/ROLLBACK, and the
# pool (a real DBIO::Storage::PoolBase of size 1) records, for every release,
# whether the connection it took back was still inside a transaction. With one
# connection in the pool, the next acquire hands out that same connection, so
# "released in a transaction" and "the next borrower inherits it" are the same
# fact seen from two sides; both are asserted.

# --- A connection whose transaction state the fake wire drives --------------
{
  package K228::Conn;
  sub new { bless { id => $_[1], in_txn => 0 }, $_[0] }
}

# --- A real PoolBase (size 1) that records the state of each release --------
{
  package K228::Pool;
  use base 'DBIO::Storage::PoolBase';

  sub _create_connection { K228::Conn->new(++$_[0]->{_next_id}) }

  sub release {
    my ($self, $conn) = @_;
    push @{ $self->{release_log} },
      { conn => $conn->{id}, in_txn => $conn->{in_txn} };
    return $self->SUPER::release($conn);
  }
}

# --- The async backend: real txn_do_async / pipeline, fake wire -------------
{
  package K228::Backend;
  use base 'DBIO::Storage::Async';

  sub future_class     { 'DBIO::Test::Future' }
  sub sql_maker_class  { 'DBIO::SQLMaker' }
  sub _sql_maker_args  { (quote_char => '"', name_sep => '.') }
  sub _transform_sql   { $_[1] }
  sub _post_insert_sql { ' RETURNING *' }

  sub pool {
    return $_[0]->{pool} ||= K228::Pool->new(
      conninfo     => 'fake',
      size         => 1,
      future_class => 'DBIO::Test::Future',
    );
  }

  sub _query_async_pinned {
    my ($self, $conn, $sql, $bind) = @_;
    push @{ $self->{captured} }, $sql;
    $conn->{in_txn} = 1 if $sql eq 'BEGIN';
    $conn->{in_txn} = 0 if $sql eq 'COMMIT' || $sql eq 'ROLLBACK';
    # The RETURNING row of an INSERT: the database-populated primary key.
    return $self->future_class->done({ artistid => 7 }) if $sql =~ /^INSERT/;
    return $self->future_class->done;
  }

  sub _pipeline_enter { push @{ $_[0]->{captured} }, 'PIPELINE_ENTER'; 1 }
  sub _pipeline_exit  { push @{ $_[0]->{captured} }, 'PIPELINE_EXIT';  1 }
  sub _pipeline_sync {
    push @{ $_[0]->{captured} }, 'PIPELINE_SYNC';
    return $_[0]->future_class->done;
  }
}

# Wire the backend to an owning sync storage and a shared context-owner token,
# as t/test/15_async_orchestration.t does, so the TransactionContext's
# ownership assertion holds and $ctx->insert can run.
sub new_backend {
  my $schema  = DBIO::Test->init_schema;
  my $backend = K228::Backend->new($schema);
  my $owner   = $schema->storage;
  $backend->_owner_storage($owner);
  $owner->_async_context_owner_token($backend->_context_owner_token);
  $backend->{_test_schema_guard} = $schema;
  $backend->{captured} = [];
  return $backend;
}

sub verbs { [ map { /^(\w+)/ ? $1 : $_ } @{ $_[0]->{captured} } ] }

# Settle-state of a Future as (value, error): the value it resolved with, or
# the error it failed with -- without letting a failure abort the test file.
sub outcome {
  my ($f) = @_;
  my $value;
  return ($value, undef) if eval { $value = $f->get; 1 };
  return (undef, "$@");
}

# The connection is back in the pool and outside a transaction: it was
# released exactly once, not inside a transaction, and the next acquire (pool
# of one) resolves at once with a connection that is not inside one either.
sub connection_is_clean {
  my ($backend, $label) = @_;
  my $pool = $backend->pool;
  is_deeply $pool->{release_log}, [ { conn => 1, in_txn => 0 } ],
    "$label: the connection was released once, outside a transaction";
  my $next = $pool->acquire;
  ok $next->is_ready, "$label: the next acquire resolves";
  ok !$next->get->{in_txn},
    "$label: the next borrower does not inherit an open transaction";
  $pool->release($next->get);
}

# ---------------------------------------------------------------------------
# A coderef that returns an unblessed HASH ref -- here the returned-columns
# hashref of $ctx->insert, the case the card was found on. Asserts: the wire
# sees BEGIN, INSERT, COMMIT in that order; txn_do_async resolves with that very
# hashref (not a failure, not a copy); the connection comes back outside a
# transaction. Before the fix the Future failed with "Can't call method "can"
# on unblessed reference", the wire stopped after the INSERT, and the
# connection was released with in_txn still 1.
# ---------------------------------------------------------------------------
{
  my $backend = new_backend();
  my $returned;
  my $f = $backend->txn_do_async(sub {
    my ($ctx) = @_;
    $returned = $ctx->insert('artist', { name => 'Miles Davis' });
    return $returned;
  });

  my ($got, $error) = outcome($f);
  is $error, undef, 'hashref return: txn_do_async succeeds';
  is_deeply verbs($backend), [ 'BEGIN', 'INSERT', 'COMMIT' ],
    'hashref return: COMMIT is sent after the work';
  is ref $returned, 'HASH', 'the coderef really returned an unblessed hashref';
  is $got, $returned,
    'hashref return: the transaction resolves with the coderef\'s own hashref';
  is_deeply $got, { name => 'Miles Davis', artistid => 7 },
    'hashref return: carrying the returned columns';
  connection_is_clean($backend, 'hashref return');
}

# ---------------------------------------------------------------------------
# A coderef that returns an unblessed ARRAY ref. Same claim as above for the
# other common container shape: COMMIT is sent, the transaction resolves with
# that arrayref, the connection comes back clean.
# ---------------------------------------------------------------------------
{
  my $backend = new_backend();
  my $returned = [ 'Miles Davis', 'John Coltrane' ];
  my $f = $backend->txn_do_async(sub { return $returned });

  my ($got, $error) = outcome($f);
  is $error, undef, 'arrayref return: txn_do_async succeeds';
  is_deeply verbs($backend), [ 'BEGIN', 'COMMIT' ],
    'arrayref return: COMMIT is sent';
  is $got, $returned,
    'arrayref return: the transaction resolves with the coderef\'s own arrayref';
  connection_is_clean($backend, 'arrayref return');
}

# ---------------------------------------------------------------------------
# A coderef that dies. This path already worked; it is here so the fix cannot
# trade one terminal statement for the other. Asserts: ROLLBACK (never COMMIT)
# is sent after BEGIN, the transaction fails with the coderef's own error, and
# the connection comes back clean.
# ---------------------------------------------------------------------------
{
  my $backend = new_backend();
  my $f = $backend->txn_do_async(sub {
    my ($ctx) = @_;
    $ctx->insert('artist', { name => 'Miles Davis' });
    die "callback gave up\n";
  });

  my (undef, $error) = outcome($f);
  like $error, qr/callback gave up/,
    'dying coderef: txn_do_async fails with the coderef\'s own error';
  is_deeply verbs($backend), [ 'BEGIN', 'INSERT', 'ROLLBACK' ],
    'dying coderef: ROLLBACK is sent, COMMIT is not';
  connection_is_clean($backend, 'dying coderef');
}

# ---------------------------------------------------------------------------
# The same test on the pipeline scaffold (_pipeline_on_conn), found by the
# k228 sweep. There the connection was already released before the check, so
# nothing leaked, but a batch coderef returning a plain hashref or arrayref
# made pipeline() fail with "Can't call method "can" on unblessed reference"
# after every statement had run. Asserts: the pipeline resolves with the
# coderef's own reference, brackets as usual, and releases once.
# ---------------------------------------------------------------------------
for my $case (
  [ hashref  => { inserted => 2 } ],
  [ arrayref => [ 1, 2 ] ],
) {
  my ($label, $returned) = @$case;
  my $backend = new_backend();
  my $f = $backend->pipeline(sub { return $returned });

  my ($got, $error) = outcome($f);
  is $error, undef, "pipeline, $label return: succeeds";
  is $got, $returned,
    "pipeline, $label return: resolves with the coderef's own $label";
  is_deeply verbs($backend), [ 'PIPELINE_ENTER', 'PIPELINE_SYNC', 'PIPELINE_EXIT' ],
    "pipeline, $label return: bracketed as usual";
  is scalar @{ $backend->pool->{release_log} }, 1,
    "pipeline, $label return: the connection was released once";
}

done_testing;
