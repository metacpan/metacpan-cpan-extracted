#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

#----------------------------------------
# Demonstration of generating inset chart
#----------------------------------------

my $multiChart = Chart::Gnuplot->new(
    output => "gallery/multiplot_2.png",
);

#----------------------------------------
# Large chart
my $large = Chart::Gnuplot->new(
    title  => "Inset chart",
);
my $dataSet = Chart::Gnuplot::DataSet->new(
    func => "norm(x)",
);
$large->add2d($dataSet);
#----------------------------------------

#----------------------------------------
# Small chart
my $small = Chart::Gnuplot->new(
    title  => 'a small chart',
    origin => '0.1, 0.5',
    size   => '0.4, 0.4',
);
$dataSet = Chart::Gnuplot::DataSet->new(
    func => "cos(x)",
);
$small->add2d($dataSet);
#----------------------------------------

#----------------------------------------
# Plot the multplot chart
$multiChart->multiplot($large, $small);
#----------------------------------------
