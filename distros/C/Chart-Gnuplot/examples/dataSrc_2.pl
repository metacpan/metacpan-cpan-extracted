#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

# Input data source
my @xy = (
    [-2, 5],
    [-1, 3],
    [1, 2],
    [3, 1],
    [5, 0],
    [6, 1],
    [7, 2],
    [9, 3],
    [10, 4],
    [11, 5],
);

# Chart object
my $chart = Chart::Gnuplot->new(
    output => "gallery/dataSrc_2.png",
);

# Data set object
my $dataSet = Chart::Gnuplot::DataSet->new(
    points => \@xy
);

$chart->plot2d($dataSet);
