#!perl

use Test::More 'no_plan';
use List::Compare::Functional 'get_symdiff';

use Bio::Translator::Utils;

my $utils = new Bio::Translator::Utils;

is(
    scalar(
        get_symdiff(
            [
                $utils->nonstop( \'TACGTTGGTTAAGTT' ),
                [ 2, 3, -1, -3 ]
            ]
        )
    ),
    0,
    'Nonstop on both strands'
);

is(
    scalar(
        get_symdiff(
            [
                $utils->nonstop( \'TACGTTGGTTAAGTT', { strand => 1 } ),
                [ 2, 3 ]
            ]
        )
    ),
    0,
    'Nonstop on + strand'
);

is(
    scalar(
        get_symdiff(
            [
                $utils->nonstop( \'TACGTTGGTTAAGTT', { strand => -1 } ),
                [ -1, -3 ]
            ]
        )
    ),
    0,
    'Nonstop on - strand'
);