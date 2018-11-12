#!/usr/bin/env perl

use strict;
use warnings;
BEGIN{ delete @ENV{qw(NDEBUG PERL_NDEBUG)} };
use Test::More;

use Assert::Refute::Report;

my $rep = Assert::Refute::Report->new;

$rep->done_testing;

ok( $rep->is_passing, "Passing contract" );

is eval {
    $rep->done_testing;
}, undef, "second done_testing failed";
like $@, qr/done_testing().*was called/, "Correct error message";

is eval {
    $rep->done_testing(0);
    1;
}, 1, "done_testing(0) lives"
    or diag "Exception: $@";

is( $rep->get_tap, "1..0\n", "No more appended" );

is eval {
    $rep->done_testing("Very bad exception");
    1;
}, 1, "done_testing('Exception') lives"
    or diag "Exception: $@";

ok ( !$rep->is_passing, "Not passing anymore" );
like $rep->get_tap, qr/#.*interrupted.*Very bad exception/, "tap amended";

done_testing;
