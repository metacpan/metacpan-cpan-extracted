#!perl -w

use strict;
use Test::More tests => 1;

use B::Foreach::Iterator;

my @next;
my @ary;

@ary = (11 .. 15);
foreach (@ary){
	push @next, iter->peek;
}

is_deeply \@next, [12 .. 15, undef];
