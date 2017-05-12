#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

my $chart = Chart::Gnuplot->new(
    output => "gallery/plot3d_3.png",
    title  => "3D plot from data file",
);


my $dataSet = Chart::Gnuplot::DataSet->new(
    datafile => "plot3d_3.dat",
);

$chart->plot3d($dataSet);
