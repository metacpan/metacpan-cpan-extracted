use strict;
use warnings;
use Data::Monad::Identity;
use Test::More;

is_deeply [Data::Monad::Identity->unit(1, 2, 3)->map(sub {
    map { $_ + 1 } @_
})->value], [2, 3, 4];


is +Data::Monad::Identity->unit(4)->map(sub { $_[0] + 1 })->value, 5;


done_testing;
