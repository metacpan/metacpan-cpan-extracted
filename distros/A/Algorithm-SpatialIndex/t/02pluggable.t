use strict;
use warnings;
use Test::More tests => 13;
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

SCOPE: {
  no warnings 'once';
  ok($Algorithm::SpatialIndex::Strategy::Test::InitCalled, 'strategy init hook called');
  ok($Algorithm::SpatialIndex::Strategy::Test::InitStorageCalled, 'strategy init_storage hook called');
}

my @strategies = $index->strategies;
ok(scalar(@strategies) >= 1, 'Strategy available');
ok(scalar(grep /^Algorithm::SpatialIndex::Strategy::Test$/, @strategies) == 1, 'Test strategy available');

my @storages = $index->storage_backends;
ok(scalar(@storages) >= 1, 'Storage backends available');
ok(scalar(grep /^Algorithm::SpatialIndex::Storage::Memory$/, @storages) == 1, 'Memory storage available');

my $strategy = $index->strategy;
isa_ok($strategy, 'Algorithm::SpatialIndex::Strategy');
isa_ok($strategy, 'Algorithm::SpatialIndex::Strategy::Test');

my $storage = $index->storage;
isa_ok($storage, 'Algorithm::SpatialIndex::Storage');
isa_ok($storage, 'Algorithm::SpatialIndex::Storage::Memory');

is($strategy->no_of_subnodes, 4, 'Test default no of subnodes');
is_deeply([$strategy->coord_types], [qw(double double double double)], 'Test default coord types');
