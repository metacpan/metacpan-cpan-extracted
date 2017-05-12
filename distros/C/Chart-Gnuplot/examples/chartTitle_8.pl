#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

#-----------------------------------------------
# Demonstrate setting sophisticated chart title
#-----------------------------------------------

# Initiate the chart object
my $chart = Chart::Gnuplot->new(
    output  => 'gallery/chartTitle_8.png',
    title   => {
        text     => "My so^{phis}ticate_d title",
        font     => "arial, 20",
        color    => "#99ccff",
        offset   => "-10, 2",
        enhanced => 'on',
    },
);

# Data sets
my $cos = Chart::Gnuplot::DataSet->new(
    func => "cos(x)",
);

# Plot the graph
$chart->plot2d($cos);
