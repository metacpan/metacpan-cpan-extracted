#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

my $chart = Chart::Gnuplot->new(
    output  => "gallery/axisLabel_3.png",
    ylabel  => {
        text   => "Rotated 80 deg",
        rotate => 80,
    },
);

my $dataSet = Chart::Gnuplot::DataSet->new(
    func => "sin(x)",
);

$chart->plot2d($dataSet);
