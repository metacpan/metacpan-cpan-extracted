# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

# TODO: Make better test-cases.
use strict;
use Test;

BEGIN { plan tests => 4 }

use Algorithm::SISort;

our $unsorted='19 16 7 15 4 6 18 12 0 13 1 3 8 9 5 11 14 10 17 2';
our $sorted  ='0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19';
our $reverse ='19 18 17 16 15 14 13 12 11 10 9 8 7 6 5 4 3 2 1 0';

our @a=split ' ', $unsorted;
#Sort a predefined list, ascending...
our @b=Algorithm::SISort::Sort { $_[0] <=> $_[1] } @a;

ok(join(' ',@a) eq $unsorted && join(' ',@b) eq $sorted);

#Sort the same list inplace...
our $count=Algorithm::SISort::Sort_inplace { $_[0] <=> $_[1] } @a;
ok(join(' ',@a) eq $sorted && $count == 98);

#Reverse sort an already sorted (ascending) list...
$count=Algorithm::SISort::Sort_inplace { $_[1] <=> $_[0] } @a;
ok(join(' ',@a) eq $reverse && $count == 102);

@a=split ' ', $unsorted;
#Reverse sort an unsorted list...
$count=Algorithm::SISort::Sort_inplace { $_[1] <=> $_[0] } @a;
ok(join(' ',@a) eq $reverse && $count == 101);

