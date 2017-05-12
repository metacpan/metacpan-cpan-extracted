#!perl -T

use Test::More tests => 3;

BEGIN {
    use_ok( 'DateTime::Event::Jewish' ) || print "Bail out!";
    use_ok( 'DateTime::Event::Jewish::Sunrise' ) || print "Bail out (Sunrise)!";
    use_ok( 'DateTime::Event::Jewish::Parshah' ) || print "Bail out (Parshah)!";
}

diag( "Testing DateTime::Event::Jewish $DateTime::Event::Jewish::VERSION, Perl $], $^X" );
