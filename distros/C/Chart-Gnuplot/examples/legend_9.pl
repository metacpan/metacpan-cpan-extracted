#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

# Demonstration of formatting legend
# - format the sample lines

my $chart = Chart::Gnuplot->new(
    output => "gallery/legend_9.png",
    title  => "Format the sample lines",
    legend => {
        sample => {
            length   => 10,
            position => 'left',
            spacing  => 2,
        }
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
