#!/usr/bin/env perl

use strict;
use warnings;

# Avoid Test::More detection
use Assert::Refute::Build qw(to_scalar);
use Assert::Refute::T::Basic qw(deep_diff);
use Assert::Refute::Exec;

use Test::More;

note "TESTING deep_diff() negative";

is deep_diff( undef, undef), '', "deep_diff undef";
is deep_diff( 42, 42 ), '', "deep_diff equal";
is deep_diff( [ foo => 42 ], [ foo => 42 ] ), '', "deep_diff array";
is deep_diff( { foo => 42 }, { foo => 42 } ), '', "deep_diff hash";

note "TESTING deep_diff() positive";
is deep_diff( { foo => { bar => 42 } }, { foo => { baz => 42 } } )
    , '{"foo":{"bar":42!=(none), "baz":(none)!=42}}'
    , "deep_diff diff!";

is deep_diff(
        { foo => [], bar => { baz => [1,2,3] } },
        { foo => {}, bar => { baz => [ 1,2 ] } },
    ), '{"bar":{"baz":[2:3!=(undef)]}, "foo":[]!={}}'
    , "Harder structure";

is_deeply {foo=>42}, {foo=>42}, "smoke the sub";

done_testing;
