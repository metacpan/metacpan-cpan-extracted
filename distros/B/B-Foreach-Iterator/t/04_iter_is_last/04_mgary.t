#!perl -w

use strict;
use Test::More tests => 1;

use Tie::Array;
use B::Foreach::Iterator;

my @next;
tie my @ary, 'Tie::StdArray';

@ary = (11 .. 15);
foreach (@ary){
	push @next, iter->is_last;
}

my $nfalse = scalar(@ary) - 1;
is_deeply \@next, [(q{}) x $nfalse, 1] or diag "[@next]";
