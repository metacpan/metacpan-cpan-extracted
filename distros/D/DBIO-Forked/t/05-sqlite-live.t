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
my $schema = DBIO::SQLite::Test->init_schema(
  sqlite_use_file => 1,
  no_populate     => 1,
  async           => 'forked',
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

# 6. No zombies left behind.
my $reaped = waitpid(-1, WNOHANG);
ok($reaped == -1 || $reaped == 0, "no unreaped children left (waitpid -> $reaped)");

done_testing;
