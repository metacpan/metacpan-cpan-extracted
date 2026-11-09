use strict;
use warnings;
use Test::More;

use DBIO::Test;
use DBIO::Test::Future ();
use DBIO::SQLMaker;
use DBIO::Storage::Async;
use DBIO::Storage::PoolBase;

# karr k397, part 2. A transaction or a pipeline holds a connection of its pool
# for as long as it runs. When the coderef hands back the Future of a call on the
# STORAGE ($storage->delete_async(...), not $ctx->delete_async(...)), that call
# queues for a connection of the same pool -- with pool_size 1, for the one the
# transaction holds. The transaction waits for the Future, the Future for the
# transaction: nothing blocks and nothing moves, the transaction stays open on
# the server and every later acquire waits behind it.
#
# The pool knows which Futures it queued the storage's calls for (and the
# aggregates made of them). The default of _txn_inner_future and of the new
# _pipeline_inner_future ask it. The claims:
#
#   * a Future that waits in the queue of the pool the transaction or pipeline
#     holds a connection of is refused: its waiter leaves the queue and fails,
#     so its statement NEVER runs -- not after the ROLLBACK either -- and the
#     bracket fails at once with "the coderef returned a Future queued for this
#     transaction's own pool; call it on the context" (pipeline: "pipeline's"),
#     ROLLBACK for a transaction, the connection retired for a pipeline;
#   * so is an aggregate (needs_all) that contains such a Future;
#   * the pipeline of a transaction is refused the same way, and the
#     transaction fails with the message;
#   * a Future that waits on nothing of this pool's queue is not touched: the
#     context's own calls, a plain pending Future, a storage call that got a
#     connection at once (pool_size 2).
#
# Mock only: the real txn_do_async / pipeline over a fake wire and a real
# PoolBase.

{
  package K397B::Conn;
  sub new { bless { id => $_[1] }, $_[0] }
}

{
  package K397B::Pool;
  use base 'DBIO::Storage::PoolBase';
  sub _create_connection   { K397B::Conn->new(++$_[0]->{_next_id}) }
  sub _shutdown_connection { push @{ $_[0]{closed} }, $_[1]->{id} }
}

{
  package K397B::Backend;
  use base 'DBIO::Storage::Async';

  sub future_class     { 'DBIO::Test::Future' }
  sub sql_maker_class  { 'DBIO::SQLMaker' }
  sub _sql_maker_args  { (quote_char => '"', name_sep => '.') }
  sub _transform_sql   { $_[1] }
  sub _post_insert_sql { '' }

  sub pool {
    my $self = shift;
    return $self->{pool} ||= K397B::Pool->new(
      conninfo     => 'fake',
      size         => $self->{pool_size} || 1,
      future_class => 'DBIO::Test::Future',
    );
  }

  # A statement of the storage itself: it takes a connection of its own.
  sub _query_async {
    my ($self, $sql, $bind) = @_;
    my $pool = $self->pool;
    return $pool->acquire->then(sub {
      my $conn = shift;
      push @{ $self->{captured} }, "pooled:$sql";
      $pool->release($conn);
      return $self->future_class->done(1);
    });
  }

  # Statements of a transaction or pipeline: on the connection it holds.
  sub _query_async_pinned {
    my ($self, $conn, $sql, $bind) = @_;
    push @{ $self->{captured} }, $sql;
    return $self->future_class->done(1);
  }

  sub _pipeline_enter { push @{ $_[0]{captured} }, 'PIPELINE_ENTER'; 1 }
  sub _pipeline_sync  { push @{ $_[0]{captured} }, 'PIPELINE_SYNC'; $_[0]->future_class->done }
  sub _pipeline_exit  { push @{ $_[0]{captured} }, 'PIPELINE_EXIT'; 1 }
}

sub new_backend {
  my (%knobs) = @_;
  my $schema  = DBIO::Test->init_schema;
  my $backend = K397B::Backend->new($schema);
  my $owner   = $schema->storage;
  $backend->_owner_storage($owner);
  $owner->_async_context_owner_token($backend->_context_owner_token);
  $backend->{_test_schema_guard} = $schema;
  $backend->{captured} = [];
  $backend->{$_} = $knobs{$_} for keys %knobs;
  return $backend;
}

sub outcome {
  my ($f) = @_;
  return (undef, 'pending') unless $f->is_ready;
  my $value;
  return ($value, undef) if eval { $value = $f->get; 1 };
  return (undef, "$@");
}

my $TXN  = qr/the coderef returned a Future queued for this transaction's own pool; call it on the context/;
my $PIPE = qr/the coderef returned a Future queued for this pipeline's own pool; call it on the context/;

# --- transaction: a storage call in the coderef ------------------------------
{
  my $backend = new_backend();
  my $f = $backend->txn_do_async(sub {
    return $backend->delete_async('artist', { id => 1 });
  });

  my (undef, $error) = outcome($f);
  like $error, $TXN, 'txn: the transaction fails at once with the refusal, it does not hang';
  is_deeply $backend->{captured}, [ qw(BEGIN ROLLBACK) ],
    'txn: BEGIN, then ROLLBACK -- and the storage call\'s statement never ran';
  my $pool = $backend->pool;
  is $pool->available, 1, 'txn: the connection is back in the pool';
  is scalar @{ $pool->{_waiters} }, 0, 'txn: nobody is left queued';

  # The pool works on: the next call is served and runs.
  my ($rows, $e) = outcome($backend->delete_async('artist', { id => 2 }));
  is $e, undef, 'txn: the next call on the storage is served';
  is $backend->{captured}[-1], 'pooled:DELETE FROM "artist" WHERE "id" = ?',
    'txn: and runs';
}

# --- transaction: an aggregate containing a storage call -----------------------
{
  my $backend = new_backend();
  my $f = $backend->txn_do_async(sub {
    my ($ctx) = @_;
    return DBIO::Test::Future->needs_all(
      $ctx->delete_async('artist', { id => 1 }),
      $backend->delete_async('artist', { id => 2 }),
    );
  });

  my (undef, $error) = outcome($f);
  like $error, $TXN, 'txn aggregate: needs_all of a context call and a storage call is refused';
  ok !(grep { /^pooled:/ } @{ $backend->{captured} }),
    'txn aggregate: the storage call\'s statement never ran';
  is $backend->{captured}[-1], 'ROLLBACK', 'txn aggregate: ROLLBACK went out';
  is $backend->pool->available, 1, 'txn aggregate: the connection is back in the pool';
}

# --- transaction: what is not refused -------------------------------------------
{
  my $backend = new_backend();
  my ($v, $error) = outcome($backend->txn_do_async(sub {
    my ($ctx) = @_;
    return $ctx->delete_async('artist', { id => 1 });
  }));
  is $error, undef, 'context call: the transaction commits';
  is $backend->{captured}[-1], 'COMMIT', 'context call: COMMIT went out';

  my $plain = DBIO::Test::Future->new;
  my $f = $backend->txn_do_async(sub { $plain });
  ok !$f->is_ready, 'plain pending Future: the transaction waits for it';
  $plain->done('later');
  my ($value, $e) = outcome($f);
  is $e, undef, 'plain pending Future: and commits once it is done';
  is $value, 'later', 'plain pending Future: with its value';
}
{
  # A second connection is free: the storage call is served at once, it waits
  # on no queue, and nothing is refused.
  my $backend = new_backend(pool_size => 2);
  my ($v, $error) = outcome($backend->txn_do_async(sub {
    return $backend->delete_async('artist', { id => 1 });
  }));
  is $error, undef, 'pool_size 2: a storage call that got a connection is not refused';
  is_deeply $backend->{captured},
    [ 'BEGIN', 'pooled:DELETE FROM "artist" WHERE "id" = ?', 'COMMIT' ],
    'pool_size 2: it ran on the other connection, inside the transaction\'s time';
}

# --- pipeline: a storage call in the batch coderef --------------------------------
{
  my $backend = new_backend();
  my $f = $backend->pipeline(sub {
    return $backend->delete_async('artist', { id => 1 });
  });

  my (undef, $error) = outcome($f);
  like $error, $PIPE, 'pipeline: the batch fails at once with the refusal';
  ok !(grep { $_ eq 'PIPELINE_SYNC' } @{ $backend->{captured} }),
    'pipeline: no sync went out';
  ok !(grep { /^pooled:/ } @{ $backend->{captured} }),
    'pipeline: the storage call\'s statement never ran';
  my $pool = $backend->pool;
  is scalar @{ $pool->{_waiters} }, 0, 'pipeline: nobody is left queued';
  is_deeply $pool->{closed} // [], [ 1 ], 'pipeline: the connection was retired, as a failed batch retires it';

  # The slot is free again: a new connection serves the next call.
  my (undef, $e) = outcome($backend->delete_async('artist', { id => 2 }));
  is $e, undef, 'pipeline: the pool serves the next call on a fresh connection';
}

# --- pipeline: the batch's own Future is not refused -------------------------------
{
  my $backend = new_backend();
  my ($v, $error) = outcome($backend->pipeline(sub {
    my ($batch) = @_;
    return $batch->delete_async('artist', { id => 1 });
  }));
  is $error, undef, 'pipeline: a call on the batch is not refused';
  ok((grep { $_ eq 'PIPELINE_SYNC' } @{ $backend->{captured} }), 'pipeline: and the sync goes out');
}

# --- pipeline of a transaction ------------------------------------------------------
{
  my $backend = new_backend();
  my $f = $backend->txn_do_async(sub {
    my ($ctx) = @_;
    return $ctx->pipeline(sub {
      return $backend->delete_async('artist', { id => 1 });
    });
  });

  my (undef, $error) = outcome($f);
  like $error, $PIPE, 'txn pipeline: the transaction fails with the pipeline\'s refusal';
  ok !(grep { /^pooled:/ } @{ $backend->{captured} }),
    'txn pipeline: the storage call\'s statement never ran';
  is $backend->{captured}[-1], 'ROLLBACK', 'txn pipeline: ROLLBACK went out';
}

# --- an unbound resultset call derives its Future from the storage's ---------------------
# $rs->all_async is built with ->then from the Future of the storage; the pool
# knows it like the storage's own.
{
  my $backend = new_backend();
  my $owner   = $backend->_owner_storage;
  $owner->{_async_storage_obj} = $backend;
  my $rs = $owner->schema->resultset('Artist');

  my $f = $backend->txn_do_async(sub { $rs->all_async });
  my (undef, $error) = outcome($f);
  like $error, $TXN, 'txn rs: an unbound all_async is refused, the transaction does not hang';
  ok !(grep { /^pooled:/ } @{ $backend->{captured} }),
    'txn rs: its statement never ran';
  is $backend->{captured}[-1], 'ROLLBACK', 'txn rs: ROLLBACK went out';
  is $backend->pool->available, 1, 'txn rs: the connection is back in the pool';

  my $g = $backend->pipeline(sub { $rs->count_async });
  (undef, $error) = outcome($g);
  like $error, $PIPE, 'pipeline rs: an unbound count_async is refused';
  is scalar @{ $backend->pool->{_waiters} }, 0, 'pipeline rs: nobody is left queued';
}

# --- the seams stay overridable ---------------------------------------------------------
{
  package K397B::Driver;
  use base 'K397B::Backend';
  sub _txn_inner_future {
    my ($self, @args) = @_;
    $self->{seam_asked}++;
    return $self->next::method(@args);
  }
}
{
  my $backend = new_backend();
  bless $backend, 'K397B::Driver';
  my $f = $backend->txn_do_async(sub { $backend->delete_async('artist', { id => 1 }) });
  my (undef, $error) = outcome($f);
  is $backend->{seam_asked}, 1, 'driver override: the seam is asked';
  like $error, $TXN, 'driver override: next::method keeps the default refusal';
}

done_testing;
