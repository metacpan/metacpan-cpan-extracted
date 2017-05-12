#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

my $chart = Chart::Gnuplot->new(
    output => "gallery/range_3.png",
    title  => "A hypotrochoid",
    trange => [0, 40],
);

# A hypotrochoid
my $dataSet = Chart::Gnuplot::DataSet->new(
    func => {
        x => 'cos(t) + 5*cos(0.4*t)',
        y => 'sin(t) - 5*sin(0.4*t)',
    },
);

$chart->plot2d($dataSet);
