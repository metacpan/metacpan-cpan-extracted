#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

my $chart = Chart::Gnuplot->new(
    output => "gallery/grid_8.png",
    xtics  => {
        minor => 3,
    },
    grid   => {
        width  => '1, 5',
        color  => 'blue, #228b22',
        xlines => 'on, on',
    },
);

my $dataSet = Chart::Gnuplot::DataSet->new(
    func => "sin(x)",
);

$chart->plot2d($dataSet);
