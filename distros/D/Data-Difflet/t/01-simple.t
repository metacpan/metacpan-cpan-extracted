use strict;
use warnings;
use utf8;
use Test::More 0.96;

# Yes, this is silly.
# please write correct test case and pull-req for me!
use Data::Difflet;

my $difflet = Data::Difflet->new();

note $difflet->compare(+{
    1 => 2,
    2 => 3,
    foo => 'bar',
}, {1 => 2, 2 => 4, 3 => 1});

note $difflet->compare(+{
    1 => 2,
    2 => 3,
    foo => 'bar',
}, [1,2,3]);

note $difflet->compare(+[
    4,
    2,
    3,
    8
], [1,2,3]);

note $difflet->compare(+[1], {});
note $difflet->compare('a', 'b');
note $difflet->compare('a', 'a');

note $difflet->compare(
    +[
        {
            1 => 2,
            2 => 3,
        },
    ],
    [ { 2 => 4, 3 => 5 } ]
);

note $difflet->compare(
    +[
        {
            1   => 2,
            2   => 3,
            foo => [ 3, 4, 7, 8 ]
        },
    ],
    [ { 2 => 4, 3 => 5, foo => [ 3, 4, 5 ] } ]
);

ok 1;

done_testing;

