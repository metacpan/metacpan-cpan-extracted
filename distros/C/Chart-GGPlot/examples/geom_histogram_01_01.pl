#!/usr/bin/env perl

use 5.016;
use warnings;

use Getopt::Long;
use Chart::GGPlot qw(:all);
use Data::Frame::Examples qw(diamonds);

my $save_as;
GetOptions( 'o=s' => \$save_as );

my $diamonds = diamonds();

my $p = ggplot(
    data    => $diamonds,
    mapping => aes( x => 'carat' )
)->geom_histogram();

if (defined $save_as) {
    $p->save($save_as);
} else {
    $p->show();
}

