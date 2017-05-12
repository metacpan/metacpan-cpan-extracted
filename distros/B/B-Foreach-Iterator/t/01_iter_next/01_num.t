#!perl -w

use strict;
use Test::More tests => 7;

use B::Foreach::Iterator;

my @next;
foreach (1 .. 5){
	push @next, iter->next;
}

is_deeply \@next, [2, 4, undef];

@next = ();
foreach my $i(5 .. 10){
	my $old = $i;
	push @next, iter->next;
	is $i, $old;
}
is_deeply \@next, [6, 8, 10];


@next = ();
foreach (reverse 1 .. 5){
	push @next, iter->next;
}

is_deeply \@next, [4, 2, undef];

@next = ();
foreach my $i(reverse 5 .. 10){
	push @next, iter->next;
}
is_deeply \@next, [9, 7, 5];
