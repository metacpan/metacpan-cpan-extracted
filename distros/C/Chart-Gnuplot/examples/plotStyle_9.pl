#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

#------------------------------------
# Demonstrate setting error line styles
#------------------------------------

# Initiate the chart object
my $chart = Chart::Gnuplot->new(
    output => 'gallery/plotStyle_9.png',
);

# - Data can be specified by xdata and ydata, or points
# - Styles include xerrorlines, yerrorlines and xyerrorlines
my @x = (1, 2, 3, 4, 5, 6);
my @y = (-2, -1, 0, 1, 2, 3);
my @err = (0.5, 0.4, 0.3, 0.1, 0.5, 0.2);
my $xerrorlines = Chart::Gnuplot::DataSet->new(
    xdata => [\@x, \@err],
    ydata => \@y,
    style => 'xerrorlines',
);

# Plot the graph
$chart->plot2d($xerrorlines);
