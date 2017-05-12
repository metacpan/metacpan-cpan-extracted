#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 35;
use Scalar::Util qw(looks_like_number);

BEGIN {
    use_ok('AlignDB::IntSpan');
}

# find_islands
{
    my @find_tests = (
        [ "1-5",     1, "1-5" ],
        [ "1-5,7",   1, "1-5" ],
        [ "1-5,7",   6, "-" ],
        [ "1-5,7-8", 7, "7-8" ],
        [ "1-5,7",   7, "7" ],
        [ "1-5,8",   7, "-" ],
        [ "1-8",     7, "1-8" ],

        [ "1-8",           "7-8",  "1-8" ],
        [ "1-5,7-8",       "7-8",  "7-8" ],
        [ "1-5,8-9",       "7-8",  "8-9" ],
        [ "1-5,8-9,11-15", "9-11", "8-9,11-15" ],
    );

    my $count = 1;
    for my $t (@find_tests) {
        my $set = AlignDB::IntSpan->new( $t->[0] );
        my $n_set
            = looks_like_number( $t->[1] )
            ? $t->[1]
            : AlignDB::IntSpan->new( $t->[1] );
        my $expected = $t->[2];
        my $result   = $set->find_islands($n_set);

        printf "#%-12s %-12s %-12s -> %s\n", 'find_islands', $set->runlist,
            $n_set, $result->runlist;
        my $test_name = "find_islands|$count";
        is( $result->runlist, $expected, $test_name );
        $count++;
    }
    print "\n";
}

# nearest_island
{
    my @nearest_tests = (
        [ "1-5",     1,  "-" ],
        [ "1-5,7",   6,  "1-5,7" ],
        [ "1-5,7",   8,  "7" ],
        [ "1-5,7-8", 8,  "1-5" ],
        [ "1-5,7-8", 9,  "7-8" ],
        [ "1-5,7-8", 10, "7-8" ],
        [ "1-5,7-8", -5, "1-5" ],

        [ "1-5,7-8",   "-5--3", "1-5" ],
        [ "1-5,8-9",   "6-7",   "1-5,8-9" ],
        [ "1-5,10-15", "6-7",   "1-5" ],
    );

    my $count = 1;
    for my $t (@nearest_tests) {
        my $set = AlignDB::IntSpan->new( $t->[0] );
        my $n_set
            = looks_like_number( $t->[1] )
            ? $t->[1]
            : AlignDB::IntSpan->new( $t->[1] );
        my $expected = $t->[2];
        my $result   = $set->nearest_island($n_set);

        printf "#%-12s %-12s %-12s -> %s\n", 'nearest_island', $set->runlist,
            $n_set, $result->runlist;
        my $test_name = "nearest_island|$count";
        is( $result->runlist, $expected, $test_name );
        $count++;
    }
    print "\n";
}

# at_island
{
    my @at_tests = (
        [ "-",          0,  undef ],
        [ "-",          1,  undef ],
        [ "-",          -1, undef ],
        [ "1",          0,  undef ],
        [ "1",          1,  "1" ],
        [ "1",          -1, "1" ],
        [ "1-5",        1,  "1-5" ],
        [ "1-5,7",      1,  "1-5" ],
        [ "1-5,7",      2,  "7" ],
        [ "1-5,7-8",    1,  "1-5" ],
        [ "1-5,7-8",    2,  "7-8" ],
        [ "1-5,7-8,10", 3,  "10" ],
        [ "1-5,7-8,10", 4,  undef ],
    );

    my $count = 1;
    for my $t (@at_tests) {
        my $set      = AlignDB::IntSpan->new( $t->[0] );
        my $n        = $t->[1];
        my $expected = $t->[2];
        my $result   = $set->at_island($n);

        my $test_name = "at_island|$count";
        if ($expected) {
            printf "#%-12s %-12s %-12s -> %s\n", 'at_island', $set->runlist,
                $n, $result;
            is( $result->runlist, $expected, $test_name );
        }
        else {
            is( $result, $expected, $test_name );
        }
        $count++;
    }
    print "\n";
}
