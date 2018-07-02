#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Assert::Refute::T::Errors;
use Assert::Refute::Report;

my $report = Assert::Refute::Report->new;

dies_like {
    $report->set_result(1, 42);
} qr/set_result.*removed/, "set_result is no more available";
# If this test starts failing, should probably be just removed.

done_testing;
