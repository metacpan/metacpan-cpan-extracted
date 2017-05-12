#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;
use Authorize::Rule;

my $cb   = 0;
my $auth = Authorize::Rule->new(
    default => -1,
    rules   => {
        Marge => {
           '' => [
                [
                    1,
                    {
                        now => sub { $cb++; 77 }
                    },
                ]
            ]
        },
    },
);

isa_ok( $auth, 'Authorize::Rule' );
can_ok( $auth, qw<is_allowed>    );

ok(
    $auth->is_allowed( 'Marge', 'Anywhere', { now => 77 } ),
    'We can provide a callback as a subroutine (succeeds)',
);

cmp_ok( $cb, '==', 1, 'Callback called successfully once' );

is(
    $auth->is_allowed( 'Marge', 'Anywhere', { now => 1 } ),
    -1,
    'We can provide a callback as a subroutine (fails)',
);

cmp_ok( $cb, '==', 2, 'Callback called successfully once' );
