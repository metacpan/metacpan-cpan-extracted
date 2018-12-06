#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Data::Cmp::StrOrNumeric qw(cmp_data);

subtest undef => sub {
    is(cmp_data(undef, undef), 0);
    is(cmp_data(undef, 0), -1);
    is(cmp_data(0, undef), 1);
};

subtest str => sub {
    is(cmp_data("", ""), 0);
    is(cmp_data("abc", "abc"), 0);
    is(cmp_data("abc", "ab"), 1);
    is(cmp_data("Abc", "abc"), -1);
    is(cmp_data(["Abc"], ["abc"]), -1);
};

subtest num => sub {
    is(cmp_data(10, 9), 1);
    is(cmp_data([10], [9]), 1);
};

subtest str_vs_num => sub {
    is(cmp_data("a", 0), 1);
};

subtest ref => sub {
    is(cmp_data([], 0), 2);
    is(cmp_data(0, []), 2);
    is(cmp_data([], {}), 2);
};

subtest obj => sub {
    is(cmp_data(bless([], "foo"), bless([], "bar")), 2);
    is(cmp_data(bless([], "foo"), bless([], "foo")), 0);
};

subtest array => sub {
    is(cmp_data([], []), 0);
    is(cmp_data([0], []), 1);
    is(cmp_data([0], [0,0]), -1);
    is(cmp_data([1], [0,0]), 1);
};

subtest hash => sub {
    is(cmp_data({}, {}), 0);
    is(cmp_data({a=>1}, {}), 1);
    is(cmp_data({a=>1}, {a=>1}), 0);
    is(cmp_data({a=>1}, {a=>1, b=>2}), -1);
    is(cmp_data({a=>1, c=>3, d=>4}, {a=>1, b=>2}), 1);
    is(cmp_data({a=>1, c=>3}, {a=>1, b=>2}), 2);
    is(cmp_data({a=>1}, {a=>0, b=>2}), 1);
    is(cmp_data({a=>1}, {b=>1}), 2);
};

subtest scalarref => sub {
    my $s1 = \1;
    is(cmp_data($s1, $s1), 0);
    is(cmp_data($s1, \1), 2);
};

DONE_TESTING:
done_testing;
