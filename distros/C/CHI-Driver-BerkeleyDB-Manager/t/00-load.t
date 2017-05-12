#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'CHI::Driver::BerkeleyDB::Manager' ) || print "Bail out!
";
}

diag( "Testing CHI::Driver::BerkeleyDB::Manager $CHI::Driver::BerkeleyDB::Manager::VERSION, Perl $], $^X" );
