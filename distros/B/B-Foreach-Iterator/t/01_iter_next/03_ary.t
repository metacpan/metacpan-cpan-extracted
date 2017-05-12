#!perl -w

use strict;
use Test::More tests => 4;

use B::Foreach::Iterator;

my @next;
my @ary;

@ary = (11 .. 15);
foreach (@ary){
	push @next, iter->next;
}

is_deeply \@next, [12, 14, undef];

@next = ();
@ary  = (10 .. 15);
foreach my $i(@ary){
	push @next, iter->next;
}
is_deeply \@next, [11, 13, 15] or diag "[@next]";


@next = ();
@ary = (11 .. 15);
foreach (reverse @ary){
	push @next, iter->next;
}

is_deeply \@next, [14, 12, undef];

@next = ();
@ary  = (10 .. 15);
foreach my $i(reverse @ary){
	push @next, iter->next;
}
is_deeply \@next, [14, 12, 10];

