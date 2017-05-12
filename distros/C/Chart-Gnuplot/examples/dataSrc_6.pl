#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

#---------------------------------------------------------
# Demonstrate four types of data input
# - Data set can be input as Perl arrays, file or function
#---------------------------------------------------------

# Initiate the chart object
my $chart = Chart::Gnuplot->new(
    output => 'gallery/dataSrc_6.png',
    title  => 'Different ways to input data set',
);

# Arrays of x-values and y-values
my @x = (-10 .. 10);
my @y = (0 .. 20);
my $data1 = Chart::Gnuplot::DataSet->new(
	xdata => \@x,
	ydata => \@y,
	title => 'Arrays of x-values and y-values',
);

# Data points
my @points = (
    [-7, 7],
    [-6, 6],
    [-5, 5],
    [-4, 4],
    [-3, 3],
    [-2, 4],
    [-1, 5],
    [0, 6],
    [1, 7],
    [2, 8],
);
my $data2 = Chart::Gnuplot::DataSet->new(
    points => \@points,
    title  => 'Array of x-y pairs',
);

# Data file
my $file = Chart::Gnuplot::DataSet->new(
    datafile => 'dataSrc_3.dat',
    title    => 'Text file',
);

# Function: sine function
my $func = Chart::Gnuplot::DataSet->new(
    func  => 'sin(x)',
    title => 'Math expression',
);

# Plot the graph
$chart->plot2d($data1, $data2, $file, $func);
