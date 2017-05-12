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
	: plan( tests => 8 );

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

isa_ok(
	$report, 'Business::SiteCatalyst::Report',
	'Return value of Business::SiteCatalyst->new()',
) || diag( explain( $report ) );


my $is_ready = 0;
subtest(
	'Verify that is_ready() eventually returns true',
	sub
	{
		plan( tests => 20 );
		
		for ( my $i = 0; $i < 20; $i++ )
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

is
(
	$is_ready,
	1,
	'The report is ready.',
);

