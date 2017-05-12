#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

# Demonstration of the horizontal bar style

# Initiate the chart object
my $chart = Chart::Gnuplot->new(
    output => 'gallery/plotStyle_13.png',
    title  => 'horizontal bars'
);

# Raw data
# - Gaussian distribution
my (@x, @y) = ();
for (my $x = 0; $x < 5; $x += 0.1)
{
    my $y = exp(-$x*$x/2);
    push(@x, $x);
    push(@y, $y);
}

# Data set object
my $hbars = Chart::Gnuplot::DataSet->new(
	xdata => \@x,
	ydata => \@y,
	style => "hbars",
);

# Plot the graph
$chart->plot2d($hbars);
