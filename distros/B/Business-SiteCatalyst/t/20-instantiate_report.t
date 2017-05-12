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

my $report = $site_catalyst->instantiate_report(
	type            => 'report type',
	report_suite_id => 'report suite id',
);

isa_ok(
	$report, 'Business::SiteCatalyst::Report',
	'Return value of Business::SiteCatalyst->instantiate_report()',
) || diag( explain( $report ) );
