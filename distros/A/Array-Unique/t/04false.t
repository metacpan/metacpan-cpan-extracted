use strict;
use warnings;
use Test::More "no_plan";


use Array::Unique;
tie my @a, 'Array::Unique';
push @a, (1, 0, "x", "");
is_deeply([1, 0, "x", ""], \@a, "false but defined elements are kept");


