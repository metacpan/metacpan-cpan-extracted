use strict;
use warnings;
use Test::More;

use DBIO::Test;
use DBIO::Test::Future ();
use DBIO::SQLMaker;
use DBIO::Storage::Async;
use DBIO::Storage::PoolBase;

# karr k232, the transaction half of k231. Inside a transaction
# ($ctx->pipeline) the connection belongs to the transaction: the pipeline
# scaffold neither releases nor retires it. When its _pipeline_exit died, the
# connection was left in pipeline mode, and the transaction went on to end on
# it as if nothing had happened -- sent ROLLBACK (or, if the coderef had
# handled the pipeline's failure, COMMIT) on it, waited for the answer, and
# then released it to the pool, still in pipeline mode, for the next borrower.
# A transport that queues a statement sent in pipeline mode until the next
# sync never answers that ROLLBACK at all, so the transaction never settled and
# the connection never came back.
#
# The claim this file pins: a transaction whose connection a pipeline left in
# pipeline mode ends without waiting on that connection. It fails -- with the
# error that ended the batch, or, when the coderef handled that error, with a
# refusal to COMMIT -- a ROLLBACK goes out best-effort, not waited for, and
# the connection is retired instead of released: closed once, never handed out
# again, its slot freed for a fresh connection or for a caller already queued.
#
# Fixture as in t/test/40_async_pipeline_release.t: the fake wire keeps
# pipeline mode on the connection object, and a real PoolBase of size 1
# records every release and every close. Every statement and every close lands
# in one ordered wire log, so "ROLLBACK before the close" is observable.

{
  package K232::Conn;
  sub new { bless { id => $_[1], in_pipeline => 0 }, $_[0] }
}

{
  package K232::Pool;
  use base 'DBIO::Storage::PoolBase';

  sub _create_connection { K232::Conn->new(++$_[0]->{_next_id}) }

  sub _shutdown_connection {
    my ($self, $conn) = @_;
    push @{ $self->{closed} }, $conn->{id};
    push @{ $self->{wire} }, "CLOSE $conn->{id}";
  }

  sub release {
    my ($self, $conn) = @_;
    push @{ $self->{release_log} },
      { conn => $conn->{id}, in_pipeline => $conn->{in_pipeline} };
    return $self->SUPER::release($conn);
  }
}

# Knobs:
#   die_exit       -- _pipeline_exit dies, leaving the connection in pipeline
#                     mode
#   queue_in_pipe  -- a statement sent on a connection in pipeline mode is
#                     queued and never answered (EV::Pg's query_params there,
#                     with no sync to follow)
#   sync_future    -- _pipeline_sync returns this (pending) Future
{
  package K232::Backend;
  use base 'DBIO::Storage::Async';

  sub future_class     { 'DBIO::Test::Future' }
  sub sql_maker_class  { 'DBIO::SQLMaker' }
  sub _sql_maker_args  { (quote_char => '"', name_sep => '.') }
  sub _transform_sql   { $_[1] }
  sub _post_insert_sql { '' }

  sub pool {
    my ($self) = @_;
    return $self->{pool} ||= do {
      my $pool = K232::Pool->new(
        conninfo     => 'fake',
        size         => 1,
        future_class => 'DBIO::Test::Future',
      );
      $pool->{wire} = $self->{captured};
      $pool;
    };
  }

  sub _query_async_pinned {
    my ($self, $conn, $sql, $bind) = @_;
    push @{ $self->{captured} }, $sql;
    return $self->future_class->new if $self->{queue_in_pipe} && $conn->{in_pipeline};
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

# Wired to an owning sync storage and a shared context-owner token, as in
# t/test/40_async_pipeline_release.t.
sub new_backend {
  my (%knobs) = @_;
  my $schema  = DBIO::Test->init_schema;
  my $backend = K232::Backend->new($schema);
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

# The connection was retired, not released: closed exactly once, no longer
# counted, and the next acquire resolves at once on a fresh connection out of
# pipeline mode.
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
  is $fresh->{id}, 2, "$label: on a fresh connection, never the retired one";
  ok !$fresh->{in_pipeline}, "$label: the fresh connection is not in pipeline mode";
}

# ---------------------------------------------------------------------------
# _pipeline_exit dies inside the transaction, and the coderef lets the
# failure through -- by returning the pipeline's Future, or by dying after the
# pipeline failed. Asserts: the transaction fails with the error that ended it
# (the exit's, or the coderef's own die), not a ROLLBACK's; on the wire, BEGIN
# and the bracket, then exactly one ROLLBACK, then the close -- no COMMIT; and
# the connection is retired, not released. Before the fix the connection went
# back to the pool still in pipeline mode.
# ---------------------------------------------------------------------------
for my $case (
  [ 'the coderef returns the pipeline Future',
    sub { my ($ctx) = @_; return $ctx->pipeline(sub { return 1 }) },
    qr/exit croaked: pipeline not idle/ ],
  [ 'the coderef dies after the pipeline failed',
    sub {
      my ($ctx) = @_;
      my $f = $ctx->pipeline(sub { return 1 });
      die "coderef gave up\n" if $f->is_failed;
      return $f;
    },
    qr/coderef gave up/ ],
) {
  my ($how, $coderef, $want) = @$case;
  my $label = "exit dies in a transaction, $how";
  my $backend = new_backend(die_exit => 1);

  my (undef, $error) = outcome($backend->txn_do_async($coderef));
  like $error, $want, "$label: the transaction fails with the error that ended it";
  is_deeply $backend->{captured},
    [ 'BEGIN', 'PIPELINE_ENTER', 'PIPELINE_SYNC', 'PIPELINE_EXIT', 'ROLLBACK', 'CLOSE 1' ],
    "$label: one ROLLBACK, then the close -- no COMMIT";
  retired_not_released($backend, $label);
}

# ---------------------------------------------------------------------------
# The same, on a transport that queues a statement sent in pipeline mode until
# the next sync -- so a ROLLBACK sent there is never answered. Asserts: the
# transaction still settles, failing with the exit's error; the ROLLBACK went
# out; the connection is retired, and the next acquire gets a fresh one.
# Before the fix the transaction waited for that ROLLBACK for good: it never
# settled, and the connection was never handed back at all.
# ---------------------------------------------------------------------------
{
  my $label = 'exit dies in a transaction, ROLLBACK never answered';
  my $backend = new_backend(die_exit => 1, queue_in_pipe => 1);

  my (undef, $error) = outcome($backend->txn_do_async(sub {
    my ($ctx) = @_;
    return $ctx->pipeline(sub { return 1 });
  }));
  like $error, qr/exit croaked: pipeline not idle/,
    "$label: the transaction settles, failing with the exit's error";
  is_deeply [ grep { $_ eq 'ROLLBACK' } @{ $backend->{captured} } ], [ 'ROLLBACK' ],
    "$label: the ROLLBACK went out";
  retired_not_released($backend, $label);
}

# ---------------------------------------------------------------------------
# The coderef handles the pipeline's failure and returns normally. The
# transaction cannot COMMIT on a connection still in pipeline mode. Asserts:
# it fails, saying COMMIT was not sent and why; on the wire, no COMMIT -- one
# ROLLBACK, then the close; the connection is retired. Before the fix COMMIT
# went out on that connection, the transaction succeeded, and the connection
# was released in pipeline mode.
# ---------------------------------------------------------------------------
{
  my $label = 'exit dies in a transaction, the coderef handles it';
  my $backend = new_backend(die_exit => 1);

  my ($got, $error) = outcome($backend->txn_do_async(sub {
    my ($ctx) = @_;
    return $ctx->pipeline(sub { return 1 })
      ->catch(sub { DBIO::Test::Future->done('handled') });
  }));
  is $got, undef, "$label: the transaction does not succeed";
  like $error, qr/COMMIT not sent.*pipeline/s,
    "$label: it fails, saying COMMIT was not sent and why";
  is_deeply $backend->{captured},
    [ 'BEGIN', 'PIPELINE_ENTER', 'PIPELINE_SYNC', 'PIPELINE_EXIT', 'ROLLBACK', 'CLOSE 1' ],
    "$label: no COMMIT -- one ROLLBACK, then the close";
  retired_not_released($backend, $label);
}

# ---------------------------------------------------------------------------
# Another caller is queued for the pool's one connection while the
# transaction holds it. Asserts: once the transaction has failed and retired
# the connection, the queued caller resolves at once on a fresh connection out
# of pipeline mode -- retiring alone would free the slot but wake nobody.
# ---------------------------------------------------------------------------
{
  my $label = 'exit dies in a transaction, caller queued';
  my $backend = new_backend(die_exit => 1);
  my $pool = $backend->pool;

  my $sync = DBIO::Test::Future->new;
  $backend->{sync_future} = $sync;

  my $txn = $backend->txn_do_async(sub {
    my ($ctx) = @_;
    return $ctx->pipeline(sub { return 1 });
  });
  my $waiter = $pool->acquire;
  ok !$waiter->is_ready, "$label: the caller waits while the transaction holds the connection";

  $sync->done;
  my (undef, $error) = outcome($txn);
  like $error, qr/exit croaked/, "$label: the transaction fails with the exit's error";
  is_deeply $pool->{release_log} // [], [], "$label: the connection was not released";
  is_deeply $pool->{closed} // [], [ 1 ], "$label: it was retired, closed exactly once";
  ok $waiter->is_ready, "$label: the queued caller resolves";
  if ($waiter->is_ready) {
    is $waiter->get->{id}, 2, "$label: on a fresh connection";
    ok !$waiter->get->{in_pipeline}, "$label: out of pipeline mode";
  }
}

# ---------------------------------------------------------------------------
# The claim the fix must not cost: a pipeline whose exit succeeds leaves the
# transaction alone. Asserts: the transaction commits with the coderef's value,
# COMMIT goes out and no extra ROLLBACK, and the connection is released once,
# out of pipeline mode, and not closed.
# ---------------------------------------------------------------------------
{
  my $label = 'exit succeeds in a transaction';
  my $backend = new_backend();
  my ($got, $error) = outcome($backend->txn_do_async(sub {
    my ($ctx) = @_;
    return $ctx->pipeline(sub { return 'batched' });
  }));
  is $error, undef, "$label: the transaction succeeds";
  is $got, 'batched', "$label: with the coderef's value";
  is_deeply $backend->{captured},
    [ 'BEGIN', 'PIPELINE_ENTER', 'PIPELINE_SYNC', 'PIPELINE_EXIT', 'COMMIT' ],
    "$label: COMMIT goes out, no ROLLBACK";
  is_deeply $backend->pool->{release_log}, [ { conn => 1, in_pipeline => 0 } ],
    "$label: the connection is released once, out of pipeline mode";
  is_deeply $backend->pool->{closed} // [], [], "$label: and not closed";
}

done_testing;
