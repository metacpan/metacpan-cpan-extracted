#! /usr/bin/perl
# $Id: 02_explicit.t,v 1.1.1.1 2007/04/11 15:15:54 dk Exp $

use strict;
use warnings;

use Test::More tests => 15;

use Array::Slice qw(:all);

for my $array ( 
	[],
	[2],
	[4,6],
	[8,10,undef],
	[12,14,16,18,20,22]
) {
	for my $i ( 1, 2, 3) {
		my $expected = int(@$array / $i) + (@$array % $i ? 1 : 0);
		my $done     = 0;
		while ( my @a = slice @$array, $i) {
			$done++;
			last if $done > 100;
		}
		ok ( $done == $expected, "array with ". scalar(@$array) . " items sliced by $i");
	}
}

