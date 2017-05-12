#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

# Demonstration of formatting legend
# - composite example

my $chart = Chart::Gnuplot->new(
    output => "gallery/legend_10.png",
    legend => {
        position => "outside center bottom",
        order    => "horizontal reverse",
        align    => 'left',
        border   => 'on',
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
