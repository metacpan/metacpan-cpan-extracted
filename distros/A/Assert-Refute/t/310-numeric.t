#!perl

use strict;
use warnings;
BEGIN{ delete @ENV{qw(NDEBUG PERL_NDEBUG)} };
use Test::More;

use Assert::Refute {};
use Assert::Refute::T::Numeric;

note "TESTING is_between";

my $is_between = try_refute {
    is_between 3, 10, 100;
    is_between 10, 10, 100;
    is_between 30, 10, 100;
    is_between 100, 10, 100;
    is_between 300, 10, 100;

    is_between undef, 10, 100;
    is_between "foo", 10, 100;
};

contract_is $is_between, "tN3NNNd", "contract as expected";
like $is_between->get_result(1), qr/is not in/, "correct explanation";
like $is_between->get_result(5), qr/is not in/, "correct explanation";
like $is_between->get_result(6), qr/[Nn]ot a number/, "bad values processed";
like $is_between->get_result(7), qr/[Nn]ot a number/, "bad values processed";

my $within_delta = try_refute {
    within_delta 10.2, 10, .3;
    within_delta 10.2, 10, .1;
    within_delta undef, 10, .1;
    within_delta "foo", 10, .1;
};

contract_is $within_delta, "t1NNNd", "contract as expected";
like $within_delta->get_result(3), qr/[Nn]ot a number/, "bad values processed";
like $within_delta->get_result(4), qr/[Nn]ot a number/, "bad values processed";

my $within_rel = try_refute {
    within_relative 101, 100, 0.02;
    within_relative 103, 100, 0.02;
    within_relative undef, 100, 0.02;
    within_relative "foo", 100, 0.02;
};

contract_is $within_rel, "t1NNNd", "contract as expected";
like $within_rel->get_result(3), qr/[Nn]ot a number/, "bad values processed";
like $within_rel->get_result(4), qr/[Nn]ot a number/, "bad values processed";

done_testing;
