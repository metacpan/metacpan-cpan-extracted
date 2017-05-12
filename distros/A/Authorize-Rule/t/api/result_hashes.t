#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 8;
use Authorize::Rule;

my $auth = Authorize::Rule->new(
    rules => {
        Lisa => {
            School => [ [1] ],
            Home   => [
                [ 1, { has_weapons => 0 } ],
                [ 1, { is_smiling  => 1 } ],
                [ 1, { tired       => 1 } ],
                [0],
            ],
            ''     => [ ['DefaultFail'] ],
        },
    },
);

isa_ok( $auth, 'Authorize::Rule'      );
can_ok( $auth, qw<allowed is_allowed> );

{
    my $res = $auth->allowed( 'Lisa', 'School' );
    is_deeply(
        $res,
        {
            entity      => 'Lisa',
            resource    => 'School',
            ruleset_idx => 1,
            action      => 1,
            params      => {},
        },
        'Correct result object from allowed()',
    );

    is(
        $auth->is_allowed( 'Lisa', 'School' ),
        $res->{'action'},
        'is_allowed returns what allowed returns',
    );
}

{
    my $res = $auth->allowed( 'Lisa', 'Home', { is_smiling => 1 } );
    is_deeply(
        $res,
        {
            entity      => 'Lisa',
            resource    => 'Home',
            ruleset_idx => 2,
            action      => 1,
            params      => { is_smiling => 1 },
        },
        'Correct result object from allowed()',
    );

    is(
        $auth->is_allowed( 'Lisa', 'Home', { is_smiling => 1 } ),
        $res->{'action'},
        'is_allowed returns what allowed returns',
    );
}

{
    my $res = $auth->allowed( 'Lisa', 'Petshop' );
    is_deeply(
        $res,
        {
            entity      => 'Lisa',
            resource    => 'Petshop',
            ruleset_idx => 1,
            action      => 'DefaultFail',
            params      => {},
        },
        'Correct result object from allowed()',
    );

    is(
        $auth->is_allowed( 'Lisa', 'Petshop' ),
        $res->{'action'},
        'is_allowed returns what allowed returns',
    );
}

