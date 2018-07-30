#!/usr/bin/env perl

use strict;
use warnings;
BEGIN{ delete @ENV{qw(NDEBUG PERL_NDEBUG)} };
use Test::More;

use Assert::Refute::Report;

subtest "plan ok" => sub {
    my $rep = Assert::Refute::Report->new;

    $rep->plan(tests => 1);
    $rep->ok(1);
    $rep->done_testing;

    ok $rep->is_passing, "Tests are passing";
    is $rep->get_sign, "t1d", "Signature as expected";
    is $rep->get_tap, "1..1\nok 1\n", "TAP with plan ahead";
};

subtest "bad plan" => sub {
    my $rep = Assert::Refute::Report->new;

    $rep->plan(tests => 5);
    $rep->ok(1) for 1..4;
    $rep->done_testing;

    ok !$rep->is_passing, "Tests are not passing";
    is $rep->get_sign, "t4E", "1 failing test added";
    like $rep->get_tap, qr/^#.* planned 5.*but ran 4/m
        , "There's diag for bad plan";
};

done_testing;
