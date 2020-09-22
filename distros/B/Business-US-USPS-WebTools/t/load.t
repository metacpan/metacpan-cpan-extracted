BEGIN {
	@classes = qw(
		Business::US::USPS::WebTools
		Business::US::USPS::WebTools::AddressStandardization
		Business::US::USPS::WebTools::ZipCodeLookup
		Business::US::USPS::WebTools::CityStateLookup
		);
	}

use Test::More tests => scalar @classes;

foreach my $class ( @classes ) {
	BAIL_OUT() unless use_ok( $class );
	}
