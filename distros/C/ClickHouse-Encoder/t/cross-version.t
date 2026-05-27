#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch';
use ClickHouse::Encoder;
use Digest::SHA qw(sha1_hex);

# Generate-and-pin: for each pinned (schema, rows) pair, assert the
# encoder still produces a buffer with the expected SHA-1. Catches
# accidental wire-format regressions across refactors, simplifier
# passes, or upstream changes that touch encode emission.
#
# Update fixtures by running the script with PIN=1; the new hashes
# print to STDOUT for committing. Don't update casually - every change
# should be explained.

my @fixtures = (
    {
        name => 'scalars',
        cols => [
            ['i', 'Int32'], ['u', 'UInt64'], ['s', 'String'],
            ['f', 'Float64'], ['b', 'Bool'], ['n', 'Nullable(Int32)']],
        rows => [
            [-1, 1, 'a', 1.5, 1, 10],
            [2,  '18446744073709551615', '', -3.14, 0, undef],
        ],
        sha => 'ec120add8295b459615a6b6d7d78cf0792e5dbf1',
    },
    {
        name => 'arrays',
        cols => [
            ['t', 'Array(String)'],
            ['n', 'Array(Nullable(Int32))']],
        rows => [
            [['a','b','c'], [1, undef, 3]],
            [[],            []],
        ],
        sha => '2bfd3219e1674367dc3142bb9f2d070406f08381',
    },
    {
        name => 'lc',
        cols => [['c', 'LowCardinality(String)']],
        rows => [['x'], ['y'], ['x'], ['x']],
        sha => 'bd5e572a38d59f8070002ae4f1688dc422057c6e',
    },
    {
        name => 'tuple-named',
        cols => [['t', 'Tuple(a Int32, b String)']],
        rows => [[[1,'one']], [[2,'two']]],
        sha => 'a2ef15e7b5db8be389c975a112781644c808b2c3',
    },
    {
        name => 'variant',
        cols => [['v', 'Variant(UInt32, String)']],
        rows => [[[0, 42]], [[1, 'hi']], [undef]],
        sha => '81b2ade710e4ebe7ff276842a3f26a31ca29b70a',
    },
);

# When PIN=1, recompute and print the SHA-1 line for each fixture so
# we can update the table above.
my $pin = $ENV{PIN};

for my $f (@fixtures) {
    my $enc = ClickHouse::Encoder->new(columns => $f->{cols});
    my $bytes = $enc->encode($f->{rows});
    my $got = sha1_hex($bytes);
    if ($pin) {
        print "  { name => '$f->{name}', sha => '$got' },\n";
        next;
    }
    is($got, $f->{sha}, "$f->{name}: wire-format SHA-1 stable")
        or diag("if this is an intentional encoder change, "
              . "rerun with PIN=1 to refresh fixtures");
}

done_testing();
