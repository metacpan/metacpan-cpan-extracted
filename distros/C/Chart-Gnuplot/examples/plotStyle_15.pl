#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

# Initiate the chart object
my $chart = Chart::Gnuplot->new(
    output => 'gallery/plotStyle_15.png',
);

# Raw data
my @x = (1, 2, 3, 4, 5, 6);
my @y = (2, 8, 3, 2, 4, 0);

my $points = Chart::Gnuplot::DataSet->new(
    xdata => \@x,
    ydata => \@y,
    style => 'linespoints',
);
my $csplines = Chart::Gnuplot::DataSet->new(
    xdata  => \@x,
    ydata  => \@y,
    style  => 'lines',
    smooth => 'csplines',
    title  => 'Smoothed by cubic splines',
);
my $bezier = Chart::Gnuplot::DataSet->new(
    xdata  => \@x,
    ydata  => \@y,
    style  => 'lines',
    smooth => 'bezier',
    title  => 'Smoothed by a Bezier curve',
);

# Plot the graph
$chart->plot2d($points, $csplines, $bezier);
