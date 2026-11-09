use strict;
use warnings;

use Test::More;
use Time::HiRes ();

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn;

# The standby of the server DBIO_TEST_PG_DSN names. A physical standby has its
# primary's roles, so user and password fall back to the primary's.
my $standby_dsn  = $ENV{DBIO_TEST_PG_STANDBY_DSN};
my $standby_user = $ENV{DBIO_TEST_PG_STANDBY_USER} // $user;
my $standby_pass = $ENV{DBIO_TEST_PG_STANDBY_PASS} // $pass;

use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;

use DBIO::PostgreSQL::Storage;

# A server that is not there fails the file, with a plan.
LiveServer->require_server;

# karr k118 -- is_replicating and lag_behind_master against real servers. The
# reading of the status row is pinned offline in t/88-replication-status.t;
# this file asks whether the statement behind it runs and whether what it says
# about a real primary and a real standby is true.
#
# Two parts:
#
#   1. needs DBIO_TEST_PG_DSN only: a server that is not in recovery.
#   2. needs DBIO_TEST_PG_STANDBY_DSN as well: a streaming hot standby of that
#      server. The last block of it pauses WAL replay on the standby and runs
#      only for a role that may (superuser, or EXECUTE granted on
#      pg_wal_replay_pause() and pg_wal_replay_resume()).
#
# Creates no objects. It commits transactions on the primary that change no
# data (one logical decoding message each, prefix 'dbio-k118', a no-op on
# replay) and, in that last block, pauses replay on the standby for a few
# seconds.

{
  package ReplLive::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');

  # The same without the driver component: the replicated storage takes the
  # schema's place as storage_type, and is told which driver its backends are.
  package ReplLive::Replicated;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Replicated');
}

my $TIMEOUT = 30;   # seconds to wait for the standby to replay a position

# Runs $check every 0.2 s until it returns true or $seconds have passed.
sub wait_for {
  my ($seconds, $check) = @_;
  my $deadline = Time::HiRes::time() + $seconds;
  while (1) {
    my $got = $check->();
    return $got if $got;
    return 0 if Time::HiRes::time() >= $deadline;
    Time::HiRes::sleep(0.2);
  }
}

sub one {
  my ($schema, $sql, @bind) = @_;
  my ($value) = $schema->storage->dbh->selectrow_array($sql, undef, @bind);
  return $value;
}

# Commits a transaction that changes no data and returns a WAL position that
# includes its commit record and that the standby can reach.
#
# The transaction has to WRITE WAL of its own, not just hold an xid: a commit
# is flushed before it returns only when the transaction wrote WAL before its
# commit record (RecordTransactionCommit, xact.c: wrote_xlog && an xid &&
# synchronous_commit > off). An xid alone gets a commit record too, but that
# one is left to the WAL writer whatever synchronous_commit says. A
# transactional pg_logical_emit_message is such a record without any object:
# it takes an xid, is executable by PUBLIC, and is a no-op on replay.
#
# synchronous_commit is set for this transaction, because the role or the
# database may have it off. To "local", not "on": the local flush is all that
# is wanted here, and "on" would also wait for the standbys named in
# synchronous_standby_names -- forever, if one of them is not there.
#
# The position is the flush position: after that commit it is at or past the
# end of the commit record, it is what a WAL sender sends up to, and it is the
# END of a record, as the standby's replay position is. The insert position is
# neither -- it includes WAL nobody has flushed, and it points at where the
# next record will START, which after a record ending on a page boundary is
# behind the next page's header, where replay does not get until another
# record follows.
sub commit_on {
  my $schema = shift;
  $schema->txn_do(sub {
    $schema->storage->dbh->do('SET LOCAL synchronous_commit = local');
    one($schema, q{SELECT pg_catalog.pg_logical_emit_message(true, 'dbio-k118', '')::text});
  });
  return one($schema, 'SELECT pg_catalog.pg_current_wal_flush_lsn()::text');
}

sub replayed {
  my ($schema, $lsn) = @_;
  return wait_for($TIMEOUT, sub {
    one($schema, 'SELECT (pg_catalog.pg_last_wal_replay_lsn() >= ?::pg_lsn)::int', $lsn);
  });
}

# The lag is taken from two readings that move independently, so one sample
# can fall between WAL arriving and WAL being applied. A standby that is
# caught up answers 0 within a few samples; a formula that reports the age of
# the last transaction never does.
sub lag_settles_at_zero {
  my $storage = shift;
  my $lag;
  wait_for(3, sub {
    $lag = $storage->lag_behind_master;
    return defined $lag && $lag == 0;
  });
  return $lag;
}

# A replicated storage with the primary as master and the given replicants,
# validated once. Returns the schema.
sub replicated {
  my ($maximum_lag, @replicants) = @_;

  my $schema = ReplLive::Replicated->connect($dsn, $user, $pass, {
    backend_storage_class => 'DBIO::PostgreSQL::Storage',
    pool_args             => { maximum_lag => $maximum_lag },
  });
  $schema->storage->connect_replicants(@replicants);
  $schema->storage->debugobj->silence(1);
  $schema->storage->pool->validate_replicants;

  return $schema;
}

my $primary = ReplLive::Schema->connect($dsn, $user, $pass);
my $storage = $primary->storage;
$storage->ensure_connected;

isa_ok $storage, 'DBIO::PostgreSQL::Storage', 'the storage under test';

note 'server version: ' . one($primary, 'SHOW server_version');
note 'role may read all statistics (pg_read_all_stats): '
  . (one($primary, q{SELECT pg_catalog.pg_has_role(current_user, 'pg_read_all_stats', 'MEMBER')::int}) ? 'yes' : 'no');

# --- 1. a server that is not in recovery ------------------------------------

SKIP: {
  skip 'DBIO_TEST_PG_DSN names a server in recovery; this part needs a primary', 9
    if one($primary, 'SELECT pg_catalog.pg_is_in_recovery()::int');

  my $row = $storage->_replication_status_row;
  is_deeply [ sort keys %$row ],
    [ qw( in_recovery receiver_pid receiver_status replay_age replay_backlog ) ],
    'the status statement runs and answers its five facts';
  is $row->{in_recovery}, 0, '... not in recovery';
  is $row->{receiver_pid}, undef, '... and no WAL receiver';

  my $answer = $storage->is_replicating;
  ok defined $answer, 'a primary answers is_replicating';
  ok !$answer, '... with no';

  my @lag = $storage->lag_behind_master;
  is scalar(@lag), 0, '... and has no lag to report';

  $primary->txn_do(sub {
    my $in_txn = $storage->is_replicating;
    ok defined $in_txn && !$in_txn, 'the same answer inside a transaction';
  });

  # The primary listed as its own replicant, by mistake or because it is a
  # standby that was promoted: it is taken out, and reads go to the master.
  my $schema = replicated(0, [ $dsn, $user, $pass ]);
  my ($replicant) = $schema->storage->pool->all_replicants;

  ok !$replicant->active,
    'a server that is not in recovery is deactivated as a replicant';
  is $schema->storage->balancer->next_storage_with_fallback, $schema->storage->master,
    '... and reads fall back to the master';
}

# --- 2. a primary and its streaming standby ---------------------------------

my $paused_by_us = 0;

END {
  # Whatever happened above: replay is not left paused.
  if ($paused_by_us) {
    my $resumed = eval {
      my $dbh = LiveServer->dbh_or_die(
        login => [ $standby_dsn, $standby_user, $standby_pass ]);
      $dbh->do('SELECT pg_catalog.pg_wal_replay_resume()');
      $dbh->disconnect;
      1;
    };
    Test::More::diag(
      'WAL replay on the standby is STILL PAUSED and could not be resumed: '
      . 'run SELECT pg_wal_replay_resume() there'
    ) unless $resumed;
  }
}

subtest 'primary and standby' => sub {
  plan skip_all => 'Set DBIO_TEST_PG_STANDBY_DSN (and _USER, _PASS if they differ) '
    . 'to a streaming standby of DBIO_TEST_PG_DSN to run this part'
    unless $standby_dsn;

  plan skip_all => 'DBIO_TEST_PG_DSN names a server in recovery; this part needs the primary there'
    if one($primary, 'SELECT pg_catalog.pg_is_in_recovery()::int');

  my $standby = ReplLive::Schema->connect($standby_dsn, $standby_user, $standby_pass);
  my $replica = $standby->storage;
  $replica->ensure_connected;

  ok one($standby, 'SELECT pg_catalog.pg_is_in_recovery()::int'),
    'DBIO_TEST_PG_STANDBY_DSN names a server in recovery'
    or return;

  my $reads_stats = one($standby,
    q{SELECT pg_catalog.pg_has_role(current_user, 'pg_read_all_stats', 'MEMBER')::int});

  # What the role sees of the WAL receiver, which is_replicating has to cope
  # with either way.
  my $row = $replica->_replication_status_row;
  ok defined $row->{receiver_pid}, 'the standby has a WAL receiver';
  if ($reads_stats) {
    is $row->{receiver_status}, 'streaming', '... which this role sees streaming';
  }
  else {
    is $row->{receiver_status}, undef,
      '... whose state this role, outside pg_read_all_stats, cannot read';
  }

  ok $replica->is_replicating, 'the standby is replicating';

  my $lag = $replica->lag_behind_master;
  ok defined $lag, 'its lag is an answer';
  like $lag, qr/\A[0-9]+\z/, '... a whole, non-negative number of seconds';

  # A commit on the primary, replayed on the standby: caught up.
  my $lsn = commit_on($primary);
  ok replayed($standby, $lsn), "the standby replays a commit of the primary within $TIMEOUT s"
    or do {
      diag 'is DBIO_TEST_PG_STANDBY_DSN a standby of the server DBIO_TEST_PG_DSN names?';
      return;
    };

  is lag_settles_at_zero($replica), 0, 'caught up, the lag is 0';

  # The trap: nothing is written, the last replayed transaction ages, and the
  # standby is missing nothing.
  Time::HiRes::sleep(4);
  my $age = one($standby,
    'SELECT EXTRACT(EPOCH FROM pg_catalog.clock_timestamp() - pg_catalog.pg_last_xact_replay_timestamp())');

  SKIP: {
    skip 'other sessions commit on the primary; the idle case is not what this run saw', 1
      unless defined $age and $age >= 3;

    is lag_settles_at_zero($replica), 0,
      sprintf('... and still 0 with the last replayed transaction %.1f s old', $age);
  }

  # Through the pool: the standby stays, a non-replica goes.
  {
    my $schema = replicated(0,
      [ $standby_dsn, $standby_user, $standby_pass ],
      [ $dsn, $user, $pass ],
    );
    my ($as_standby, $as_primary) = $schema->storage->pool->all_replicants;

    # maximum_lag is 0, so one sample between arrival and replay would
    # deactivate it; validate again before calling that a failure.
    wait_for(3, sub {
      return 1 if $as_standby->active;
      $schema->storage->pool->validate_replicants;
      return $as_standby->active;
    });

    ok  $as_standby->active, 'validate_replicants keeps the streaming standby active';
    ok !$as_primary->active, '... and deactivates the primary listed beside it';
    is $schema->storage->balancer->next_storage_with_fallback, $as_standby,
      '... so reads go to the standby';
  }

  # A standby that really is behind. Needs the right to pause replay.
  SKIP: {
    my $may_pause = one($standby, q{
      SELECT (pg_catalog.has_function_privilege('pg_catalog.pg_wal_replay_pause()', 'EXECUTE')
          AND pg_catalog.has_function_privilege('pg_catalog.pg_wal_replay_resume()', 'EXECUTE'))::int
    });
    skip 'the role may not pause WAL replay on the standby (superuser, or EXECUTE on '
      . 'pg_wal_replay_pause() and pg_wal_replay_resume())', 9
      unless $may_pause;

    skip 'WAL replay on the standby is already paused by somebody else', 9
      if one($standby, 'SELECT pg_catalog.pg_is_wal_replay_paused()::int');

    $paused_by_us = 1;
    one($standby, 'SELECT pg_catalog.pg_wal_replay_pause()');

    my $behind = commit_on($primary);

    # Received, and not replayed: the WAL receiver goes on while replay is
    # paused.
    my $received = wait_for($TIMEOUT, sub {
      one($standby, 'SELECT (pg_catalog.pg_last_wal_receive_lsn() >= ?::pg_lsn)::int', $behind);
    });
    ok $received, 'with replay paused the standby still receives the commit';
    ok one($standby, 'SELECT (pg_catalog.pg_last_wal_replay_lsn() < ?::pg_lsn)::int', $behind),
      '... and does not replay it';

    Time::HiRes::sleep(2);

    ok $replica->is_replicating, '... and is still replicating';

    my $paused_lag = $replica->lag_behind_master;
    cmp_ok $paused_lag, '>=', 1, 'its lag is now more than nothing';

    # now() would stand still here; the lag must not.
    $standby->txn_do(sub {
      my $first = $replica->lag_behind_master;
      Time::HiRes::sleep(2.5);
      cmp_ok $replica->lag_behind_master, '>', $first,
        '... and keeps growing inside one transaction';
    });

    my $schema = replicated(0, [ $standby_dsn, $standby_user, $standby_pass ]);
    my ($lagging) = $schema->storage->pool->all_replicants;
    ok !$lagging->active, 'validate_replicants deactivates the standby that is behind';

    one($standby, 'SELECT pg_catalog.pg_wal_replay_resume()');
    $paused_by_us = 0;

    ok replayed($standby, $behind), 'resumed, the standby replays what it had received';
    is lag_settles_at_zero($replica), 0, '... and its lag is 0 again';

    wait_for(3, sub {
      $schema->storage->pool->validate_replicants;
      return $lagging->active;
    });
    ok $lagging->active, '... and the pool takes it back';
  }
};

done_testing;
