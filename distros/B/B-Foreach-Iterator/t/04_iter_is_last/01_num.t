#!perl -w

use strict;
use Test::More tests => 2;

use B::Foreach::Iterator;

my @next;
foreach (1 .. 5){
	push @next, iter->is_last;
}

is_deeply \@next, [(q{}) x 4, 1];

@next = ();
foreach my $i(6 .. 10){
	push @next, iter->is_last;
}
is_deeply \@next, [(q{}) x 4, 1];
