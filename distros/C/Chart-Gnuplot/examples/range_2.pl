#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

my $chart = Chart::Gnuplot->new(
    output => "gallery/range_2.png",

    xlabel => "Auto lower limit. User-specified upper limit",
    xrange => ["*", "pi"],

    ylabel => "User-specified lower limit. Auto upper limit",
    yrange => [0, "*"],
);

my $dataSet = Chart::Gnuplot::DataSet->new(
    func => "sin(x)",
);

$chart->plot2d($dataSet);
