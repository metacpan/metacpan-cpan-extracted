#! perl

use v5.10;

use Test2::V0;
use Test::Alien;
use Alien::Qhull;
use Path::Tiny;

my $bin_dir = path( Alien::Qhull->bin_dir );

ok( $bin_dir->exists, 'bin_dir exists' )
  or bail_out $@;

for my $bin (qw(  qconvex  qdelaunay  qhalf  qhull  qvoronoi  rbox )) {
    ok( $bin_dir->child($bin)->exists, $bin );

}

done_testing;