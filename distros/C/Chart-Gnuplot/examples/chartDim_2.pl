#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

my $chart = Chart::Gnuplot->new(
    output    => "gallery/chartDim_2.png",
    title     => "20% shorter in length, 50% shorter in height",
    imagesize => "0.8, 0.5",
);

my $dataSet = Chart::Gnuplot::DataSet->new(
    func => "sin(x)",
);

$chart->plot2d($dataSet);
