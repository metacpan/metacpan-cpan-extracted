#!/usr/bin/env perl

use 5.016;
use warnings;

use Getopt::Long;
use Chart::GGPlot qw(:all);
use Data::Frame::Examples qw(mtcars);

my $save_as;
GetOptions( 'o=s' => \$save_as );

my $p = ggplot(
    data    => mtcars(),
    mapping => aes( x => 'factor($cyl)', fill => 'factor($vs)' )
)->geom_bar();

if (defined $save_as) {
    $p->save($save_as);
} else {
    $p->show();
}

