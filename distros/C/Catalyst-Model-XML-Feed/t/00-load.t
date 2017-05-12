#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::Model::XML::Feed' );
}

diag( "Testing Catalyst::Model::XML::Feed $Catalyst::Model::XML::Feed::VERSION, Perl $], $^X" );
