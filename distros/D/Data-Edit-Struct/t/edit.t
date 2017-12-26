#! perl

use strict;
use warnings;

use Test2::Bundle::Extended;

use Data::Edit::Struct qw[ edit ];

isa_ok(
    dies { edit( undef, {} ) },
    ['Data::Edit::Struct::failure::input::param'],
    "no action specified"
);


isa_ok(
    dies {
        edit( 'say_what', {} )
    },
    ['Data::Edit::Struct::failure::input::param'],
    "unknown action"
);

done_testing;
