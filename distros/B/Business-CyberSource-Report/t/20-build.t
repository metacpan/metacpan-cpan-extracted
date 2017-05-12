#!perl -T

use strict;
use warnings;

use Business::CyberSource::Report;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 4;


use_ok( 'Business::CyberSource::Report::SingleTransaction' );

my $report_factory = Business::CyberSource::Report->new(
	merchant_id           => 'test_merchant_id',
	username              => 'test_username',
	password              => 'test_password',
	use_production_system => 0,
);

my $report;
lives_ok(
	sub
	{
		$report = $report_factory->build( 'SingleTransaction' )
	},
	'Create a SingleTransaction report object.',
);

isa_ok(
	$report,
	'Business::CyberSource::Report::SingleTransaction',
	'The module object',
);

dies_ok(
	sub
	{
		$report = $report_factory->build( '_invalid_type_' )
	},
	'Create a report object of a type that does not exist.',
);
