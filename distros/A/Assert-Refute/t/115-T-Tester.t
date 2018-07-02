#!/usr/bin/env perl

# This script validates test_test refutation.
# Two report object are used:
#    1) $sample - a crafted contract execution log that contains data for tests
#    2) $report - a contract execution log that contains assertions
#       (some true, some not) about the former.
# We hereby verify that the second contract passes and fails
#     exactly as predicted, and test_test() refutation is thus
#     reliable enough to study other reports.

use strict;
use warnings;

# Assure we don't autodetect Test::More and adjust to it
use Assert::Refute::Report;
use Assert::Refute::T::Tester;

use Test::More;

my $sample = Assert::Refute::Report->new;
$sample->diag( "Testing T::Tester" );
$sample->refute( 0, "passing test" );
$sample->refute( 1, "failing test" );
$sample->refute( "reason", "very failing test" );
$sample->diag( "more data here" );
$sample->refute( [ {}, "isn't", 42 ], "multiline reason" );
$sample->done_testing;

is $sample->get_tap, q{# Testing T::Tester
ok 1 - passing test
not ok 2 - failing test
not ok 3 - very failing test
# reason
# more data here
not ok 4 - multiline reason
# {}
# isn't
# 42
# Looks like 3 tests out of 4 have failed
1..4
}, "self-test (fix hardcoded expected value if formatting changes)";

subtest "happy case" => sub {
    my $report = Assert::Refute::Report->new;
    $report->test_test(
        $sample->get_result_details(0),
        {
            diag => [
                qr/Testing T::Tester/,
            ],
        }
    );

    $report->test_test(
        $sample->get_result_details(1),
        {
            ok     => 1,
            diag   => [],
            name   => qr/passing/,
        }
    );

    $report->test_test(
        $sample->get_result_details(2),
        {
            ok     => 0,
            diag   => [],
        }
    );

    $report->test_test(
        $sample->get_result_details(3),
        {
            ok     => 0,
            diag   => [ "reason", qr/\bmore\b/ ],
        }
    );

    $report->test_test(
        $sample->get_result_details(4),
        {
            ok     => 0,
            diag   => [ "{}", qr/isn't/, qr/\d+/ ],
        }
    );

    $report->test_test(
        $sample->get_result_details(-1),
        {
            diag   => [ qr/Looks.*have failed/ ],
        }
    );

    $report->done_testing;
    is $report->get_sign, "t6d", "Tests above should pass"
        or diag "<report>\n", $report->get_tap, "</report>";
};

subtest "{ok} failure modes" => sub {
    my $report = Assert::Refute::Report->new;
    $report->test_test( $sample->get_result_details(1), { ok => 0 } );
    $report->test_test( $sample->get_result_details(1), { ok => 1 } );
    $report->test_test( $sample->get_result_details(2), { ok => 0 } );
    $report->test_test( $sample->get_result_details(2), { ok => 1 } );

    $report->done_testing;
    is $report->get_sign, "tN2Nd", "Deliberate fails & passes"
        or diag "<report>\n", $report->get_tap, "</report>";
};

subtest "{name} failure modes" => sub {
    my $report = Assert::Refute::Report->new;
    # this passes because undef is read as "do not check"
    $report->test_test( $sample->get_result_details(1), { name => undef } );
    $report->test_test( $sample->get_result_details(1), { name => "passing" } );
    $report->test_test( $sample->get_result_details(1), { name => qr/passing/ } );
    $report->test_test( $sample->get_result_details(1), { name => qr/fail/ } );

    $report->done_testing;
    is $report->get_sign, "t1N1Nd", "Deliberate fails & passes"
        or diag "<report>\n", $report->get_tap, "</report>";
};

subtest "{diag} failure modes" => sub {
    my $report = Assert::Refute::Report->new;
    $report->test_test(
        $sample->get_result_details(1),
        {
            diag => [
                qr/foo/,
            ],
        }
    );
    $report->test_test(
        $sample->get_result_details(2),
        {
            diag => [
                qr/bar/,
            ],
        }
    );
    $report->test_test(
        $sample->get_result_details(3),
        {
            diag => [
                qr/baz/,
            ],
        }
    );
    $report->test_test(
        $sample->get_result_details(3),
        {
            diag => [
            ],
        }
    );

    $report->done_testing;
    is $report->get_sign, "tNNNNd", "Deliberate fails"
        or diag "<report>\n", $report->get_tap, "</report>";
};

eval {
    my $report = Assert::Refute::Report->new;
    $report->test_test(
        $sample->get_result_details(1),
        {
            foobared => 42,
        }
    );
};
like $@, qr/Unknown.*foobared/, "Extra fields are not allowed";

eval {
    my $report = Assert::Refute::Report->new;
    $report->test_test(
        $sample->get_result_details(1),
        {
            diag => qr/zzz/,
        }
    );
};
like $@, qr/diag.*ARRAY/i, "diag != ARRAY not allowed";

done_testing;
