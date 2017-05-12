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
	: plan( tests => 5 );

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
	$response = $company->get_token_usage(),
	'Get current token usage statistics.',
);

ok(
	Data::Validate::Type::is_hashref( $response ),
	'Retrieve response.',
) || diag( explain( $response ) );

cmp_ok(
	$response->{'allowed_tokens'},
	'==',
	10000,
	'Allowed tokens total is 10,000.',
	) || diag ( explain( $response->{'allowed_tokens'} ) );
