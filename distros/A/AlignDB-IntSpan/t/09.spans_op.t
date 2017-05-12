#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

use AlignDB::IntSpan;

my $pos = AlignDB::IntSpan->new->POS_INF;
my $neg = AlignDB::IntSpan->new->NEG_INF;

# cover
{
    my @cover_tests = (
        [ '-',          '-' ],
        [ '1',          '1' ],
        [ '5',          '5' ],
        [ '1,3,5',      '1-5' ],
        [ '1,3-5',      '1-5' ],
        [ '1-3,5,8-11', '1-11' ],
    );

    my $count = 1;
    for my $t (@cover_tests) {
        my $original = AlignDB::IntSpan->new( $t->[0] );
        my $expected = $t->[1];
        my $result   = $original->cover->runlist;

        printf "#%-12s %-12s -> %-12s\n", "cover", $original, $result;
        my $test_name = "cover|$count";
        is( $result, $expected, $test_name );
        $count++;
    }
    print "\n";
}

# holes
{
    my @holes_tests = (
        [ '-',          '-' ],
        [ '1',          '-' ],
        [ '5',          '-' ],
        [ '1,3,5',      '2,4' ],
        [ '1,3-5',      '2' ],
        [ '1-3,5,8-11', '4,6-7' ],
    );

    my $count = 1;
    for my $t (@holes_tests) {
        my $original = AlignDB::IntSpan->new( $t->[0] );
        my $expected = $t->[1];
        my $result   = $original->holes->runlist;

        printf "#%-12s %-12s -> %-12s\n", "holes", $original, $result;
        my $test_name = "holes|$count";
        is( $result, $expected, $test_name );
        $count++;
    }
    print "\n";
}

# inset, trim, pad
{

    my @inset_tests = (
        [ '-', -2, '-' ],
        [ '-', -1, '-' ],
        [ '-', 0,  '-' ],
        [ '-', 1,  '-' ],
        [ '-', 2,  '-' ],

        [ "$neg-$pos", -2, "$neg-$pos" ],
        [ "$neg-$pos", 2,  "$neg-$pos" ],

        [ "$neg-0", -2, "$neg-2" ],
        [ "$neg-0", 2,  "$neg--2" ],

        [ "0-$pos", -2, "-2-$pos" ],
        [ "0-$pos", 2,  "2-$pos" ],

        [ '0,2-3,6-8,12-15,20-24,30-35', -2, '-2-26,28-37' ],
        [ '0,2-3,6-8,12-15,20-24,30-35', -1, '-1-9,11-16,19-25,29-36' ],
        [ '0,2-3,6-8,12-15,20-24,30-35', 0,  '0,2-3,6-8,12-15,20-24,30-35' ],
        [ '0,2-3,6-8,12-15,20-24,30-35', 1,  '7,13-14,21-23,31-34' ],
        [ '0,2-3,6-8,12-15,20-24,30-35', 2,  '22,32-33' ],
    );

    my $count = 1;
    for my $t (@inset_tests) {
        my $set      = AlignDB::IntSpan->new( $t->[0] );
        my $n        = $t->[1];
        my $expected = AlignDB::IntSpan->new( $t->[2] );
        my $result   = $set->inset($n);

        printf "#%-12s %-12s %d -> %s\n", 'inset', $set->runlist, $n, $result->runlist;
        my $test_name = "inset|$count";
        ok( $result->equal($expected), $test_name );
        $count++;
    }

    ok( AlignDB::IntSpan->new('1-3')->pad(1)->size == 5,  'pad' );
    ok( AlignDB::IntSpan->new('1-3')->trim(1)->size == 1, 'trim' );
    print "\n";
}

# excise
{
    my @excise_tests = (
        [ "1-5",        1, "1-5" ],
        [ "1-5,7",      1, "1-5,7" ],
        [ "1-5,7",      2, "1-5" ],
        [ "1-5,7-8",    1, "1-5,7-8" ],
        [ "1-5,7-8",    3, "1-5" ],
        [ "1-5,7-8",    6, "-" ],
        [ "1-5,7,9-10", 0, "1-5,7,9-10" ],
    );

    my $count = 1;
    for my $t (@excise_tests) {
        my $set      = AlignDB::IntSpan->new( $t->[0] );
        my $n        = $t->[1];
        my $expected = AlignDB::IntSpan->new( $t->[2] );
        my $result   = $set->excise($n);

        printf "#%-12s %-12s %d -> %s\n", 'excise', $set->runlist, $n, $result->runlist;
        my $test_name = "excise|$count";
        ok( $result->equal($expected), $test_name );
        $count++;
    }
}

# fill
{
    my @fill_tests = (
        [ "1-5",               1, "1-5" ],
        [ "1-5,7",             1, "1-7" ],
        [ "1-5,7",             2, "1-7" ],
        [ "1-5,7-8",           1, "1-8" ],
        [ "1-5,9-10",          2, "1-5,9-10" ],
        [ "1-5,9-10",          3, "1-10" ],
        [ "1-5,9-10,12-13,15", 2, "1-5,9-15" ],
        [ "1-5,9-10,12-13,15", 3, "1-15" ],
    );

    my $count = 1;
    for my $t (@fill_tests) {
        my $set      = AlignDB::IntSpan->new( $t->[0] );
        my $n        = $t->[1];
        my $expected = AlignDB::IntSpan->new( $t->[2] );
        my $result   = $set->fill($n);

        printf "#%-12s %-12s %d -> %s\n", 'fill', $set->runlist, $n, $result->runlist;
        my $test_name = "fill|$count";
        ok( $result->equal($expected), $test_name );
        $count++;
    }
}

done_testing(45);
