#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

# Create the chart object
my $chart = Chart::Gnuplot->new(
    output => 'gallery/grid_9.png',
    xtics  => {
        minor => 4
    },
    ytics  => {
        minor => 4
    },
    grid   => {
        linetype => 'longdash, dot-longdash',
        color    => 'light-blue',
        width    => '3, 1',
        xlines   => 'off, on',
    },
);

# Data set object
my $data = Chart::Gnuplot::DataSet->new(
    func => 'sin(x)',
);

# Plot the graph
$chart->plot2d($data);
