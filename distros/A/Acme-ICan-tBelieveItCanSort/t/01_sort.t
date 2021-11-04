use strict;
use Test::More 0.98;
use lib '../lib';
use Acme::ICan'tBelieveItCanSort;
#
is_deeply(
    [ Acme::ICan'tBelieveItCanSort( 3, 5, 2, 8, 1 ) ],
    [ 1, 2, 3, 5, 8 ],
    "Acme::ICan'tBelieveItCanSort( 3, 5, 2, 8, 1 )"
);
is_deeply(
    [ Acme::ICan'tBelieveItCanSort( 3, 4, 5, 5, 68, 1, 4, 321, 32, 321 ) ],
    [ 1, 3, 4, 4, 5, 5, 32, 68, 321, 321 ],
    "Acme::ICan'tBelieveItCanSort( 3, 4, 5, 5, 68, 1, 4, 321, 32, 321 )"
);
done_testing;
