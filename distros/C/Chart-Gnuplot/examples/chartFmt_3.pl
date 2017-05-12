#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

my $chart = Chart::Gnuplot->new(
    output => 'gallery/chartFmt_3.png',
);

my $data = Chart::Gnuplot::DataSet->new(
    func  => "tanh(x)",
    title => 'legend',     # legend
);

# Plot the graph
$chart->plot2d($data);
