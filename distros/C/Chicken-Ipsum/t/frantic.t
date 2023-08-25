#!perl
use 5.012;
use warnings FATAL => 'all';

use Test::More 'no_plan';
require_ok 'Chicken::Ipsum';
my $ci;

# Frantic mode turned up to 100%
$ci = Chicken::Ipsum->new(
    frantic => 1,
);
my $lc_letters = qr/[a-z]/;
unlike(scalar $ci->words(10), $lc_letters,
    'frantic words should be all upper-case'
);
unlike(scalar $ci->sentences(10), $lc_letters,
    'frantic sentences should be all upper-case'
);
unlike(scalar $ci->paragraphs(10), $lc_letters,
    'frantic paragraphs should be all upper-case'
);

# Frantic mode turned down to 0%
$ci = Chicken::Ipsum->new(
    frantic => 0,
);
like(scalar $ci->words(10), $lc_letters,
    'non-frantic words should not be all upper-case'
);
like(scalar $ci->sentences(10), $lc_letters,
    'non-frantic sentences should not be all upper-case'
);
like(scalar $ci->paragraphs(10), $lc_letters,
    'non-frantic paragraphs should not be all upper-case'
);
