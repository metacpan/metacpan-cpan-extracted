#!perl -T

use strict;
use warnings;

use Test::FailWarnings;
use Test::More tests => 3;

use lib 't/';
use LocalTest;


my $tests =
[
	{
		'function_name' => 'is_hashref',
		'function_type' => 'boolean',
	},
	{
		'function_name' => 'assert_hashref',
		'function_type' => 'assert',
	},
	{
		'function_name' => 'filter_hashref',
		'function_type' => 'filter',
	},
];

foreach my $test ( @$tests )
{
	my $function_name = delete( $test->{'function_name'} );
	my $function_type = delete( $test->{'function_type'} );

	subtest(
		"Test function $function_name (type $function_type).",
		sub
		{
			plan( tests => 5 );

			subtest
			(
				'Test without arguments.',
				sub
				{
					LocalTest::ok_run_tests(
						function_name => $function_name,
						type          => $function_type,
						pass_tests    =>
						[
							qw(
								empty_hashref
								non_empty_hashref
								blessed_hashref
							)
						],
					);
				}
			);

			subtest
			(
				'Test with allow_empty=1.',
				sub
				{
					LocalTest::ok_run_tests(
						function_name => $function_name,
						type          => $function_type,
						function_args =>
						{
							allow_empty => 1,
						},
						pass_tests    =>
						[
							qw(
								empty_hashref
								non_empty_hashref
								blessed_hashref
							)
						],
					);
				}
			);

			subtest(
				'Test with allow_empty=0.',
				sub
				{
					LocalTest::ok_run_tests(
						function_name => $function_name,
						type          => $function_type,
						function_args =>
						{
							allow_empty => 0,
						},
						pass_tests    =>
						[
							qw(
								non_empty_hashref
								blessed_hashref
							)
						],
					);
				}
			);

			subtest(
				'Test with no_blessing=1.',
				sub
				{
					LocalTest::ok_run_tests(
						function_name => $function_name,
						type          => $function_type,
						function_args =>
						{
							no_blessing => 1,
						},
						pass_tests    =>
						[
							qw(
								empty_hashref
								non_empty_hashref
							)
						],
					);
				}
			);

			subtest(
				'Test with no_blessing=0.',
				sub
				{
					LocalTest::ok_run_tests(
						function_name => $function_name,
						type          => $function_type,
						function_args =>
						{
							no_blessing => 0,
						},
						pass_tests    =>
						[
							qw(
								empty_hashref
								non_empty_hashref
								blessed_hashref
							)
						],
					);
				}
			);
		}
	);
}
