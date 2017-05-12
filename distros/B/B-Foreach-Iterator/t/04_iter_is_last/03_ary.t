#!perl -w

use strict;
use Test::More tests => 2;

use B::Foreach::Iterator;

my @next;
my @ary;

@ary = (11 .. 15, undef, 1 .. 5);
my $nfalse = scalar(@ary) - 1;

foreach (@ary){
	push @next, iter->is_last;
}
is_deeply \@next, [(q{}) x $nfalse, 1];

@next = ();
foreach (reverse @ary){
	push @next, iter->is_last;
}
is_deeply \@next, [(q{}) x $nfalse, 1];
