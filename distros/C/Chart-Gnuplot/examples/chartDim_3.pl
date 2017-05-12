#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

my $chart = Chart::Gnuplot->new(
    output  => "gallery/chartDim_3.png",
    title   => "Margin",
    bmargin => 10,  # bottom margin: 10 characters height
    rmargin => 20,  # right margin: 20 characters width
);

my $dataSet = Chart::Gnuplot::DataSet->new(
    func => "sin(x)",
);

$chart->plot2d($dataSet);
