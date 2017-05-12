#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

my $chart = Chart::Gnuplot->new(
    output => "gallery/plotStyle_3.png",
);

# Impulses
my $impulses = Chart::Gnuplot::DataSet->new(
    func  => "cos(x)",
    style => "impulses",
);

# Plot the graph
$chart->plot2d($impulses);
