use strict;
use warnings;

use Test::More;
use Test::Moose::More;

use aliased 'CPAN::Local::Role::MetaCPAN::API';

validate_role API,
    attributes => [
        metacpan => {
            reader   => 'metacpan',
            writer   => undef,
            accessor => undef,
            lazy     => 1,
            builder  => '_build_metacpan',
        },
    ],
    ;

done_testing;
