#!/usr/bin/env perl

use strict;
use warnings;
BEGIN{ delete @ENV{qw(NDEBUG PERL_NDEBUG)} };
use warnings FATAL => 'recursion';

# Avoid Test::More detection
use Assert::Refute::Build qw(to_scalar);
use Assert::Refute::T::Basic qw(deep_diff);
use Assert::Refute::Report;

use Test::More;

note "TESTING deep_diff() negative";

my $rep = Assert::Refute::Report->new;
$rep->is_deeply( undef, undef,                  "deep_diff undef" );
$rep->is_deeply( 42, 42 ,                       "deep_diff equal" );
$rep->is_deeply( [ foo => 42 ], [ foo => 42 ] , "deep_diff array" );
$rep->is_deeply( { foo => 42 }, { foo => 42 } , "deep_diff hash"  );
$rep->is_deeply( [ \*STDERR ], [ \*STDERR ] ,   "deep_diff the same object" );
$rep->done_testing;

is $rep->get_sign, "t5d", "All negative tests succeeded"
    or diag "<report>\n", $rep->get_tap, "</report>";

note "TESTING deep_diff() positive";

multi_like (
    scalar deep_diff(
            { foo => 42 },
            { foo => 137 }
    ),
    [
        qr/At.*\Q{foo}\E/,
        qr/Got *: *42/,
        qr/Expected *: *137/,
    ],
    "Scalar value mismatch",
);

multi_like (
    scalar deep_diff(
            { foo => { bar => {} }},
            { foo => { bar => [] }},
    ),
    [
        qr/At.*\Q{foo}{bar}\E/,
        qr/Got *: *\{\}/,
        qr/Expected *: *\[\]/,
    ],
    "Type mismatch",
);

multi_like (
    scalar deep_diff(
        { long => [ undef, undef ], short => [ undef, undef, undef ] },
        { long => [ undef, undef, undef ], short => [ undef, undef ] },
    ),
    [
        qr/At.*\Q{long}[2]\E/,
        qr/Got.*Does not exist/,
        qr/Expected.*undef/,
        qr/At.*\Q{short}[2]\E/,
        qr/Got.*undef/,
        qr/Expected.*Does not exist/,
    ],
    "Can tell apart missing from undef"
);

multi_like (
    scalar deep_diff(
        { long => [ undef, undef ], short => [ undef, undef, undef ] },
        { long => [ undef, undef, undef ], short => [ undef, undef ] },
        0,
    ),
    [
        qr/At.*\Q{long}[2]\E/,
        qr/Got.*Does not exist/,
        qr/Expected.*undef/,
    ],
    "Same as above, but short circuit"
);

multi_like (
    scalar deep_diff(
        { foo => { bar => 42 } },
        { foo => { baz => 42 } },
    ),
    [
        qr/At.*\Q{foo}{bar}\E/,
        qr/Got *: *42/,
        qr/Expected *: *Does not exist/,
        qr/At.*\Q{foo}{baz}\E/,
        qr/Got *: *Does not exist/,
        qr/Expected *: *42/,
    ],
    "Differing data structures explained correctly, multiple diff returned",
);

multi_like (
    scalar deep_diff(
        { foo => { bar => 42 } },
        { foo => { baz => 42 } },
        0,
    ),
    [
        qr/At.*\Q{foo}{bar}\E/,
        qr/Got *: *42/,
        qr/Expected *: *Does not exist/,
    ],
    "Same as above, short circuit",
);

my @very_long_spec;
for (1..10) {
    push @very_long_spec,
         qr/At .*\{\d+\}/,
         qr/Got *: *["']?\d+/,
         qr/Expected *: *Does not exist/;
};
multi_like (
    scalar deep_diff(
        { 11 .. 90 },
        {},
    ),
    \@very_long_spec,
    "A ton of difference - only 10 shown",
);


my $leaf1 = [];
my $leaf2 = [];

ok (
    !deep_diff(
        [ $leaf1, $leaf1 ],
        [ $leaf2, $leaf2 ],
    ),
    "Identical structures recognized correctly",
);

multi_like (
    scalar deep_diff(
        [ $leaf1, $leaf1 ],
        [ $leaf1, $leaf2 ],
    ),
    [
        qr/\[1\]/,
        qr/Got *: *Same as/,
        qr/Expected *: *\[\]/,
    ],
    "Tree > DAG"
);

multi_like (
    scalar deep_diff(
        [ $leaf1, $leaf2 ],
        [ $leaf1, $leaf1 ],
    ),
    [
        qr/\[1\]/,
        qr/Got *: *\[\]/,
        qr/Expected *: *Same as/,
    ],
    "DAG > Tree"
);

multi_like (
    scalar deep_diff(
        [ $leaf1, $leaf2, $leaf1 ],
        [ $leaf2, $leaf1, $leaf1 ],
    ),
    [
        qr/\[2\]/,
        qr/Got *: *Same as.*0/,
        qr/Expected *: *Same as.*1/,
    ],
    "Identical structure copied from different places"
);

my $loop3 = [];
push @$loop3, [[$loop3]];

my $loop5 = [];
push @$loop5, [[[[$loop5]]]];

multi_like (
    scalar deep_diff(
        $loop3,
        $loop5,
    ),
    [
        qr/\Q[0][0][0]\E/,
        qr/Got *: *Same as.*/,
        qr/Expected *: *\[\[/,
    ],
    "Looped structures separated correctly"
);

multi_like (
    scalar deep_diff(
        [ \*STDIN ],
        [ \*STDOUT ],
    ),
    [
        qr/At.*\Q[0]\E/,
        qr/Got *: /,
        qr/Expected *:/,
    ],
    "Different unknown objects just different"
);

done_testing;

sub multi_like {
    my ($array, $regexen, $message) = @_;

    if (ref $array ne 'ARRAY') {
        ok 0, "Not an array in multi_like";
        diag "Got: ", explain $array;
        return 0;
    };

    # Thanks haukex for this test
    # See https://www.perlmonks.org/?node_id=1217318
    subtest $message => sub {
        for (my $i = 0; $i < @$regexen; $i++ ) {
            if (ref $regexen->[$i] eq 'Regexp') {
                like $array->[$i], $regexen->[$i], "Line $i matches $regexen->[$i]";
            } else {
                is $array->[$i], $regexen->[$i], "Line $i equals ".explain($regexen->[$i]);
            }
        };
        is scalar @$array, scalar @$regexen,
            "Exactly ".scalar @$regexen." lines present";
    }
        or diag explain $array;
};
