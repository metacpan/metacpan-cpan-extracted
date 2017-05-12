use strict;
use warnings;
use Test::More tests => 90;
use Algorithm::SpatialIndex;

my $tlibpath;
BEGIN {
  $tlibpath = -d "t" ? "t/lib" : "lib";
}
use lib $tlibpath;

use Algorithm::SpatialIndex::OTreeTest;
Algorithm::SpatialIndex::OTreeTest->run('Memory');
