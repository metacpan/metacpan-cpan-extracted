#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

# Demonstration of the horizontal line style

# Initiate the chart object
my $chart = Chart::Gnuplot->new(
    output => 'gallery/plotStyle_14.png',
    title  => 'horizontal lines',
);

# Raw data
# - Gaussian dis\tribution
# - uniformly sampled in y-axis
my (@x, @y) = ();
for (my $y = 0.02; $y < 1; $y += 0.02)
{
    my $x = sqrt(-2*log($y));
    push(@x, $x);
    push(@y, $y);
}

# Data set object
my $hlines = Chart::Gnuplot::DataSet->new(
	xdata => \@x,
	ydata => \@y,
	style => "hlines",
);

# Plot the graph
$chart->plot2d($hlines);
