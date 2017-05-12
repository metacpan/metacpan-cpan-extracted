#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

use AlignDB::IntSpan;

my @sets = split ' ', q{ - 1 5 1-5 3-7 1-3,8,10-23 };

{

    my @greps = split ' ', q{1 0 $_==1 $_<5 $_&1};

    print "#grep_set\n";

    my @expected = (
        [ '-', '1', '5', '1-5',   '3-7',   '1-3,8,10-23' ],
        [ '-', '-', '-', '-',     '-',     '-' ],
        [ '-', '1', '-', '1',     '-',     '1' ],
        [ '-', '1', '-', '1-4',   '3-4',   '1-3' ],
        [ '-', '1', '5', '1,3,5', '3,5,7', '1,3,11,13,15,17,19,21,23' ],
    );

    for ( my $s = 0; $s < @sets; $s++ ) {
        for ( my $g = 0; $g < @greps; $g++ ) {
            my $set      = AlignDB::IntSpan->new( $sets[$s] );
            my $result   = $set->grep_set( sub { eval $greps[$g] } );
            my $expected = $expected[$g][$s];

            printf "# grep_set( sub { %-8s } ) from %-12s \n#\t-> %s\n",
                $greps[$g], $sets[$s], $result;

            is( $result->runlist(), $expected, "grep|g$g|s$s" );
        }
    }

    print "\n";
}

{
    my @maps = ( '', split( ' ', q{1 $_ -$_ $_+5 $_%5 -$_,$_} ) );

    print "#map_set\n";

    my @expected = (
        [ '-', '-',    '-',    '-',         '-',         '-' ],
        [ '-', '1',    '1',    '1',         '1',         '1' ],
        [ '-', '1',    '5',    '1-5',       '3-7',       '1-3,8,10-23' ],
        [ '-', '-1',   '-5',   '-5--1',     '-7--3',     '-23--10,-8,-3--1' ],
        [ '-', '6',    '10',   '6-10',      '8-12',      '6-8,13,15-28' ],
        [ '-', '1',    '0',    '0-4',       '0-4',       '0-4' ],
        [ '-', '-1,1', '-5,5', '-5--1,1-5', '-7--3,3-7', '-23--10,-8,-3--1,1-3,8,10-23' ],
    );

    for ( my $s = 0; $s < @sets; $s++ ) {
        for ( my $m = 0; $m < @maps; $m++ ) {
            my $set      = new AlignDB::IntSpan $sets[$s];
            my $result   = $set->map_set( sub { eval $maps[$m] } );
            my $expected = $expected[$m][$s];

            printf "# map_set( sub { %-8s } ) from %-12s \n#\t-> %s\n",
                $maps[$m], $sets[$s], $result;

            is( $result->runlist(), $expected, "map|g$m|s$s" );
        }
    }
}

# banish_span
{
    my @tests = (
        [ '-',          3, '-' ],
        [ '1',          3, '1' ],
        [ '5',          3, '4' ],
        [ '1,3,5',      3, '1,4' ],
        [ '1,3-5',      3, '1,3-4' ],
        [ '1-3,5,8-11', 3, '1-2,4,7-10' ],
    );

    my $count = 1;
    for my $t (@tests) {
        my $original = AlignDB::IntSpan->new( $t->[0] );
        my $expected = $t->[2];
        my $result   = $original->banish_span( $t->[1], $t->[1] )->runlist;

        my $test_name = "banish_span|$count";
        is( $result, $expected, $test_name );
        $count++;
    }
    print "\n";
}

# substr_span
{
    my $string = '123456789';
    my @tests = (
        [ '-',      '' ],
        [ '1',      '1' ],
        [ '5',      '5' ],
        [ '1,3,5',  '135' ],
        [ '1,3-5',  '1345' ],
    );

    my $count = 1;
    for my $t (@tests) {
        my $original = AlignDB::IntSpan->new( $t->[0] );
        my $expected = $t->[1];
        my $result   = $original->substr_span( $string );

        my $test_name = "substr_span|$count";
        is( $result, $expected, $test_name );
        $count++;
    }
    print "\n";
}

done_testing(83);
