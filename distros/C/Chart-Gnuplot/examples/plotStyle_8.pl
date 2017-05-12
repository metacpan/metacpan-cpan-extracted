#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

#------------------------------------
# Demonstrate setting error bar styles
#------------------------------------

# Initiate the chart object
my $chart = Chart::Gnuplot->new(
    output => 'gallery/plotStyle_8.png',
    title  => 'Error bar styles',
);

# - Data can be specified by xdata and ydata
# - Data sets with x error bars
my @x = (1, 2, 3, 4, 5, 6);
my @y = (3, 2, 1, 0, -1, -2);
my @err = (0.5, 0.4, 0.3, 0.1, 0.5, 0.2);
my $xerrorbars = Chart::Gnuplot::DataSet->new(
    xdata => [[@x], [@err]],
    ydata => [@y],
    style => 'xerrorbars',
    title => 'xerrorbars',
);

# - Data sets with y error bars
@x = (1, 2, 3, 4, 5, 6);
@y = (5, 4, 3, 2, 1, 0);
@err = (0.5, 0.4, 0.1, 0, 0.3, 0.6);
my $yerrorbars = Chart::Gnuplot::DataSet->new(
    xdata => [@x],
    ydata => [[@y], [@err]],
    style => 'yerrorbars',
    title => 'yerrorbars',
);

# - Alternatively, data can be specified by points
# - Data sets with both x and y error bars
my @pairs = (
    [1, 7, 0.1, 0.5],
    [2, 6, 0.3, 0.4],
    [3, 5, 0.3, 0.1],
    [4, 4, 0.4, 0.1],
    [5, 3, 0.1, 0.3],
    [6, 2, 0.6, 0.6],
);
my $xyerrorbars = Chart::Gnuplot::DataSet->new(
    points => \@pairs,
    style  => 'xyerrorbars',
    title  => 'xyerrorbars',
);

# Plot the graph
$chart->plot2d($xerrorbars, $yerrorbars, $xyerrorbars);
