#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

# Chart object
my $chart = Chart::Gnuplot->new(
    output => "gallery/dataSrc_4.png",
);

# Data set object
my $dataSet = Chart::Gnuplot::DataSet->new(
    func => "sin(x)"
);

$chart->plot2d($dataSet);
