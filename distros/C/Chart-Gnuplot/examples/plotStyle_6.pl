#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

my $chart = Chart::Gnuplot->new(
    output => "gallery/plotStyle_6.png",
    title  => "Joining points with steps",
);

# steps and fsteps styles
my @y = (1, 2, 0, 3, 2, -1, 2, 0, 2, 4);
my $line_1 = Chart::Gnuplot::DataSet->new(
    ydata => [@y],
    style => "points",
);
my $steps = Chart::Gnuplot::DataSet->new(
    ydata => [@y],
    style => "steps",
    title => "steps"
);
my $fsteps = Chart::Gnuplot::DataSet->new(
    ydata => [@y],
    style => "fsteps",
    title => "fsteps",
);

# histeps style
@y = (-5, -6, -8, -4, -7, -5, -3, -1, -4);
my $line_2 = Chart::Gnuplot::DataSet->new(
    ydata => [@y],
    style => "points",
);
my $histeps = Chart::Gnuplot::DataSet->new(
    ydata => [@y],
    style => "histeps",
    title => "histeps",
);

# Plot the graph
$chart->plot2d($line_1, $steps, $fsteps, $line_2, $histeps);
