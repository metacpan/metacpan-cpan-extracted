#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 8;
use Authorize::Rule;

my $auth = Authorize::Rule->new(
    default => -1,
    rules   => {
        Marge => {
            '' => [ [ 1, sub {
                    my $params = shift;
                    ::isa_ok( $params, 'HASH' );
                    ::is_deeply(
                        [ keys %{$params} ],
                        ['now'],
                        'Only key "now" in params',
                    );

                    time - $params->{'now'} < 10
                        and return 1;

                    return 0;
            } ] ],
        },
    },
);

isa_ok( $auth, 'Authorize::Rule' );
can_ok( $auth, qw<is_allowed>    );

ok(
    $auth->is_allowed( 'Marge', 'Anywhere', { now => time } ),
    'We can provide a callback as a subroutine (succeeds)',
);

is(
    $auth->is_allowed( 'Marge', 'Anywhere', { now => 1 } ),
    -1,
    'We can provide a callback as a subroutine (fails)',
);

