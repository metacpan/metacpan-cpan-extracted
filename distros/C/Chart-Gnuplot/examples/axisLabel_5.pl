#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

my $chart = Chart::Gnuplot->new(
    output  => "gallery/axisLabel_5.png",
    ylabel  => {
        text => "Arial 20 axis label",
        font => "arial, 20",
    },
);

my $dataSet = Chart::Gnuplot::DataSet->new(
    func => "sin(x)",
);

$chart->plot2d($dataSet);
