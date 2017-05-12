#!perl

use 5.010;
use strict;
use warnings;

use Test::More 0.98;

use Data::Circular::Util qw(
                               has_circular_ref
                               clone_circular_refs
                       );

subtest has_circular_ref => sub {
    ok(!has_circular_ref(undef), "undef");
    ok(!has_circular_ref("x"), "x");
    ok(!has_circular_ref([]), "[]");
    ok(!has_circular_ref([[], []]), "[[], []]");

    my $a;
    $a = []; push @$a, $a;
    ok( has_circular_ref($a), "circ array 1");
    my $b = [1];
    $a = [$b, $b];
    ok( has_circular_ref($a), "circ array 2");

    $a = {k1=>$b, k2=>$b};
    ok( has_circular_ref($a), "circ hash 1");
};

subtest clone_circular_refs => sub {
    ok(clone_circular_refs(undef), "undef");
    ok(clone_circular_refs("x"), "x");
    ok(clone_circular_refs([]), "[]");
    ok(clone_circular_refs([[], []]), "[[], []]");

    my $b = [];
    my $a = [$b, $b, $b];
    ok(clone_circular_refs($a), "circ 1 status");
    is_deeply($a, [[], [], []], "circ 1 result");

    $a = [1]; push @$a, $a;
    ok(!clone_circular_refs($a), "circ 2 status");
};

DONE_TESTING:
done_testing;
