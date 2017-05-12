#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

my $chart = Chart::Gnuplot->new(
    output => "gallery/lineStyle_3.png",
);

my $width = Chart::Gnuplot::DataSet->new(
    func  => "cos(x)",
    style => "lines",
    width => 3,
);

# Plot the graph
$chart->plot2d($width);
