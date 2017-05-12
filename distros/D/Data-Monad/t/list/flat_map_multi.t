use strict;
use warnings;
use Data::Monad::List;
use Test::More;

ok eq_set(
    [(
        list_flat_map_multi { scalar_list($_[0] + $_[1], $_[0] * $_[1]) }
                            scalar_list(1 ,2, 3),
                            scalar_list(4, 5)
    )->scalars],
    [5, 4, 6, 5, 6, 8, 7, 10, 7, 12, 8, 15]
);

done_testing;
