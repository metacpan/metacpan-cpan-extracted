#!perl -T

use Test::More tests => 2;

BEGIN {
	use_ok( 'Data::RuledValidator' );
	use_ok( 'Data::RuledValidator::Plugin::Japanese' );
}

diag( "Testing Data::RuledValidator::Plugin::Japanese $Data::RuledValidator::Plugin::Japanese::VERSION, Perl $], $^X" );
