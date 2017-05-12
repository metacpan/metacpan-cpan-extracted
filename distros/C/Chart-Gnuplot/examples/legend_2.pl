#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

# Demonstration of formatting legend
# - position of the legend

my $chart = Chart::Gnuplot->new(
    output => "gallery/legend_2.png",
    legend => {
        position => 'left',
    },
);

# Lines
my $lines = Chart::Gnuplot::DataSet->new(
    func  => "cos(x)",
    title => "cosine",
);

# Points
my $points = Chart::Gnuplot::DataSet->new(
    func  => "sin(x)",
    title => "sine",
);

# Points on line
my $linespoints = Chart::Gnuplot::DataSet->new(
    func  => "x**2",
    title => "quadratic",
);

# Plot the graph
$chart->plot2d($lines, $points, $linespoints);
