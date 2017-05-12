use strict;
use warnings;
use utf8;
use Test::More 0.96;
use Test::Difflet qw/is_deeply/;

is_deeply {a => 1, b => 2, c => 3}, {a => 1, b => 2, c => 3};

done_testing;

