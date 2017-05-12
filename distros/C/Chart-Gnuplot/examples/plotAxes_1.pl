#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

# Initiate the chart object
my $chart = Chart::Gnuplot->new(
    output  => 'gallery/plotAxes_1.png',
    xrange  => [-1, 1],
    x2range => ['-pi', 'pi'],
    x2tics  => 'on',
    y2tics  => 'on',
);

# Data sets
my $cos = Chart::Gnuplot::DataSet->new(
    func  => "cos(x)",
    style => "lines",
);
my $sin = Chart::Gnuplot::DataSet->new(
    func  => "sin(x)*2",
    style => "lines",
    axes  => 'x2y2',
);

# Plot the graph
$chart->plot2d($cos, $sin);
