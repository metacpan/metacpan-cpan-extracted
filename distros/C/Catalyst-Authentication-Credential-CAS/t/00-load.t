#!perl -T

use Test::More tests => 1;

BEGIN {
  use_ok( 'Catalyst::Authentication::Credential::CAS' );
}

diag( "Testing Catalyst::Authentication::Credential::CAS, $Catalyst::Authentication::Credential::CAS::VERSION, Perl $], $^X" );
