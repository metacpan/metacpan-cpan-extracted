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
	: plan( tests => 7 );

ok(
	open( FILE, 'business-sitecatalyst-report-reportid.tmp'),
	'Open temp file to read report id'
);

my $report_id;

ok(
	$report_id = do { local $/; <FILE> },
	'Read in previously queued report id'
);

ok(
	close FILE,
	'Close temp file'
);

my $config = SiteCatalystConfig->new();

# Create an object to communicate with Adobe SiteCatalyst
my $site_catalyst = Business::SiteCatalyst->new( %$config );
ok(
	defined( $site_catalyst ),
	'Create a new Business::SiteCatalyst object.',
);

ok(
	defined( 
		my $report = $site_catalyst->instantiate_report(
			report_id => $report_id,
		)
	),
	'Instantiate a new Business::SiteCatalyst::Report.',
);

my $response;
lives_ok(
	sub
	{
		$response = $report->cancel();
		die "No response" unless defined $response;
	},
	'Cancel report.',
);

ok(
	Data::Validate::Type::is_number( $response ),
	'Response is a number.',
);

