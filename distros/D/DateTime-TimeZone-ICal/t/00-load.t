#!perl -T

use Test::More tests => 3;

BEGIN {
    use_ok( 'DateTime::TimeZone::ICal' ) || print "Bail out!\n";
    use_ok( 'DateTime::TimeZone::ICal::Spec' ) || print "Bail out!\n";
    use_ok( 'DateTime::TimeZone::ICal::Parsing' ) || print "Bail out!\n";
}

diag( "Testing DateTime::TimeZone::ICal $DateTime::TimeZone::ICal::VERSION, Perl $], $^X" );
