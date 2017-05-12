#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

my $chart = Chart::Gnuplot->new(
    output  => "gallery/axisLabel_1.png",
    title   => "Default format of the axis labels",
    xlabel  => "x-label",
    ylabel  => "y-label",
    x2label => "x2-label",
    y2label => "y2-label",
);

my $dataSet = Chart::Gnuplot::DataSet->new(
    func => "sin(x)",
);

$chart->plot2d($dataSet);
