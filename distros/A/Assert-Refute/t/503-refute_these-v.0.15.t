#!/usr/bin/env perl

use strict;
use warnings;
BEGIN{ delete @ENV{qw(NDEBUG PERL_NDEBUG)} };
use Test::More;
use Assert::Refute::T::Errors;

my $report;
warns_like {
    package T;
    use Assert::Refute {};
    $report = refute_these {
        refute 1, "If you see this message the tests have failed!";
    };
} [qr/refute_these.*DEPRECATED.*try_refute/], "Deprecated, alternative suggested";

isa_ok $report, "Assert::Refute::Report";
is $report->get_count, 1, "1 test in refute block";
ok !$report->is_passing, "... and it has failed";

done_testing;
