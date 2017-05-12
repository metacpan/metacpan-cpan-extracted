#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'AppConfig::Exporter' );
}

diag( "Testing AppConfig::Exporter $AppConfig::Exporter::VERSION, Perl $], $^X" );
