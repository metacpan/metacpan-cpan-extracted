use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::Test;
use DBIO::Test::Future ();
use DBIO::SQLMaker;
use DBIO::Storage::Async;

# karr core k213 -- a TransactionContext must never hand work to a connection
# other than the one BEGIN ran on.
#
# Before k213 the context's `pipeline` and `txn_do_async` were plain
# delegations to the storage, so both reached into the pool for a SECOND
# connection: the "pipeline inside a transaction" ran outside the transaction
# (invisible to it, not rolled back with it), and the "nested transaction" was
# an independent one that commits even when the outer one rolls back -- and
# deadlocks as soon as it waits on a row lock the outer transaction holds,
# because the outer COMMIT waits on the inner Future in turn.
#
# The claims this file pins:
#   * $ctx->pipeline runs its batch on the PINNED transaction connection: no
#     pool acquire, the bracket and every batched statement on the txn
#     connection, and the pipeline does not release that connection -- only the
#     transaction boundary does, exactly once.
#   * $ctx->txn_do_async refuses loudly. There is no async savepoint seam, so
#     the only honest nesting would be an independent transaction; that stays
#     reachable, but only when asked for by name ($ctx->storage->txn_do_async).
#
# The fake pool hands out DISTINCT connections per acquire so that "a foreign
# connection was taken" is observable, not masked by a shared 'CONN' string.

{
  package K213::Pool;

  sub new { bless { acquired => [], txn_acquired => [], released => [], n => 0 }, $_[0] }
  sub future_class { 'DBIO::Test::Future' }

  sub acquire {
    my ($self) = @_;
    my $conn = 'POOLED-' . ++$self->{n};
    push @{ $self->{acquired} }, $conn;
    return DBIO::Test::Future->done($conn);
  }

  sub acquire_txn {
    my ($self) = @_;
    my $conn = 'TXN-' . ++$self->{n};
    push @{ $self->{txn_acquired} }, $conn;
    return DBIO::Test::Future->done($conn);
  }

  sub release   { push @{ $_[0]->{released} }, $_[1]; 1 }
  sub available { 1 }
  sub shutdown  { 1 }
}

{
  package K213::Backend;
  use base 'DBIO::Storage::Async';

  sub future_class     { 'DBIO::Test::Future' }
  sub sql_maker_class  { 'DBIO::SQLMaker' }
  sub _sql_maker_args  { (quote_char => '"', name_sep => '.') }
  sub _transform_sql   { $_[1] }
  sub _post_insert_sql { '' }
  sub pool             { $_[0]->{pool} ||= K213::Pool->new }

  sub _query_async {
    my ($self, $sql, $bind) = @_;
    push @{ $self->{captured} }, { sql => $sql, conn => 'POOLED-QUERY' };
    return DBIO::Test::Future->done;
  }

  sub _query_async_pinned {
    my ($self, $conn, $sql, $bind) = @_;
    push @{ $self->{captured} }, { sql => $sql, conn => $conn };
    return DBIO::Test::Future->done;
  }

  sub _pipeline_enter { push @{ $_[0]->{captured} }, { sql => 'PIPELINE_ENTER', conn => $_[1] }; 1 }
  sub _pipeline_exit  { push @{ $_[0]->{captured} }, { sql => 'PIPELINE_EXIT',  conn => $_[1] }; 1 }
  sub _pipeline_sync  {
    push @{ $_[0]->{captured} }, { sql => 'PIPELINE_SYNC', conn => $_[1] };
    return DBIO::Test::Future->done;
  }
}

sub new_backend {
  my $schema  = DBIO::Test->init_schema;
  my $backend = K213::Backend->new($schema);
  $backend->{captured} = [];
  my $owner = $schema->storage;
  $backend->_owner_storage($owner);
  $owner->_async_context_owner_token($backend->_context_owner_token);
  $backend->{_test_schema_guard} = $schema;
  return $backend;
}

sub trail { [ map { ($_->{sql} =~ /^INSERT/ ? 'INSERT' : $_->{sql}) . '@' . $_->{conn} } @{ $_[0]->{captured} } ] }

# ---------------------------------------------------------------------------
# $ctx->pipeline batches on the pinned transaction connection
# ---------------------------------------------------------------------------
{
  my $backend = new_backend();
  my $batch_ctx;

  my $f = $backend->txn_do_async(sub {
    my ($ctx) = @_;
    return $ctx->pipeline(sub {
      my ($batch) = @_;
      $batch_ctx = $batch;
      return $batch->insert_async('artist', { name => 'Miles Davis' });
    });
  });

  lives_ok { $f->get } 'a pipeline inside a transaction completes';

  my $pool = $backend->pool;
  is_deeply $pool->{acquired}, [],
    'the pipeline took NO connection from the pool (no foreign connection)';
  is_deeply $pool->{txn_acquired}, [ 'TXN-1' ],
    'exactly one connection was checked out: the transaction connection';
  is $batch_ctx->pipeline_conn, 'TXN-1',
    'the batch context is bracketed on the pinned transaction connection';

  is_deeply trail($backend), [
    'BEGIN@TXN-1',
    'PIPELINE_ENTER@TXN-1',
    'INSERT@TXN-1',
    'PIPELINE_SYNC@TXN-1',
    'PIPELINE_EXIT@TXN-1',
    'COMMIT@TXN-1',
  ], 'the whole batch runs inside BEGIN .. COMMIT on the transaction connection';

  is_deeply $pool->{released}, [ 'TXN-1' ],
    'the pinned connection is released once, by the transaction boundary -- '
    . 'the inner pipeline does not hand it back mid-transaction';
}

# ---------------------------------------------------------------------------
# A failing batch inside the transaction rolls the transaction back
# ---------------------------------------------------------------------------
{
  my $backend = new_backend();

  my $f = $backend->txn_do_async(sub {
    my ($ctx) = @_;
    return $ctx->pipeline(sub { die "batch boom\n" });
  });

  throws_ok { $f->get } qr/batch boom/, 'the batch failure fails the transaction';
  is_deeply trail($backend), [
    'BEGIN@TXN-1', 'PIPELINE_ENTER@TXN-1', 'PIPELINE_EXIT@TXN-1', 'ROLLBACK@TXN-1',
  ], 'the batch exits pipeline mode and the transaction rolls back on the same connection';
  is_deeply $backend->pool->{released}, [],
    'and the connection is not released: the failed batch marked it unusable, '
    . 'the boundary retires it';
}

# ---------------------------------------------------------------------------
# $ctx->pipeline after the transaction ended refuses
# ---------------------------------------------------------------------------
{
  my $backend = new_backend();
  my $kept;
  $backend->txn_do_async(sub { $kept = $_[0]; return 1 })->get;

  throws_ok { $kept->pipeline(sub { 1 }) }
    qr/transaction context is no longer active/,
    'a pipeline on a finished transaction context refuses instead of touching a released connection';
  is_deeply $backend->pool->{acquired}, [], 'and does not fall back to a pooled connection';
}

# ---------------------------------------------------------------------------
# $ctx->txn_do_async refuses: no silent independent transaction
# ---------------------------------------------------------------------------
{
  my $backend = new_backend();
  my $inner_ran = 0;

  my $f = $backend->txn_do_async(sub {
    my ($ctx) = @_;
    return $ctx->txn_do_async(sub { $inner_ran++; return 1 });
  });

  throws_ok { $f->get }
    qr/nested txn_do_async.*independent transaction.*storage->txn_do_async/s,
    'nested txn_do_async on a transaction context refuses and names the explicit alternative';
  is $inner_ran, 0, 'the nested coderef never ran';
  is_deeply $backend->pool->{txn_acquired}, [ 'TXN-1' ],
    'no second transaction connection was acquired';
  is_deeply $backend->pool->{acquired}, [], 'no pooled connection either';
  is_deeply trail($backend), [ 'BEGIN@TXN-1', 'ROLLBACK@TXN-1' ],
    'the refusal rolls the outer transaction back';

  isa_ok(
    do { my $e; eval { $f->get; 1 } or $e = $@; $e },
    'DBIO::Exception',
    'the refusal is a DBIO::Exception',
  );
}

# The independent transaction stays reachable when asked for by name.
{
  my $backend = new_backend();

  my $f = $backend->txn_do_async(sub {
    my ($ctx) = @_;
    return $ctx->storage->txn_do_async(sub { return 'inner' });
  });

  is scalar $f->get, 'inner',
    'an explicitly independent transaction via $ctx->storage->txn_do_async still works';
  is_deeply $backend->pool->{txn_acquired}, [ 'TXN-1', 'TXN-2' ],
    'and it is visibly a second transaction connection';
}

done_testing;
