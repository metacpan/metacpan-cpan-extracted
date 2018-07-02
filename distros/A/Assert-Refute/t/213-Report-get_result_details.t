#!/usr/bin/env perl

# Test get_result_details
# This call is likely to evolve...

use strict;
use warnings;
use Assert::Refute {};

use Test::More tests => 4;

my $report = try_refute {
    my $rep = shift;
    $rep->diag( "premature text" );
    refute 0, "Passing test";
    refute [ 42, 137 ], "Failing test";
};

subtest "premature" => sub {
    my $hash = $report->get_result_details(0);
    is $hash->{ok}, undef, "ok undefined";
    is $hash->{reason}, undef, "No reason";
    is_deeply $hash->{log}, [ [ 0, -1, "premature text" ] ], "diag recorded";
};

subtest "passing test" => sub {
    my $hash = $report->get_result_details(1);
    is $hash->{ok}, 1, "ok positive";
    is $hash->{reason}, undef, "No reason";
    is_deeply $hash->{log}, [ ], "nothing logged";
};

subtest "failing test" => sub {
    my $hash = $report->get_result_details(2);
    is $hash->{ok}, '', "ok defined and false";
    is_deeply $hash->{reason}, [42, 137], "reason present";
    is_deeply $hash->{log}, [ [0, -1, 42], [0, -1, 137] ], "reason also logged";
};

subtest "tail notes" => sub {
    my $hash = $report->get_result_details(-1);
    is $hash->{ok}, undef, "ok undefined";
    is $hash->{reason}, undef, "No reason";
    is_deeply $hash->{log},
        [ [0, -1, "Looks like 1 tests out of 2 have failed" ] ],
        "Note about failing tests goes here";
};
