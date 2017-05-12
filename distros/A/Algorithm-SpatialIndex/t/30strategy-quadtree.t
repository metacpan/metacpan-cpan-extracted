use strict;
use warnings;
use Test::More tests => 70;
use Algorithm::SpatialIndex;

my $tlibpath;
BEGIN {
  $tlibpath = -d "t" ? "t/lib" : "lib";
}
use lib $tlibpath;

use Algorithm::SpatialIndex::QTreeTest;
Algorithm::SpatialIndex::QTreeTest->run('Memory');
