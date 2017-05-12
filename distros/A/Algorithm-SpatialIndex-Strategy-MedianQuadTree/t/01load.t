use strict;
use warnings;
use Test::More;

my @modules = (
  map { "Algorithm::SpatialIndex::" . $_ }
  qw(
    Strategy::MedianQuadTree
  )
);
plan tests => scalar(@modules);

use_ok($_) for @modules;


