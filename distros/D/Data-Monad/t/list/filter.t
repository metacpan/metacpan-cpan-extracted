use strict;
use warnings;
use Data::Monad::List;
use Test::More;

ok eq_array(
    [scalar_list(1,2,3,4)->filter(sub { $_[0] % 2 == 0 })->scalars],
    [2, 4]
);

done_testing;
