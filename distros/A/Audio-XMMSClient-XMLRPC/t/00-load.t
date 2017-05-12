#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Audio::XMMSClient::XMLRPC' );
}

diag( "Testing Audio::XMMSClient::XMLRPC $Audio::XMMSClient::XMLRPC::VERSION, Perl $], $^X" );
