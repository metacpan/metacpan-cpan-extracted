#!/usr/bin/env perl

use strict;
use warnings;
use Assert::Refute qw(:core);
use Test::More;

my $c = contract {
    package T;
    use Assert::Refute qw(:all);
    cmp_ok 1, "<", 2;
    cmp_ok 2, "<", 1;
    cmp_ok "a", "lt", "b";
    cmp_ok "a", "gt", "b";
    cmp_ok undef, "eq", '';
    cmp_ok undef, "==", undef;
}->apply;
is $c->get_sign, "t1N1NNNd", "Compare results";
note $c->get_tap;

my $ce = contract {
    package T;
    cmp_ok 1, "<<", 2;
}->apply;
is $ce->get_sign, 'tE', "Bad operator died";
like $ce->get_error, qr/cmp_ok.*Comparison.*<</, "Error as expected";

done_testing;
