#!perl -T

use strict;
use warnings;

use Test::More tests => 1;

use Business::SiteCatalyst;


# Create an object to communicate with Adobe SiteCatalyst.
my $site_catalyst = Business::SiteCatalyst->new(
		username               => 'XXXXXXXX',
		shared_secret          => 'XXXXXXXXXXXXXXXXXXXXXXXXX',
);

my $company = $site_catalyst->instantiate_company();

isa_ok(
	$company, 'Business::SiteCatalyst::Company',
	'Return value of Business::SiteCatalyst->instantiate_company()',
) || diag( explain( $company ) );
