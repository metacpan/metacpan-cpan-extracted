#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

# Data in Perl arrays
my (@x, @y, @z) = ();
for (my $x = -5; $x < 5; $x += 0.02)
{
	my $y = sin($x*3);
	my $z = cos($x*3);

	push(@x, $x);
	push(@y, $y);
	push(@z, $z);
}

my $chart = Chart::Gnuplot->new(
    output => "gallery/plot3d_1.png",
    title  => "3D plot from arrays of coordinates",
);

my $dataSet = Chart::Gnuplot::DataSet->new(
    xdata => \@x,
    ydata => \@y,
    zdata => \@z,
    style => 'lines',
);

$chart->plot3d($dataSet);
