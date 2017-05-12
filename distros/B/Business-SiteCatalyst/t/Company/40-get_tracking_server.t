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
	: plan( tests => 6 );

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
		$response = $company->get_tracking_server( report_suite => $config->{'report_suite_id'} )
	),
	'Request tracking server - report suite specified.',
);

ok(
	Data::Validate::Type::is_string( $response, allow_empty => 0 ),
	'Retrieve tracking server - report suite specified.',
) || diag( explain( $response ) );

ok(
	defined(
		$response = $company->get_tracking_server()
	),
	'Request tracking server - report suite not specified.',
);

ok(
	Data::Validate::Type::is_string( $response, allow_empty => 0 ),
	'Retrieve tracking server - report suite not specified.',
) || diag( explain( $response ) );

