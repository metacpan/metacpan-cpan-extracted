#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

my $multiChart = Chart::Gnuplot->new(
    output => "gallery/multiplot_3.png",
    title  => "Multiplot chart",
);

#----------------------------------------
# Left chart
my @charts = ();
$charts[0][0] = Chart::Gnuplot->new(
    grid => "on",
);
my $dataSet = Chart::Gnuplot::DataSet->new(
    func => "(x*x+y*y) * exp(-0.05*(x*x+y*y))",
);
$charts[0][0]->add3d($dataSet);
#----------------------------------------

#----------------------------------------
# Central chart
my @y = (5, 2.3, 6.78, 1, 0, 4.4, 7, 2.7, 5.4, 7.8, 9.5);
$charts[0][1] = Chart::Gnuplot->new();
$dataSet = Chart::Gnuplot::DataSet->new(
    ydata => \@y,
    style => "boxes",
);
$charts[0][1]->add2d($dataSet);
#----------------------------------------

#----------------------------------------
# Right chart
$charts[0][2] = Chart::Gnuplot->new(
    title => {
        text  => "Right chart",
        color => "#99ccff",
    }
);
$dataSet = Chart::Gnuplot::DataSet->new(
    func      => "cos(x)",
    style     => "linespoints",
    pointtype => "triangle",
);
$charts[0][2]->add2d($dataSet);
#----------------------------------------

# Plot the multplot chart
$multiChart->multiplot(\@charts);
