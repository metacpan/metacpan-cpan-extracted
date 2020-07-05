#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Data::Validate::WithYAML::Plugin::EmailMX' );
}

diag( "Testing Data::Validate::WithYAML::Plugin::EmailMX $Data::Validate::WithYAML::Plugin::EmailMX::VERSION, Perl $], $^X" );
