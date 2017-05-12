#!perl -T

use strict;
use warnings;

use Test::More;

use Business::SiteCatalyst::Report;


eval 'use SiteCatalystConfig';
$@
	? plan( skip_all => 'Local connection information for Adobe SiteCatalyst required to run tests.' )
	: plan( tests => 3 );

my $config = SiteCatalystConfig->new();

like(
	$config->{'username'},
	qr/\w/,
	'The username is defined.',
);

like(
	$config->{'shared_secret'},
	qr/\w/,
	'The shared_secret is defined.',
);

like(
	$config->{'report_suite_id'},
	qr/\w/,
	'The report_suite_id is defined.',
);


