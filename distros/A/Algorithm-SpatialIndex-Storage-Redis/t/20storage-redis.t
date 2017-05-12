use strict;
use warnings;
use Test::More;
use Algorithm::SpatialIndex;

my $tlibpath;
BEGIN {
  $tlibpath = -d "t" ? "t/lib" : "lib";
}
use lib $tlibpath;
use Algorithm::SpatialIndex::Test;
my $config = test_redis_config();
if (!$config) {
  plan skip_all => 'No test config for Redis found';
  exit(0);
}
else {
  plan tests => 9;
}

my $storage;
END {
  $storage->remove_all() if defined $storage;
}
$SIG{INT} = sub {
  $storage->remove_all() if defined $storage;
};

my $index = Algorithm::SpatialIndex->new(
  strategy => 'Test',
  storage  => 'Redis',
  redis => $config,
);

isa_ok($index, 'Algorithm::SpatialIndex');

$storage = $index->storage;
isa_ok($storage, 'Algorithm::SpatialIndex::Storage::Redis');

ok(!defined($storage->fetch_node(0)), 'No nodes to start with');
ok(!defined($storage->fetch_node(1)), 'No nodes to start with');

my $node = Algorithm::SpatialIndex::Node->new;
my $id = $storage->store_node($node);
ok(defined($id), 'New id assigned');
is($node->id, $id, 'New id inserted');

my $fetched = $storage->fetch_node($id);
is_deeply($fetched, $node, 'Node retrievable');

$storage->set_option('foo', 'bar');
is($storage->get_option('foo'), 'bar', 'get/set option works');
is($storage->get_option('foo2'), undef, 'get/set option works for nonexistent keys');

$storage->remove_all;

