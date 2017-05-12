#!perl -w

use strict;
use Test::More tests => 2;

use B::Foreach::Iterator;

my @next;
foreach (1 .. 5){
	push @next, iter->peek;
}

is_deeply \@next, [2 .. 5, undef];

@next = ();
foreach my $i(5 .. 10){
	push @next, iter->peek;
}
is_deeply \@next, [6 .. 10, undef];
