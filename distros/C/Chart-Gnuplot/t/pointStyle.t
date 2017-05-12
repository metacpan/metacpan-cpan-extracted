#!/usr/bin/perl -w
use strict;
use Test::More (tests => 1);

BEGIN {use Chart::Gnuplot;}

# Test formatting the line style
{
	my $d = Chart::Gnuplot::DataSet->new(
		func      => "sin(x)",
		style     => "linespoints",
		pointsize => 3,
		pointtype => "circle",
	);

    my $s = $d->_thaw();
    ok($s eq 'sin(x) title "" with linespoints pointtype 65 pointsize 3');
}
