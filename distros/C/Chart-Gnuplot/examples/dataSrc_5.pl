#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

# Chart object
my $chart = Chart::Gnuplot->new(
    output => "gallery/dataSrc_5.png",
);

# Data set object
# - parametric function: a circle
my $circle = Chart::Gnuplot::DataSet->new(
    func  => {x => 'sin(t)', y => 'cos(t)'},
    title => 'circle',
);

# Vertical straight line
my $vertical = Chart::Gnuplot::DataSet->new(
    func  => {x => 0, y => 't'},
    title => 'vertical line',
);

$chart->plot2d($circle, $vertical);
