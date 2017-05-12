#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

my $chart = Chart::Gnuplot->new(
    output  => "gallery/axisLabel_2.png",
    xlabel  => {
        text   => "Shifted rightwards and downwards",
        offset => "10, -2",
    },
);

my $dataSet = Chart::Gnuplot::DataSet->new(
    func => "sin(x)",
);

$chart->plot2d($dataSet);
