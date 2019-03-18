#!/usr/bin/env perl

# This example defaultly uses ggplot's "scattergl" trace. Generally to
#  force using "scatter" trace you can use below variable,
#
#   use Chart::GGPlot::Backend::Plotly;
#   $Chart::GGPlot::Backend::Plotly::WEBGL_THRESHOLD = -1;
#
# But for this example I believe it will take forever to render without
#  webgl support. 
#
# As a side note, on my Virtualbox Ubuntu 18.04 guest firefox does not work
#  while chromimum works, so I would need to set below env var to test this
#  example.
# 
#   BROWSER=chromium-browser


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
    mapping => aes( x => 'carat', y => 'price' )
)->geom_point( alpha => 0.1 );

if (defined $save_as) {
    $p->save($save_as);
} else {
    $p->show();
}

