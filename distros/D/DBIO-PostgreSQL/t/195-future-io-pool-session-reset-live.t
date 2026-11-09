use strict;
use warnings;
use Test::More;
use Time::HiRes ();

# LIVE test: the session of a pooled future_io connection is the borrow's own
# (karr k154, core k398, ADR 0079).
#
# CLAIM: when a borrow ends, the transport resets the connection with DISCARD ALL
# and replays the connect actions before anyone else gets it. What one borrow
# set in the server session -- a session setting (set_config with is_local
# false, SET search_path), a temporary table, a prepared statement, a session
# advisory lock -- is gone in the next borrow, which runs on the SAME backend
# (pool of one) with the session its connect gave it: on_connect_do in effect.
#
# Gated like the other live tests: DBIO_TEST_PG_DSN, _USER and _PASS.

use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;

my ($dsn, $user, $pass) = LiveServer->login;

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn;

BEGIN {
  eval {
    require IO::Async::Loop;
    require Future::IO::Impl::IOAsync;
    Future::IO::Impl::IOAsync->import;
    require DBIO::PostgreSQL::Storage::Async;
    1;
  } or plan skip_all => 'IO::Async, Future::IO::Impl::IOAsync and DBIO::Async required for the live future_io test';
}

use DBIO::Test;

DBIO::Test::Schema->storage_type('+DBIO::PostgreSQL::Storage');

LiveServer->require_server;

my $loop  = IO::Async::Loop->new;
my $admin = LiveServer->control_dbh;

my $schema = DBIO::Test::Schema->connect($dsn, $user, $pass, {
  async         => 'future_io',
  pool_size     => 1,
  on_connect_do => [ q{SET application_name = 'dbio_k154'} ],
});
my $async = $schema->storage->async;

# Wait for $f, 10 seconds at most: its result, or dies with its failure.
sub wait_for {
  my ($f) = @_;
  my $deadline = Time::HiRes::time() + 10;
  until ($f->is_ready) {
    die "still pending after 10s\n" if Time::HiRes::time() > $deadline;
    $loop->loop_once(0.05);
  }
  return $f->get;
}

# One borrow: a transaction whose pinned connection runs @sql in order; the
# rows of the last statement come back.
sub borrow {
  my (@sql) = @_;
  my $rows;
  wait_for($async->txn_do_async(sub {
    my ($txn) = @_;
    my $f = $async->future_class->done;
    for my $sql (@sql) {
      $f = $f->then(sub {
        $async->_query_async_pinned($txn->txn_conn, $sql, [])
          ->then(sub { $rows = [ @_ ]; $async->future_class->done });
      });
    }
    return $f;
  }));
  return $rows;
}

my $LOCK = 154_154;

# What a borrow asks of its session: setting, search_path, application_name (a
# connect action), temp table, prepared statement, the advisory lock held, pid.
my $probe = q{SELECT
    coalesce(current_setting('dbio.k154', true), ''),
    current_setting('search_path'),
    current_setting('application_name'),
    to_regclass('pg_temp.k154_tmp') IS NOT NULL,
    (SELECT count(*) FROM pg_prepared_statements WHERE name = 'k154_stmt'),
    (SELECT count(*) FROM pg_locks WHERE locktype = 'advisory' AND pid = pg_backend_pid() AND objid = } . $LOCK . q{),
    pg_backend_pid()};

my $fresh = borrow($probe)->[0];
my $pid   = $fresh->[6];
is $fresh->[2], 'dbio_k154', 'the connect action is in effect on a fresh connection';

borrow(
  q{SELECT set_config('dbio.k154', 'tenant-a', false)},
  q{SET search_path = pg_catalog},
  q{CREATE TEMPORARY TABLE k154_tmp (a integer)},
  q{PREPARE k154_stmt AS SELECT 1},
  q{SELECT pg_advisory_lock(} . $LOCK . q{)},
  q{SET application_name = 'someone_else'},
);

# The reset runs on the loop after the borrow's Future is done; the connection
# is idle again once it has finished.
{
  my $deadline = Time::HiRes::time() + 10;
  $loop->loop_once(0.05) until $async->pool->available || Time::HiRes::time() > $deadline;
  ok $async->pool->available, 'the connection is idle again, its reset done';
}

my ($held) = $admin->selectrow_array(
  q{SELECT count(*) FROM pg_locks WHERE locktype = 'advisory' AND pid = ? AND objid = ?},
  undef, $pid, $LOCK);
is $held, 0, 'the session advisory lock of the ended borrow is released';

my $next = borrow($probe)->[0];
is $next->[6], $pid, 'the next borrow runs on the SAME backend';
is $next->[0], '',            'set_config(..., false): current_setting is empty';
is $next->[1], $fresh->[1],   'search_path is the one the connect gave';
is $next->[2], 'dbio_k154',   'on_connect_do is in effect again';
ok !$next->[3],               'the temporary table is gone';
is $next->[4], 0,             'the prepared statement is gone';
is $next->[5], 0,             'the session advisory lock is not held';

$schema->storage->disconnect;
done_testing;
