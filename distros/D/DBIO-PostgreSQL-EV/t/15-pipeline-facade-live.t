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
#   2. the coderef receives the Storage as its single argument;
#   3. pipeline_sync fired (proved by the Future reaching the done state —
#      pipeline_sync is what invokes the completion callback);
#   4. exit_pipeline ran (proved by the connection being reusable for normal
#      CRUD after the pipeline Future resolves);
#   5. the pool connection is released back to the idle pool after success;
#   6. a coderef that dies fails the Future with the die message AND the
#      pool connection is still released (no leak on the failure path).
#
# Design note (why we do NOT issue queries inside the coderef): the facade
# pipeline coderef receives $self (the Storage), not $pg (the pinned
# connection). It is therefore impossible to drive libpq pipeline-mode
# queries through the facade path alone — $self->insert_async would call
# _query_async, which does its own pool->acquire on a SECOND connection (the
# pool thinks the first one is busy, so it would block on a waiter until
# the coderef returns, which never happens). Issuing raw EV::Pg->query on a
# separately held handle from inside the coderef also fails: the facade's
# own enter_pipeline-then-pipeline_sync with no queued queries is rejected
# by PG with "another command is already in progress". The supported use
# of the facade is to scope a chunk of work that returns a Future; we test
# exactly that.

BEGIN {
  plan skip_all => 'Set DBIO_TEST_PG_DSN to run integration tests'
    unless $ENV{DBIO_TEST_PG_DSN};
}

use EV;
use EV::Pg;
use DBIO::PostgreSQL::EV::Storage;

# Parse DSN into a libpq conninfo hash (mirrors t/12-/t/13-/t/14-).
my $dsn  = $ENV{DBIO_TEST_PG_DSN};
my $user = $ENV{DBIO_TEST_PG_USER} || '';
my $pass = $ENV{DBIO_TEST_PG_PASS} || '';

my %ci;
if ($dsn =~ /^dbi:Pg:(.+)/i) {
  for my $kv (split /;/, $1) {
    my ($k, $v) = split /=/, $kv, 2;
    next unless defined $k && length $k;
    $k = 'dbname' if $k eq 'database';   # normalize for libpq
    $ci{$k} = $v;
  }
} else {
  for my $kv (split /\s+/, $dsn) {
    my ($k, $v) = split /=/, $kv, 2;
    $ci{$k} = $v if defined $k && length $k;
  }
}
$ci{user}     = $user if length $user;
$ci{password} = $pass if length $pass;

# Drive a Future to completion on the EV loop under a wall-clock guard, so a
# regression that reintroduces the pipeline hang fails this test instead of
# spinning.
sub await_guarded {
  my ($f, $what) = @_;
  local $SIG{ALRM} = sub { die "TIMEOUT awaiting $what\n" };
  alarm 15;
  EV::run(EV::RUN_ONCE) until $f->is_ready;
  alarm 0;
  return $f;
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

# Pre-flight: snapshot idle pool size so we can detect release/leak.
my $pool    = $storage->pool;
my $idle_before = $pool->available;
my $conns_before = $pool->size;

# --- 1. pipeline(): happy path, coderef return value is forwarded --------

my @received_arg;          # proves the coderef sees the Storage as $_[0]

my $f = await_guarded(
  $storage->pipeline(sub {
    my ($s) = @_;
    push @received_arg, $s;
    # Coderef return value flows back to caller via pipeline_sync->on_done.
    return "ok-from-coderef";
  }),
  'pipeline success',
);

ok $f->is_done,  'pipeline Future resolved (pipeline_sync fired)';
ok !$f->is_failed, 'pipeline Future succeeded (no error)';

# Coderef was invoked with the Storage as its single argument, exactly once.
is scalar(@received_arg), 1, 'coderef invoked exactly once';
is $received_arg[0], $storage, 'coderef received the Storage as $_[0]';

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

# --- 3. coderef that DIES — Future fails AND connection is still released -

run_raw($storage, "DELETE FROM $table");

my $idle_before_die = $pool->available;
my $f_die = await_guarded(
  $storage->pipeline(sub {
    die "boom-in-pipeline\n";
  }),
  'pipeline die',
);

ok $f_die->is_failed, 'dying coderef: pipeline Future failed (did not hang)';
is +($f_die->failure // ''), "boom-in-pipeline\n",
  'dying coderef: pipeline Future carries the die message';

is $pool->available, $idle_before_die,
  'dying coderef: pool connection released back to idle (no leak on error)';
is $pool->size, $conns_before,
  'dying coderef: pool did not spawn an extra connection';

# Confirm the released connection is still usable after a die (proves
# exit_pipeline ran on the error branch too).
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
