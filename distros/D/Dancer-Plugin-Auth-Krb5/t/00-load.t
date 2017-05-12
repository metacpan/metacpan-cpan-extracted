#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dancer::Plugin::Auth::Krb5' ) || print "Bail out!\n";
}

diag( "Testing Dancer::Plugin::Auth::Krb5 $Dancer::Plugin::Auth::Krb5::VERSION, Perl $], $^X" );
