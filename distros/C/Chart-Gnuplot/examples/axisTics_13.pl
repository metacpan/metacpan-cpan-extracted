#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

# Create the chart object
my $chart = Chart::Gnuplot->new(
    output  => 'gallery/axisTics_13.png',
    xtics   => {
        labelfmt  => '%.1g',         # label format
        font      => 'arial,18',     # font
        fontcolor => 'magenta',      # text color
    },
    ytics   => {
        labels => [-0.8, 0.3, 0.6],  # specify tic labels
        rotate => '30',              # rotate the text in degree
        mirror => 'off',             # no tic on y2 axis
    },
    x2tics => [-8, -6, -2, 2, 5, 9],
    y2tics => {
        length    => "4,2",          # tic size
        minor     => 4,              # 2 minor tics between major tics
    },
);

# Data set object
my $data = Chart::Gnuplot::DataSet->new(
    func => "sin(x)",
);

# Plot the graph
$chart->plot2d($data);
