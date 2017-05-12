#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 4;

BEGIN {
    use_ok('AlignDB::IntSpanXS');
}

# overload
{
    my @tests = ( [ "1-5", "1-5" ], [ "-", "-" ], [ "-1-5", "-1-5" ], );

    my $count = 1;
    for my $t (@tests) {
        my $set      = AlignDB::IntSpanXS->new( $t->[0] );
        my $exp_str  = $t->[1];

        my $result_str = "$set";

        my $test_name = "overload|$count";
        is( $result_str, $exp_str, $test_name );
        $count++;
    }
    print "\n";
}
