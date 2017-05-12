#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;
use Authorize::Rule;

my $auth = Authorize::Rule->new(
    rules => {
        Marge => {
            '' => [ [
                sub {
                    my $result = shift;
                    ::isa_ok( $result, 'HASH', 'Action CB got result hash' );
                    ::is_deeply(
                        $result,
                        {
                            ruleset_idx => 1,
                            params      => { time => 'now' },
                            entity      => 'Marge',
                            resource    => 'Anywhere',
                        },
                        'Correct resultset',
                    );

                    return 'SpecialActionValue';
                },
                { time => 'now' }
            ] ],
        },
    },
);

isa_ok( $auth, 'Authorize::Rule' );
can_ok( $auth, qw<is_allowed>    );

is(
    $auth->is_allowed( 'Marge', 'Anywhere', { time => 'now' } ),
    'SpecialActionValue',
    'We can override the value from the callback',
);


