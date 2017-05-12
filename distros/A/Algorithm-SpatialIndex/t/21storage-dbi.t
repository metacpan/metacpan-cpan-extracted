use strict;
use warnings;
use Test::More;
use Algorithm::SpatialIndex;

my $do_unlink = !$ENV{PERL_ASI_TESTING_PRESERVE};

my $tlibpath;
BEGIN {
  $tlibpath = -d "t" ? "t/lib" : "lib";
}
use lib $tlibpath;

if (not eval {require DBI; require DBD::SQLite; 1;}) {
  plan skip_all => 'These tests require DBI and DBD::SQLite';
}
plan tests => 26;

my $dbfile = '21storage-dbi.test.sqlite';
unlink $dbfile if -f $dbfile;

my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile", "", "");
ok(defined($dbh), 'got dbh');

END {
  unlink $dbfile if $do_unlink;
}

my $index = Algorithm::SpatialIndex->new(
  strategy => 'Test',
  storage  => 'DBI',
  dbh_rw   => $dbh,
);

isa_ok($index, 'Algorithm::SpatialIndex');

my $storage = $index->storage;
isa_ok($storage, 'Algorithm::SpatialIndex::Storage::DBI');

is($storage->get_option('no_of_subnodes'), '4');
$storage->set_option('no_of_subnodes', 5);
is($storage->get_option('no_of_subnodes'), '5');
my $prefix = $storage->table_prefix;
my $res = $storage->dbh_ro->selectall_arrayref(
  qq(SELECT id, value FROM ${prefix}_options WHERE id=?), {}, 'no_of_subnodes'
);
is_deeply($res, [['no_of_subnodes' => '5']], 'set_options writes to db');

ok(!defined($storage->fetch_node(0)), 'No nodes to start with');
ok(!defined($storage->fetch_node(1)), 'No nodes to start with');
$storage->set_option('no_of_subnodes', 4);

$storage->dbh_rw->do(
  qq#INSERT INTO ${prefix}_nodes VALUES (0, 1., 2., 3., 4., 9, NULL, NULL, NULL)#
);

my $n = $storage->fetch_node(0);

isa_ok($n, 'Algorithm::SpatialIndex::Node');
is($n->id, 0, 'node id okay (manual insertion)');
is_deeply($n->coords, [1.,2.,3.,4.], 'node coords okay (manual insertion)');
is_deeply($n->subnode_ids, [9, undef, undef, undef], 'subnode ids okay (manual insertion)');

$n->subnode_ids->[1] = 15;

$storage->store_node($n);

$n = $storage->fetch_node(0);
isa_ok($n, 'Algorithm::SpatialIndex::Node');
is($n->id, 0, 'node id okay (manual insertion)');
is_deeply($n->coords, [1.,2.,3.,4.], 'node coords okay (manual insertion)');
is_deeply($n->subnode_ids, [9, 15, undef, undef], 'subnode ids okay (manual insertion)');

# Test that we are able to get the same node from a separate index object
SCOPE: {
  my $i2 = Algorithm::SpatialIndex->new(
    strategy => 'Test',
    storage  => 'DBI',
    dbh_rw   => $dbh,
  );

  isa_ok($i2, 'Algorithm::SpatialIndex');

  my $s2 = $i2->storage;
  isa_ok($s2, 'Algorithm::SpatialIndex::Storage::DBI');

  my $n = $s2->fetch_node(0);
  isa_ok($n, 'Algorithm::SpatialIndex::Node');
  is($n->id, 0, 'node id okay (manual insertion)');
  is_deeply($n->coords, [1.,2.,3.,4.], 'node coords okay (manual insertion)');
  is_deeply($n->subnode_ids, [9, 15, undef, undef], 'subnode ids okay (manual insertion)');
}

my $node = Algorithm::SpatialIndex::Node->new;
$node->coords([0..3]);
$node->subnode_ids([]);
my $id = $storage->store_node($node);
ok(defined($id), 'New id assigned');
is($node->id, $id, 'New id inserted');

my $fetched = $storage->fetch_node($id);
is_deeply($fetched, $node, 'Node retrievable');

my $bucket = Algorithm::SpatialIndex::Bucket->new(
  node_id => 13,
  items => [
    [1,2,3],
    [2,3,4],
    [4,5,6],
    [1,2,3],
  ],
);
$storage->store_bucket($bucket);
is_deeply($storage->fetch_bucket(13), $bucket, 'bucket can be fetched');

