#!perl

use strict;
use warnings;
use Test::More;

use Assert::Refute qw(:core);

my $inner = contract {
    package T;
    use Assert::Refute;
    is shift, 42, "Life is fine";
};

my $outer = contract {
    # no package T - subcontract must be exportable with :core
    subcontract "First attempt", $inner, shift;
    subcontract "Second attempt", $inner, shift;
};

my $c1 =  $outer->apply( 137, 42 );
is $c1->signature, "tN1d", "pass/fail as expected";

my $tap = $c1->as_tap;
note "TEST LOG\n$tap\n/TEST LOG";
like $tap, qr/^not ok 1.*subtest.*\n    not ok 1.*# *Expected.*42.*\n    1..1.*\nok 2/s
    , "Reason for failure present";

is $outer->apply(42,42)->signature, "t2d", "Success propagates";

done_testing;
