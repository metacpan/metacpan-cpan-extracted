#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::Helper::FastCGI::ExternalServer' );
}

diag( "Testing Catalyst::Helper::FastCGI::ExternalServer $Catalyst::Helper::FastCGI::ExternalServer::VERSION, Perl $], $^X" );
