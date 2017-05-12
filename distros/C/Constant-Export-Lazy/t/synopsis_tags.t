package My::More::User::Code;
use strict;
use warnings;
use Test::More;
BEGIN {
    if ($] >= 5.010000) {
        plan 'no_plan';
    } else {
        plan skip_all => "This test requires perl 5.10.0 or later";
    }
}
use lib 't/lib';
use My::Constants::Tags qw(
    KG_TO_MG
    :math
    :alphabet
);

is(KG_TO_MG, 10**6);
is(A, "A");
is(B, "B");
is(C, "C");
like(PI, qr/^3\.14/);
