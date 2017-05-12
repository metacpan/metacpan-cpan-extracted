#!perl -T

use strict;
use warnings;

use Data::Validate::Type;
use Test::Exception;
use Test::More;

use Business::SiteCatalyst;


eval 'use SiteCatalystConfig';
$@
	? plan( skip_all => 'Local connection information for Adobe SiteCatalyst required to run tests.' )
	: plan( tests => 4 );

my $config = SiteCatalystConfig->new();

# Create an object to communicate with Adobe SiteCatalyst
my $site_catalyst = Business::SiteCatalyst->new( %$config );
ok(
	defined( $site_catalyst ),
	'Create a new Business::SiteCatalyst object.',
);

ok(
	defined( 
		my $company = $site_catalyst->instantiate_company()
	),
	'Instantiate a new Business::SiteCatalyst::Company.',
);

my $response;
ok(
	defined(
		$response = $company->get_report_suites()
	),
	'Request report suites.',
);

ok(
	Data::Validate::Type::is_arrayref( $response ),
	'Retrieve response.',
) || diag( explain( $response ) );

