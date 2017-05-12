#!perl -w

use strict;
use Test::More tests => 2;

use B::Foreach::Iterator;

my @ary;
foreach my $i1(1 .. 6){
	my $iter1 = iter;

	foreach my $i2('a'){
		push @ary, $iter1->next;
	}
}
is_deeply \@ary, [2, 4, 6];

@ary = ();
foreach my $i1(1 .. 6){
	my $iter1 = iter;

	foreach my $i2('a'){
		foreach my $i3('b'){
			push @ary, $iter1->next;
		}
	}
}
is_deeply \@ary, [2, 4, 6];

