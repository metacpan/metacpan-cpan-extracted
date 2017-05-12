#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::Plugin::I18N::DBI' );
}

diag( "Testing Catalyst::Plugin::I18N::DBI $Catalyst::Plugin::I18N::DBI::VERSION, Perl $], $^X" );
