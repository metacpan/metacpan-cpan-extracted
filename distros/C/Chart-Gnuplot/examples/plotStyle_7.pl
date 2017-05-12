#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

my $chart = Chart::Gnuplot->new(
    output => "gallery/plotStyle_7.png",
);

# Filled curves
my $filled_1 = Chart::Gnuplot::DataSet->new(
    func  => "cos(x)",
    style => "filledcurve",
);
my $filled_2 = Chart::Gnuplot::DataSet->new(
    func  => "cos(x) - 2",
    style => "filledcurve x1",
);
my $filled_3 = Chart::Gnuplot::DataSet->new(
    func  => "cos(x) + 2",
    style => "filledcurve x2",
);

# Plot the graph
$chart->plot2d($filled_1, $filled_2, $filled_3);
