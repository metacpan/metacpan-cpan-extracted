#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'CGI::Wiki::Store::Mediawiki' );
}

diag( "Testing CGI::Wiki::Store::Mediawiki $CGI::Wiki::Store::Mediawiki::VERSION, Perl $], $^X" );
