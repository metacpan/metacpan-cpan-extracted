#!perl -T

use Test::More tests => 3;

BEGIN
{
	use_ok( 'Data::Dumper' );
	use_ok( 'Carp' );
	use_ok( 'Business::SiteCatalyst::Company' );
}

diag( "Testing Business::SiteCatalyst::Company $Business::SiteCatalyst::Company::VERSION, Perl $], $^X" );
