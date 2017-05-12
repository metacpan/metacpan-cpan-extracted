#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

my $chart = Chart::Gnuplot->new(
    output => "gallery/lineStyle_5.png",
);

my $width = Chart::Gnuplot::DataSet->new(
    func      => "cos(x)",
    style     => "points",
    pointsize => 3,
);

# Plot the graph
$chart->plot2d($width);
