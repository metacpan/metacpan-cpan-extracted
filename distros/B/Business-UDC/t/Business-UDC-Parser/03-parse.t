use strict;
use warnings;

use Business::UDC::Parser qw(parse);
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $ret_hr = parse('0/9');
is_deeply(
	$ret_hr,
	{
		'ast' => {
			'left' => {
				'modifiers' => [],
				'primary' => {
					'value' => 0,
					'type' => 'NUMBER',
				},
				'type' => 'TERM',
			},
			'operator' => '/',
			'right' => {
				'modifiers' => [],
				'primary' => {
					'value' => 9,
					'type' => 'NUMBER',
				},
				'type' => 'TERM',
			},
			'type' => 'BINARY_OP',
		},
		'tokens' => [{
			'pos' => 0,
			'type' => 'NUMBER',
			'value' => 0,
		}, {
			'pos' => 1,
			'type' => 'OP',
			'value' => '/',
		}, {
			'pos' => 2,
			'type' => 'NUMBER',
			'value' => 9,
		}],
	},
	'Parse UDC (0/9).',
);

# Test.
eval {
	parse();
};
is($EVAL_ERROR, "No input provided.\n",
	"No input provided.");
clean();

# Test.
eval {
	parse('');
};
is($EVAL_ERROR, "Empty input.\n",
	"Empty input.");
clean();
