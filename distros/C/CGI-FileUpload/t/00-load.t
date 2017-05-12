#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'CGI::FileUpload' );
}

diag( "Testing CGI::FileUpload $CGI::FileUpload::VERSION, Perl $], $^X" );
