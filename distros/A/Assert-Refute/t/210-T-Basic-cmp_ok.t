#!/usr/bin/env perl

use strict;
use warnings;
use Assert::Refute qw(:core);
use Test::More;

my $c = contract {
    package T;
    use Assert::Refute;
    cmp_ok 1, "<", 2;
    cmp_ok 2, "<", 1;
    cmp_ok "a", "lt", "b";
    cmp_ok "a", "gt", "b";
    cmp_ok undef, "eq", '';
    cmp_ok undef, "==", undef;
}->apply;
is $c->signature, "t1N1NNNd", "Compare results";
note $c->as_tap;

my $ce = contract {
    package T;
    cmp_ok 1, "<<", 2;
}->apply;
is $ce->signature, 'tNE', "Bad operator died";
like $ce->last_error, qr/cmp_ok.*Comparison.*<</, "Error as expected";

done_testing;
