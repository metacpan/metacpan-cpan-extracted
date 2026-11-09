use strict;
use warnings;
use Test::More;
use POSIX qw(WNOHANG);

# Skip the entire file if live deps are absent.
# This preserves the dep-free default-suite posture (ADR 0001): installing only
# dbio-forked + DBIO core must give a fully green prove run without DBD::SQLite
# or dbio-sqlite on the system.
BEGIN {
  for my $mod (qw(DBD::SQLite DBIO::SQLite::Test DBIO::SQLite::Storage)) {
    eval "require $mod; 1"
      or plan skip_all => "$mod not installed -- skipping SQLite live tests";
  }
}

use DBIO::SQLite::Test;

# Loading DBIO::Forked registers the generic 'forked' async mode on the core
# base storage class (ADR 0030), so any driver connection can opt into it with
# { async => 'forked' }.
use DBIO::Forked;
use DBIO::Forked::Future;
use DBIO::AccessBroker::Static;
use DBIO::Storage::Async;

# A real FILE-backed SQLite db (sqlite_use_file => 1, NOT :memory:): the forked
# child reconnects in its own process and must see the same database the parent
# deployed.  _database() sets AutoCommit => 1 with a fixed file path, so the DDL
# is committed and the child (reconnecting via the inherited connect_info) sees
# the tables.
#
# The connection opts into the forked async mode at connect time (ADR 0030):
# init_schema threads the extra { async => 'forked' } attribute into the DBI
# connect_info, which the core resolver extracts as the per-connection async
# mode.  A connection without it would be sync and every *_async would croak.
#
# on_connect_do is threaded into the same connect_info (it replaces the
# DBIO::SQLite::Test default, so the default's PRAGMA is kept here).  It stamps
# the CONNECTING process's pid into a SQLite TEMPORARY table -- a temp table
# lives and dies with one connection, so whoever can read it is on the
# connection that ran the action.  Section 6 uses that to prove the child's own
# reconnect re-runs the connection actions (ADR 0002 addendum).
#
# A schema always declares its driver (core ADR 0067): the shared test schema
# keeps none in its class, so this use declares SQLite through storage_type.
my $schema = DBIO::SQLite::Test->init_schema(
  storage_type    => 'DBIO::SQLite::Storage',
  sqlite_use_file => 1,
  no_populate     => 1,
  async           => 'forked',
  on_connect_do   => sub {
    my $storage = shift;
    my $dbh = $storage->_get_dbh;
    $dbh->do('PRAGMA synchronous = OFF');
    $dbh->do('CREATE TEMPORARY TABLE IF NOT EXISTS connect_marker (pid INTEGER)');
    $dbh->do('DELETE FROM connect_marker');
    $dbh->do('INSERT INTO connect_marker (pid) VALUES (?)', undef, $$);
  },
);

# 1. The connection resolved the 'forked' mode and its embedded backend is the
#    fork-based storage.
is($schema->storage->_async_mode, 'forked',
  "connection chose the 'forked' async mode");
isa_ok($schema->storage->async, 'DBIO::Forked::Storage',
  "{ async => 'forked' } resolves the embedded backend to DBIO::Forked::Storage");

# 2. txn_do_async forks: the body runs in a child process, writes, COMMITs.
my $parent = $$;
my $f = $schema->storage->txn_do_async(sub {
  $schema->resultset('Artist')->create({ name => 'forked-write' });
  return $$;            # the child's pid (serializable)
});
isa_ok($f, 'DBIO::Forked::Future', 'txn_do_async returns a Forked::Future');

my $child = $f->get;
isnt($child, $parent, "txn body ran in a forked child (child pid $child != parent $parent)");

# 3. File-DB sharing: the child's committed insert is visible from the parent.
is(
  $schema->resultset('Artist')->search({ name => 'forked-write' })->count, 1,
  'child-committed row is visible in the parent -- real fork + shared file DB',
);

# 4. Parallel forks collected via needs_all (the Phase-5 future surface).
#    Reads, so no SQLite write-lock contention; proves N concurrent children.
my @futs = map {
  $schema->storage->txn_do_async(sub {
    return { pid => $$, count => $schema->resultset('Artist')->count };
  });
} 1 .. 3;

my @res = DBIO::Forked::Future->needs_all(@futs)->get;
is(scalar @res, 3, 'needs_all collected 3 parallel forked reads');

my %pids = map { $_->{pid} => 1 } @res;
ok(!$pids{$parent}, 'every parallel read ran in a child, none in the parent');
is($_->{count}, 1, 'each child saw the committed row over the shared file DB') for @res;

# 5. Core ResultSet/Row *_async run REALLY async over the forked backend (ADR
#    0031). These are the core's RS/Row helpers -- all_async / count_async /
#    create_async -- routed through DBIO::Forked::Storage, NOT bespoke calls on
#    the backend.  They prove the two ADR-0031 contracts end-to-end over fork:
#      * select_async resolves to raw rows that the core collapse/inflate path
#        turns into real Row objects (and DBIO::Forked::Future->then auto-wraps
#        the plain rows the inflater returns);
#      * insert_async resolves to a returned-columns HASHREF that
#        Row::insert_async folds back into the object (autoinc PK populated).

# all_async: real SELECT in a child, raw rows inflated into Row objects.
{
  my @artists = $schema->resultset('Artist')->all_async->get;
  is(scalar @artists, 1, 'all_async->get returned the one committed Artist');
  isa_ok($artists[0], 'DBIO::Row', 'all_async yields an inflated result object');
  is($artists[0]->name, 'forked-write',
    'inflated Row carries the correct column value over the forked backend');
  ok(defined $artists[0]->artistid,
    'inflated Row has its autoinc PK populated from the real SELECT');
}

# count_async: COUNT(*) via select_single_async over the fork.
is($schema->resultset('Artist')->count_async->get, 1,
  'count_async->get returns the correct count over the forked backend');

# create_async: Row::insert_async over the fork. The sync insert runs in the
# child and returns the returned-columns hashref; the parent folds it back so
# the returned Row is in_storage with its autoinc PK filled (ADR-0031 contract).
{
  my $created = $schema->resultset('Artist')->create_async({ name => 'forked-created' })->get;
  isa_ok($created, 'DBIO::Row', 'create_async->get yields a Row object');
  ok($created->in_storage, 'created Row is marked in_storage');
  ok(defined $created->artistid,
    'created Row has its autoinc PK folded back from the insert_async hashref');
  is($created->name, 'forked-created', 'created Row carries the inserted value');
}

# The create is durable + visible: count is now 2, both names present.
is($schema->resultset('Artist')->count_async->get, 2,
  'count_async reflects the create_async insert (now 2 rows)');
is_deeply(
  [ sort map { $_->name } $schema->resultset('Artist')->all_async->get ],
  [ 'forked-created', 'forked-write' ],
  'all_async sees both the txn-written and the create_async-written rows',
);

# 6. Connection actions re-run in the child (ADR 0002 addendum).
#    Nothing in DBIO::Forked implements this: the child's first DB op goes
#    through the inherited sync storage, whose _verify_pid sees the new PID and
#    makes _get_dbh reconnect; that reconnect is the ordinary _connect, which
#    calls _run_connection_actions -> on_connect_call + on_connect_do.
#    The marker table is connection-scoped, so finding the CHILD's own pid in it
#    proves both halves: the child is on a fresh connection of its own (not the
#    parent's handle), and the connect actions ran on that connection.
#
#    Explicitly NOT the on_connect_replay transport capability -- that name is
#    for pool transports opening connections outside the sync connect path
#    (core karr k68), and DBIO::Forked::Storage advertises no capability an
#    async layer could require (its one, broker_connect_options, is read by
#    core -- section 7).
{
  my ($parent_marker) = $schema->storage->_get_dbh
    ->selectrow_array('SELECT pid FROM connect_marker');
  is($parent_marker, $parent, 'parent connection ran its own connect actions');

  my $seen = $schema->storage->txn_do_async(sub {
    my ($pid) = $schema->storage->_get_dbh
      ->selectrow_array('SELECT pid FROM connect_marker');
    return { child => $$, marker => $pid };
  })->get;

  isnt($seen->{child}, $parent, 'connect-action probe ran in a forked child');
  is($seen->{marker}, $seen->{child},
    'child re-ran on_connect_do on its own fresh connection (pid stamped in the child)');
}

# 7. Connect options beside an AccessBroker reach the child's connection
#    (karr k12, core k243) -- here on a real DBD handle; what the owner storage
#    hands to DBI->connect in the child is t/06's subject, without any DBD.
#    A second connection to the same database file, its details answered by a
#    broker (a dbname that is a whole DSN is taken as the DSN; the clone keeps
#    the SQLite driver the schema declared above), with DBD attributes and
#    pool_size beside it. Core refuses that at first async use unless the
#    transport declares broker_connect_options; DBIO::Forked::Storage does, and
#    keeps the promise without code: the child's connection is the owner
#    storage's own, reconnected through the broker with the options joined in.
#    LongReadLen is the probe -- DBI's default is 80, so only the options can
#    have put 4096 on the child's handle.
SKIP: {
  skip 'the installed DBIO core predates connect options beside an AccessBroker (core k243)', 6
    unless DBIO::Storage::Async->can('_takes_broker_connect_options');

  my $broker = DBIO::AccessBroker::Static->new(
    dbname => $schema->storage->_dbi_connect_info->[0],
  );
  my $brokered = $schema->connect($broker, {
    async       => 'forked',
    pool_size   => 2,
    AutoCommit  => 1,
    LongReadLen => 4096,
  });

  my $seen = eval {
    $brokered->storage->txn_do_async(sub {
      my $storage = $brokered->storage;
      return {
        pid         => $$,
        LongReadLen => $storage->_get_dbh->{LongReadLen},
        autocommit  => $storage->_dbh_autocommit,   # the handle's, as connected
        attrs       => $storage->_dbi_connect_info->[3],
        count       => $brokered->resultset('Artist')->count,
      };
    })->get;
  };
  is($@, '', 'DBD attributes and pool_size beside a broker: the forked mode is not refused');

  skip 'no child to look at', 5 unless $seen;

  isnt($seen->{pid}, $parent, 'the broker-backed transaction ran in a forked child');
  is($seen->{LongReadLen}, 4096,
    "the child's own DBD handle carries the attribute given beside the broker");
  ok($seen->{autocommit}, '... and was opened with AutoCommit on');
  ok(!exists $seen->{attrs}{pool_size},
    'pool_size was not among the attributes of the child\'s DBI->connect');
  is($seen->{count}, 2,
    'the child reached the database the broker answered (both committed rows)');
}

# 8. No zombies left behind.
my $reaped = waitpid(-1, WNOHANG);
ok($reaped == -1 || $reaped == 0, "no unreaped children left (waitpid -> $reaped)");

done_testing;
