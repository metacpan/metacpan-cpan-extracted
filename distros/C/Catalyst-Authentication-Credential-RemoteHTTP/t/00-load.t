#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Catalyst::Authentication::Credential::RemoteHTTP' ) || print "Bail out!
";
}

diag( "Testing Catalyst::Authentication::Credential::RemoteHTTP $Catalyst::Authentication::Credential::RemoteHTTP::VERSION, Perl $], $^X" );
