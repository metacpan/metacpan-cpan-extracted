#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 1;

use Assert::Refute {};
use Assert::Refute::T::Deep;

my $report = try_refute {
    cmp_deeply { mix => [ 3,1,2 ] }, { mix => bag( 1,2,3 ) }, "IF YOU SEE THIS, TEST FAILED";
    cmp_deeply { mix => [ 1,2,3,3 ] }, { mix => bag( 1,2,3 ) }, "Fail";
};

is $report->get_sign, "t1Nd", "Contract as expected";
note "<report>\n", $report->get_tap, "</report>";
