use strict;
use warnings;
use utf8;
use Test::More;
use Array::PrintCols::EastAsian qw / _min /;

my @numbers = qw/ 1 2 3 4 5 6 7 8 9 0 /;
is _min(@numbers), 0;

done_testing;

