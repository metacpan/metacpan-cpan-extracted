#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'ACME::PM::Voronezh' ) || print "Bail out!
";
}

diag( "Testing ACME::PM::Voronezh $ACME::PM::Voronezh::VERSION, Perl $], $^X" );
