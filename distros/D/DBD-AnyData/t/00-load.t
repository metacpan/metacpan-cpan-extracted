#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'DBD::AnyData' ) || print "Bail out!
";
}

diag( "Testing DBD::AnyData $DBD::AnyData::VERSION, Perl $], $^X" );
