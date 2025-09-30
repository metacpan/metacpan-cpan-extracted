#!/usr/bin/env perl

use strict;
use warnings;
BEGIN{ delete @ENV{qw(NDEBUG PERL_NDEBUG)} };
use Test::More;
use Assert::Refute::T::Errors;

my $report;
dies_like {
    package T;
    use Assert::Refute {};
    $report = refute_these {
        refute 1, "If you see this message the tests have failed!";
    };
} qr/refute_these.*no more.*try_refute/, "Deprecated, alternative suggested";

done_testing;
