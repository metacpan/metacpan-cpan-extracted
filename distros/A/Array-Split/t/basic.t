#!/usr/bin/perl
use strict;
use warnings;

BEGIN {
    use Cwd;
    chdir '..' if getcwd =~ m@/t$@;
    use lib 'lib';
}

package basic_tests;

use Test::Most;

use_ok( 'Array::Split', qw( split_by split_into ) );

my @by_res = split_by( 2, ( 1, 2, 3, 4, 5 ) );
is_deeply( \@by_res, [ [ 1, 2 ], [ 3, 4 ], [5] ] );

my @into_res = split_into( 2, ( 1, 2, 3, 4, 5 ) );
is_deeply( \@into_res, [ [ 1, 2, 3 ], [ 4, 5 ] ] );

done_testing();

exit;
