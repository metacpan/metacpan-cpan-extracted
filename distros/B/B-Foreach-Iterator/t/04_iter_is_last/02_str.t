#!perl -w

use strict;
use Test::More tests => 2;

use B::Foreach::Iterator;

my @next;
foreach ('a' .. 'e'){
	push @next, iter->is_last;
}
my @a = ('a' .. 'e');
my $nfalse = scalar(@a) - 1;

is_deeply \@next, [(q{}) x $nfalse, 1] or diag "[@next]";


@next = ();
foreach (reverse 'a' .. 'e'){
	push @next, iter->is_last;
}
is_deeply \@next, [(q{}) x $nfalse, 1] or diag "[@next]";
