#!perl -w

use strict;
use Test::More tests => 16;

use B::Foreach::Iterator;

FOO: foreach my $i(0, 1){
	foreach my $j(0, 1){
		my($x, $y) = map{ iter } 0, 1;
		is_deeply $x, $y, "iter [$i][$j]";

		($x, $y)   = map{ iter('FOO') } 0, 1;
		is_deeply $x, $y;

		($x, $y) = map{ iter($_ == 0 ? 'FOO' : undef) } 0, 1;
		is $x->label, 'FOO';
		is $y->label, undef;
	}
}

