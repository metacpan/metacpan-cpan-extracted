use strict;
use warnings;
use Test::More;

# LIVE, karr k73 (a) and (b): a statement Future cancelled while its statement
# is in flight on a real PostgreSQL -- on the pooled path and inside
# txn_do_async. The live half of t/55-cancel-in-flight-mock.t.
#
# WHY: cancelling the Future, or losing it in a wait_any against a timeout, is
# the only way a caller has to stop waiting, and it is a client-side act: the
# statement is on the server and its result is on its way. t/55 claims what
# this transport does then, over a stand-in EV::Pg whose behaviour was read
# from EV::Pg's POD and Pg.xs -- above all that EV::Pg calls the callback of a
# cancelled statement all the same, with that statement's result, so that the
# connection can go back to the pool from there. If a real EV::Pg did not, the
# connection of every cancelled statement would stay checked out for good, and
# a pool of one would be wedged by the first timeout. Only a real EV::Pg and a
# real server say; and only a server says what was committed, what state the
# backend is left in, and whether its locks are gone.
#
# What this file claims, each from the SERVER where the server can say it (a
# connection of its own reads pg_stat_activity, the table and its sequence):
#   1. pooled, pool of one (k73 a), on a warm and on a cold pool, the next call
#      issued before or after the cancel: the cancel alone releases nothing --
#      EV::Pg still holds the statement's callback and libpq is busy -- and the
#      next call is not sent; the late result hands the connection on; the next
#      call gets its own row, on the same backend; afterwards the pool has its
#      one connection idle, and the server has one backend for it;
#   2. pooled, the late answer is a server error: the Future stays cancelled,
#      the connection is released and kept;
#   3. pooled, the connection is lost with the cancelled statement in flight:
#      the call waiting for it runs on a fresh backend, the lost one is gone;
#   4. txn_do_async (k73 b), an INSERT cancelled in flight -- in the coderef,
#      after it returned, or as the loser of a wait_any against an EV::timer:
#      the server is still on the INSERT when the transaction would end, so
#      ROLLBACK cannot have been sent; once the INSERT has its result the
#      transaction fails -- with core's "cancelled before it was answered", or
#      with the timeout that won --, the last statement the server ran on the
#      backend is ROLLBACK, it is "idle" and not "idle in transaction", the
#      row count is unchanged, the next call runs on the same backend, and
#      another session's ALTER TABLE is not blocked;
#   5. txn_do_async, the statement issued behind the cancelled one is answered
#      with its own row;
#   6. txn_do_async, a statement cancelled while it waits behind another one:
#      the transaction rolls back just the same;
#   7. no callback of this transport dies out of EV::Pg.
# The INSERT of 4 and 5 is held in flight by an ACCESS EXCLUSIVE lock another
# session takes on the table first, so "in flight" is a state the server
# reports (active, waiting for a lock), not a race against a timer.
#
# karr k75, decided 2026-10-09 (A): a Future's cancel stops the statement on
# the server, where the stack can -- EV::Pg's cancel_async, libpq 17+, found
# with `can`; the blocking cancel never. The rest of this file states it, for
# a stack that has the capability ($CAN) -- one that has not keeps today's
# behaviour, which the file then pins instead (the same sections, the old
# claims):
#   - exactly one cancel_async per statement cancelled in flight, no cancel;
#   - the server stops the statement within milliseconds, not at its end;
#   - the next call on a pool of one is answered after milliseconds, not after
#     the statement's end -- and it is its own: the request did not reach it.
#     That is the race (10): the request is on its way while its statement
#     ends, and lands on the next statement of the connection if the
#     connection is let go before the request is answered. The connection is
#     held until the result AND the answer are in;
#   - the connection is usable afterwards, on the same backend, IDLE;
#   - no request for a statement that waits in the pinned queue, none for a
#     COPY.
# karr k75 (B): a statement cancelled while it waits in the pinned
# connection's queue is skipped, not sent. Read from the table's sequence,
# which a rollback does not turn back (6). The COMMIT / ROLLBACK of core is
# the exception, a cancelled one is sent all the same (6b).
# 8 is not this transport's, and measures only: what EV::Pg's cancel_async
# does to a statement in flight on this stack. Nothing in lib/ can turn 8 red.
#
# 9 and 10 are core k274's (t/test/47_async_cancel_outer_future.t there): the
# Future of txn_do_async, or only the one its coderef returned, is cancelled.
# Core ends the transaction itself -- it fails with "Transaction cancelled",
# ROLLBACK goes out unwaited, the connection is retired, never released. 9
# claims that from the server: the transaction does not stay pending, its
# session is gone with nothing left open, nothing is committed, the pool's slot
# went to a fresh backend. 10 is this transport's half: core retires the
# connection at the cancel, and closing it would drop the cancel_async request
# unsent -- the statement ran to its end, 3 s for pg_sleep(3) -- so the pool
# closes a retired connection with a statement in flight only once the request
# is answered (Pool.pm _shutdown_connection): the server is off the statement
# within milliseconds, one request, and the session ends.
#
# Every wait on the EV loop is bounded by a watchdog, and alarm is the backstop.

use DBIO::PostgreSQL::EV::TestHarness;

DBIO::PostgreSQL::EV::TestHarness->skip_all_unless_live;

use EV;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use PoolReset;

alarm 180;

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

my $EVF   = 'DBIO::PostgreSQL::EV::Future';
my $TAG   = "dbio_k73_cancel_$$";
my $TABLE = 'dbio_karr73_cancel';
my $SLEEP = 1;     # seconds the statement of (1) runs on the server: well above a cold connect plus the reset of the borrow before

my $CANCELLED = qr/cancelled before it was answered/;

# Another session, told apart from the pool's by its application_name. Its
# waits are bounded. A server that is not there fails the file at the first
# one, with a plan (karr k77).
sub session {
  my ($name) = @_;
  my $dbh = LiveServer->control_dbh(application_name => "${TAG}_$name");
  $dbh->do('SET client_min_messages = warning');
  $dbh->do(q{SET lock_timeout = '3s'});
  $dbh->do(q{SET statement_timeout = '10s'});
  return $dbh;
}

# The server's view, from a connection that belongs to no pool.
my $observer = session('observer');
{
  my ($seen_as) = $observer->selectrow_array(
    'SELECT application_name FROM pg_catalog.pg_stat_activity WHERE pid = pg_backend_pid()'
  );
  plan skip_all => 'the test DSN sets an application_name of its own; this file tells its backends apart by PGAPPNAME'
    unless defined $seen_as && $seen_as eq "${TAG}_observer";
}
my $locker = session('locker');
$ENV{PGAPPNAME} = $TAG;   # every connection a harness opens from here on

$observer->do("DROP TABLE IF EXISTS $TABLE");
$observer->do("CREATE TABLE $TABLE (id serial PRIMARY KEY, name text NOT NULL)");
$observer->do("INSERT INTO $TABLE (name) VALUES ('kept')");

END {
  if ($observer) {
    local $@;
    eval { $locker->rollback unless $locker->{AutoCommit} } if $locker;
    eval { $observer->do("DROP TABLE IF EXISTS $TABLE") };
  }
}

# Every cancel request this process sends through EV::Pg is counted, by call.
my %REQUESTS = (cancel => 0, cancel_async => 0);
for my $method (qw( cancel cancel_async )) {
  my $orig = EV::Pg->can($method) or next;
  no strict 'refs';
  no warnings 'redefine';
  *{"EV::Pg::$method"} = sub { $REQUESTS{$method}++; goto &$orig };
}

# Does this stack have the capability? Asked of EV::Pg as the transport does,
# before the counting wrapper -- the wrapper is there only if EV::Pg has it.
my $CAN = EV::Pg->can('cancel_async') ? 1 : 0;

# A SELECT of SQL expressions through the async API, as a consumer writes it:
# one row of pg_namespace, each expression as literal SQL.
sub exprs {
  my @sql = @_;
  return ('pg_namespace', [ map { \$_ } @sql ], { nspname => 'pg_catalog' });
}

my @PID = exprs('pg_backend_pid()');

# One row naming the backend it ran on and the call it belongs to.
sub tagged { exprs('pg_backend_pid()', "'$_[0]'") }

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

# Run the EV loop until $cond holds; false if it does not within 10 seconds.
sub wait_until {
  my ($cond) = @_;
  my $deadline = EV::time() + 10;
  until ($cond->()) {
    return 0 if EV::time() > $deadline;
    EV::now_update();
    my $tick = EV::timer(0.02, 0, sub { });
    EV::run(EV::RUN_ONCE());
  }
  return 1;
}

# Run the loop for a while, so anything that would fire late has fired.
sub settle {
  my ($seconds) = @_;
  my $done = 0;
  EV::now_update();
  my $t = EV::timer($seconds // 0.1, 0, sub { $done = 1 });
  EV::run(EV::RUN_ONCE()) until $done;
  return;
}

sub harness  { DBIO::PostgreSQL::EV::TestHarness->new(connect_attrs => { pool_size => 1 }) }
sub the_conn { $_[0]->pool->{_connections}[0] }

# A pool of one with its connection up and idle: the harness, the backend of
# that connection, and the connection.
sub fresh {
  my $h = harness();
  my ($ok, @r) = wait_for($h->async->select_async(@PID));
  die "warming the pool failed: $r[0]" unless $ok;
  PoolReset->until_reset($h->async);
  settle();
  return ($h, $r[0][0], the_conn($h));
}

sub state_of {
  my ($f) = @_;
  return !$f->is_ready ? 'pending' : $f->is_cancelled ? 'cancelled' : $f->is_failed ? 'failed' : 'done';
}

# What the server says of backend $pid; a hash of empty strings once it is gone.
sub backend {
  my ($pid) = @_;
  my $row = $observer->selectrow_hashref(
    'SELECT state, wait_event_type, query FROM pg_catalog.pg_stat_activity WHERE pid = ?', undef, $pid,
  );
  return { map { $_ => $row ? $row->{$_} // '' : '' } qw( state wait_event_type query ) };
}

sub backend_gone {
  my ($pid) = @_;
  my ($n) = $observer->selectrow_array('SELECT count(*) FROM pg_catalog.pg_stat_activity WHERE pid = ?', undef, $pid);
  return !$n;
}

# The backends the server has for the pool of $h: the owner's DBI connection,
# which carries the same application_name, left out.
sub pool_backends {
  my ($h) = @_;
  my $owner = $h->sync_storage->dbh->{pg_pid};
  return [ grep { $_ != $owner } @{ $observer->selectcol_arrayref(
    'SELECT pid FROM pg_catalog.pg_stat_activity WHERE application_name = ? ORDER BY pid', undef, $TAG,
  ) } ];
}

sub terminate {
  my ($pid) = @_;
  my ($ok) = $observer->selectrow_array('SELECT pg_terminate_backend(?, 5000)', undef, $pid);
  return $ok;
}

sub rows_in_table { ($observer->selectrow_array("SELECT count(*) FROM $TABLE"))[0] }

# How many values the table's sequence has handed out. A rollback does not
# turn it back, so it counts the INSERTs the server ran, committed or not.
sub inserts_run {
  my ($last, $called) = $observer->selectrow_array("SELECT last_value, is_called FROM ${TABLE}_id_seq");
  return $called ? $last : 0;
}

sub no_callback_died {
  my ($label) = @_;
  my @died = grep { /exception in callback/ } @warnings;
  is scalar @died, 0, "$label: no callback died out of EV::Pg" or diag @died;
  @warnings = ();
}

# The pool has its one connection, idle, with nothing in flight -- and the
# server has exactly that backend for it.
sub idle_again {
  my ($label, $h, $pid) = @_;
  settle();
  my $conn = the_conn($h);
  is $h->pool->size, 1, "$label: the pool has its one connection";
  is $h->pool->available, 1, "$label: idle";
  is $conn && $conn->transaction_status, EV::Pg::PQTRANS_IDLE(), "$label: IDLE -- no transaction open, nothing in flight";
  is $conn && $conn->pending_count, 0, "$label: no result due";
  is_deeply pool_backends($h), [ $pid ], "$label: and the server has that one backend for the pool";
  no_callback_died($label);
}

# --- 1. pooled, pool of one: cancelled in flight (k73 a) ------------------------

for my $case (
  [ warm => 'cancel, then the next call' ],
  [ warm => 'the next call, then cancel' ],
  [ cold => 'cancel, then the next call' ],
) {
  my ($temp, $order) = @$case;
  my $label = "pooled, $temp pool, $order";
  my ($h, $pid, $conn) = $temp eq 'warm' ? fresh() : (harness());

  my $issued = EV::time();
  my $q1 = $h->async->select_async(exprs('pg_backend_pid()', "pg_sleep($SLEEP)"));
  if ($temp eq 'cold') {
    ok wait_until(sub { ($conn = the_conn($h)) && $conn->pending_count }),
      "$label: the connection came up and the statement was sent"
      or next;
    $pid = $conn->backend_pid;
  }
  is $conn->pending_count, 1, "$label: the statement is in flight";

  my $q2;
  my $requests = $REQUESTS{cancel_async};
  my $blocking = $REQUESTS{cancel};
  my $cancelled_at;
  if ($order =~ /^cancel/) {
    $q1->cancel;
    $cancelled_at = EV::time();
    $q2 = $h->async->select_async(tagged('q2'));
  }
  else {
    $q2 = $h->async->select_async(tagged('q2'));
    $q1->cancel;
    $cancelled_at = EV::time();
  }
  is $REQUESTS{cancel_async} - $requests, $CAN ? 1 : 0,
    "$label: " . ($CAN ? 'exactly one cancel request' : 'no cancel request, this EV::Pg has no cancel_async');
  is $REQUESTS{cancel} - $blocking, 0, "$label: and never the blocking cancel";
  is state_of($q1), 'cancelled', "$label: the caller's Future is cancelled";
  is $h->pool->available, 0, "$label: the cancel releases nothing";
  is $conn->pending_count, 1, "$label: EV::Pg still holds the statement's callback";
  is $conn->transaction_status, EV::Pg::PQTRANS_ACTIVE(), "$label: and libpq is still busy with the statement";
  is state_of($q2), 'pending', "$label: the next call waits";
  is scalar @{ $h->pool->{_waiters} }, 1, "$label: queued for the connection -- it is not sent";

  # Asked while the loop runs, so a cancel request has gone out by now.
  my $running;
  my $stopped = wait_until(sub { $running = backend($pid); !($running->{state} eq 'active' && $running->{query} =~ /pg_sleep/) });
  my $stopped_after = EV::time() - $cancelled_at;
  if ($CAN) {
    ok $stopped, "$label: the server stops the cancelled statement"
      or diag "the backend is '$running->{state}' with: $running->{query}";
    cmp_ok $stopped_after, '<', $SLEEP / 2,
      "$label: within milliseconds of the cancel, not at the statement's end";
    note sprintf '%s: the server was off the statement %.3fs after the cancel', $label, $stopped_after;
  }
  else {
    cmp_ok $stopped_after, '>=', $SLEEP / 2,
      "$label: without cancel_async the server goes on running the cancelled statement";
  }

  my ($ok, @r) = wait_for($q2);
  my $answered = EV::time() - $issued;
  ok $ok, "$label: the next call completes" or diag "it failed: $r[0]";
  is_deeply \@r, [ [ $pid, 'q2' ] ], "$label: with its own row, on the same backend -- the request did not reach it";
  is state_of($q1), 'cancelled', "$label: the first call stays cancelled";

  if ($CAN) {
    cmp_ok $answered, '<', $SLEEP,
      "$label: the next call does not wait for a statement nobody waits for any more";
  }
  else {
    cmp_ok $answered, '>=', $SLEEP,
      "$label: without cancel_async the pool of one stands until the cancelled statement has run to its end";
  }
  note sprintf '%s: the next call was answered %.3fs after the cancelled pg_sleep(%s) was issued', $label, $answered, $SLEEP;

  idle_again($label, $h, $pid);
  $h->disconnect;
}

# --- 2. pooled: the late answer is a server error ---------------------------------

{
  my $label = 'pooled, late server error';
  my ($h, $pid, $conn) = fresh();

  my $q1 = $h->async->select_async('dbio_karr73_no_such_table', ['x'], {});
  $q1->cancel;
  is $h->pool->available, 0, "$label: the cancel releases nothing";
  ok wait_until(sub { $h->pool->available == 1 }), "$label: the late answer releases the connection";
  is state_of($q1), 'cancelled', "$label: the Future stays cancelled, it does not fail";
  SKIP: {
    skip 'this EV::Pg has no error_fields', 1 unless EV::Pg->can('error_fields');
    is +($conn->error_fields || {})->{sqlstate}, '42P01', "$label: (the late answer was the server's error)";
  }
  ok $conn->is_connected, "$label: the session survived";

  my ($ok, @r) = wait_for($h->async->select_async(tagged('next')));
  is_deeply \@r, [ [ $pid, 'next' ] ], "$label: the next call gets its own row, on the same backend"
    or diag $ok ? 'another row' : "it failed: $r[0]";
  idle_again($label, $h, $pid);
  $h->disconnect;
}

# --- 3. pooled: the connection is lost with the cancelled statement in flight -----

{
  my $label = 'pooled, connection lost';
  my ($h, $pid, $conn) = fresh();

  my $q1 = $h->async->select_async(exprs('pg_backend_pid()', 'pg_sleep(5)'));
  $q1->cancel;
  my $q2 = $h->async->select_async(tagged('q2'));
  ok terminate($pid), "$label: the backend is terminated";

  my ($ok, @r) = wait_for($q2);
  ok $ok, "$label: the call waiting for the connection completes" or diag "it failed: $r[0]";
  my $fresh = $ok ? $r[0][0] : 0;
  ok $fresh && $fresh != $pid, "$label: on a fresh backend";
  is $ok ? $r[0][1] : undef, 'q2', "$label: with its own row";
  is state_of($q1), 'cancelled', "$label: the cancelled Future stays cancelled";
  like join('', @warnings), qr/pool error: /, "$label: the pool reported the loss";
  ok wait_until(sub { backend_gone($pid) }), "$label: the lost backend is gone";
  idle_again($label, $h, $fresh);
  $h->disconnect;
}

# --- 4. txn_do_async: an INSERT cancelled in flight (k73 b) -----------------------

# Hold every INSERT into the table until hold_released.
sub hold_inserts {
  $locker->begin_work;
  $locker->do("LOCK TABLE $TABLE IN ACCESS EXCLUSIVE MODE");
  return;
}

sub hold_released { $locker->commit }

# The backend's INSERT is on the server, waiting for the lock.
sub insert_in_flight {
  my ($pid) = @_;
  return wait_until(sub {
    my $b = backend($pid);
    $b->{state} eq 'active' && $b->{wait_event_type} eq 'Lock' && $b->{query} =~ /^INSERT/;
  });
}

# After a transaction that must have rolled back: what the server has, the
# pool, the next call, and another session's DDL.
sub rolled_back {
  my ($label, $h, $pid, $rows) = @_;
  settle();
  my $b = backend($pid);
  # The pool resets the connection behind the ROLLBACK (karr k99): DISCARD ALL
  # is the last statement now, and the server refuses it inside a transaction
  # block -- it ran, so the transaction had ended, and by ROLLBACK: the row
  # count below is unchanged, which a COMMIT could not leave.
  is $b->{query}, 'DISCARD ALL', "$label: the last statement the server ran on the backend is the reset behind the ROLLBACK, never COMMIT";
  is $b->{state}, 'idle', "$label: which is idle, not idle in transaction";
  is rows_in_table(), $rows, "$label: the row count is unchanged";

  my ($ok, @r) = wait_for($h->async->select_async($TABLE, [ \'count(*)', \'pg_backend_pid()' ], {}));
  is_deeply \@r, [ [ $rows, $pid ] ],
    "$label: the next call runs on the same backend and sees no row of the transaction"
    or diag $ok ? 'another answer' : "it failed: $r[0]";

  ok eval {
    $observer->do("ALTER TABLE $TABLE ADD COLUMN k73_probe int");
    $observer->do("ALTER TABLE $TABLE DROP COLUMN k73_probe");
    1;
  }, "$label: another session's ALTER TABLE is not blocked"
    or diag "it failed: $@";
  idle_again($label, $h, $pid);
}

# The transaction's INSERT is in flight on the server and its Future $stmt is
# cancelled: the transaction must roll back behind it, and fail with $error.
# $rows is the table's row count from before the INSERTs were held: while they
# are, the table cannot be read.
sub rolls_back_behind {
  my ($label, $h, $pid, $txn, $stmt, $error, $rows) = @_;

  settle(0.2);
  is state_of($stmt), 'cancelled', "$label: the statement's Future is cancelled";
  my $b = backend($pid);
  if ($CAN) {
    # The server stopped the INSERT where it waited for its lock: the late
    # result is its 57014, and ROLLBACK went behind it -- with the lock
    # still held by the other session.
    is $b->{query}, 'DISCARD ALL',
      "$label: the server stopped the INSERT at once -- ROLLBACK followed, then the reset, the lock is still held";
    is $b->{state}, 'idle', "$label: and the backend is idle";
    is state_of($txn), 'failed', "$label: the transaction has failed, it did not wait for the lock";
  }
  else {
    ok $b->{state} eq 'active' && $b->{query} =~ /^INSERT/,
      "$label: the server is still on the INSERT -- ROLLBACK was not sent while it is in flight"
      or diag "the backend is '$b->{state}' with: $b->{query}";
    is state_of($txn), 'pending', "$label: the transaction waits";
    is $h->pool->available, 0, "$label: its connection stays pinned";
  }

  hold_released();   # without the capability: the INSERT gets its lock, the late result
  my ($ok, $err) = wait_for($txn);
  ok !$ok, "$label: the transaction fails";
  if (ref $error) { like $err, $error, "$label: saying a statement was cancelled" }
  else            { is   $err, $error, "$label: with the error that cancelled it" }
  is state_of($stmt), 'cancelled', "$label: the statement stays cancelled";
  rolled_back($label, $h, $pid, $rows);
}

for my $when ('in the coderef', 'after the coderef returned') {
  my $label = "txn, cancelled $when";
  my ($h, $pid) = fresh();
  my $rows = rows_in_table();
  hold_inserts();

  my $stmt;
  my $txn = $h->async->txn_do_async(sub {
    my ($ctx) = @_;
    $stmt = $ctx->insert_async($TABLE, { name => 'doomed' });
    $stmt->cancel if $when eq 'in the coderef';
    return 'gave up';
  });
  ok insert_in_flight($pid), "$label: the INSERT is in flight on the server, waiting for a lock"
    or do { hold_released(); $h->disconnect; next };
  $stmt->cancel if $when ne 'in the coderef';

  rolls_back_behind($label, $h, $pid, $txn, $stmt, $CANCELLED, $rows);
  $h->disconnect;
}

{
  my $label = 'txn, lost a wait_any against an EV::timer';
  my ($h, $pid) = fresh();
  my $rows = rows_in_table();
  hold_inserts();

  my ($stmt, $timer);
  my $txn = $h->async->txn_do_async(sub {
    my ($ctx) = @_;
    $stmt = $ctx->insert_async($TABLE, { name => 'doomed' });
    my $timeout = $EVF->new;
    $timer = EV::timer(0.2, 0, sub { $timeout->fail("timed out\n") unless $timeout->is_ready });
    return $EVF->wait_any($stmt, $timeout);
  });
  SKIP: {
    ok insert_in_flight($pid), "$label: the INSERT is in flight on the server, waiting for a lock"
      or do { hold_released(); skip 'the INSERT never got there', 1 };
    ok wait_until(sub { $stmt->is_ready }), "$label: the timer won";
    rolls_back_behind($label, $h, $pid, $txn, $stmt, "timed out\n", $rows);
  }
  $h->disconnect;
}

# --- 5. txn_do_async: the statement behind the cancelled one ----------------------

{
  my $label = 'txn, a statement behind the cancelled one';
  my ($h, $pid) = fresh();
  my $rows = rows_in_table();
  hold_inserts();

  my ($doomed, $behind);
  my $txn = $h->async->txn_do_async(sub {
    my ($ctx) = @_;
    $doomed = $ctx->insert_async($TABLE, { name => 'doomed' });
    $behind = $ctx->select_async(tagged('behind'));
    return $behind;
  });
  SKIP: {
    ok insert_in_flight($pid), "$label: the INSERT is in flight on the server, waiting for a lock"
      or do { hold_released(); skip 'the INSERT never got there', 1 };
    $doomed->cancel;
    settle(0.2);
    if ($CAN) {
      # The server stopped the INSERT, so the transaction is aborted and is
      # what the statement behind is told: not "user request" -- the request
      # did not reach it, it was sent after the request was answered.
      is state_of($behind), 'failed', "$label: the statement behind was answered, with the lock still held";
      like $behind->is_failed ? $behind->failure : '', qr/current transaction is aborted/,
        "$label: with the aborted transaction, not with the cancel request";
      hold_released();
      my ($ok, $err) = wait_for($txn);
      ok !$ok, "$label: the transaction fails";
      like $err, qr/current transaction is aborted/, "$label: with the same error";
    }
    else {
      like backend($pid)->{query}, qr/^INSERT/,
        "$label: no request -- the server is still on the cancelled INSERT";
      is state_of($behind), 'pending', "$label: the statement behind it waits";

      hold_released();
      my ($ok, $err) = wait_for($txn);
      is state_of($behind), 'done', "$label: the statement behind completes";
      is_deeply [ $behind->is_done ? $behind->get : () ], [ [ $pid, 'behind' ] ],
        "$label: with its own row -- the cancelled statement's late result did not reach it";
      ok !$ok, "$label: the transaction fails";
      like $err, $CANCELLED, "$label: saying a statement was cancelled";
    }
    rolled_back($label, $h, $pid, $rows);
  }
  $h->disconnect;
}

# --- 6. txn_do_async: cancelled while it waits behind another statement -----------

{
  my $label = 'txn, cancelled while queued';
  my ($h, $pid) = fresh();
  my $rows = rows_in_table();
  my $run  = inserts_run();

  my ($first, $queued);
  my ($ok, $err) = wait_for($h->async->txn_do_async(sub {
    my ($ctx) = @_;
    $first  = $ctx->insert_async($TABLE, { name => 'first' });
    $queued = $ctx->insert_async($TABLE, { name => 'queued' });
    $queued->cancel;
    return $first;
  }));
  ok !$ok, "$label: the transaction fails";
  like $err, $CANCELLED, "$label: saying a statement was cancelled";
  is state_of($first), 'done', "$label: the statement in flight completed";
  is state_of($queued), 'cancelled', "$label: the cancelled one stays cancelled";

  my $sent = inserts_run() - $run;
  is $sent, 1, "$label: a statement cancelled before it was sent is not sent (karr k75)";
  rolled_back($label, $h, $pid, $rows);
  $h->disconnect;
}

# --- 6b. the ROLLBACK of core, cancelled in the queue, is sent anyway -------------

for my $end (qw( ROLLBACK )) {
  my $label = "txn, $end cancelled while queued";
  my ($h, $pid, $pg) = fresh();
  my $rows = rows_in_table();

  my ($first, $ending);
  my ($ok, $err) = wait_for($h->async->txn_do_async(sub {
    my ($ctx) = @_;
    $first  = $ctx->insert_async($TABLE, { name => 'first' });
    $ending = $h->async->_query_async_pinned($pg, $end);
    $ending->cancel;
    return $first;
  }));
  ok !$ok, "$label: the transaction fails";
  is state_of($first), 'done', "$label: the statement in flight completed";
  is state_of($ending), 'cancelled', "$label: the cancelled one stays cancelled";
  my $b = do { settle(); backend($pid) };
  # The ROLLBACK of this file is already issued on the pinned connection, so the
  # COMMIT of core is refused behind it ("Statement refused"), and an end of the
  # transaction nobody confirmed retires the connection (core k395, which
  # replaced the release this file used to see). The backend is gone from the
  # server then, and the transaction with it: no longer "idle", so the claim is
  # that no backend is left in the transaction. (Retiring cancels first, which
  # is one more request below.)
  is $b->{state}, '', "$label: the connection is retired, its backend is gone -- not idle in transaction";
  is rows_in_table(), $rows, "$label: nothing of the transaction is there";
  $h->disconnect;
}

is $REQUESTS{cancel}, 0, 'karr k75: none of these cancels called the blocking EV::Pg cancel';
# 3 pooled cases of 1, late error, lost connection, then 3 txn cases, the one
# behind the cancelled statement: every cancel of a statement in flight, and
# not the one that waited in the queue (6).
# Plus one: the retirement of the connection in 6b cancels what it may still be
# running before it closes the connection (_pg_close_after_cancel).
is $REQUESTS{cancel_async}, $CAN ? 3 + 1 + 1 + 3 + 1 + 1 : 0,
  'karr k75: one cancel request for each statement cancelled in flight, none for the one cancelled in the queue';

# --- 10. the race: the connection is held until the request is answered (k75) -----

SKIP: {
  skip 'this EV::Pg has no cancel_async', 3 unless $CAN;
  my $label = 'race, cancelled right after it was issued';
  my ($h, $pid) = fresh();
  my $rounds = 25;
  my @hit;
  my $requests = $REQUESTS{cancel_async};
  for my $round (1 .. $rounds) {
    # A statement that is cancelled the moment it is on its way, and a next
    # call that runs long enough for a request still open to land on it. The
    # reset of the round before is answered first (karr k99): a statement
    # queued behind it is not on its way, and its cancel sends no request.
    PoolReset->until_reset($h->async);
    my $q1 = $h->async->select_async(tagged("r$round"));
    $q1->cancel;
    my $q2 = $h->async->select_async(exprs('pg_backend_pid()', "'q2'", '(SELECT 1 FROM pg_sleep(0.03))'));
    my ($ok, @r) = wait_for($q2);
    push @hit, "$round: " . ($ok ? 'another row' : $r[0]) unless $ok && $r[0][1] eq 'q2' && $r[0][0] == $pid;
  }
  is_deeply \@hit, [], "$label: the next caller was hit by none of $rounds requests, it got its own row on the same backend"
    or diag join '', @hit;
  is $REQUESTS{cancel_async} - $requests, $rounds, "$label: each cancel sent its request";
  idle_again($label, $h, $pid);
  $h->disconnect;
}

# --- 11. no request for a COPY (k75) --------------------------------------------

{
  my $label = 'COPY, cancelled';
  my ($h, $pid) = fresh();
  my $requests = $REQUESTS{cancel_async} + $REQUESTS{cancel};
  my $copy = $h->async->copy_in($TABLE, ['name'], sub { $_[0]->(['k75_copied']) });
  $copy->cancel;
  is state_of($copy), 'cancelled', "$label: the Future is cancelled";
  is $REQUESTS{cancel_async} + $REQUESTS{cancel}, $requests, "$label: no cancel request";
  ok wait_until(sub { $h->pool->available == 1 }), "$label: the connection comes back when the COPY has ended";
  idle_again($label, $h, $pid);
  $h->disconnect;
}

# --- 8. MEASURED, not this transport's: EV::Pg's cancel_async on this stack -------

SKIP: {
  my $label = 'measured, EV::Pg cancel_async';
  skip 'this EV::Pg has no cancel_async', 7 unless EV::Pg->can('cancel_async');
  my ($h, $pid) = fresh();
  my ($got, $pg) = wait_for($h->pool->acquire);
  die "acquiring the pool's connection failed: $pg" unless $got;

  my $sent_at = EV::time();
  my $f = $h->query_on($pg, 'SELECT pg_sleep(5)');
  my @answer;
  unless (eval { $pg->cancel_async(sub { @answer = @_ }); 1 }) {
    my $why = $@;
    wait_for($f);
    $h->pool->release($pg);
    $h->disconnect;
    skip "EV::Pg refused cancel_async (it needs libpq 17): $why", 7;
  }
  my ($ok, $err) = wait_for($f);
  my $took = EV::time() - $sent_at;
  ok !$ok, "$label: the statement in flight fails";
  like $err, qr/canceling statement due to user request/, "$label: with the server's query_canceled";
  is +($pg->error_fields || {})->{sqlstate}, '57014', "$label: SQLSTATE 57014";
  cmp_ok $took, '<', 2.5, "$label: long before its pg_sleep(5) would have ended";
  note sprintf '%s: the statement failed %.3fs after it was sent', $label, $took;
  ok wait_until(sub { @answer }), "$label: the cancel request is answered";
  note "$label: its callback got (" . join(', ', map { defined ? $_ : 'undef' } @answer) . ')';
  is $pg->transaction_status, EV::Pg::PQTRANS_IDLE(), "$label: the connection is IDLE";
  my ($again, @r) = wait_for($h->query_on($pg, 'SELECT pg_backend_pid()'));
  is $again ? $r[0][0] : undef, $pid, "$label: and the next statement runs on it, on the same backend";
  $h->pool->release($pg);
  no_callback_died($label);
  $h->disconnect;
}

# --- 9. the coderef returned the cancelled Future ---------------------------------
#
# Future.pm runs no ->then callback of a cancelled Future, so core answers the
# cancel itself (core k274, ADR 0055 addendum): the transaction fails with
# "Transaction cancelled", ROLLBACK goes out best-effort and unwaited, and the
# connection is retired -- never released, the pool's slot going to a fresh
# connection. Whether the INSERT the server was waiting a lock for still runs
# is the server's (with cancel_async it is cancelled while it waits); what is
# claimed is that nothing is committed and no session is left with the
# transaction open.

{
  my $label = 'txn, the coderef returned the cancelled Future';
  my ($h, $pid) = fresh();
  my $rows = rows_in_table();
  hold_inserts();

  my $stmt;
  my $txn = $h->async->txn_do_async(sub {
    my ($ctx) = @_;
    return $stmt = $ctx->insert_async($TABLE, { name => 'doomed' });
  });
  SKIP: {
    ok insert_in_flight($pid), "$label: the INSERT is in flight on the server, waiting for a lock"
      or do { hold_released(); skip 'the INSERT never got there', 6 };
    $stmt->cancel;
    is state_of($txn), 'failed', "$label: the transaction fails at once, it does not stay pending";
    like $txn->is_failed ? ($txn->failure)[0] : '', qr/Transaction cancelled/, "$label: saying it was cancelled";
    is $h->pool->available, 0, "$label: its connection is not idle in the pool";
    hold_released();
    ok wait_until(sub { backend_gone($pid) }),
      "$label: the retired connection's session ends, with no transaction left open";
    is $h->pool->size, 0, "$label: and the pool does not count it";
    my ($ok, @r) = wait_for($h->async->select_async(@PID));
    ok $ok && $r[0][0] != $pid, "$label: the next call runs on a fresh backend";
  }
  is rows_in_table(), $rows, "$label: nothing was committed";
  $h->disconnect;
  no_callback_died($label);
}

# --- 10. core k274 over the capability: the statement is still asked to stop ------
#
# Core retires the connection at the cancel, and EV::Pg's finish drops a
# cancel_async request that is not through yet, unsent: the statement then ran
# to its end on the server -- 3 s for pg_sleep(3), measured, against 13 ms with
# the request answered first. The pool closes a retired connection with a
# statement in flight only once the request is answered
# (DBIO::PostgreSQL::EV::Pool _shutdown_connection).

for my $how ('the coderef returned the cancelled Future', 'the transaction itself is cancelled') {
  my $label = "txn, $how, a statement running";
  my ($h, $pid) = fresh();

  my $stmt;
  my $txn = $h->async->txn_do_async(sub {
    my ($ctx) = @_;
    return $stmt = $ctx->select_async(exprs('pg_backend_pid()', 'pg_sleep(1)'));
  });
  ok wait_until(sub { my $b = backend($pid); $b->{state} eq 'active' && $b->{query} =~ /pg_sleep/ }),
    "$label: the statement runs on the server"
    or do { $h->disconnect; next };

  my $requests = $REQUESTS{cancel_async};
  $how =~ /^the coderef/ ? $stmt->cancel : $txn->cancel;
  my $cancelled_at = EV::time();
  is $REQUESTS{cancel_async} - $requests, $CAN ? 1 : 0,
    "$label: " . ($CAN ? 'exactly one cancel request' : 'no cancel request, this EV::Pg has no cancel_async');
  is $REQUESTS{cancel}, 0, "$label: and never the blocking cancel";
  is state_of($txn), $how =~ /^the coderef/ ? 'failed' : 'cancelled', "$label: the transaction's Future is settled";
  is $h->pool->available, 0, "$label: its connection is not idle in the pool";

  my $running;
  my $stopped = wait_until(sub {
    $running = backend($pid);
    !($running->{state} eq 'active' && $running->{query} =~ /pg_sleep/);
  });
  my $stopped_after = EV::time() - $cancelled_at;
  note sprintf '%s: the server was off the statement %.3fs after the cancel', $label, $stopped_after;
  if ($CAN) {
    ok $stopped, "$label: the server stops the statement"
      or diag "the backend is '$running->{state}' with: $running->{query}";
    cmp_ok $stopped_after, '<', 0.5, "$label: within milliseconds of the cancel, not at the statement's end";
  }
  ok wait_until(sub { backend_gone($pid) }), "$label: and the session ends";
  is $REQUESTS{cancel_async} - $requests, $CAN ? 1 : 0, "$label: no second request";
  $h->disconnect;
  no_callback_died($label);
}

$locker->disconnect;
$observer->do("DROP TABLE IF EXISTS $TABLE");
$observer->disconnect;
undef $observer;

done_testing;
