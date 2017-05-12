#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 16;

BEGIN {
    use_ok('AlignDB::IntSpan');
}

# overlap
{
    my @overlap_sets = (
        [ "1",     "1",    1 ],
        [ "1",     "2",    0 ],
        [ "1-5",   "1-10", 5 ],
        [ "1-5,6", "6-10", 1 ],
    );

    my $count = 1;
    for my $t (@overlap_sets) {
        my $set1     = AlignDB::IntSpan->new( $t->[0] );
        my $set2     = AlignDB::IntSpan->new( $t->[1] );
        my $ol       = $set1->overlap($set2);
        my $expected = $t->[2];

        printf( "#overlap %s -> %s\n", $ol, $expected );
        my $test_name = "overlap|$count";
        is( $ol, $expected, $test_name );
        $count++;
    }
    print "\n";
}

# distance
{
    my @distance_sets = (
        [ "1",         "1",     -1 ],
        [ "1",         "2",     1 ],
        [ "1-5",       "1-10",  -5 ],
        [ "1-5,6",     "6-10",  -1 ],
        [ "1-5",       "10-15", 5 ],
        [ "1-5,10-15", "5-9",   -1 ],
        [ "1-5,10-15", "6",     1 ],
        [ "1-5,10-15", "7",     2 ],
        [ "1-5,10-15", "7-9",   1 ],
        [ "1-5,10-15", "16-20", 1 ],
        [ "1-5,10-15", "17-20", 2 ],
    );

    my $count = 1;
    for my $t (@distance_sets) {
        my $set1     = AlignDB::IntSpan->new( $t->[0] );
        my $set2     = AlignDB::IntSpan->new( $t->[1] );
        my $distance = $set1->distance($set2);
        my $expected = $t->[2];

        printf( "#distance %s -> %s\n", $distance, $expected );
        my $test_name = "distance|$count";
        is( $distance, $expected, $test_name );
        $count++;
    }
    print "\n";
}
