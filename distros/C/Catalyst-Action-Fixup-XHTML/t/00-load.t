#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::Action::Fixup::XHTML' );
}

diag( "Testing Catalyst::Action::Fixup::XHTML $Catalyst::Action::Fixup::XHTML::VERSION, Perl $], $^X" );
