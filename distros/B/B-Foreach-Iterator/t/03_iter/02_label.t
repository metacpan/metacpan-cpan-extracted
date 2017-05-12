#!perl -w

use strict;
use Test::More tests => 2;

use B::Foreach::Iterator;

my @ary;
FOO: foreach my $i1(1 .. 6){
	foreach my $i2('a'){
		push @ary, iter('FOO')->next;
	}
}
is_deeply \@ary, [2, 4, 6];

@ary = ();
BAR: foreach my $i1(1 .. 6){
	foreach my $i2('a'){
		foreach my $i3('b'){
			push @ary, iter('BAR')->next;
		}
	}
}
is_deeply \@ary, [2, 4, 6];

