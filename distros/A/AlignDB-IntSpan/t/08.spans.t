#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

use AlignDB::IntSpan;

my $pos = AlignDB::IntSpan->new->POS_INF;
my $neg = AlignDB::IntSpan->new->NEG_INF;

my @tests = (
    [ '-',         '',              [] ],
    [ "$neg-$pos", "$neg-$pos",     [ [ $neg, $pos ] ] ],
    [ '-2--1',     '-2,-1',         [ [ -2, -1 ] ] ],
    [ '-',         '',              [] ],
    [ '0',         '0',             [ [ 0, 0 ] ] ],
    [ '1',         '1',             [ [ 1, 1 ] ] ],
    [ '1',         '1',             [ [ 1, 1 ] ] ],
    [ '-1',        '-1',            [ [ -1, -1 ] ] ],
    [ '1-2',       '1,2',           [ [ 1, 2 ] ] ],
    [ '-2--1',     '-2,-1',         [ [ -2, -1 ] ] ],
    [ '-2-1',      '-2,-1,0,1',     [ [ -2, 1 ] ] ],
    [ '1-4',       '1,2,3,4',       [ [ 1, 4 ] ] ],
    [ '1-7',       '1,2,3,4,5,6,7', [ [ 1, 7 ] ] ],
    [ '1-4',       '1,2,3,4',       [ [ 1, 4 ] ] ],
    [ '1-2,4-7',   '1,2,4,5,6,7',   [ [ 1, 2 ], [ 4, 7 ] ] ],
    [ "1-$pos", "1-$pos", [ [ 1, $pos ] ] ],
    [ "$neg-1", "$neg-1", [ [ $neg, 1 ] ] ],
    [ "-3,-1-$pos", "-3,-1-$pos", [ [ -3, -3 ], [ -1, $pos ] ] ],
    [ "$neg--1,3", "$neg--1,3", [ [ $neg, -1 ], [ 3, 3 ] ] ],
);

# spans
{
    my $count = 1;
    for my $t (@tests) {
        my $set      = AlignDB::IntSpan->new( $t->[0] );
        my @spans    = $set->spans;
        my $expected = $t->[2];

        my $test_name = "spans|$count";
        is_deeply( \@spans, $expected, $test_name );
        $count++;
    }
}

# ranges
{
    my $count = 1;
    for my $t (@tests) {
        my $set      = AlignDB::IntSpan->new( $t->[0] );
        my @ranges   = $set->ranges;
        my $expected = $t->[2];
        my @expected;
        for (@$expected) {
            push @expected, @$_;
        }

        my $test_name = "ranges|$count";
        is_deeply( \@ranges, \@expected, $test_name );
        $count++;
    }
}

# sets
{
    my $count = 1;
    for my $t (@tests) {
        my $set  = AlignDB::IntSpan->new( $t->[1] );
        my @sets = $set->sets;
        my @expected
            = map { $_ eq '-' ? () : AlignDB::IntSpan->new($_) } split /,/,
            $t->[0];

        my $test_name = "sets|$count";
        is_deeply( \@sets, \@expected, $test_name );
        $count++;
    }
}

# runlists
{
    my $count = 1;
    for my $t (@tests) {
        my $set      = AlignDB::IntSpan->new( $t->[1] );
        my @runlists = $set->runlists;
        my @expected = split /,/, $t->[0];

        my $test_name = "runlists|$count";
        is_deeply( \@runlists, \@expected, $test_name );
        $count++;
    }
}

done_testing(76);
