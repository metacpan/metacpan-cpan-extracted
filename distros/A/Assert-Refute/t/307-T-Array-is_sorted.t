#!perl

use strict;
use warnings;
BEGIN{ delete @ENV{qw(NDEBUG PERL_NDEBUG)} };
use Test::More;

use Assert::Refute qw(:core), {};
use Assert::Refute::T::Array;

my $report;

$report = try_refute {
    is_sorted{ 0 } [], "empty = sorted";
    is_sorted{ 0 } [1], "lone = sorted";
    is_sorted{ 0 } [1,2], "pair = unsorted";
};

contract_is $report, "t2Nd", "Obvious cases";

$report = try_refute {
    package T;
    use Assert::Refute::T::Array;
    use Assert::Refute::T::Basic qw(is);
    $a = "foo";
    is_sorted{ $a == $b } [ 1, 1, 1 ], "Holds";
    is_sorted{ $a == $b } [ 1, 1, 2 ], "Nope";
    is $a, "foo", "And \$a properly localized";
};

contract_is $report, "t1N1d", "Actual work";
note "REPORT\n".$report->get_tap."/REPORT";

$report = try_refute {
    package T2;
    use Assert::Refute::T::Array;
    use Assert::Refute qw(:all);
    # Horrible, but it works...
    is_sorted{ cmp_ok $a, "<", $b, "Inside array" } [1,2,3], "Holds";
    is_sorted{ cmp_ok $a, "<", $b, "Inside array 2" } [1,2,2,3], "Nope";
};

contract_is $report, "t4N1Nd", "Actual work";
note "REPORT\n".$report->get_tap."/REPORT";

done_testing;
