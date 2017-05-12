# Test utility module.

use strict;

use Test::More tests => 2;

BEGIN {use_ok('Alien::Taco::Util', qw/filter_struct/);}

my ($in, $out);

$in = {
    a => 1,
    b => {
        c => {
            replace_me => 2,
        },
        d => [
            3,
            {
                replace_me => 4,
            },
            5
        ]
    },
};

$out = {
    a => 1,
    b => {
        c => {
            replacement => 2,
        },
        d => [
            3,
            {
                replacement => 4,
            },
            5
        ]
    },
};

filter_struct($in, sub {
        my $x = shift;
        return ref $x eq 'HASH' && exists $x->{'replace_me'};
    },
    sub {
        my $x = shift;
        return {'replacement' => $x->{'replace_me'}};
    });

is_deeply($in, $out, 'filter_struct with replace_me hash entries');
