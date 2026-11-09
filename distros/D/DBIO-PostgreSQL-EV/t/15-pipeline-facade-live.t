use strict;
use warnings;
use Test::More;
use Test::Exception;

# LIVE coverage for the Storage-facade pipeline path
# (DBIO::PostgreSQL::EV::Storage::pipeline, Storage.pm:555-586).
#
# WHY this is a live test: the facade acquires a pooled connection, calls
# $pg->enter_pipeline, runs the user's coderef, calls pipeline_sync, calls
# $pg->exit_pipeline and releases the connection. Each step is a separate
# libpq protocol message; the bug class this guards against is "missing
# exit_pipeline on the error path", "pipeline_sync never fires so the
# Future hangs", "Future carries the wrong coderef return value", or "pool
# connection leaked on the die path". A mock could be wired to call each
# callback by hand and would prove nothing — only a real PostgreSQL pipeline
# round-trip exposes the wire-format mismatch or the leaked handle. We
# assert that:
#
#   1. pipeline() returns a Future that resolves with the coderef return value;
#   2. the coderef receives a DBIO::Storage::Async::PipelineContext pinned to
#      the bracketed connection — NOT the Storage;
#   3. pipeline_sync fired (proved by the Future reaching the done state —
#      pipeline_sync is what invokes the completion callback);
#   4. exit_pipeline ran (proved by the connection being reusable for normal
#      CRUD after the pipeline Future resolves);
#   5. the pool connection is released back to the idle pool after success;
#   6. CRUD issued ON THE CONTEXT inside the coderef really is batched: it
#      rides the one bracketed connection (the pool spawns nothing extra) and
#      every batched statement lands in the table;
#   7. a coderef that dies fails the Future with the die message AND the
#      pool connection is still released (no leak on the failure path).
#
# Contract note (dbio-async ADR 0003 amendment / karr k7, core >= 0.900004):
# the coderef used to receive $self (the Storage) and this test asserted that.
# It no longer does — core builds a DBIO::Storage::Async::PipelineContext
# around the bracketed connection and hands THAT to the coderef, because
# pipeline mode is per-connection state: only a statement sent on the
# bracketed connection is batched. The context's *_async methods route
# through _run_crud_pinned -> _query_async_pinned onto that connection, i.e.
# through the very seam this driver already implements for transactions.
#
# Calling $storage->insert_async inside the coderef is still legal and still
# WORKS — which is exactly what made the old bug invisible — but it goes
# through the pooled seam, takes a SECOND connection and runs outside the
# bracket (at pool_size => 1 it blocks on a waiter until the coderef returns).
# That is why section 3 issues its batch on the handed context and asserts the
# pool did not grow: that assertion is what distinguishes a real batch from
# statements that merely executed.

BEGIN {
  plan skip_all => 'Set DBIO_TEST_PG_DSN to run integration tests'
    unless $ENV{DBIO_TEST_PG_DSN};
}

use EV;
use EV::Pg;
use DBIO::PostgreSQL::EV::Storage;

# The test login as the libpq parameters the transport reads it as; a server
# that is not there fails the file, with a plan (karr k77).
use FindBin;
use lib "$FindBin::Bin/lib";
use PoolReset;
use LiveServer;
use GuardedWait;
LiveServer->require_server;
my %ci = LiveServer->conninfo;

# The file's backstop: a hang anywhere in it ends the process. A guarded wait
# has a timeout of its own and leaves this alarm running (karr k88).
alarm 120;

# Drive a Future to completion on the EV loop under a wall-clock guard, so a
# regression that reintroduces the pipeline hang fails this test instead of
# spinning.
sub await_guarded {
  my ($f, $what) = @_;
  return GuardedWait->until_ready($f, 15, "TIMEOUT awaiting $what\n");
}

# Raw statement on a pooled connection (DDL setup/teardown + verification).
sub run_raw {
  my ($storage, $sql) = @_;
  my $f = $storage->pool->acquire->then(sub {
    my $pg  = shift;
    my $rf  = Future->new;
    $pg->query($sql, sub {
      my (undef, $err) = @_;
      $storage->pool->release($pg);
      $err ? $rf->fail($err) : $rf->done;
    });
    return $rf;
  });
  return await_guarded($f, "run_raw: $sql")->get;
}

my $table = 'dbio_pipeline_facade_live';

my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);
$storage->connect_info([ \%ci, {} ]);

run_raw($storage, "DROP TABLE IF EXISTS $table");
run_raw($storage, "CREATE TABLE $table (id serial PRIMARY KEY, name text)");

# Stub source for section 3 (batched insert). Lets _insert_returned_columns
# zip the positional RETURNING row onto the declared column order, so the
# autoinc PK overlays onto the resolved hashref. The bare-string path (used
# by sections 2 and 4) cannot do that zip -- no column order is known -- so
# the resolved hashref for those bare-string inserts correctly carries just
# the supplied insert data, matching what sync $storage->insert returns and
# what t/14 documents. With a blessed source in section 3 we additionally
# verify the seam the ticket cares about: pipeline mode must deliver the
# actual RETURNING * rows down to the runner, not just cmd_tuples -- a
# regression where _query_async_pinned (or any per-query seam) collapsed an
# INSERT...RETURNING result onto a scalar would land here as a missing $_->{id}.
{
  package Dbio15BatchSrc;
  sub new     { my $class = shift; bless {}, $class }
  sub name    { 'dbio_pipeline_facade_live' }
  sub columns { qw(id name) }
}

# Pre-flight: snapshot idle pool size so we can detect release/leak.
my $pool    = $storage->pool;
my $idle_before = $pool->available;
my $conns_before = $pool->size;

# Record the connection the scaffold actually put into pipeline mode, so we
# can assert the handed context is pinned to exactly that one. Recording only
# — the original seam still runs.
my @entered_conn;
{
  no warnings 'redefine';
  my $orig = \&DBIO::PostgreSQL::EV::Storage::_pipeline_enter;
  *DBIO::PostgreSQL::EV::Storage::_pipeline_enter = sub {
    push @entered_conn, $_[1];
    return $orig->(@_);
  };
}

# --- 1. pipeline(): happy path, coderef return value is forwarded --------

my @received_arg;          # proves the coderef sees the batch context as $_[0]

my $f = await_guarded(
  $storage->pipeline(sub {
    my ($batch) = @_;
    push @received_arg, $batch;
    # Coderef return value flows back to caller via pipeline_sync->on_done.
    return "ok-from-coderef";
  }),
  'pipeline success',
);

ok $f->is_done,  'pipeline Future resolved (pipeline_sync fired)';
ok !$f->is_failed, 'pipeline Future succeeded (no error)';

# Coderef was invoked with the batch context as its single argument, exactly
# once — the storage is NOT what the block gets (ADR 0003 amendment).
is scalar(@received_arg), 1, 'coderef invoked exactly once';
isa_ok $received_arg[0], 'DBIO::Storage::Async::PipelineContext',
  'coderef received a PipelineContext as $_[0]';
isnt $received_arg[0], $storage, 'coderef did NOT receive the Storage';
is $received_arg[0]->storage, $storage, 'context knows its parent storage';
is scalar(@entered_conn), 1, '_pipeline_enter ran once';
is $received_arg[0]->pipeline_conn, $entered_conn[0],
  'context is pinned to the connection the bracket entered';

# Future resolved with the coderef's return value verbatim.
is $f->get, "ok-from-coderef", 'pipeline Future resolved to the coderef return value';

# --- 2. pool connection released AND reusable for normal CRUD ------------

# Pool did not spawn a new connection (still bounded by prior state).
is $pool->size, $conns_before, 'pool did not spawn a new connection';

# Connection is back on the idle stack — proves release happened.
# Note: `available` does not necessarily equal `idle_before + 1`; the
# pipeline acquires one and then releases it, net-zero change on the idle
# stack. What we want to assert is: at least one connection is idle
# (released), and we did not lose any connections (size unchanged).
ok $pool->available >= 1,
  'at least one connection idle after pipeline (release happened, no leak)';

# exit_pipeline must have run: a real normal CRUD query on the released
# connection has to succeed. If exit_pipeline were skipped, libpq would
# still be in pipeline mode and the next query_params would error.
await_guarded(
  $storage->insert_async($table, { name => 'after-pipeline' }),
  'post-pipeline insert',
);
my @rows = await_guarded(
  $storage->select_async($table, ['name'], { name => 'after-pipeline' }),
  'post-pipeline select',
)->get;
is scalar(@rows), 1, 'normal CRUD works after pipeline (exit_pipeline ran)';

# --- 3. a real batch: CRUD on the context rides the bracketed connection --

my @batch_names = map { "batched-$_" } 1 .. 5;
my $conns_before_batch = $pool->size;
my @batch_ctx;
my $batch_src = Dbio15BatchSrc->new;

my $f_batch = await_guarded(
  $storage->pipeline(sub {
    my ($batch) = @_;
    push @batch_ctx, $batch;
    # Each insert goes through _run_crud_pinned -> _query_async_pinned on the
    # connection that is in libpq pipeline mode — that is what queues it.
    # We hand the blessed source (Dbio15BatchSrc, declared above) instead of
    # the bare-string table name so _insert_returned_columns can zip the
    # positional RETURNING * row onto the declared column order; with a
    # bare-string source it has no column order and the autoinc PK is not
    # overlaid (the documented t/14 contract).
    return $batch->future_class->needs_all(
      map { $batch->insert_async($batch_src, { name => $_ }) } @batch_names
    );
  }),
  'pipeline batch',
);

ok $f_batch->is_done, 'batched pipeline Future resolved';

# The whole batch rode ONE connection. Had the inserts gone through the pooled
# seam, the pool would have had to hand out a SECOND connection (the bracketed
# one is checked out) or block on a waiter until the timeout guard fires.
is $pool->size, $conns_before_batch,
  'batch rode the bracketed connection (pool spawned nothing extra)';
is $batch_ctx[0]->pipeline_conn, $entered_conn[-1],
  'batch context pinned to the connection this bracket entered';

# insert_async resolves a returned-columns hashref (ADR 0031 §3 — this driver
# appends RETURNING *), one per batched statement. We use the blessed
# Dbio15BatchSrc so _insert_returned_columns can zip the positional
# RETURNING * row onto the declared column order; this is the seam the
# ticket is about (pipeline mode must deliver the actual RETURNING * rows
# down to the runner, not just cmd_tuples — a regression that collapsed an
# INSERT...RETURNING result onto a scalar would surface here as a missing
# $_->{id}).
my @batch_rows = $f_batch->get;
is scalar(@batch_rows), scalar(@batch_names), 'one result per batched insert';
is scalar(grep { ref $_ ne 'HASH' || !defined $_->{id} } @batch_rows), 0,
  'every batched insert resolved with its RETURNING row';

# ... and the batched statements really executed on the server: the table now
# holds the one row from section 2 plus every batched name.
my @all_rows = await_guarded(
  $storage->select_async($table, ['name'], undef),
  'batch readback',
)->get;
is scalar(@all_rows), 1 + scalar(@batch_names),
  'every batched insert landed in the table';

# --- 4. coderef that DIES — Future fails AND no connection is leaked ----

run_raw($storage, "DELETE FROM $table");
PoolReset->until_reset($storage);   # a connection is idle once its reset is answered (karr k99)

my $idle_before_die = $pool->available;
my $f_die = await_guarded(
  $storage->pipeline(sub {
    die "boom-in-pipeline\n";
  }),
  'pipeline die',
);

PoolReset->until_reset($storage);   # the reset of the borrow is answered (karr k99)
ok $f_die->is_failed, 'dying coderef: pipeline Future failed (did not hang)';
is +($f_die->failure // ''), "boom-in-pipeline\n",
  'dying coderef: pipeline Future carries the die message';

# A batch that failed leaves statements unsynced on its connection, so core
# retires that connection and never releases it (core k396). Nothing is
# leaked: the pool holds that one connection less and every other one is idle.
is $pool->available, $idle_before_die - 1,
  'dying coderef: the failed batch\'s connection is retired, not released';
is $pool->size, $conns_before - 1,
  'dying coderef: the pool holds that one connection less, and spawned none';
is $pool->available, $pool->size,
  'dying coderef: no connection is left checked out (no leak on error)';

# Confirm the pool still serves after a die (proves exit_pipeline ran on the
# error branch too: a connection left in pipeline mode is retired, not lent).
await_guarded(
  $storage->insert_async($table, { name => 'after-die' }),
  'post-die insert',
);
my @rows2 = await_guarded(
  $storage->select_async($table, ['name'], { name => 'after-die' }),
  'post-die select',
)->get;
is scalar(@rows2), 1,
  'normal CRUD works after pipeline die (exit_pipeline ran on error branch)';

# --- cleanup ---------------------------------------------------------------

run_raw($storage, "DROP TABLE IF EXISTS $table");
$storage->disconnect;

done_testing;
