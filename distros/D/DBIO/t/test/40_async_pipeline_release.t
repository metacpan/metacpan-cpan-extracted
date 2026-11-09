use strict;
use warnings;
use Test::More;

use DBIO::Test;
use DBIO::Test::Future ();
use DBIO::SQLMaker;
use DBIO::Storage::Async;
use DBIO::Storage::PoolBase;

# karr k231. The pipeline scaffold (_pipeline_on_conn) handed its pooled
# connection back only on the paths where nothing it called died:
#
#   * a dying context constructor escaped before anything was released;
#   * a _pipeline_sync that died instead of returning a Future skipped both the
#     pipeline exit and the release;
#   * a dying _pipeline_exit skipped the release that followed it, on every one
#     of its three call sites, and replaced whatever error ended the batch.
#
# Each leak keeps one connection checked out for good, so N of them wedge a
# pool of N. The claim this file pins is the one k229 pinned for deploy_async:
# whatever dies, the pipeline reports it through its Future with the error that
# ended the batch, pipeline mode is left where it was entered (best-effort),
# and the pool gets its slot back exactly once. Where the exit succeeded that
# is a release. Where the exit died, the connection is still in pipeline mode
# and the next borrower could not use it, so it is retired instead: never
# handed out again, its slot freed for a fresh connection.
#
# The fixture makes all of it observable. The fake wire keeps pipeline mode on
# the connection object -- _pipeline_enter sets it, a successful _pipeline_exit
# clears it -- and a real DBIO::Storage::PoolBase of size 1 records, for every
# release, whether the connection it took back was still in pipeline mode, and
# every connection it closes on retirement. With one connection, a leak shows
# as a next acquire that never resolves.

# --- A connection whose pipeline state the fake wire drives ------------------
{
  package K231::Conn;
  sub new { bless { id => $_[1], in_pipeline => 0 }, $_[0] }
}

# --- A real PoolBase (size 1) recording each release and each close ---------
{
  package K231::Pool;
  use base 'DBIO::Storage::PoolBase';

  sub _create_connection { K231::Conn->new(++$_[0]->{_next_id}) }

  sub _shutdown_connection { push @{ $_[0]->{closed} }, $_[1]->{id} }

  sub release {
    my ($self, $conn) = @_;
    push @{ $self->{release_log} },
      { conn => $conn->{id}, in_pipeline => $conn->{in_pipeline} };
    return $self->SUPER::release($conn);
  }
}

# --- A pipeline context class whose constructor dies -------------------------
{
  package K231::DyingContext;
  sub new { die "context constructor gave up\n" }
}

# --- The async backend: real pipeline / txn_do_async, fake wire -------------
# Knobs, each a failure point of the bracket:
#   die_context  -- the context constructor dies
#   die_sync     -- _pipeline_sync dies instead of returning a Future
#   fail_sync    -- _pipeline_sync returns a failed Future
#   sync_future  -- _pipeline_sync returns this (pending) Future
#   die_exit     -- _pipeline_exit dies, leaving the connection in pipeline
#                   mode (EV::Pg's exit_pipeline croaks when the pipeline is
#                   not idle)
{
  package K231::Backend;
  use base 'DBIO::Storage::Async';

  sub future_class     { 'DBIO::Test::Future' }
  sub sql_maker_class  { 'DBIO::SQLMaker' }
  sub _sql_maker_args  { (quote_char => '"', name_sep => '.') }
  sub _transform_sql   { $_[1] }
  sub _post_insert_sql { '' }

  sub pool {
    return $_[0]->{pool} ||= K231::Pool->new(
      conninfo     => 'fake',
      size         => 1,
      future_class => 'DBIO::Test::Future',
    );
  }

  sub _pipeline_context_class {
    my ($self) = @_;
    return 'K231::DyingContext' if $self->{die_context};
    return $self->next::method;
  }

  sub _query_async_pinned {
    my ($self, $conn, $sql, $bind) = @_;
    push @{ $self->{captured} }, $sql;
    return $self->future_class->done;
  }

  sub _pipeline_enter {
    my ($self, $conn) = @_;
    push @{ $self->{captured} }, 'PIPELINE_ENTER';
    $conn->{in_pipeline} = 1;
    return 1;
  }

  sub _pipeline_sync {
    my ($self, $conn) = @_;
    push @{ $self->{captured} }, 'PIPELINE_SYNC';
    die "sync croaked\n" if $self->{die_sync};
    return $self->future_class->fail("sync failed\n") if $self->{fail_sync};
    return $self->{sync_future} if $self->{sync_future};
    return $self->future_class->done;
  }

  sub _pipeline_exit {
    my ($self, $conn) = @_;
    push @{ $self->{captured} }, 'PIPELINE_EXIT';
    die "exit croaked: pipeline not idle\n" if $self->{die_exit};
    $conn->{in_pipeline} = 0;
    return 1;
  }
}

# Wire the backend to an owning sync storage and a shared context-owner token,
# as t/test/15_async_orchestration.t does, so the pipeline and transaction
# contexts' ownership assertions hold.
sub new_backend {
  my (%knobs) = @_;
  my $schema  = DBIO::Test->init_schema;
  my $backend = K231::Backend->new($schema);
  my $owner   = $schema->storage;
  $backend->_owner_storage($owner);
  $owner->_async_context_owner_token($backend->_context_owner_token);
  $backend->{_test_schema_guard} = $schema;
  $backend->{captured} = [];
  $backend->{$_} = $knobs{$_} for keys %knobs;
  return $backend;
}

# Settle-state of a Future as (value, error), without letting a failure abort
# the test file. A pending Future reports as the error 'pending'.
sub outcome {
  my ($f) = @_;
  return (undef, 'pending') unless $f->is_ready;
  my $value;
  return ($value, undef) if eval { $value = $f->get; 1 };
  return (undef, "$@");
}

# The pipeline answered through a Future instead of throwing, and that Future
# failed with $want.
sub pipeline_fails_with {
  my ($backend, $coderef, $want, $label) = @_;
  my $f;
  my $lived = eval { $f = $backend->pipeline($coderef); 1 };
  ok $lived, "$label: pipeline reports through its Future, it does not throw"
    or diag $@;
  return unless $lived;
  my (undef, $error) = outcome($f);
  like $error, $want, "$label: the pipeline fails with the error that ended it";
}

# The connection went back exactly once, out of pipeline mode, by release and
# not by retirement, and the next acquire (pool of one) resolves at once with
# that same connection.
sub released_once {
  my ($backend, $label) = @_;
  my $pool = $backend->pool;
  is_deeply $pool->{release_log}, [ { conn => 1, in_pipeline => 0 } ],
    "$label: the connection was released exactly once, out of pipeline mode";
  is_deeply $pool->{closed} // [], [],
    "$label: it was released, not retired";
  my $next = $pool->acquire;
  ok $next->is_ready, "$label: the next acquire resolves";
  return unless $next->is_ready;
  ok !$next->get->{in_pipeline},
    "$label: the next borrower does not inherit pipeline mode";
  $pool->release($next->get);
}

# The connection whose exit died never goes back: it was retired -- closed
# once, no longer counted by the pool, never released -- and the next acquire
# (pool of one) still resolves at once, on a fresh connection out of pipeline
# mode.
sub retired_not_released {
  my ($backend, $label) = @_;
  my $pool = $backend->pool;
  is_deeply $pool->{release_log} // [], [],
    "$label: the connection was not released";
  is_deeply $pool->{closed} // [], [ 1 ],
    "$label: it was retired, closed exactly once";
  is $pool->size, 0, "$label: the pool no longer counts it";
  my $next = $pool->acquire;
  ok $next->is_ready, "$label: the next acquire resolves";
  return unless $next->is_ready;
  my $fresh = $next->get;
  is $fresh->{id}, 2,
    "$label: on a fresh connection, never the retired one";
  ok !$fresh->{in_pipeline},
    "$label: the fresh connection is not in pipeline mode";
  $pool->release($fresh);
}

# ---------------------------------------------------------------------------
# The context constructor dies. Asserts: pipeline() fails with the
# constructor's own error; the coderef never runs and pipeline mode is never
# entered, so there is nothing to exit (no ENTER, no EXIT on the wire); the
# connection goes back exactly once and the next acquire resolves. Before the
# fix the die escaped the acquire continuation -- the Future failed, the
# connection stayed checked out and the next acquire stayed pending.
# ---------------------------------------------------------------------------
{
  my $backend = new_backend(die_context => 1);
  my $ran = 0;
  pipeline_fails_with($backend, sub { $ran++; return 1 },
    qr/context constructor gave up/, 'context constructor dies');
  is $ran, 0, 'context constructor dies: the batch coderef never ran';
  is_deeply $backend->{captured}, [],
    'context constructor dies: pipeline mode was neither entered nor exited';
  released_once($backend, 'context constructor dies');
}

# ---------------------------------------------------------------------------
# _pipeline_sync dies instead of returning a Future. Asserts: the pipeline
# fails with the sync's own error; pipeline mode is exited after the attempted
# sync (ENTER, SYNC, EXIT); the connection goes back exactly once, out of
# pipeline mode, and the next borrower gets it out of pipeline mode. Before the
# fix neither the exit nor the release ran.
# ---------------------------------------------------------------------------
{
  my $backend = new_backend(die_sync => 1);
  pipeline_fails_with($backend, sub { return 1 },
    qr/sync croaked/, '_pipeline_sync dies');
  is_deeply $backend->{captured}, [ 'PIPELINE_ENTER', 'PIPELINE_SYNC', 'PIPELINE_EXIT' ],
    '_pipeline_sync dies: pipeline mode is exited after the attempted sync';
  retired_not_released($backend, '_pipeline_sync dies');
}

# ---------------------------------------------------------------------------
# _pipeline_exit dies, on each of its call sites. The exit is best-effort: it
# must neither cost the pool its slot nor replace the error that ended the
# batch. The connection is still in pipeline mode -- the exit that would have
# cleared it is the one that died -- so handing it to the next borrower would
# break that borrower (EV::Pg rejects a plain query in pipeline mode).
# Asserts per case: the pipeline fails with that error -- the exit's own only
# when nothing else failed, since a batch whose connection could not leave
# pipeline mode is not a success the caller may ignore -- the full bracket
# ran, and the connection is retired, never released: closed once, dropped from
# the pool, and the next acquire resolves on a fresh connection. Before the
# fix the connection was never handed back at all, and the three failure cases
# reported the exit's error instead of their own.
# ---------------------------------------------------------------------------
for my $case (
  [ 'after a successful batch', {},
    sub { return 1 },
    qr/exit croaked: pipeline not idle/,
    [ 'PIPELINE_ENTER', 'PIPELINE_SYNC', 'PIPELINE_EXIT' ] ],
  [ 'after the batch coderef died', {},
    sub { die "batch gave up\n" },
    qr/batch gave up/,
    [ 'PIPELINE_ENTER', 'PIPELINE_EXIT' ] ],
  [ 'after the sync Future failed', { fail_sync => 1 },
    sub { return 1 },
    qr/sync failed/,
    [ 'PIPELINE_ENTER', 'PIPELINE_SYNC', 'PIPELINE_EXIT' ] ],
  # The EV::Pg shape: pipeline_sync croaks with batched statements still in
  # flight, and exit_pipeline then croaks because the pipeline is not idle.
  [ 'after _pipeline_sync died', { die_sync => 1 },
    sub { return 1 },
    qr/sync croaked/,
    [ 'PIPELINE_ENTER', 'PIPELINE_SYNC', 'PIPELINE_EXIT' ] ],
) {
  my ($where, $knobs, $coderef, $want, $wire) = @$case;
  my $label = "_pipeline_exit dies $where";
  my $backend = new_backend(%$knobs, die_exit => 1);
  pipeline_fails_with($backend, $coderef, $want, $label);
  is_deeply $backend->{captured}, $wire, "$label: the exit was attempted";
  retired_not_released($backend, $label);
}

# ---------------------------------------------------------------------------
# _pipeline_exit dies while another caller is already queued for the pool's
# one connection. Retiring alone frees the slot but wakes nobody: the waiter
# was queued for this very connection, and no release will ever come for it.
# Asserts: while the pipeline holds the connection the waiter is pending; once
# the sync resolves and the exit dies, the pipeline fails with the exit's
# error, the connection is retired and never released, and the waiter resolves
# at once -- on a fresh connection out of pipeline mode, not on the retired one.
# ---------------------------------------------------------------------------
{
  my $sync = DBIO::Test::Future->new;
  my $backend = new_backend(sync_future => $sync, die_exit => 1);
  my $pool = $backend->pool;
  my $f = $backend->pipeline(sub { return 1 });
  my $waiter = $pool->acquire;
  ok !$waiter->is_ready,
    'queued waiter, _pipeline_exit dies: the waiter is pending while the pipeline holds the connection';

  $sync->done;
  my (undef, $error) = outcome($f);
  like $error, qr/exit croaked: pipeline not idle/,
    'queued waiter, _pipeline_exit dies: the pipeline fails with the exit\'s error';
  is_deeply $pool->{release_log} // [], [],
    'queued waiter, _pipeline_exit dies: the connection was not released';
  is_deeply $pool->{closed} // [], [ 1 ],
    'queued waiter, _pipeline_exit dies: it was retired, closed exactly once';
  ok $waiter->is_ready,
    'queued waiter, _pipeline_exit dies: the waiter resolves';
  if ($waiter->is_ready) {
    my $fresh = $waiter->get;
    is $fresh->{id}, 2,
      'queued waiter, _pipeline_exit dies: on a fresh connection, never the retired one';
    ok !$fresh->{in_pipeline},
      'queued waiter, _pipeline_exit dies: the fresh connection is not in pipeline mode';
    is $pool->size, 1,
      'queued waiter, _pipeline_exit dies: the pool counts the fresh connection only';
  }
}

# ---------------------------------------------------------------------------
# The obligation documented at _pipeline_sync, held against the fix: on the
# success path the connection goes back only once the sync Future has settled,
# because until then the batch's results are still being read off it. Asserts:
# while the sync is pending the pipeline is pending, nothing was released and
# pipeline mode is still on; once the sync resolves, pipeline mode is exited,
# the connection goes back exactly once and the pipeline resolves with the
# coderef's value. A fix that released on the way out of the synchronous part
# -- a "finally" around the whole bracket -- fails here.
# ---------------------------------------------------------------------------
{
  my $sync = DBIO::Test::Future->new;
  my $backend = new_backend(sync_future => $sync);
  my $f = $backend->pipeline(sub { return 'batched' });

  ok !$f->is_ready, 'pending sync: the pipeline is pending too';
  is_deeply $backend->pool->{release_log} // [], [],
    'pending sync: the connection is not released while results may be read off it';
  is_deeply $backend->{captured}, [ 'PIPELINE_ENTER', 'PIPELINE_SYNC' ],
    'pending sync: pipeline mode is not exited yet';

  $sync->done;
  my ($got, $error) = outcome($f);
  is $error, undef, 'settled sync: the pipeline succeeds';
  is $got, 'batched', 'settled sync: with the coderef\'s value';
  is_deeply $backend->{captured}, [ 'PIPELINE_ENTER', 'PIPELINE_SYNC', 'PIPELINE_EXIT' ],
    'settled sync: pipeline mode is exited';
  released_once($backend, 'settled sync');
}

# ---------------------------------------------------------------------------
# The same scaffold on a transaction's pinned connection ($ctx->pipeline): the
# pipeline must not release that connection -- only the transaction boundary
# does (karr k213) -- but it must still leave pipeline mode when _pipeline_sync
# dies. Asserts: the transaction fails with the sync's own error; the wire runs
# BEGIN, the bracket including its EXIT, then ROLLBACK; the connection goes
# back exactly once, out of pipeline mode. Before the fix the die skipped the
# exit, so ROLLBACK went out on a connection still in pipeline mode and the
# connection went back to the pool that way.
# ---------------------------------------------------------------------------
{
  my $backend = new_backend(die_sync => 1);
  my $f = $backend->txn_do_async(sub {
    my ($ctx) = @_;
    return $ctx->pipeline(sub { return 1 });
  });

  my (undef, $error) = outcome($f);
  like $error, qr/sync croaked/,
    'txn pipeline, _pipeline_sync dies: the transaction fails with the sync\'s error';
  is_deeply $backend->{captured},
    [ 'BEGIN', 'PIPELINE_ENTER', 'PIPELINE_SYNC', 'PIPELINE_EXIT', 'ROLLBACK' ],
    'txn pipeline, _pipeline_sync dies: pipeline mode is exited before ROLLBACK';
  retired_not_released($backend, 'txn pipeline, _pipeline_sync dies');
}

done_testing;
