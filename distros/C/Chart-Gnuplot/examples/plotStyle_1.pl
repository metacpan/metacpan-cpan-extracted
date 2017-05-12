#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

my $chart = Chart::Gnuplot->new(
    output => "gallery/plotStyle_1.png",
);

# Lines
my $lines = Chart::Gnuplot::DataSet->new(
    func  => "cos(x)",
    style => "lines",
    title => "lines",
);

# Points
my $points = Chart::Gnuplot::DataSet->new(
    func  => "sin(x)",
    style => "points",
    title => "points",
);

# Points on line
my $linespoints = Chart::Gnuplot::DataSet->new(
    func  => "-atan(x)",
    style => "linespoints",
    title => "linespoints",
);

# Plot the graph
$chart->plot2d($lines, $points, $linespoints);
