#!perl

use strict;
use warnings;
use Test::More;

use Assert::Refute qw(:core);
use Assert::Refute::T::Array;

my $rep;

$rep = contract {
    is_sorted{ 0 } [], "empty = sorted";
    is_sorted{ 0 } [1], "lone = sorted";
    is_sorted{ 0 } [1,2], "pair = unsorted";
}->apply;

contract_is $rep, "t2Nd", "Obvious cases";

$rep = contract {
    package T;
    use Assert::Refute::T::Array;
    use Assert::Refute::T::Basic qw(is);
    $a = "foo";
    is_sorted{ $a == $b } [ 1, 1, 1 ], "Holds";
    is_sorted{ $a == $b } [ 1, 1, 2 ], "Nope";
    is $a, "foo", "And \$a properly localized";
}->apply;

contract_is $rep, "t1N1d", "Actual work";
note "REPORT\n".$rep->get_tap."/REPORT";

$rep = contract {
    package T2;
    use Assert::Refute::T::Array;
    use Assert::Refute qw(:all);
    # Horrible, but it works...
    is_sorted{ cmp_ok $a, "<", $b, "Inside array" } [1,2,3], "Holds";
    is_sorted{ cmp_ok $a, "<", $b, "Inside array 2" } [1,2,2,3], "Nope";
}->apply;

contract_is $rep, "t4N1Nd", "Actual work";
note "REPORT\n".$rep->get_tap."/REPORT";

done_testing;
