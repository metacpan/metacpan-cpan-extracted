#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

# Plot 2D Gaussian distribution in dots

# Construct data points to plot
my $pi = 3.14159;
my @pairs = ();

# Box-Muller transformation
for (my $i = 0; $i < 10000; $i++) {
    my $rand_1 = rand();
    my $rand_2 = rand();

    my $common_1 = sqrt(-2*log($rand_1));
    my $common_2 = 2*$pi*$rand_2;
    my $x = $common_1 * cos($common_2);
    my $y = $common_1 * sin($common_2);
    push(@pairs, [$x, $y]);
}

# Chart object
my $chart = Chart::Gnuplot->new(
    output => "gallery/plotStyle_2.png",
);

# Plot in dots
my $dot = Chart::Gnuplot::DataSet->new(
    points => \@pairs,
    style  => "dots",
);

# Plot the graph
$chart->plot2d($dot);
