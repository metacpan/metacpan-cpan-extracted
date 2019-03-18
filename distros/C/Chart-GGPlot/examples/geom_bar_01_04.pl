#!/usr/bin/env perl

use 5.016;
use warnings;

use Getopt::Long;
use Chart::GGPlot qw(:all);
use Data::Frame::Examples qw(mpg);

my $save_as;
GetOptions( 'o=s' => \$save_as );

my $mpg = mpg();

my $p = ggplot(
    data    => $mpg,
    mapping => aes( x => 'class' )
)->geom_bar( mapping => aes( fill => 'drv' ), position => 'dodge' );

if (defined $save_as) {
    $p->save($save_as);
} else {
    $p->show();
}

