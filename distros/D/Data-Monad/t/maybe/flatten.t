use strict;
use warnings;
use Data::Monad::Maybe qw/just nothing/;
use Test::More;

is_deeply [just(just 1, 2, 3)->flatten->value], [1, 2, 3];

done_testing;
