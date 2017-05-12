#!perl -w

use strict;
use Test::More tests => 2;

use B::Foreach::Iterator;

my @next;
foreach ('a' .. 'e'){
	push @next, iter->peek;
}
is_deeply \@next, ['b' .. 'e', undef] or diag "[@next]";


@next = ();
foreach (reverse 'a' .. 'e'){
	push @next, iter->peek;
}
is_deeply \@next, [reverse('a' .. 'd'), undef] or diag "[@next]";
