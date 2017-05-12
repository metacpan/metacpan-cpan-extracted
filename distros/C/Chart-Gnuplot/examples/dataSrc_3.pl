#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

# Chart object
my $chart = Chart::Gnuplot->new(
    output => "gallery/dataSrc_3.png",
);

# Data set object
my $dataSet = Chart::Gnuplot::DataSet->new(
    datafile => "dataSrc_3.dat"
);

$chart->plot2d($dataSet);
