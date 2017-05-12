#!perl -T

use Test::More tests => 3;

BEGIN
{
	use_ok( 'Data::Dumper' );
	use_ok( 'Carp' );
	use_ok( 'Business::SiteCatalyst' );
}

diag( "Testing Business::SiteCatalyst $Business::SiteCatalyst::VERSION, Perl $], $^X" );
