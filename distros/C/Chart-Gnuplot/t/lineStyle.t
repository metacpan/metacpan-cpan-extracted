#!/usr/bin/perl -w
use strict;
use Test::More (tests => 1);

BEGIN {use Chart::Gnuplot;}

# Test formatting the line style
{
	my $d = Chart::Gnuplot::DataSet->new(
		func     => "sin(x)",
		style    => "linespoints",
		color    => "blue",
		linetype => "dash",
		width    => 3,
	);

    my $s = $d->_thaw();
    ok($s eq 'sin(x) title "" with linespoints linetype 3 '.
		'linecolor rgb "blue" linewidth 3');
}
