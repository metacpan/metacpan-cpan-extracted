#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;
use Authorize::Rule;

my $auth = Authorize::Rule->new(
    rules => {
        DeployUser => {
            Release => [
                [ 1, { author => qr/^(Sawyer|Mickey)$/ } ]
            ]
        },
    },
);

isa_ok( $auth, 'Authorize::Rule' );
can_ok( $auth, qw<is_allowed>    );

ok(
    $auth->is_allowed( 'DeployUser', 'Release', { author => 'Sawyer' } ),
    'Sawyer can release',
);

ok(
    $auth->is_allowed( 'DeployUser', 'Release', { author => 'Mickey' } ),
    'Mickey can release',
);

ok(
    ! $auth->is_allowed( 'DeployUser', 'Release', { author => 'John' } ),
    'John cannot release',
);

