#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

my $chart = Chart::Gnuplot->new(
    output => "gallery/lineStyle_1.png",
);

# The color of line and points are changed together
my $color = Chart::Gnuplot::DataSet->new(
    func  => "cos(x)",
    style => "linespoints",
    color => "violet",  # can be color name or RGB value
);

# Plot the graph
$chart->plot2d($color);
