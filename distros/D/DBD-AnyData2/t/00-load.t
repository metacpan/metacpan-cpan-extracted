#!perl

use 5.008;
use strict;
use warnings FATAL => 'all';

use Test::More;

BEGIN {
    use_ok( 'DBD::AnyData2' ) || BAIL_OUT "Couldn't load DBD::AnyData2";
}

diag( "Testing DBD::AnyData2 $DBD::AnyData2::VERSION, Perl $], $^X" );

done_testing;
