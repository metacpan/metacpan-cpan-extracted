#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

# Date array
my @x = qw(
    2007-01-01
    2007-01-10
    2007-01-24
    2007-02-01
    2007-02-14
    2007-02-28
    2007-03-05
    2007-03-13
    2007-03-21
    2007-03-31
);
my @y = (1 .. 10);

# Create the chart object
my $chart = Chart::Gnuplot->new(
    output   => 'gallery/datetime_1.png',
    xlabel   => 'Date axis',
    timeaxis => "x",            # declare that x-axis uses time format
);

# Data set object
my $data = Chart::Gnuplot::DataSet->new(
    xdata   => \@x,
    ydata   => \@y,
    style   => 'linespoints',
    timefmt => '%Y-%m-%d',      # input time format
);

# Plot the graph
$chart->plot2d($data);
