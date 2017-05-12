#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

my $chart = Chart::Gnuplot->new(
    output => "gallery/background_1.png",
    title  => "Filling background color in the chart",
    bg     => {
        color   => "#c9c9ff",
        density => 0.2,
    },
);

my $dataSet = Chart::Gnuplot::DataSet->new(
    func => "sin(x)",
);

$chart->plot2d($dataSet);
