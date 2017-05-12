#!perl -T

use strict;
use warnings;

use Business::CyberSource::Report;
use Scalar::Util qw();
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 7;


my $modules =
[
	qw(
		Business::CyberSource::Report::SingleTransaction
		Business::CyberSource::Report::PaymentEvents
	)
];

foreach my $module ( @$modules )
{
	use_ok( $module );
}

my $report_factory = Business::CyberSource::Report->new(
	merchant_id           => 'test_merchant_id',
	username              => 'test_username',
	password              => 'test_password',
	use_production_system => 0,
);

ok(
	defined(
		my $loaded_report_modules = $report_factory->list_loaded()
	),
	'Retrieve the loaded report modules.',
);

is(
	Scalar::Util::reftype( $loaded_report_modules ),
	'ARRAY',
	'The function returned an arrayref.',
);

is(
	scalar( @$loaded_report_modules ),
	2,
	'Find 2 loaded report modules.',
);

foreach my $module ( @$modules )
{
	my ( $module_name ) = ( $module =~ m/^\QBusiness::CyberSource::Report::\E([^\:]+)$/ );

	is(
		scalar( grep { $module_name eq $_ } @$loaded_report_modules ),
		1,
		"Detect loaded >$module_name<.",
	) || diag( 'Loaded modules: ', explain( $loaded_report_modules ) );
}
