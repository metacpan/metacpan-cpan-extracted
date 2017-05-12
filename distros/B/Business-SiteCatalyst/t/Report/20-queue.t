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
			type            => 'Ranked',
			report_suite_id => $config->{'report_suite_id'}
		) 
	),
	'Instantiate a new Business::SiteCatalyst::Report.',
);

my $response;
lives_ok(
	sub
	{
		$response = $report->queue(
			dateFrom      => "2012-04-01",
			dateTo        => "2012-04-15",
			metrics       => [{"id" => "instances"}],
			elements      => [{"id" => "referrer","top" => "5"}]
		);
	},
	'Queue report.',
);

ok(
	Data::Validate::Type::is_hashref( $response ),
	'Retrieve response.',
) || diag( explain( $response ) );

like(
	$response->{'reportID'},
	qr/^\d+$/,
	'reportID is a number.',
);

is(
	$response->{'status'},
	'queued',
	'Report is queued.',
);


ok(
	open( FILE, '>', 'business-sitecatalyst-report-reportid.tmp'),
	'Open temp file to store report id'
);
	
print FILE "$response->{'reportID'}";

ok(
	close FILE,
	'Close temp file'
);
