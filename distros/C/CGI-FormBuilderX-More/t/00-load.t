#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'CGI::FormBuilderX::More' );
}

diag( "Testing CGI::FormBuilderX::More $CGI::FormBuilderX::More::VERSION, Perl $], $^X" );
