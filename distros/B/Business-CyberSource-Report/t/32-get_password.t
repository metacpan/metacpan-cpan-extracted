#!perl -T

use strict;
use warnings;

use Business::CyberSource::Report;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 1;


my $report_factory = Business::CyberSource::Report->new(
	merchant_id           => 'test_merchant_id',
	username              => 'test_username',
	password              => 'test_password',
	use_production_system => 0,
);

is(
	$report_factory->get_password(),
	'test_password',
	'Retrieve the password.',
);
