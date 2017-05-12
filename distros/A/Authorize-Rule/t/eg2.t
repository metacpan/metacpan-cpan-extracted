#!perl

use strict;
use warnings;

use Test::More tests => 7;
use Authorize::Rule;

my $auth = Authorize::Rule->new(
    default => -1,
    rules   => {
        cats => { '' => [ [1] ] },
        dogs => {
            table          => [ [0] ],
            'laundry room' => [ [0] ],
            ''             => [ [1] ],
        },
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

cmp_ok(
    $auth->is_allowed( dogs => 'table' ),
    '==',
    0,
    'Dogs cannot go on the table',
);

cmp_ok(
    $auth->is_allowed( dogs => 'laundry room' ),
    '==',
    0,
    'Dogs cannot go on the table',
);

cmp_ok(
    $auth->is_allowed( dogs => 'bedroom' ),
    '==',
    1,
    'Dogs can go in the bedroom',
);

