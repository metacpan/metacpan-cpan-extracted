use strict;
use warnings;

use Business::UDC::Tokenizer qw(tokenize);
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
my $ret_ar = tokenize('123');
is_deeply(
	$ret_ar,
	[
		{
			'pos' => 0,
			'type' => 'NUMBER',
			'value' => '123',
		},
	],
	'Tokenize simple number (123).',
);

# Test.
$ret_ar = tokenize('123.4');
is_deeply(
	$ret_ar,
	[
		{
			'pos' => 0,
			'type' => 'NUMBER',
			'value' => '123.4',
		},
	],
	'Tokenize decimal number with one dot (123.4).',
);

# Test.
$ret_ar = tokenize('811.162.3');
is_deeply(
	$ret_ar,
	[
		{
			'pos' => 0,
			'type' => 'NUMBER',
			'value' => '811.162.3',
		},
	],
	'Tokenize decimal number with two dots (811.162.3).',
);

# Test.
$ret_ar = tokenize('78.03.011.26');
is_deeply(
	$ret_ar,
	[
		{
			'pos' => 0,
			'type' => 'NUMBER',
			'value' => '78.03.011.26',
		},
	],
	'Tokenize decimal number with three dots (78.03.011.26).',
);

# Test.
$ret_ar = tokenize('78.089.6.087.6');
is_deeply(
	$ret_ar,
	[
		{
			'pos' => 0,
			'type' => 'NUMBER',
			'value' => '78.089.6.087.6',
		},
	],
	'Tokenize decimal number with four dots (78.089.6.087.6).',
);
