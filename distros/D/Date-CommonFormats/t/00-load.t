#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Date::CommonFormats' ) || print "Bail out!
";
}

diag( "Testing Date::CommonFormats $Date::CommonFormats::VERSION, Perl $], $^X" );
