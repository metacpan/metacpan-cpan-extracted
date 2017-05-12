#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

my $chart = Chart::Gnuplot->new(
    output => "gallery/plotStyle_4.png",
);

# Boxes
my $boxes = Chart::Gnuplot::DataSet->new(
    func  => "cos(x)",
    style => "boxes",
);

# Plot the graph
$chart->plot2d($boxes);
