#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

# Demo of the candle sticks plotting style

# Initiate the chart object
my $chart = Chart::Gnuplot->new(
    output => 'gallery/plotStyle_12.png',
);

# Raw data
my @t = (0 .. 100);
my (@op, @hi, @lo, @cl) = ();
$op[0] = 100;                       # open price
$hi[0] = $op[0] + rand()/5;         # high price
$lo[0] = $op[0] - rand()/5;         # low price
$cl[0] = ($op[0]+$hi[0]+$lo[0])/3;  # close price
foreach my $i (1 .. $#t)
{
    $op[$i] = $cl[$i-1] + (rand()-0.5)/2;
    $hi[$i] = $op[$i] + rand()/5;
    $lo[$i] = $op[$i] - rand()/5;
    $cl[$i] = ($op[$i]+$hi[$i]+$lo[$i])/3;
}

# Plot the data
my $timeSeries = Chart::Gnuplot::DataSet->new(
    xdata => \@t,
    ydata => [\@op, \@hi, \@lo, \@cl],
    style => 'candlesticks',
);

# Plot the graph
$chart->plot2d($timeSeries);
