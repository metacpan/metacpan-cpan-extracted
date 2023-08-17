#!perl
use strict;
use warnings;

use Test::More 'no_plan';
require_ok 'Chicken::Ipsum';
my $ci = Chicken::Ipsum->new;

# Scalar context

like(scalar $ci->words(5), qr/^\S+(?:\s+\S+){4}$/,
    '->words(5) contains 5 words'
);

like(scalar $ci->words(1), qr/^\S+$/,
    '->words(1) contains 1 words'
);

is(scalar $ci->words(0), '',
    '->words(0) is empty'
);

# List context

my @words;
@words = $ci->words(5);
is(scalar @words, 5,
    '->words(5) gives a 5-element list'
);
