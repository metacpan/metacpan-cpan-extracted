#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

my $chart = Chart::Gnuplot->new(
    output => "gallery/plotStyle_5.png",
);

# Boxes
my $boxes = Chart::Gnuplot::DataSet->new(
    func  => "cos(x)",
    style => "boxes",
    fill  => {
        density => 0.2,
        border  => 'off',
    },
);

# Plot the graph
$chart->plot2d($boxes);
