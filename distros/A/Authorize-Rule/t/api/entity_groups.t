#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;
use Authorize::Rule;

my $auth = Authorize::Rule->new(
    entity_groups => {
        Group => [ qw<Foo Bar Baz> ],
    },

    rules => {
        Group => {
            Place => [
                [ 1, { name => 'me' } ]
            ]
        },

        Person => {
            Place => [ [1] ],
        },
    },
);

isa_ok( $auth, 'Authorize::Rule' );

ok(
    $auth->is_allowed( 'Person', 'Place' ),
    'Person allowed to enter Place',
);

ok(
    ! $auth->is_allowed( 'Foo', 'Place' ),
    'Foo is not allowed in Place',
);

ok(
    $auth->is_allowed( 'Foo', 'Place', { name => 'me' } ),
    'Foo is allowed to Place as part of Group',
);

ok(
    $auth->is_allowed( 'Baz', 'Place', { name => 'me' } ),
    'Foo is allowed to Place as part of Group',
);

ok(
    ! $auth->is_allowed( 'Group', 'Place', { name => 'me' } ),
    'Group group not allowed in Place',
);

