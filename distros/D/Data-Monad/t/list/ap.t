use strict;
use warnings;
use Data::Monad::List;
use Test::More;

ok eq_set
    [scalar_list(sub { $_[0] + 1 }, sub { $_[0] - 1 })
        ->ap(scalar_list(2, 5))->scalars],
    [3, 1, 6, 4];

ok eq_set
    [scalar_list(sub { $_[0] + $_[1] }, sub { $_[0] * $_[1] })
        ->ap(scalar_list(2, 5), scalar_list(3, 7))->scalars],
    [5, 6, 9, 14, 8, 15, 12, 35];

done_testing;
