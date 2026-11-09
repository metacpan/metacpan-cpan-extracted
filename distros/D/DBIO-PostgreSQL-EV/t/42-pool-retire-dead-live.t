use strict;
use warnings;
use Test::More;

# LIVE regression for karr k49: a pooled connection whose backend is gone is
# retired, and the pool recovers on a fresh connection. t/41 proves the same
# claims against a stand-in EV::Pg; this file terminates real backends of a
# real PostgreSQL, on a pool of one, driven through the async API as a
# consumer would.
#
# WHY: the pool cannot see a connection die -- the readiness Future it checks
# resolved when the connection first came up and stays resolved (core k230).
# After a backend was terminated, the dead EV::Pg handle went back to the pool
# and was handed out again, and every later call on it failed with "not
# connected", for good: the pool of one never recovered (measured at k46).
#
# What this file claims:
#   1. the backend of the pool's one connection is terminated while it is
#      idle and the loop does not run. What the next call does is decided by
#      one thing, and this file asks for it instead of taking either outcome:
#      can the pool see the server's close on the socket (karr k72, a poll
#      that can be asked for a closed peer)? Where it can, and once the close
#      is there, the next call completes, on a FRESH connection (another
#      backend pid) -- the dead one is never handed out. Where it cannot, the
#      next call fails -- it goes out on the dead connection -- with the
#      connection's end, not with a hang. Either way the call after that
#      completes on a fresh connection. (t/63-idle-liveness-live.t measures
#      the socket itself and every way the session can end.)
#   2. the same, but the EV loop runs a while first: the pool retires the
#      connection as soon as EV::Pg reads the end of it, and the next call
#      completes on a fresh connection, first time;
#   3. a statement error the session survives does not cost the connection:
#      the next call runs on the SAME backend;
#   4. the backend of a transaction's pinned connection is terminated inside
#      the transaction: the transaction fails, and the next call completes on a
#      fresh connection -- core hands the pinned connection back through the
#      pool's release, which retires it;
#   5. the same inside a pipeline, whose connection core retires itself when
#      pipeline mode cannot be left (core k231) -- the report must not get in
#      its way;
#   6. no callback of this transport dies out of EV::Pg.
#
# Before the fix 1, 2 and 4 fail: the call after the kill fails with "not
# connected", and so does every one after it. 3 and 5 pass before and after:
# 3 is the control that keeps the fix from throwing healthy connections away,
# 5 shows that core's own retirement and the report do not collide. Every wait
# is bounded by a watchdog, and alarm is the backstop.
#
# Terminating backends needs pg_terminate_backend on this file's own sessions
# only -- the same role -- which PostgreSQL allows without superuser.

use DBIO::PostgreSQL::EV::TestHarness;

DBIO::PostgreSQL::EV::TestHarness->skip_all_unless_live;

# A server that is not there fails the file, with a plan (karr k77).
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
LiveServer->require_server;

use EV;
use DBIO::PostgreSQL::EV::Pool ();
use PoolReset;

alarm 300;

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

# The backend pid of the connection a call runs on.
my @PID = ('pg_namespace', [ \'pg_backend_pid()' ], { nspname => 'pg_catalog' });

sub harness {
  return DBIO::PostgreSQL::EV::TestHarness->new(connect_attrs => { pool_size => 1 });
}

# Wait for $f: (1, @result) once it is done, (0, $error) once it failed. A
# Future still pending after 10 seconds is failed by the watchdog.
sub wait_for {
  my ($f) = @_;
  EV::now_update();   # a timer counts from the loop's last "now", maybe long ago
  my $dog = EV::timer(10, 0, sub { $f->fail("watchdog: still pending after 10s\n") unless $f->is_ready });
  $dog->keepalive(0);
  my @r;
  return (1, @r) if eval { @r = $f->get; 1 };
  return (0, $@);
}

# Run the loop until $cond is true, 10 seconds at most.
sub run_until {
  my ($cond) = @_;
  my $expired = 0;
  EV::now_update();
  my $dog = EV::timer(10, 0, sub { $expired = 1 });
  EV::run(EV::RUN_ONCE()) until $cond->() || $expired;
  return !$expired;
}

# Run the loop a little, so anything that would fire late has fired before the
# pool is counted.
sub settle {
  my $done = 0;
  EV::now_update();
  my $t = EV::timer(0.1, 0, sub { $done = 1 });
  EV::run(EV::RUN_ONCE()) until $done;
  return;
}

# Asks the server to wait for the backend to exit, 5 seconds at most.
sub terminate {
  my ($h, $pid) = @_;
  my ($ok) = $h->sync_storage->dbh->selectrow_array(
    'SELECT pg_terminate_backend(?, 5000)', undef, $pid,
  );
  return $ok;
}

# Is the close of the server's end on the socket of $conn within $secs (2)?
# The pool's own look (karr k72), asked again and again with sleeps in
# between: the EV loop does not run, nothing reads.
sub closed_on_socket {
  my ($h, $conn, $secs) = @_;
  my $deadline = EV::time() + ($secs // 2);
  until ($h->pool->_pg_peer_closed($conn)) {
    return 0 if EV::time() > $deadline;
    select undef, undef, undef, 0.002;
  }
  return 1;
}

# The backend pid the next call runs on, or undef and the error.
sub backend_of_next_call {
  my ($h) = @_;
  my ($ok, @r) = wait_for($h->async->select_async(@PID));
  # The connection is idle again once the reset of the call is answered (karr
  # k99): "killed while idle" means after that, and the loop is not run again
  # until the next call.
  PoolReset->until_reset($h->async);
  return $ok ? ($r[0][0]) : (undef, $r[0]);
}

sub no_callback_died {
  my ($label) = @_;
  my @died = grep { /exception in callback/ } @warnings;
  is scalar @died, 0, "$label: no callback died out of EV::Pg"
    or diag @died;
  @warnings = ();
}

# The next call completes on a backend other than $dead, and the pool of one
# is whole again.
sub recovers {
  my ($label, $h, $dead) = @_;
  my ($pid, $err) = backend_of_next_call($h);
  ok defined $pid, "$label: the next call completes"
    or diag "it failed: $err";
  ok defined $pid && $pid != $dead, "$label: on a fresh connection (backend $dead is gone)";
  settle();
  is $h->pool->size, 1, "$label: the pool has its one connection";
  is $h->pool->available, 1, "$label: idle";
  no_callback_died($label);
}

# --- 1. killed while idle, the loop not run ------------------------------------

{
  my $label = 'killed, no loop';
  my $h     = harness();
  my ($dead, $err) = backend_of_next_call($h);
  ok defined $dead, "$label: the pooled connection is up" or diag $err;
  my $conn = $h->pool->{_connections}[0];
  ok terminate($h, $dead), "$label: its backend is terminated";

  # From the kill to the call nothing runs the EV loop: terminate asks over
  # the owner's dbh, closed_on_socket polls.
  if (DBIO::PostgreSQL::EV::Pool::_pg_rdhup()) {
    ok closed_on_socket($h, $conn),
      "$label: the close of the server's end is on the socket, and the pool can see it";
    my ($first, $first_err) = backend_of_next_call($h);
    ok defined $first, "$label: the first call after it completes -- the dead connection is not handed out"
      or diag "it failed: $first_err";
    ok defined $first && $first != $dead, "$label: on another backend";
  }
  else {
    note "$label: this platform's poll cannot be asked for a closed peer -- the pool vouches for the connection";
    my ($first, $first_err) = backend_of_next_call($h);
    ok !defined $first, "$label: the first call after it fails -- it went out on the dead connection";
    unlike $first_err // '', qr/watchdog/, "$label: with the end of the connection, not with a hang"
      or diag $first_err;
    note "  with: $first_err" if defined $first_err;
  }
  recovers($label, $h, $dead);
  $h->disconnect;
}

# --- 2. killed while idle, the loop runs ---------------------------------------

{
  my $label = 'killed, loop runs';
  my $h     = harness();
  my ($dead, $err) = backend_of_next_call($h);
  ok defined $dead, "$label: the pooled connection is up" or diag $err;
  ok terminate($h, $dead), "$label: its backend is terminated";

  ok run_until(sub { $h->pool->size == 0 }),
    "$label: the pool retires the connection once EV::Pg has read the end of it";
  recovers($label, $h, $dead);
  $h->disconnect;
}

# --- 3. a statement error --------------------------------------------------------

{
  my $label = 'statement error';
  my $h     = harness();
  my ($pid, $err) = backend_of_next_call($h);
  ok defined $pid, "$label: the pooled connection is up" or diag $err;

  my ($ok, $error) = wait_for($h->async->select_async('k49_no_such_table', ['x'], {}));
  ok !$ok, "$label: the call fails";
  like $error, qr/k49_no_such_table/, "$label: with the server's error";

  my ($again, $again_err) = backend_of_next_call($h);
  is $again, $pid, "$label: the next call runs on the same connection"
    or diag $again_err // 'another backend';
  is $h->pool->size, 1, "$label: which is still the pool's one connection";
  no_callback_died($label);
  $h->disconnect;
}

# --- 4. killed inside a transaction ----------------------------------------------

{
  my $label = 'killed in a transaction';
  my $h     = harness();
  my ($warm, $err) = backend_of_next_call($h);
  ok defined $warm, "$label: the pooled connection is up" or diag $err;

  my $dead;
  my ($ok, $error) = wait_for($h->async->txn_do_async(sub {
    my ($ctx) = @_;
    return $ctx->select_async(@PID)->then(sub {
      $dead = $_[0][0];
      terminate($h, $dead) or die "pg_terminate_backend($dead) failed\n";
      return $ctx->select_async(@PID);
    });
  }));
  ok !$ok, "$label: the transaction fails";
  note "  with: $error";
  ok defined $dead, "$label: on the pinned connection's backend";
  recovers($label, $h, $dead);
  $h->disconnect;
}

# --- 5. killed inside a pipeline -------------------------------------------------

{
  my $label = 'killed in a pipeline';
  my $h     = harness();
  my ($dead, $err) = backend_of_next_call($h);
  ok defined $dead, "$label: the pooled connection is up" or diag $err;

  my ($ok, $error) = wait_for($h->async->pipeline(sub {
    my ($batch) = @_;
    terminate($h, $dead) or die "pg_terminate_backend($dead) failed\n";
    return $batch->select_async(@PID);
  }));
  ok !$ok, "$label: the pipeline fails";
  note "  with: $error";
  recovers($label, $h, $dead);
  $h->disconnect;
}

done_testing;
