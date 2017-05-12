#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

#----------------------------------------
# Demonstrate how to plot multiplot chart
# - Use "add"-"multiplot" method pair
#----------------------------------------

my $multiChart = Chart::Gnuplot->new(
    output => "gallery/multiplot_1.png",
    title  => "Multiplot chart",
);

#----------------------------------------
# Top left chart
my @charts = ();
$charts[0][0] = Chart::Gnuplot->new(
    title => "Top left chart",
);
my $dataSet = Chart::Gnuplot::DataSet->new(
    func => "sin(x)",
);
$charts[0][0]->add2d($dataSet);
#----------------------------------------

#----------------------------------------
# Top right chart
$charts[0][1] = Chart::Gnuplot->new(
    title => "Top right chart",
);
$dataSet = Chart::Gnuplot::DataSet->new(
    func => "cos(x)",
);
$charts[0][1]->add2d($dataSet);
#----------------------------------------

#----------------------------------------
# Bottom left chart
$charts[1][0] = Chart::Gnuplot->new(
    title => "Bottom left chart",
);
$dataSet = Chart::Gnuplot::DataSet->new(
    func => "exp(x)",
);
$charts[1][0]->add2d($dataSet);
#----------------------------------------

#----------------------------------------
# Bottom right chart
$charts[1][1] = Chart::Gnuplot->new(
    title => "Bottom right chart",
);
$dataSet = Chart::Gnuplot::DataSet->new(
    func => "log(x)",
);
$charts[1][1]->add2d($dataSet);
#----------------------------------------

# Plot the multplot chart
$multiChart->multiplot(\@charts);
