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
	: plan( tests => 9 );

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


# In case this report takes a bit to complete, check that it is actually ready before attempting to retrieve
my $is_ready = 0;
subtest(
	'Verify that is_ready() eventually returns true',
	sub
	{
		plan( tests => 5 );
		
		for ( my $i = 0; $i < 5; $i++ )
		{
			SKIP: {
				skip 'Report is ready', 1 if $is_ready;
				$is_ready = $report->is_ready();
			
				like (
					$is_ready,
					qr/^[01]$/,
					'Check if is_ready() returns a boolean.',
				);
			}
		}
	}
);

lives_ok(
	sub
	{
		$response = $report->retrieve();
		die "No response" unless defined $response;
	},
	'Retrieve report.',
);

ok(
	defined( $response->{'data'} ),
	'We have a "data" block in the response.',
);

ok(
	Data::Validate::Type::is_arrayref( $response->{'data'} ),
	'"data" block is an arrayref.',
);

