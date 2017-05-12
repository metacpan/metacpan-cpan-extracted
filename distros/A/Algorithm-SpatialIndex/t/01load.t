use strict;
use warnings;
use Test::More;

my @modules = (
  'Algorithm::SpatialIndex',
  map { "Algorithm::SpatialIndex::" . $_ }
  qw(
    Node
    Bucket
    Strategy
    Storage
    Storage::Memory
    Storage::DBI
    Strategy::2D
    Strategy::3D
    Strategy::QuadTree
    Strategy::OctTree
  )
);
plan tests => scalar(@modules);

use_ok($_) for @modules;


