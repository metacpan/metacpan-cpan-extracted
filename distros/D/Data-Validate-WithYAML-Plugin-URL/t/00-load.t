#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Data::Validate::WithYAML::Plugin::URL' );
}

diag( "Testing Data::Validate::WithYAML::Plugin::URL $Data::Validate::WithYAML::Plugin::URL::VERSION, Perl $], $^X" );
