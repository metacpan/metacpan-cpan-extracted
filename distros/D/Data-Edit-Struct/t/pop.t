#! perl

use strict;
use warnings;

use Test2::Bundle::Extended;

use Data::Edit::Struct qw[ edit ];

my %dest = (

    array => [ 0, 10, 20, 40 ],
);


edit(
    pop => {
        dest  => \%dest,
        dpath => '/array',
    },
);


is( $dest{array}, [ 0, 10, 20 ], "pop" );

edit(
    pop => {
        dest   => \%dest,
        dpath  => '/array',
        length => 2,
    },
);

is( $dest{array}, [0], "pop 2" );

edit(
    pop => {
        dest   => \%dest,
        dpath  => '/array',
        length => 2,
    },
);

is( $dest{array}, [], "pop 2" );


isa_ok(
    dies {
        edit( pop => { dest => {} } )
    },
    ['Data::Edit::Struct::failure::input::dest'],
    "destination is not an array"
);

done_testing;
