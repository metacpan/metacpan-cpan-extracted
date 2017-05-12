#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;
use Test::Fatal;
use Authorize::Rule;

like(
    exception { Authorize::Rule->new },
    qr/^You must provide rules/,
    'Cannot instantiate Authorize::Rule without rules',
);

my $auth = Authorize::Rule->new(
    rules => {
        Person => {
            Place => [
                [ 1, { name => ['error'] } ]
            ]
        }
    },
);

isa_ok( $auth, 'Authorize::Rule' );
can_ok( $auth, qw<allowed is_allowed> );

like(
    exception { $auth->allowed( 'Person', 'Place', { name => 'blah' } ) },
    qr/^Rule keys can only be strings, regexps, or code/,
    'We fail on unknown reference in key value in params',
);
