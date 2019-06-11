#!/usr/bin/env perl

# Do not show legend.

use 5.016;
use warnings;

use Getopt::Long;
use Chart::GGPlot qw(:all);
use Data::Frame::Examples qw(mtcars);

my $save_as;
GetOptions( 'o=s' => \$save_as );

my $mtcars = mtcars();

my $p = ggplot(
    data    => $mtcars,
    mapping => aes( x => 'wt', y => 'mpg' )
)->geom_point(
    mapping     => aes( color => 'factor($cyl)' ),
    show_legend => 0
);

if (defined $save_as) {
    $p->save($save_as);
} else {
    $p->show();
}

