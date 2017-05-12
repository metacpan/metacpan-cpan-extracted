#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;
use Authorize::Rule;

my $auth = Authorize::Rule->new(
    default => 0,
    rules   => {
        'Person' => {
            'place' => [ [ 1 ] ]
        },
        '' => {
            'public'     => [ [ 1 ] ],
            ''           => [ [ 1 ] ], # ignored
        }
    },
);

isa_ok( $auth, 'Authorize::Rule' );

ok(
    $auth->is_allowed( 'Person', 'place' ),
    'Person allowed to enter Place',
);

ok(
    ! $auth->is_allowed( 'Foo', 'place' ),
    'Foo is not allowed in Place',
);

ok(
    $auth->is_allowed( 'Person', 'public' ),
    'Person is allowed in the public place'
);

ok(
    $auth->is_allowed( 'Foo', 'public' ),
    'Foo is allowed in the public place',
);

ok(
    ! $auth->is_allowed( 'Person', 'not_public'),
    'Person not allowed in the not_public place(default rule)',
);

