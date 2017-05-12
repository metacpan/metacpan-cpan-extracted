#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

my $chart = Chart::Gnuplot->new(
    output => "gallery/plot3d_4.png",
    title  => "3D plot from function",
);


my $dataSet = Chart::Gnuplot::DataSet->new(
    func => "exp(-(x**2 + y**2)/5)",
);

$chart->plot3d($dataSet);
