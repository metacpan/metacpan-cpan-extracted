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
		'function_name' => 'is_coderef',
		'function_type' => 'boolean',
	},
	{
		'function_name' => 'assert_coderef',
		'function_type' => 'assert',
	},
	{
		'function_name' => 'filter_coderef',
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
			plan( tests => 1 );

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
								unnamed_subroutine
							)
						],
					);
				}
			);
		}
	);
}
