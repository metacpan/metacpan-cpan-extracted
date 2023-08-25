#!perl
use 5.012;
use warnings FATAL => 'all';

use Test::More 'no_plan';
require_ok 'Chicken::Ipsum';
my $ci = Chicken::Ipsum->new;

# Scalar context

like(scalar $ci->sentences(1), qr/^[A-Z]/,
    '->sentences(1) begins with capital letter'
);

like(scalar $ci->sentences(1), qr/[.?!]$/,
    '->sentences(1) ends with a sentence-ending mark [., ?, !]'
);

like(scalar $ci->sentences(2), qr/[.?!] [A-Z]/,
    '->sentences(2) joins and capitalizes sentences'
);

is(scalar $ci->sentences(0), '',
    '->sentences(0) is empty'
);

# List context

my @sentences;
@sentences = $ci->sentences(5);
is(scalar @sentences, 5,
    '->sentences(5) gives a 5-element list'
);
