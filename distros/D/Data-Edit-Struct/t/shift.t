#! perl

use strict;
use warnings;

use Test2::Bundle::Extended;

use Data::Edit::Struct qw[ edit ];

my %dest = (

    array => [ 0, 10, 20, 40 ],
);


edit(
    shift => {
        dest  => \%dest,
        dpath => '/array',
    },
);


is( $dest{array}, [ 10, 20, 40 ], "shift" );

edit(
    shift => {
        dest   => \%dest,
        dpath  => '/array',
        length => 2,
    },
);

is( $dest{array}, [40], "shift 2" );

edit(
    shift => {
        dest   => \%dest,
        dpath  => '/array',
        length => 2,
    },
);

is( $dest{array}, [], "shift 2" );


isa_ok(
    dies {
        edit(
            shift => {
                dest => {} } )
    },
    ['Data::Edit::Struct::failure::input::dest'],
    "destination is not an array"
);

done_testing;
