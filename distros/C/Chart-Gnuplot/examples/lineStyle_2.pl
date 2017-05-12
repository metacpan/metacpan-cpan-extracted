#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

my $chart = Chart::Gnuplot->new(
    output => "gallery/lineStyle_2.png",
);

my $type = Chart::Gnuplot::DataSet->new(
    func     => "cos(x)",
    style    => "lines",
    linetype => "2dash",
);

# Plot the graph
$chart->plot2d($type);
