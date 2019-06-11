#!/usr/bin/env perl

use 5.016;
use warnings;

use Getopt::Long;
use Chart::GGPlot qw(:all);
use Data::Frame;
use PDL::Core qw(pdl);
use PDL::Primitive qw(random);

srand(0);

my $save_as;
GetOptions( 'o=s' => \$save_as );

my $df = Data::Frame->new(
    columns => [
        x => pdl( [ ( 0 .. 5 ) x 6 ] ),
        y => pdl( [ map { ($_) x 6 } (0 .. 5) ] ),
        # bottom-left should be the darkest, top-right the lightest
        z => random(36)->qsort,
    ]
);

my $p = ggplot(
    data    => $df,
    mapping => aes( x => 'x', y => 'y', fill => 'z' )
)->geom_raster();

if (defined $save_as) {
    $p->save($save_as);
} else {
    $p->show();
}

