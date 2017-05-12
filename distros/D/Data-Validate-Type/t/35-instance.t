#!perl -T

use strict;
use warnings;

use Test::Exception;
use Test::FailWarnings;
use Test::More tests => 5;

use lib 't/';
use LocalTest;


# Make sure the class argument is required.
subtest
(
	'The class argument cannot be undef.',
	sub
	{
		plan( tests => 2 );
		dies_ok(
			sub
			{
				Data::Validate::Type::is_instance( {} );
			},
			'is_instance() croaks.',
		);
		like(
			$@,
			qr/A class argument is required/,
			'The error message indicates that class is a required argument.',
		);
	}
);

subtest
(
	'The class argument cannot be an empty string.',
	sub
	{
		plan( tests => 2 );
		dies_ok(
			sub
			{
				Data::Validate::Type::is_instance( {}, class => '' );
			},
			'is_instance() croaks.',
		);
		like(
			$@,
			qr/A class argument is required/,
			'The error message indicates that class is a required argument.',
		);
	}
);

# Regular tests.
my $tests =
[
	{
		'function_name' => 'is_instance',
		'function_type' => 'boolean',
	},
	{
		'function_name' => 'assert_instance',
		'function_type' => 'assert',
	},
	{
		'function_name' => 'filter_instance',
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
						function_args =>
						{
							class       => 'InvalidClass',
						},
						type          => $function_type,
						pass_tests    => [],
					);
				}
			);

			subtest(
				'Test with class=TestArrayBless.',
				sub
				{
					LocalTest::ok_run_tests(
						function_name => $function_name,
						function_args =>
						{
							class       => 'TestArrayBless',
						},
						type          => $function_type,
						pass_tests    =>
						[
							qw(
								blessed_arrayref
							)
						],
					);
				}
			);

			subtest(
				'Test with class=TestHashBless.',
				sub
				{
					LocalTest::ok_run_tests(
						function_name => $function_name,
						function_args =>
						{
							class       => 'TestHashBless',
						},
						type          => $function_type,
						pass_tests    =>
						[
							qw(
								blessed_hashref
							)
						],
					);
				}
			);
		}
	);
}
