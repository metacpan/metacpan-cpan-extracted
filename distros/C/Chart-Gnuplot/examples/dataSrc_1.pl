#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

# Input data source
my @x = (-10 .. 10);
my @y = (0 .. 20);

# Chart object
my $chart = Chart::Gnuplot->new(
    output => "gallery/dataSrc_1.png",
);

# Data set object
my $dataSet = Chart::Gnuplot::DataSet->new(
    xdata => \@x,
    ydata => \@y,
);

$chart->plot2d($dataSet);
