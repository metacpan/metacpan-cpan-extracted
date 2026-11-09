use strict;
use warnings;
use Test::More;
use Time::HiRes ();

# LIVE test for the future_io POOL connections against a real PostgreSQL
# (karr k79). The offline half, t/64-future-io-pool.t, pins the same claims
# against a fake DBD::Pg; this file forks a real child and terminates real
# backends, on a pool of one, driven through the async API as a consumer
# drives it.
#
# WHY: a prefork app forks one child per request. Pool connections were opened
# without AutoInactiveDestroy, so a child that simply exited sent PostgreSQL
# the terminate message for the PARENT's pooled sessions: the parent's next
# pooled statement -- a query, or notify(), which runs on the pool -- died with
# "server closed the connection unexpectedly". And the pool cannot see a
# connection die (core k230), so the dead handle went back to the idle list
# and was handed out again: a pool of one failed "no connection to the server"
# for every call after that, for good.
#
# What this file claims:
#   a) a forked child that exits leaves the parent's pooled session alone: the
#      parent's next pooled query runs on the SAME backend, first time, and
#      notify() goes out on it;
#  a2) a forked child that USES the inherited pool gets a connection of its
#      own -- core's pool fork guard (PoolBase::_verify_pid, core k233) covers
#      this transport's pool -- and the parent keeps its session;
#   b) a pooled connection whose backend was terminated while idle is retired,
#      not reissued: the call after the one that discovers the death runs on a
#      fresh connection (another backend pid);
#   c) a statement error the session survives does not cost the connection:
#      the next call runs on the SAME backend;
#   d) a transaction whose pinned connection is terminated fails, and the next
#      call runs on a fresh connection -- core hands the pinned connection back
#      through the pool's release, which retires it.
#
# Before the fix a), b) and d) fail, and so does a2)'s parent half: the child
# drops the handles it inherited, and their DESTROY ended the parent's session.
# a2)'s child half is core's and passes before and after. c) is the control
# that keeps the fix from throwing healthy connections away, and passes before
# and after.
#
# Every wait is bounded. Terminating backends needs pg_terminate_backend on
# this file's own sessions only -- the same role -- which PostgreSQL allows
# without superuser. Gated like the other live tests: DBIO_TEST_PG_DSN, _USER
# and _PASS.

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
    'Future::IO::Impl::IOAsync + IO::Async required for the live future_io pool test';
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
plan skip_all => 'the installed DBIO core predates PoolBase::_mark_connection_dead (core k230)'
  unless DBIO::Storage::PoolBase->can('_mark_connection_dead');
plan skip_all => 'the installed dbio-async predates the _conn_error_is_fatal seam (dbio-async k26)'
  unless DBIO::Async::Storage->can('_conn_error_is_fatal');
plan skip_all => 'the installed DBIO core predates the LISTEN/NOTIFY contract (core k219)'
  unless DBIO::Storage::Async->can('listen_alive');

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

my $loop = IO::Async::Loop->new;

# libpq reports a terminated session as a FATAL notice too; keep it off the
# test output.
my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

# The admin session: terminates backends and hears notifications. With
# AutoInactiveDestroy, so the child in a) cannot end it either.
my $admin = LiveServer->control_dbh(attrs => { AutoInactiveDestroy => 1 });

# The backend pid of the connection a call runs on.
my @PID = ('pg_namespace', [ \'pg_backend_pid()' ], { nspname => 'pg_catalog' });

sub connect_async {
  my $schema = DBIO::Test::Schema->connect($dsn, $user, $pass,
    { async => 'future_io', pool_size => 1 });
  return $schema->storage->async;
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

# The backend pid the next pooled call runs on, or undef and the error.
sub backend_of_next_call {
  my ($async) = @_;
  my ($ok, @r) = wait_for($async->select_async(@PID));
  return $ok ? ($r[0][0]) : (undef, $r[0]);
}

sub terminate {
  my ($pid) = @_;
  my ($ok) = $admin->selectrow_array('SELECT pg_terminate_backend(?, 5000)', undef, $pid);
  return $ok;
}

sub backend_alive {
  my ($pid) = @_;
  return scalar $admin->selectrow_array(
    'SELECT 1 FROM pg_stat_activity WHERE pid = ?', undef, $pid);
}

# The next call completes on a backend other than $dead, and the pool of one
# is whole again.
sub recovers {
  my ($label, $async, $dead) = @_;
  my ($pid, $err) = backend_of_next_call($async);
  ok defined $pid, "$label: the next call completes"
    or diag "it failed: $err";
  ok defined $pid && $pid != $dead, "$label: on a fresh connection (backend $dead is gone)";
  # the connection is reset before it is idle again (karr k154)
  my $deadline = Time::HiRes::time() + 10;
  $loop->loop_once(0.05) until $async->pool->available || Time::HiRes::time() > $deadline;
  is $async->pool->size, 1, "$label: the pool has its one connection";
  is $async->pool->available, 1, "$label: idle";
}

subtest 'a) fork: a child that exits leaves the parent\'s pooled session alone' => sub {
  my $async   = connect_async();
  my $channel = "dbio_k79_${$}";
  $admin->do(qq{LISTEN "$channel"});

  my ($pid, $err) = backend_of_next_call($async);
  ok defined $pid, 'the pooled connection is up' or diag $err;

  my $child = fork;
  die "fork: $!" unless defined $child;
  if (!$child) {
    # The child touches nothing and exits normally: END blocks and global
    # destruction run, and with them DESTROY on its copies of every handle --
    # the pool's included.
    exit 0;
  }
  waitpid($child, 0);
  is $? >> 8, 0, 'the child exited normally';

  ok backend_alive($pid), "the pooled backend $pid survived the child's exit";
  my ($again, $again_err) = backend_of_next_call($async);
  is $again, $pid, 'the parent\'s next pooled query runs on the SAME backend, first time'
    or diag $again_err // 'another backend';

  my ($ok, $notify_err) = wait_for($async->notify($channel => 'after-fork'));
  ok $ok, 'notify() after the child exited succeeds' or diag $notify_err;

  my $n;
  my $deadline = Time::HiRes::time() + 10;
  until ($n = $admin->pg_notifies) {
    last if Time::HiRes::time() > $deadline;
    Time::HiRes::sleep(0.05);
  }
  ok $n, 'the notification arrived';
  is_deeply $n && [ @$n[0, 2] ], [ $channel, 'after-fork' ], '... with its channel and payload';
  is $n && $n->[1], $pid, '... sent from the same pooled session';
  is $async->pool->size, 1, 'the pool still has its one connection';

  $admin->do(qq{UNLISTEN "$channel"});
  $async->disconnect;
};

subtest 'a2) fork: a child that uses the pool gets a connection of its own' => sub {
  my $async = connect_async();
  my ($pid, $err) = backend_of_next_call($async);
  ok defined $pid, 'the pooled connection is up' or diag $err;

  my $child = fork;
  die "fork: $!" unless defined $child;
  if (!$child) {
    # Core's pool drops what it inherited on first use in another process
    # (PoolBase::_verify_pid, core k233) -- DBIO::Async::Pool is a PoolBase
    # and overrides none of acquire / release / shutdown. The acquire needs no
    # event loop here: the connect is a blocking DBI->connect. Exit 0 only if
    # the child ran a statement on a backend other than the parent's.
    my $code = eval {
      my $conn = $async->pool->acquire->get;
      my ($child_pid) = $conn->{dbh}->selectrow_array('SELECT pg_backend_pid()');
      $async->pool->release($conn);
      $child_pid && $child_pid != $pid ? 0 : 2;
    } // 3;
    exit $code;
  }
  waitpid($child, 0);
  is $? >> 8, 0, 'the child ran its statement on a backend of its own, not the parent\'s';

  my ($again, $again_err) = backend_of_next_call($async);
  is $again, $pid, 'the parent\'s next pooled query still runs on its own backend'
    or diag $again_err // 'another backend';
  $async->disconnect;
};

subtest 'b) a backend terminated while idle: retired, not reissued' => sub {
  my $async = connect_async();
  my ($dead, $err) = backend_of_next_call($async);
  ok defined $dead, 'the pooled connection is up' or diag $err;
  ok terminate($dead), "its backend $dead is terminated";

  # Since karr k90 the pool asks _idle_connection_alive before it hands the
  # connection out, which normally retires it first (t/76 pins that); without
  # that check, or if the death is not on the socket yet, the first call goes
  # out on the dead handle and discovers the death. Either way it is retired.
  my ($first, $first_err) = backend_of_next_call($async);
  if (defined $first) {
    isnt $first, $dead, 'the first call after it completes, on another backend';
  }
  else {
    pass 'the first call after it fails -- it went out on the dead connection';
    note "  with: $first_err";
    is $async->pool->size, 0, '... which the pool retired instead of taking it back';
  }
  recovers('killed while idle', $async, $dead);
  $async->disconnect;
};

subtest 'c) a statement error keeps the connection' => sub {
  my $async = connect_async();
  my ($pid, $err) = backend_of_next_call($async);
  ok defined $pid, 'the pooled connection is up' or diag $err;

  my ($ok, $error) = wait_for($async->select_async('k79_no_such_table', ['x'], {}));
  ok !$ok, 'a query on a missing table fails';
  like $error, qr/k79_no_such_table/, '... with the server\'s error';

  my ($again, $again_err) = backend_of_next_call($async);
  is $again, $pid, 'the next call runs on the SAME backend'
    or diag $again_err // 'another backend';
  is $async->pool->size, 1, 'which is still the pool\'s one connection';
  $async->disconnect;
};

subtest 'd) a backend terminated inside a transaction' => sub {
  my $async = connect_async();
  my ($warm, $err) = backend_of_next_call($async);
  ok defined $warm, 'the pooled connection is up' or diag $err;

  my $dead;
  my ($ok, $error) = wait_for($async->txn_do_async(sub {
    my ($ctx) = @_;
    return $ctx->select_async(@PID)->then(sub {
      $dead = $_[0][0];
      terminate($dead) or die "pg_terminate_backend($dead) failed\n";
      return $ctx->select_async(@PID);
    });
  }));
  ok !$ok, 'the transaction fails';
  note "  with: $error";
  ok defined $dead, 'on the pinned connection\'s backend';
  recovers('killed in a transaction', $async, $dead);
  $async->disconnect;
};

$admin->disconnect;
done_testing;
