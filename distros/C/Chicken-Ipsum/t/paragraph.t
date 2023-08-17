#!perl
use strict;
use warnings;

use Test::More 'no_plan';
require_ok 'Chicken::Ipsum';
my $ci = Chicken::Ipsum->new;

# Scalar context

like(scalar $ci->paragraphs(1), qr/^[A-Z]/,
    '->paragraphs(1) begins with capital letter'
);

like(scalar $ci->paragraphs(1), qr/[.?!]$/,
    '->paragraphs(1) ends with a sentence-ending mark [., ?, !]'
);

like(scalar $ci->paragraphs(2), qr/[.?!]\n\n[A-Z]/,
    '->paragraphs(2) joins and capitalizes sentences'
);

is(scalar $ci->paragraphs(0), '',
    '->paragraphs(0) is empty'
);

# List context

my @paragraphs;
@paragraphs = $ci->paragraphs(5);
is(scalar @paragraphs, 5,
    '->paragraphs(5) gives a 5-element list'
);
