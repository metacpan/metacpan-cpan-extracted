#!/usr/bin/env perl

use 5.016;
use warnings;

use Getopt::Long;
use Chart::GGPlot qw(:all);
use Data::Frame;
use PDL::Core qw(pdl);

my $save_as;
GetOptions( 'o=s' => \$save_as );

my $df = Data::Frame->new(
    columns => [
        x => pdl( [ ( 2, 5, 7, 9, 12 ) x 2 ] ),
        y => pdl( [ (1) x 5, (2) x 5 ] ),
        z => factor( [ 1, 1, 2, 2, 3, 3, 4, 4, 5, 5 ] ),
        w => pdl( [ 0, 4, 6, 8, 10, 14 ] )->diff->repeat(2),
    ]
);

my $p = ggplot(
    data    => $df,
    mapping => aes(x => 'x', y => 'y', width => 'w')
)->geom_tile( mapping => aes( fill => 'z' ), color => 'grey50' );

if (defined $save_as) {
    $p->save($save_as);
} else {
    $p->show();
}

