#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;
use Authorize::Rule;

my $auth = Authorize::Rule->new(
    default => -1,
    rules   => {
        Person => {
            Place => [
                [ 1, { name => 'error', city => undef } ]
            ]
        }
    },
);

isa_ok( $auth, 'Authorize::Rule' );
can_ok( $auth, qw<is_allowed>    );

cmp_ok(
    $auth->is_allowed( 'Person', 'Place', { name => 'error' } ),
    '==',
    1,
    'Matches a ruleset with a missing key',
);

cmp_ok(
    $auth->is_allowed(
        'Person', 'Place', { name => 'blah', city => 'this' }
    ),
    '==',
    -1,
    'Not allowed with name and with city',
);

