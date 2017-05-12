#!perl -T

use strict;
use warnings;

use Audit::DBI::Utils;
use Test::FailWarnings -allow_deps => 1;
use Test::More;


eval "use Math::Currency";
plan( skip_all => "Math::Currency required for testing stringification." )
    if $@;

plan( tests => 4 );

my $test_currency = Math::Currency->new( '10.99', 'en_US' );
my $object_stringification_map =
{
	'Math::Currency' => 'bstr',
};

is(
	Audit::DBI::Utils::stringify_data_structure(
		data_structure             => $test_currency,
		object_stringification_map => $object_stringification_map,
	),
	'$10.99',
	'Stringify object.',
);

is_deeply(
	Audit::DBI::Utils::stringify_data_structure(
		data_structure             =>
		[
			$test_currency,
			'A',
			$test_currency,
		],
		object_stringification_map => $object_stringification_map,
	),
	[
		'$10.99',
		'A',
		'$10.99',
	],
	'Stringify arrayref with object elements.',
);

is_deeply(
	Audit::DBI::Utils::stringify_data_structure(
		data_structure             =>
		{
			money => $test_currency,
			text  => 'A',
		},
		object_stringification_map => $object_stringification_map,
	),
	{
		money => '$10.99',
		text  => 'A',
	},
	'Stringify hash with an object in the values.',
);

is_deeply(
	Audit::DBI::Utils::stringify_data_structure(
		data_structure             =>
		{
			array =>
			[
				$test_currency,
				bless( { test => 1 }, 'TestClass' ),
				[],
				1,
			],
			money =>
			{
				money => $test_currency,
				array => [ ],
			},
		},
		object_stringification_map => $object_stringification_map,
	),
	{
		array =>
		[
			'$10.99',
			bless( { test => 1 }, 'TestClass' ),
			[],
			1,
		],
		money =>
		{
			money => '$10.99',
			array => [ ],
		},
	},
	'Stringify nested array and hashes.',
);

