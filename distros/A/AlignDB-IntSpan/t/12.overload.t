#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 5;

BEGIN {
    use_ok('AlignDB::IntSpan');
}

# overload
{
    my @tests = (
        [ "1-5",     1, "1-5" ],
        [ "-",   0, "-" ],
    );

    my $count = 1;
    for my $t (@tests) {
        my $set = AlignDB::IntSpan->new( $t->[0] );
        my $exp_bool = $t->[1];
        my $exp_str = $t->[2];

        my $result_bool   = $set ? 1 : 0;
        my $result_str   = "$set";

        my $test_name = "overload|$count";
        is( $result_bool, $exp_bool, $test_name );
        is( $result_str, $exp_str, $test_name );
        $count++;
    }
    print "\n";
}
