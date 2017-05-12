#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Date::Holidays::BR' ) || print "Bail out!
";
}

diag( "Testing Date::Holidays::BR $Date::Holidays::BR::VERSION, Perl $], $^X" );
