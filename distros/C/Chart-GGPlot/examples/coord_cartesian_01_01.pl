#!/usr/bin/env perl

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
    mapping => aes( x => 'disp', y => 'wt' )
)->geom_point()    # TODO: ->geom_smooth()
 ->coord_cartesian( xlim => [ 325, 500 ] );

if (defined $save_as) {
    $p->save($save_as);
} else {
    $p->show();
}

