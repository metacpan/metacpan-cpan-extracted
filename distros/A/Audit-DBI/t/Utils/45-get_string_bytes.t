#!perl -T

use strict;
use warnings;

use Audit::DBI::Utils;
use Test::FailWarnings -allow_deps => 1;
use Test::More;


my $tests =
[
	{
		name      => 'Test undefined variable.',
		structure => undef,
		expected  => 0,
	},
	{
		name      => 'Test string.',
		structure => 'Test',
		expected  => 4,
	},
	{
		name      => 'Test hashref.',
		structure =>
		{
			test => 4,
			key  => 'value',
		},
		expected  => 13,
	},
	{
		name      => 'Test arrayref.',
		structure =>
		[
			'Test',
			'String',
			4,
		],
		expected  => 11,
	},
	{
		name      => 'Test coderef.',
		structure => sub
		{
			return 'String';
		},
		expected  => 0,
	},
	{
		name      => 'Test nested structure.',
		structure =>
		{
			test1 =>
			[
				1,
				'Test',
				2,
			],
			test2 => 3,
			test3 =>
			{
				key => 'value',
			}
		},
		expected  => 30,
	},
	{
		name      => 'Test multi-byte characters.',
		structure => '¢',
		expected  => 2,
	},
];

plan( tests => 1 + scalar( @$tests ) );

can_ok(
	'Audit::DBI::Utils',
	'get_string_bytes',
);

foreach my $test ( @$tests )
{
	is(
		Audit::DBI::Utils::get_string_bytes( $test->{'structure'} ),
		$test->{'expected'},
		$test->{'name'},
	);
}

