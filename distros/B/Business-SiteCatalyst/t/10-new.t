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

isa_ok(
	$site_catalyst, 'Business::SiteCatalyst',
	'Return value of Business::SiteCatalyst->new()',
) || diag( explain( $site_catalyst ) );
