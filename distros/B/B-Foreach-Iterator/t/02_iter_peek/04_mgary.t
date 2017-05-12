#!perl -w

use strict;
use Test::More tests => 1;

use Tie::Array;
use B::Foreach::Iterator;

my @next;
tie my @ary, 'Tie::StdArray';

@ary = (11 .. 15);
foreach (@ary){
	push @next, iter->peek;
}

is_deeply \@next, [12 .. 15, undef] or diag "[@next]";
