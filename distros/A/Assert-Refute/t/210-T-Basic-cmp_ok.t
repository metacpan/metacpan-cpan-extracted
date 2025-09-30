#!/usr/bin/env perl

use strict;
use warnings;
use Assert::Refute qw(:core);
use Test::More;

my $report = refute_and_report {
    package T;
    use Assert::Refute qw(:all);
    cmp_ok 1, "<", 2;
    cmp_ok 2, "<", 1;
    cmp_ok "a", "lt", "b";
    cmp_ok "a", "gt", "b";
    cmp_ok undef, "eq", '';
    cmp_ok undef, "==", undef;
};
is $report->get_sign, "t1N1NNNd", "Compare results";
note $report->get_tap;

my $deadman;
eval {
    $deadman = refute_and_report {
        package T;
        cmp_ok 1, "<<", 2;
    }
};
my $err = $@;
is $deadman, undef, "Bad operator died";
like $err, qr/cmp_ok.*Comparison.*<</, "Error as expected";

done_testing;
