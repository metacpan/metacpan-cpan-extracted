use strict;
use warnings;
use Test::More;
use Time::HiRes ();

# LIVE test for karr k90 against a real PostgreSQL: the future_io transport
# answers the pool's borrow-time question _idle_connection_alive (dbio-async
# k28, core k241). The offline half, t/75-future-io-idle-connection-alive.t,
# pins the same claims against a fake DBD::Pg over a socketpair; this file
# terminates real idle backends and sends a real notification.
#
# WHY: a pooled connection whose backend ended while it sat idle -- an
# administrator's pg_terminate_backend, a server restart, an
# idle_session_timeout -- still shows an open pg_socket, because libpq notices
# a lost connection only when it reads. Before k90 the first call after such a
# death went out on the dead connection and failed ("server closed the
# connection unexpectedly"); after a server restart one call per idle
# connection did. The transport now reads, before the pool hands the
# connection out, what the dying server left on the socket.
#
# What this file claims:
#   a) a pool connection whose backend was terminated while idle is retired
#      at borrow time: the next call completes WITHOUT an error, on a fresh
#      backend, the pool keeps its one connection, and no pool error is
#      reported;
#   b) with every idle connection of a pool of two dead (what a server restart
#      leaves), the next two calls both complete, on fresh backends, and the
#      pool does not grow beyond its size;
#   c) a live idle connection that received something unasked -- a
#      notification on a channel it LISTENs to -- is NOT taken for dead: the
#      next call runs on the SAME backend (reading tells a live session from a
#      dying one; taking a readable socket as dead would throw it away).
#
# Before k90, a) and b) fail at their first call; c) passes before and after
# -- it is the control that keeps the check from throwing healthy connections
# away.
#
# Every wait is bounded and in the foreground. Terminating backends needs
# pg_terminate_backend on this file's own sessions only -- the same role --
# which PostgreSQL allows without superuser. Gated like the other live tests:
# DBIO_TEST_PG_DSN, _USER and _PASS.

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_PG_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_PG_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

BEGIN {
  eval {
    require IO::Async::Loop;
    require Future::IO::Impl::IOAsync;
    Future::IO::Impl::IOAsync->import;
    1;
  } or plan skip_all =>
    'Future::IO::Impl::IOAsync + IO::Async required for the live future_io idle-connection test';
}

use DBIO::Test;

# DBIO::Test::Schema keeps no driver in its class: this file runs it on
# PostgreSQL (core ADR 0067).
DBIO::Test::Schema->storage_type('+DBIO::PostgreSQL::Storage');

use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;

eval { require DBIO::PostgreSQL::Storage::Async; 1 }
  or plan skip_all =>
    'DBIO::Async not installed (recommends only) -- future_io transport unavailable';
plan skip_all => 'the installed dbio-async predates the _idle_connection_alive seam (dbio-async k28)'
  unless DBIO::Async::Storage->can('_idle_connection_alive')
      && DBIO::Async::Pool->can('_idle_connection_alive');

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

my $loop = IO::Async::Loop->new;

# The dying session's FATAL message reaches DBD::Pg as a notice, which it
# warns; collect the warnings, so each subtest can also check that no pool
# error was reported.
my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

my $admin = LiveServer->control_dbh(attrs => { AutoInactiveDestroy => 1 });

# The backend pid of the connection a call runs on.
my @PID = ('pg_namespace', [ \'pg_backend_pid()' ], { nspname => 'pg_catalog' });

our @SCHEMAS;   # the schema owns the connect actions the pool replays

sub connect_async {
  my ($size, %options) = @_;
  my $schema = DBIO::Test::Schema->connect($dsn, $user, $pass,
    { async => 'future_io', pool_size => $size, %options });
  push @SCHEMAS, $schema;
  return $schema->storage->async;
}

# The pool's connections are idle: the reset a borrow ends with (karr k154) has
# run, 10 seconds at most. What these claims are about is an IDLE connection.
sub wait_idle {
  my ($async, $count) = @_;
  my $deadline = Time::HiRes::time() + 10;
  $loop->loop_once(0.05)
    until $async->pool->available >= ($count // 1) || Time::HiRes::time() > $deadline;
}

# Wait for $f, 10 seconds at most: (1, @result) once done, (0, $error) once
# failed or still pending.
sub wait_for {
  my ($f) = @_;
  my $deadline = Time::HiRes::time() + 10;
  until ($f->is_ready) {
    return (0, "still pending after 10s\n") if Time::HiRes::time() > $deadline;
    $loop->loop_once(0.05);
  }
  return $f->is_done ? (1, $f->get) : (0, scalar $f->failure);
}

sub pid_of {
  my ($f) = @_;
  my ($ok, @r) = wait_for($f);
  return $ok ? ($r[0][0]) : (undef, $r[0]);
}

sub backend_of_next_call { pid_of($_[0]->select_async(@PID)) }

# Terminate a backend and wait until pg_stat_activity no longer lists it: by
# then it has sent its FATAL message and closed.
sub terminate_and_wait {
  my ($pid) = @_;
  my ($ok) = $admin->selectrow_array('SELECT pg_terminate_backend(?, 5000)', undef, $pid);
  return 0 unless $ok;
  my $deadline = Time::HiRes::time() + 10;
  while ($admin->selectrow_array('SELECT 1 FROM pg_stat_activity WHERE pid = ?', undef, $pid)) {
    return 0 if Time::HiRes::time() > $deadline;
    Time::HiRes::sleep(0.05);
  }
  return 1;
}

# Wait until the idle pool connection's socket is readable -- the server's
# message has arrived -- 10 seconds at most. Does not read.
sub socket_readable {
  my ($conn) = @_;
  open my $fh, '+<&', $conn->{dbh}{pg_socket} or die "dup: $!";
  my $rin = '';
  vec($rin, fileno($fh), 1) = 1;
  return select(my $rout = $rin, undef, undef, 10) > 0;
}

sub no_pool_error {
  my ($label) = @_;
  my @reported = grep { /pool error|liveness check failed/i } @warnings;
  ok !@reported, "$label: no pool error was reported" or diag explain \@reported;
}

subtest 'a) a backend terminated while idle: retired at borrow time, no error' => sub {
  @warnings = ();
  my $async = connect_async(1);
  my ($dead, $err) = backend_of_next_call($async);
  ok defined $dead, 'the pooled connection is up' or diag $err;
  wait_idle($async);
  is $async->pool->available, 1, '... back in the pool, idle';
  ok terminate_and_wait($dead), "its backend $dead is terminated and gone";

  my ($pid, $call_err) = backend_of_next_call($async);
  ok defined $pid, 'the next call completes, without an error'
    or diag "it failed: $call_err";
  ok defined $pid && $pid != $dead, "... on a fresh backend ($dead is gone)";
  is $async->pool->size, 1, '... the pool has its one connection';
  wait_idle($async);
  is $async->pool->available, 1, '... idle';
  no_pool_error('killed while idle');
  $async->disconnect;
};

subtest 'b) every idle connection of the pool dead: no call fails, the pool keeps its size' => sub {
  @warnings = ();
  my $async = connect_async(2);
  my @f = map { $async->select_async(@PID) } 1 .. 2;   # two at once: two connections
  my @dead = map { scalar pid_of($_) } @f;
  ok defined $dead[0] && defined $dead[1] && $dead[0] != $dead[1],
    'two pooled connections are up, on two backends';
  wait_idle($async, 2);
  is $async->pool->size, 2, '... the pool is full';
  ok terminate_and_wait($_), "backend $_ is terminated and gone" for grep { defined } @dead;

  my @g = map { $async->select_async(@PID) } 1 .. 2;
  my @pid = map { [ pid_of($_) ] } @g;
  for my $i (0, 1) {
    my ($pid, $call_err) = @{ $pid[$i] };
    ok defined $pid, "call $i completes, without an error" or diag "it failed: $call_err";
    ok defined $pid && !grep({ defined && $_ == $pid } @dead), "... on a fresh backend";
  }
  cmp_ok $async->pool->size, '<=', 2, 'the pool did not grow beyond its size';
  no_pool_error('all idle connections dead');
  $async->disconnect;
};

subtest 'c) a live idle connection that got a notification is reused' => sub {
  @warnings = ();
  my $channel = "dbio_k90_${$}";

  # The pool's one connection LISTENs, as an application that ran LISTEN in
  # on_connect_do has it (the reset a borrow ends with runs it again, k154),
  # and is idle.
  my $async = connect_async(1, on_connect_do => [ qq{LISTEN "$channel"} ]);
  my $conn  = $async->pool->acquire->get;
  my ($pid) = $conn->{dbh}->selectrow_array('SELECT pg_backend_pid()');
  $async->pool->release($conn);
  wait_idle($async);
  is $async->pool->available, 1, 'the listening pool connection is idle';

  $admin->do('SELECT pg_notify(?, ?)', undef, $channel, 'hello');
  ok socket_readable($conn), '... the notification is on its socket';

  my ($again, $err) = backend_of_next_call($async);
  is $again, $pid, 'the next call runs on the SAME backend'
    or diag $err // 'another backend';
  is $async->pool->size, 1, '... the pool\'s one connection';
  no_pool_error('notified');
  $async->disconnect;
};

$admin->disconnect;
done_testing;
