use strict;
use warnings;

use Business::UDC;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Business::UDC->new('0/9');
my $ret = $obj->ast;
is_deeply(
	$ret,
	{
		'left' => {
			'modifiers' => [],
			'primary' => {
				'type' => 'NUMBER',
				'value' => 0,
			},
			'type' => 'TERM',
		},
		'operator' => '/',
		'right' => {
			'modifiers' => [],
			'primary' => {
				'type' => 'NUMBER',
				'value' => 9,
			},
			'type' => 'TERM',
		},
		'type' => 'BINARY_OP',
	},
	'Test ast structure.',
);

# Test.
$obj = Business::UDC->new('004.42 Photo Studio ');
$ret = $obj->ast;
is_deeply(
	$ret,
	{
		'modifiers' => [
			{
				'type' => 'ALPHA_SPEC',
				'value' => 'Photo Studio',
			},
		],
		'primary' => {
			'type' => 'NUMBER',
			'value' => '004.42',
		},
		'type' => 'TERM',
	},
	'Test ast structure with trimmed ALPHA_SPEC.',
);

# Test.
$obj = Business::UDC->new('233-852.5Y-051');
$ret = $obj->ast;
is_deeply(
	$ret,
	{
		'modifiers' => [
			{
				'type' => 'FORM',
				'value' => '-852.5',
			},
			{
				'type' => 'ALPHA_SPEC',
				'value' => 'Y',
			},
			{
				'type' => 'FORM',
				'value' => '-051',
			},
		],
		'primary' => {
			'type' => 'NUMBER',
			'value' => '233',
		},
		'type' => 'TERM',
	},
	'Test ast structure with FORM after ALPHA_SPEC.',
);
