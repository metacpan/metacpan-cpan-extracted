#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

my $chart = Chart::Gnuplot->new(
    output => "gallery/lineStyle_4.png",
);

my $type = Chart::Gnuplot::DataSet->new(
    func      => "cos(x)",
    style     => "points",
    pointtype => "fill-circle",
);

# Plot the graph
$chart->plot2d($type);
