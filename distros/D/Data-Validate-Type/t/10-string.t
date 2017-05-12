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
		'function_name' => 'is_string',
		'function_type' => 'boolean',
	},
	{
		'function_name' => 'assert_string',
		'function_type' => 'assert',
	},
	{
		'function_name' => 'filter_string',
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
			plan( tests => 3 );

			subtest(
				'Test without arguments.',
				sub
				{
					LocalTest::ok_run_tests(
						function_name => $function_name,
						type          => $function_type,
						pass_tests    =>
						[
							qw(
								empty_string
								zero
								one
								string
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
								empty_string
								zero
								one
								string
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
								zero
								one
								string
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
