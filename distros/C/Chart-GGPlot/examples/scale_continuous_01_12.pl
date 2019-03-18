#!/usr/bin/env perl

use 5.016;
use warnings;

use Getopt::Long;
use Chart::GGPlot qw(:all);
use Chart::GGPlot::Trans::Functions qw(reciprocal_trans);
use Data::Frame::Examples qw(mpg);

my $save_as;
GetOptions( 'o=s' => \$save_as );

my $mpg = mpg();

my $p = ggplot(
    data    => $mpg,
    mapping => aes( x => 'displ', y => 'hwy' )
)->geom_point()
 ->scale_y_continuous(trans => reciprocal_trans());

if ( defined $save_as ) {
    $p->save($save_as);
}
else {
    $p->show();
}

