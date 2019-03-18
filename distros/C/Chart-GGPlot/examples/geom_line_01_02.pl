#!/usr/bin/env perl

use 5.016;
use warnings;

use Getopt::Long;
use Chart::GGPlot qw(:all);
use Data::Frame::Examples qw(economics);

my $save_as;
GetOptions( 'o=s' => \$save_as );

my $p = ggplot(
    data    => economics(),
    mapping => aes( x => 'date', y => 'unemploy' )
)->geom_line(color => 'red');

if (defined $save_as) {
    $p->save($save_as);
} else {
    $p->show();
}

