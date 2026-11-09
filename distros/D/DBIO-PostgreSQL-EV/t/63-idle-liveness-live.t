use strict;
use warnings;
use Test::More;

# LIVE, karr k73 (d) / karr k72: a pooled connection whose session ended while
# it sat idle, what the next borrower gets, and what the socket says before
# anything has read it -- against a real PostgreSQL. The live half of
# t/57-idle-liveness-mock.t.
#
# WHY: core's pool asks _idle_connection_alive about every idle connection it
# is about to hand out. Until karr k72 DBIO::PostgreSQL::EV::Pool did not fill
# that seam; what it had was EV::Pg's on_error, which reaches exactly as far as
# the EV loop does. A program that only ever blocks reads nothing between two
# calls, and the first call after the server ended the session -- a restart,
# idle_session_timeout, pg_terminate_backend -- was handed the dead connection.
# t/57 claims the seam over a stand-in EV::Pg, on what was read from Pg.xs:
# that EV::Pg goes on reporting the handle connected until something reads,
# and that the end of the session is on the socket for anyone who looks. What
# only a server shows is what a dead session's socket looks like, and whether
# a LIVE idle session can look the same. It can, to anyone who asks whether
# the socket has something to read; so the pool asks whether the server's end
# of it is CLOSED (poll, POLLRDHUP), which no live session's is.
#
# What this file claims:
#   1. the session ends while the connection is idle and the EV loop runs
#      before the next borrow: the connection is retired then, and the next
#      call completes first time, on a fresh backend;
#   2. a healthy idle connection is handed out again: the same backend (the
#      guard against a seam that is too eager);
#   3. however the dead connection is found, the pool serves on with a fresh
#      backend, the dead one is gone, and the server has one backend for the
#      pool;
#   4. a live idle session with a notification waiting for it is handed out
#      like any other: the pool vouches for it, the next call completes first
#      time, on the SAME backend, and the notification is delivered once the
#      loop runs. Such a session's socket is readable (see below): "readable"
#      does not cost it its connection, and the look takes nothing off it;
#   5. no callback of this transport dies out of EV::Pg;
#   A. the session ended -- by pg_terminate_backend, or by the server itself
#      on idle_session_timeout -- and the loop has NOT run since: the call is
#      not handed the dead connection. It completes first time, on a fresh
#      backend, and the pool's on_error hears nothing;
#   B. the handle is no longer connected and the pool was not told -- EV::Pg
#      lost it with a caller's on_error in place of the pool's, or a caller
#      called finish on it: the call completes first time, on a fresh backend.
# Before karr k72, A and B were this file's TODAY assertions, with these
# claims as TODO beside them: the first call failed with "connection lost"
# (A) and "not connected" (B), and the pool heard the server's last words.
#
# MEASURED for karr k72, marked so: these are facts of libpq, the socket and
# the server, and nothing in lib/ can turn them red. Without the loop having
# run,
#   - the socket of a live idle session is not readable;
#   - once the server has ended the session, it is readable -- at once -- while
#     EV::Pg still reports the handle connected;
#   - and the socket of a LIVE idle session that has a NOTIFY waiting is
#     readable just the same. Readable alone does not mean gone;
#   - the close of the server's end follows its last words once the backend
#     has exited, and is on the socket by the time pg_terminate_backend, asked
#     to wait for that, has returned.
# NOT claimed: a borrow in the milliseconds between a backend's last words and
# its exit (pg_terminate_backend not asked to wait). The socket is readable
# and open then, the pool vouches, and the call fails as it did before k72.
# Everything up to the last part is made over a plain connection, on every
# server: the pool is opened with sslmode=disable (karr k82). Left to itself
# libpq takes sslmode=prefer and encrypts wherever the server can, so against
# a server with ssl = on the bare test DSN gave a TLS connection and the
# measurements were not what they said.
# Over TLS the pool's look is the same look: it is at the TCP connection, where
# a TLS record -- a session ticket, an alert -- is data like any other and the
# close is the same close. That is read off the kernel, NOT measured: it needs
# a server with ssl = on. This file asks (SHOW ssl) and repeats A and 4, with
# every claim they make, over sslmode=require where it can, and skips that
# part, saying so, where it cannot.
#
# Terminating backends needs pg_terminate_backend on this file's own sessions
# only. The text assertions take the server's messages to be English. Every
# wait on the EV loop is bounded by a watchdog, and alarm is the backstop.

use DBIO::PostgreSQL::EV::TestHarness;

DBIO::PostgreSQL::EV::TestHarness->skip_all_unless_live;

use EV;
use FindBin;
use lib "$FindBin::Bin/lib";
use PoolReset;
use LiveServer;
use DBIO::PostgreSQL::EV::Pool ();

alarm 180;

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_PG_$_" } qw( DSN USER PASS ) };

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

my $TAG     = "dbio_k73_idle_$$";
my $CHANNEL = "dbio_k73_idle_$$";


# The server's view, from a connection that belongs to no pool.
# A server that is not there fails the file here, with a plan (karr k77).
my $observer = LiveServer->control_dbh(application_name => "${TAG}_observer");
{
  my ($seen_as) = $observer->selectrow_array(
    'SELECT application_name FROM pg_catalog.pg_stat_activity WHERE pid = pg_backend_pid()'
  );
  plan skip_all => 'the test DSN sets an application_name of its own; this file tells its backends apart by PGAPPNAME'
    unless defined $seen_as && $seen_as eq "${TAG}_observer";
}
$ENV{PGAPPNAME} = $TAG;   # every connection a harness opens from here on

# Can this platform's poll be asked whether a peer has closed? Where it cannot,
# the pool vouches for a connection whose server end is closed, as it did
# before karr k72, and A cannot hold.
my $rdhup = DBIO::PostgreSQL::EV::Pool->can('_pg_rdhup');
ok $rdhup, 'the pool measures whether poll can be asked for a closed peer (_pg_rdhup)';
my $CAN_ASK = $rdhup ? $rdhup->() : 0x2000;
my $NO_FLAG = "this platform's poll has no flag for a closed peer: the pool vouches, as before karr k72";

# The backend pid of the connection a call runs on.
my @PID = ('pg_namespace', [ \'pg_backend_pid()' ], { nspname => 'pg_catalog' });

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
  my $done = 0;
  EV::now_update();
  my $t = EV::timer(0.1, 0, sub { $done = 1 });
  EV::run(EV::RUN_ONCE()) until $done;
  return;
}

# A pool of one with its connection up and idle: the harness, the backend of
# that connection, and the connection. Over a plain connection unless a dsn is
# given: sslmode=disable behind the test DSN, where it wins over an sslmode
# the DSN carries -- libpq takes the later value of a keyword, from DBD::Pg
# for the owner's dbh as from dbi_to_conninfo for the pool
# (t/53-dbi-to-conninfo.t).
sub fresh {
  my (%harness) = @_;
  my $h = DBIO::PostgreSQL::EV::TestHarness->new(
    connect_attrs => { pool_size => 1 }, dsn => "$dsn;sslmode=disable", %harness,
  );
  my ($ok, @r) = wait_for($h->async->select_async(@PID));
  die "warming the pool failed: $r[0]" unless $ok;
  PoolReset->until_reset($h->async);   # idle once the reset of the warming call is answered (karr k99)
  settle();
  my $conn = $h->pool->{_connections}[0];
  die 'the pool did not keep its connection idle' unless $conn && $h->pool->available == 1;
  @warnings = ();
  return ($h, $r[0][0], $conn);
}

# Does select() report the socket readable within $timeout seconds? Not the EV
# loop: nothing is read, and no watcher runs.
sub readable {
  my ($fd, $timeout) = @_;
  my $rin = '';
  vec($rin, $fd, 1) = 1;
  my $n = select(my $rout = $rin, undef, undef, $timeout);
  return $n > 0 ? 1 : 0;
}

sub terminate {
  my ($pid) = @_;
  my ($ok) = $observer->selectrow_array('SELECT pg_terminate_backend(?, 5000)', undef, $pid);
  return $ok;
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

# The backend the next call runs on, or undef and the error.
sub backend_of_next_call {
  my ($h) = @_;
  my ($ok, @r) = wait_for($h->async->select_async(@PID));
  return $ok ? ($r[0][0]) : (undef, $r[0]);
}

sub no_callback_died {
  my ($label) = @_;
  my @died = grep { /exception in callback/ } @warnings;
  is scalar @died, 0, "$label: no callback died out of EV::Pg" or diag @died;
  @warnings = ();
}

# 3. However the dead connection was found: the pool serves on with a fresh
# backend, the dead one is gone, and the server has one backend for the pool.
sub serves_on_fresh {
  my ($label, $h, $dead) = @_;
  my ($pid, $err) = backend_of_next_call($h);
  ok defined $pid, "$label: the pool serves on" or diag "the call failed: $err";
  ok defined $pid && $pid != $dead, "$label: on a fresh backend";
  settle();
  is $h->pool->size, 1, "$label: the pool has its one connection";
  is $h->pool->available, 1, "$label: idle";
  ok backend_gone($dead), "$label: the dead backend is gone";
  is_deeply pool_backends($h), [ defined $pid ? $pid : () ], "$label: and the server has that one backend for the pool";
  no_callback_died($label);
}

# The first call after the pool was left with a dead connection completes, on
# a fresh backend. $got is the backend it ran on, or its error.
sub first_call_completes {
  my ($label, $ok, $got, $dead) = @_;
  ok $ok, "$label: the first call completes" or diag "it failed: $got";
  ok $ok && $got != $dead, "$label: on a fresh backend";
  return;
}

# Is the close of the server's end on the socket of $conn within $secs? The
# pool's own look, asked again and again without the EV loop: nothing reads.
sub closed_within {
  my ($h, $conn, $secs) = @_;
  my $deadline = EV::time() + $secs;
  until ($h->pool->_pg_peer_closed($conn)) {
    return 0 if EV::time() > $deadline;
    select undef, undef, undef, 0.002;
  }
  return 1;
}

# The backend $pid has left pg_stat_activity within $secs. Asked over the
# observer's connection, with sleeps in between: the EV loop does not run.
sub gone_within {
  my ($pid, $secs) = @_;
  my $deadline = EV::time() + $secs;
  until (backend_gone($pid)) {
    return 0 if EV::time() > $deadline;
    select undef, undef, undef, 0.02;
  }
  return 1;
}

# How the session of the pool's idle connection ends: each returns true once
# the backend is gone, and does not run the EV loop after the session ended.
my %END = (
  # An administrator's kill, asked to wait for the backend to exit.
  'pg_terminate_backend' => sub {
    my ($h, $pid) = @_;
    return terminate($pid);
  },
  # The server ends it itself: the connection's sessions have an
  # idle_session_timeout (PostgreSQL 14) -- a connect action, since a setting of
  # one borrow does not outlive it (karr k99) -- and the session is left idle.
  'idle_session_timeout' => sub {
    my ($h, $pid) = @_;
    return gone_within($pid, 5);
  },
);

# A. The session of the pool's idle connection ends, and the EV loop does not
# run before the next borrow.
sub ended_and_not_read {
  my ($label, $h, $pid, $conn, $how) = @_;
  my $fd = $conn->socket;

  ok !readable($fd, 0), "$label -- MEASURED: the socket of a live idle session is not readable";
  ok $END{$how}->($h, $pid), "$label: the session is ended ($how), and its backend gone";
  # From here to the borrow the loop does not run: select() and poll() look,
  # nothing reads.
  my $asked = EV::time();
  ok readable($fd, 2), "$label -- MEASURED: the end of the session is readable on the socket";
  note sprintf '%s: select() reported it %.3fs after the backend was known to be gone', $label, EV::time() - $asked;
  ok readable($fd, 0), "$label -- MEASURED: and stays so, asked with no wait at all";
  ok $conn->is_connected, "$label -- MEASURED: while EV::Pg still reports the handle connected -- libpq has not read";
  is $h->pool->available, 1, "$label: and the pool still has it idle";

  SKIP: {
    skip $NO_FLAG, 1 unless $CAN_ASK;

    ok closed_within($h, $conn, 2), "$label -- MEASURED: the close of the server's end is on the socket";
    note sprintf '%s: poll() reported it %.3fs after the backend was known to be gone', $label, EV::time() - $asked;
    ok readable($fd, 0), "$label -- MEASURED: with the server's last words still unread in front of it";
    ok !$h->pool->_idle_connection_alive($conn), "$label: the pool does not vouch for the connection";

    my $f = $h->async->select_async(@PID);
    is $conn->pending_count, 0, "$label: the call is not handed that connection -- EV::Pg was given no statement on it";
    ok !$conn->is_connected, "$label: which the pool closed as it retired it, in the acquire";
    my ($ok, @r) = wait_for($f);
    first_call_completes($label, $ok, $ok ? $r[0][0] : $r[0], $pid);
    unlike join('', @warnings), qr/pool error/,
      "$label: the pool's on_error hears nothing -- the connection is retired quietly";
    serves_on_fresh($label, $h, $pid);
  }
  return;
}

# The NOTIFY measurement, and 4: a live idle session that has a notification
# waiting for it.
sub notified_while_idle {
  my ($label, $h, $pid, $conn) = @_;
  # The session listens because its connect action does (LISTEN is session
  # state, and the reset at the end of a borrow ends it, karr k99): look at it.
  my ($got, $pg) = wait_for($h->pool->acquire);
  die "acquiring the pool's connection failed: $pg" unless $got;
  my ($listening, $channels) = wait_for($h->query_on($pg, q{SELECT pg_listening_channels()}));
  $h->pool->release($pg);
  ok $listening && ($channels->[0] // '') eq $CHANNEL, "$label: the pool's session listens on a channel"
    or diag $listening ? 'it listens on: ' . join(',', map { $_->[0] } $channels) : "the query failed: $channels";
  PoolReset->until_reset($h->async);
  settle();
  my $fd = $conn->socket;
  # What the handle is notified of, once something makes libpq read.
  my @notified;
  $conn->on_notify(sub { push @notified, "$_[0]: $_[1]" });

  ok !readable($fd, 0), "$label -- MEASURED: its socket is not readable while nothing is sent to it";
  $observer->do(qq{NOTIFY "$CHANNEL", 'still alive'});
  # No loop run from here to the borrow.
  ok readable($fd, 2),
    "$label -- MEASURED: a NOTIFY makes the socket of a LIVE idle session readable -- readable is not gone";
  ok $conn->is_connected, "$label: EV::Pg reports the handle connected, and it is";
  is $h->pool->available, 1, "$label: the pool has it idle";
  ok !$h->pool->_pg_peer_closed($conn), "$label: the server's end of the socket is not closed";
  ok $h->pool->_idle_connection_alive($conn), "$label: and the pool vouches for the connection";
  ok readable($fd, 0), "$label: the look took nothing off the socket";
  is scalar @notified, 0, "$label: and made nobody read: the notification is still to come";

  my ($next, $next_err) = backend_of_next_call($h);
  is $next, $pid, "$label: the next call completes first time, on the SAME backend -- the session was never gone"
    or diag defined $next ? "it ran on backend $next" : "it failed: $next_err";
  settle();
  is_deeply \@notified, [ "$CHANNEL: still alive" ],
    "$label: the notification is delivered to the handle once the loop runs -- nothing was lost";
  ok !readable($fd, 0), "$label -- MEASURED: the loop has read the notification; the socket is not readable any more";
  is $h->pool->size, 1, "$label: the pool has its one connection";
  is $h->pool->available, 1, "$label: idle";
  is_deeply pool_backends($h), [ $pid ], "$label: and the server has that one backend for the pool";
  no_callback_died($label);
  return;
}

# --- A. the session ended, and the loop has not run since (k73 d) ------------------

for my $how ('pg_terminate_backend', 'idle_session_timeout') {
  my $label = "ended while idle ($how), loop did not run";
  SKIP: {
    skip "$label: idle_session_timeout needs PostgreSQL 14", 1
      if $how eq 'idle_session_timeout' && $observer->{pg_server_version} < 140000;
    my ($h, $pid, $conn) = fresh($how eq 'idle_session_timeout'
      ? (connect_attrs => { pool_size => 1, on_connect_do => [ q{SET idle_session_timeout = '2000ms'} ] }) : ());
    ok !$conn->ssl_in_use, "$label: (over a plain connection)";
    ended_and_not_read($label, $h, $pid, $conn, $how);
    $h->disconnect;
  }
}

# --- 1. the session ends while idle, and the EV loop runs before the borrow --------

{
  my $label = 'ended while idle, loop ran';
  my ($h, $pid, $conn) = fresh();

  ok terminate($pid), "$label: the backend is terminated";
  is $h->pool->available, 1, "$label: (until something reads, the pool still has it idle)";
  ok wait_until(sub { $h->pool->size == 0 }),
    "$label: retired as soon as the loop read the end of the session";
  # Read on an idle connection, the server's FATAL is a notice to libpq, not
  # the connection's error: what on_error gets is the end of file alone, in
  # libpq's words for a plain connection. Over TLS the same end reads "SSL
  # connection has been closed unexpectedly" (seen against PostgreSQL 18.6
  # with ssl = on, karr k82) -- noted, not claimed here.
  like join('', @warnings), qr/pool error: server closed the connection unexpectedly/,
    "$label: the pool's on_error heard of it";
  @warnings = ();

  my ($first, $err) = backend_of_next_call($h);
  ok defined $first, "$label: the next call completes, first time" or diag "it failed: $err";
  ok defined $first && $first != $pid, "$label: on a freshly spawned backend";
  serves_on_fresh($label, $h, $pid);
  $h->disconnect;
}

# --- 2. a healthy idle connection is handed out again ------------------------------

{
  my $label = 'healthy idle connection';
  my ($h, $pid, $conn) = fresh();
  settle();   # idle for a while, the loop running

  my ($next, $err) = backend_of_next_call($h);
  is $next, $pid, "$label: the next call runs on the same backend" or diag $err // 'another backend';
  settle();
  is $h->pool->size, 1, "$label: nothing was spawned";
  is $h->pool->available, 1, "$label: and it is idle again";
  is_deeply pool_backends($h), [ $pid ], "$label: the server has that one backend for the pool";
  no_callback_died($label);
  $h->disconnect;
}

# --- 4. a live idle session with a notification waiting ----------------------------

{
  my $label = 'live idle session, NOTIFY waiting';
  my ($h, $pid, $conn) = fresh(connect_attrs => { pool_size => 1, on_connect_do => [ qq{LISTEN "$CHANNEL"} ] });
  notified_while_idle($label, $h, $pid, $conn);
  $h->disconnect;
}

# --- B. the handle is not connected any more, and the pool was not told ------------

for my $how ('lost, on_error replaced by a caller', 'finished by a caller') {
  my $label = "idle handle $how";
  my ($h, $pid, $conn) = fresh();

  if ($how =~ /^lost/) {
    my @heard;
    $conn->on_error(sub { push @heard, $_[0] });
    ok terminate($pid), "$label: the backend is terminated";
    ok wait_until(sub { !$conn->is_connected }), "$label: the loop reads the end of the session";
    is scalar @heard, 1, "$label: (EV::Pg reported the loss to the caller's handler, not to the pool)";
  }
  else {
    $conn->finish;
  }
  ok !$conn->is_connected, "$label: EV::Pg no longer reports the handle connected";
  is $h->pool->available, 1, "$label: and the pool still has it idle";

  my ($first, $err) = backend_of_next_call($h);
  first_call_completes($label, defined $first, defined $first ? $first : $err, $pid);
  ok wait_until(sub { backend_gone($pid) }), "$label: (the backend is gone)";
  serves_on_fresh($label, $h, $pid);
  $h->disconnect;
}

# --- the same over TLS, where the server has it -------------------------------------

SKIP: {
  my ($ssl) = $observer->selectrow_array('SHOW ssl');
  skip "the server has ssl = $ssl: that the pool's look at the socket (karr k72) sees the same "
    . 'over TLS cannot be measured against it -- A and 4 were held over a plain connection only', 1
    unless $ssl eq 'on';

  for my $part ('ended while idle, loop did not run', 'live idle session, NOTIFY waiting') {
    my $label = "TLS, $part";
    my ($h, $pid, $conn) = fresh(dsn => "$dsn;sslmode=require",
      $part =~ /^ended/ ? () : (connect_attrs => { pool_size => 1, on_connect_do => [ qq{LISTEN "$CHANNEL"} ] }));
    ok $conn->ssl_in_use, "$label: (the pooled connection is encrypted)";
    if ($part =~ /^ended/) { ended_and_not_read($label, $h, $pid, $conn, 'pg_terminate_backend') }
    else                   { notified_while_idle($label, $h, $pid, $conn) }
    $h->disconnect;
  }
}

$observer->disconnect;

done_testing;
