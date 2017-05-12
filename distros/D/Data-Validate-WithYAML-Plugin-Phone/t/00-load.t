#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Data::Validate::WithYAML::Plugin::Phone' );
}

diag( "Testing Data::Validate::WithYAML::Plugin::Phone $Data::Validate::WithYAML::Plugin::Phone::VERSION, Perl $], $^X" );
