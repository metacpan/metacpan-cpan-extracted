#!perl

use strict;
use warnings;

use Test::More tests => 4;
use Authorize::Rule;

my $auth = Authorize::Rule->new(
    default => -1,
    rules   => {
        cats => {
            '' => [ [1] ],
        }
    }
);

isa_ok( $auth, 'Authorize::Rule' );
can_ok( $auth, 'is_allowed'      );

cmp_ok(
    $auth->is_allowed( cats => 'kitchen' ),
    '==',
    1,
    'Cats can go in the kitchen',
);

cmp_ok(
    $auth->is_allowed( cats => 'bedroom' ),
    '==',
    1,
    'Cats can go in the bedroom',
);

