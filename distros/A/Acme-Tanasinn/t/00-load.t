#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok( 'Acme::Tanasinn' ) || print "Bail out!";
}

diag( "Testing Acme::Tanasinn $Acme::Tanasinn::VERSION, Perl $], $^X" );

my $test_string = tanasinn("Don't perform tests with canned data, feel and you'll be tanasinn.");

like($test_string, qr/\x{2235}/, 'tanasinn');
