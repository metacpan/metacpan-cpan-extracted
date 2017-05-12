#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Data::Validate::WithYAML::Plugin::NoSpam' );
}

diag( "Testing Data::Validate::WithYAML::Plugin::NoSpam $Data::Validate::WithYAML::Plugin::NoSpam::VERSION, Perl $], $^X" );
