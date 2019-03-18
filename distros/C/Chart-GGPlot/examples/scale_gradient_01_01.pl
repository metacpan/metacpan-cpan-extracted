#!/usr/bin/env perl

use 5.016;
use warnings;

use Getopt::Long;
use Chart::GGPlot qw(:all);
use Data::Frame;
use PDL::Primitive qw(random grandom);

srand(0);

my $save_as;
GetOptions( 'o=s' => \$save_as );

my $df = Data::Frame->new(
    columns => [
        x => random(100),
        y => random(100),
        z1 => grandom(100),
        z2 => grandom(100)->abs,
    ],
);

my $p = ggplot(
    data    => $df,
    mapping => aes( x => 'x', y => 'y' )
)->geom_point( mapping => aes( color => 'z2' ) );

if (defined $save_as) {
    $p->save($save_as);
} else {
    $p->show();
}

