use strict;
use warnings;
use Data::Monad::List;
use Test::More;

ok eq_set(
    [(
        list_map_multi { $_[0] + $_[1] + $_[2] }
                       scalar_list(1 ,2, 3),
                       scalar_list(4, 5),
                       scalar_list(0, 8)
    )->scalars],
    [5, 6, 7, 6, 7, 8, 13, 14, 15, 14, 15, 16]
);

done_testing;
