#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

my $chart = Chart::Gnuplot->new(
    output => "gallery/axisTics_5.png",
    xlabel => "Tic labels in times-italic",
    xtics  => {
        font => "Times-Italic",
    },
);

my $dataSet = Chart::Gnuplot::DataSet->new(
    func => "sin(x)",
);

$chart->plot2d($dataSet);
