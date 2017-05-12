#!perl -T

use Test::More tests => 3;

BEGIN
{
	use_ok( 'Data::Dumper' );
	use_ok( 'Carp' );
	use_ok( 'Business::SiteCatalyst::Report' );
}

diag( "Testing Business::SiteCatalyst::Report $Business::SiteCatalyst::Report::VERSION, Perl $], $^X" );
