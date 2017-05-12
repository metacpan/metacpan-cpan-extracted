#!perl -T

use strict;
use warnings;

use Data::Validate::Type;
use Test::FailWarnings;
use Test::More tests => 3;

use lib 't/';
use LocalTest;


my $tests =
[
	{
		'function_name' => 'is_arrayref',
		'function_type' => 'boolean',
	},
	{
		'function_name' => 'assert_arrayref',
		'function_type' => 'assert',
	},
	{
		'function_name' => 'filter_arrayref',
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
			plan( tests => 6 );

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
								empty_arrayref
								non_empty_arrayref
								blessed_arrayref
								arrayref_of_hashrefs
								arrayref_of_mixed_data
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
								empty_arrayref
								non_empty_arrayref
								blessed_arrayref
								arrayref_of_hashrefs
								arrayref_of_mixed_data
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
								non_empty_arrayref
								blessed_arrayref
								arrayref_of_hashrefs
								arrayref_of_mixed_data
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
								empty_arrayref
								non_empty_arrayref
								arrayref_of_hashrefs
								arrayref_of_mixed_data
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
								empty_arrayref
								non_empty_arrayref
								blessed_arrayref
								arrayref_of_hashrefs
								arrayref_of_mixed_data
							)
						],
					);
				}
			);

			subtest(
				'Test element_validate_type with a hashref.',
				sub
				{
					LocalTest::ok_run_tests(
						function_name => $function_name,
						type          => $function_type,
						function_args =>
						{
							element_validate_type => sub
							{
								return Data::Validate::Type::is_hashref( $_[0] );
							},
						},
						pass_tests    =>
						[
							qw(
								empty_arrayref
								arrayref_of_hashrefs
							)
						],
					);
				}
			);
		}
	);
}
