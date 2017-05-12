#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Data::Validate::WithYAML::Plugin::EMail' );
}

diag( "Testing Data::Validate::WithYAML::Plugin::EMail $Data::Validate::WithYAML::Plugin::EMail::VERSION, Perl $], $^X" );
