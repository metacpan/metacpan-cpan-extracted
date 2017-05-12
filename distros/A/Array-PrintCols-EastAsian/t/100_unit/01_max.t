use strict;
use warnings;
use utf8;
use Test::More;
use Array::PrintCols::EastAsian qw / _max /;

my @numbers = qw/ 0 1 2 3 4 5 6 7 8 9 /;
is _max(@numbers), 9;

done_testing;

