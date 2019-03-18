#!/usr/bin/env perl

use 5.016;
use warnings;

use Getopt::Long;
use Chart::GGPlot qw(:all);
use Data::Frame::Examples qw(diamonds);

srand(0);

my $save_as;
GetOptions( 'o=s' => \$save_as );

my $dsamp = diamonds()->sample(1000);

my $p = ggplot(
    data    => $dsamp,
    mapping => aes( x => 'carat', y => 'price', color => 'clarity' )
)->geom_point( alpha => 0.2 );

if (defined $save_as) {
    $p->save($save_as);
} else {
    $p->show();
}

