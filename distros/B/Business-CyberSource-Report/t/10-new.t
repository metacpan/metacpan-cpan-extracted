#!perl -T

use strict;
use warnings;

use Business::CyberSource::Report;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More;


my $tests =
[
	{
		merchant_id           => 'test_merchant_id',
		username              => 'test_username',
		password              => 'test_password',
		use_production_system => 1,
		test_name             => 'Create a new report factory object (dev).',
		expected_success      => 1,
	},
	{
		merchant_id           => 'test_merchant_id',
		username              => 'test_username',
		password              => 'test_password',
		use_production_system => 0,
		test_name             => 'Create a new report factory object (production).',
		expected_success      => 1,
	},
	{
		merchant_id           => undef,
		username              => 'test_username',
		password              => 'test_password',
		use_production_system => 1,
		test_name             => 'Require defined merchant ID.',
		expected_success      => 0,
	},
	{
		merchant_id           => '',
		username              => 'test_username',
		password              => 'test_password',
		use_production_system => 1,
		test_name             => 'Require non-empty-string merchant ID.',
		expected_success      => 0,
	},
	{
		merchant_id           => 'test_merchant_id',
		username              => 'test_username',
		password              => undef,
		use_production_system => 1,
		test_name             => 'Require defined password.',
		expected_success      => 0,
	},
	{
		merchant_id           => 'test_merchant_id',
		username              => 'test_username',
		password              => '',
		use_production_system => 1,
		test_name             => 'Require non-empty-string password.',
		expected_success      => 0,
	},
	{
		merchant_id           => 'test_merchant_id',
		username              => 'test_username',
		password              => 'test_password',
		test_name             => 'Create a new report factory object without specifying the environment.',
		expected_success      => 1,
	},
];

plan( tests => scalar( @$tests ) );

foreach my $test ( @$tests )
{
	my $merchant_id = delete( $test->{'merchant_id'} );
	my $username = delete( $test->{'username'} );
	my $password = delete( $test->{'password'} );
	my $use_production_system = delete( $test->{'use_production_system'} );
	my $test_name = delete( $test->{'test_name'} );
	my $expected_success = delete( $test->{'expected_success'} );

	my $report_options =
	{
		merchant_id           => $merchant_id,
		username              => $username,
		password              => $password,
		use_production_system => $use_production_system,
	};

	subtest(
		uc( $test_name ),
		sub
		{
			plan( tests => 2 );

			my $report_factory;
			if ( $expected_success )
			{
				lives_ok(
					sub
					{
						$report_factory = Business::CyberSource::Report->new(
							%$report_options
						);
					}
				);

				isa_ok(
					$report_factory,
					'Business::CyberSource::Report',
					'The report factory object',
				);
			}
			else
			{
				dies_ok(
					sub
					{
						$report_factory = Business::CyberSource::Report->new(
							%$report_options
						);
					}
				);

				ok(
					!defined( $report_factory ),
					'No report factory object is returned.',
				);
			}
		}
	);
}
