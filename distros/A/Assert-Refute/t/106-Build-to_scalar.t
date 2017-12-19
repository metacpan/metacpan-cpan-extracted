#!/usr/bin/env perl

use strict;
use warnings;

# Avoid Test::More detection
use Assert::Refute::Build qw(to_scalar);
use Assert::Refute::T::Basic qw(deep_diff);
use Assert::Refute::Exec;

use Test::More;

note "TESTING to_scalar()";

is to_scalar(undef), "(undef)", "to_scalar undef";
is to_scalar(-42.137), -42.137, "to_scalar number";
is to_scalar("foo bar", 1), '"foo bar"', "to_scalar string";
is to_scalar("\t\0\n\"\\", 1), '"\\t\\0\\n\\"\\\\"', "to_scalar escape";

like to_scalar( Assert::Refute::Exec->new )
    , qr#Assert::Refute::Exec\{.*\}#
    , "to_scalar blessed";

like to_scalar( Assert::Refute::Exec->new, 0 )
    , qr#Assert::Refute::Exec/[a-f0-9]+#
    , "to_scalar blessed shallow";

is to_scalar( [] ), "[]", "to_scalar empty array";
is to_scalar( {} ), "{}", "to_scalar empty hash";

is to_scalar( [foo => 42] ), "[\"foo\", 42]", "array with scalars";
is to_scalar( {foo => 42} ), "{\"foo\":42}", "hash with scalars";

done_testing;
