#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Authen::Krb5::Effortless' ) || print "Bail out!\n";
}

diag( "Testing Authen::Krb5::Effortless $Authen::Krb5::Effortless::VERSION, Perl $], $^X" );
