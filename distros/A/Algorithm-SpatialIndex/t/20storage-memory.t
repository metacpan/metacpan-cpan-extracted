use strict;
use warnings;
use Test::More tests => 9;
use Algorithm::SpatialIndex;

my $tlibpath;
BEGIN {
  $tlibpath = -d "t" ? "t/lib" : "lib";
}
use lib $tlibpath;

my $index = Algorithm::SpatialIndex->new(
  strategy => 'Test',
  storage  => 'Memory',
);

isa_ok($index, 'Algorithm::SpatialIndex');

my $storage = $index->storage;
isa_ok($storage, 'Algorithm::SpatialIndex::Storage::Memory');

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

