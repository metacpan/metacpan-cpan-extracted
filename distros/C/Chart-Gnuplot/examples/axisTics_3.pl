#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

my $chart = Chart::Gnuplot->new(
    output => "gallery/axisTics_3.png",
    xlabel => "Re-label the tics",
    xtics  => {
        labels => ['"pi" 3.1416', '"-pi" -3.1416'],
    },
);

my $dataSet = Chart::Gnuplot::DataSet->new(
    func => "sin(x)",
);

$chart->plot2d($dataSet);
