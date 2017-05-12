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
		'function_name' => 'is_number',
		'function_type' => 'boolean',
	},
	{
		'function_name' => 'assert_number',
		'function_type' => 'assert',
	},
	{
		'function_name' => 'filter_number',
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
								zero
								one
								strictly_positive_integer
								strictly_negative_integer
								strictly_positive_float
								strictly_negative_float
							)
						],
					);
				}
			);

			subtest
			(
				'Test with positive=1.',
				sub
				{
					LocalTest::ok_run_tests(
						function_name => $function_name,
						type          => $function_type,
						function_args =>
						{
							positive => 1,
						},
						pass_tests    =>
						[
							qw(
								zero
								one
								strictly_positive_integer
								strictly_positive_float
							)
						],
					);
				}
			);

			subtest(
				'Test with positive=0.',
				sub
				{
					LocalTest::ok_run_tests(
						function_name => $function_name,
						type          => $function_type,
						function_args =>
						{
							positive => 0,
						},
						pass_tests    =>
						[
							qw(
								zero
								one
								strictly_positive_integer
								strictly_negative_integer
								strictly_positive_float
								strictly_negative_float
							)
						],
					);
				}
			);

			subtest(
				'Test with strictly_positive=1.',
				sub
				{
					LocalTest::ok_run_tests(
						function_name => $function_name,
						type          => $function_type,
						function_args =>
						{
							strictly_positive => 1,
						},
						pass_tests    =>
						[
							qw(
								one
								strictly_positive_integer
								strictly_positive_float
							)
						],
					);
				}
			);

			subtest(
				'Test with strictly_positive=0.',
				sub
				{
					LocalTest::ok_run_tests(
						function_name => $function_name,
						type          => $function_type,
						function_args =>
						{
							strictly_positive => 0,
						},
						pass_tests    =>
						[
							qw(
								zero
								one
								strictly_positive_integer
								strictly_negative_integer
								strictly_positive_float
								strictly_negative_float
							)
						],
					);
				}
			);
		}
	);
}
