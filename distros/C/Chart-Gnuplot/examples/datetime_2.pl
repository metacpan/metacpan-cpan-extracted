#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

# Time array
my @x = qw(
    00:00:00
    03:05:24
    06:15:58
    10:03:20
    10:57:00
    11:42:32
    13:30:03
    15:00:30
    17:23:27
    19:38:41
);
my @y = (1 .. 10);

# Create the chart object
my $chart = Chart::Gnuplot->new(
    output   => 'gallery/datetime_2.png',
    xlabel   => 'Time axis',
    timeaxis => "x",            # declare that x-axis uses time format
);

# Data set object
my $data = Chart::Gnuplot::DataSet->new(
    xdata   => \@x,
    ydata   => \@y,
    style   => 'linespoints',
    timefmt => '%H:%M:%S',      # input time format
);

# Plot the graph
$chart->plot2d($data);
