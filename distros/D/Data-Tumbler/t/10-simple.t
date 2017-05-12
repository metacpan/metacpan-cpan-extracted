#!/usr/bin/env perl
use warnings;
use strict;

use Test::Most;
use Data::Dumper;

use Data::Tumbler;

my @output;

my $tumbler = Data::Tumbler->new(
    consumer  => sub {
        my ($names, $values, $payload) = @_;
        push @output, [ $names, $values, $payload ];
    },
);

my $names = [];
my $values = [];
my $payload = 42;

$tumbler->tumble(
    [   # provider code refs
        sub { (foo => 42, bar => 24, baz => 19) },
        sub { (ping => 1, pong => 2) },
        # ...
    ],
    $names,
    $values,
    $payload,
);

eq_or_diff \@output, [
        [ [ 'bar', 'ping' ], [ 24, 1 ], 42 ],
        [ [ 'bar', 'pong' ], [ 24, 2 ], 42 ],
        [ [ 'baz', 'ping' ], [ 19, 1 ], 42 ],
        [ [ 'baz', 'pong' ], [ 19, 2 ], 42 ],
        [ [ 'foo', 'ping' ], [ 42, 1 ], 42 ],
        [ [ 'foo', 'pong' ], [ 42, 2 ], 42 ]
    ]
    or warn Dumper(\@output);

# TODO
# test arguments to providers
# test returning nothing
# test dclone of ref payload
#

done_testing;
