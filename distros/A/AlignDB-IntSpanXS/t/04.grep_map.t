#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 73;

BEGIN {
    use_ok('AlignDB::IntSpanXS');
}

#my $set = AlignDB::IntSpanXS->new("1-3,8,10-23");
#print "[ ", $set->grep_set(sub {$_ % 2}), " ]\n";
#print "[ ", $set->map_set(sub {$_ + 1}), " ]\n";

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
            my $set      = AlignDB::IntSpanXS->new( $sets[$s] );
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
        [ '-', '-',  '-',  '-',     '-',     '-' ],
        [ '-', '1',  '1',  '1',     '1',     '1' ],
        [ '-', '1',  '5',  '1-5',   '3-7',   '1-3,8,10-23' ],
        [ '-', '-1', '-5', '-5--1', '-7--3', '-23--10,-8,-3--1' ],
        [ '-', '6',  '10', '6-10',  '8-12',  '6-8,13,15-28' ],
        [ '-', '1',  '0',  '0-4',   '0-4',   '0-4' ],
        [   '-', '-1,1', '-5,5', '-5--1,1-5', '-7--3,3-7',
            '-23--10,-8,-3--1,1-3,8,10-23'
        ],
    );

    for ( my $s = 0; $s < @sets; $s++ ) {
        for ( my $m = 0; $m < @maps; $m++ ) {
            my $set      = new AlignDB::IntSpanXS $sets[$s];
            my $result   = $set->map_set( sub { eval $maps[$m] } );
            my $expected = $expected[$m][$s];

            printf "# map_set( sub { %-8s } ) from %-12s \n#\t-> %s\n",
                $maps[$m], $sets[$s], $result;

            is( $result->runlist(), $expected, "map|g$m|s$s" );
        }
    }
}

