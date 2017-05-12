#!perl -T

use strict;
use warnings;

use Business::CyberSource::Report;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 4;


foreach my $use_production_system ( 0..1 )
{
	my $report_factory = Business::CyberSource::Report->new(
		merchant_id           => 'test_merchant_id',
		username              => 'test_username',
		password              => 'test_password',
		use_production_system => $use_production_system,
	);

	ok(
		defined( $report_factory ),
		'Create a report using the dev environment.',
	);

	is(
		$report_factory->use_production_system(),
		$use_production_system,
		'The report factory is specifying the correct environment.',
	);
}
