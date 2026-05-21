use strict;
use warnings;

use Business::UDC::Parser qw(parse);
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 9;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

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

# Test.
eval {
	parse('351,7');
};
is($EVAL_ERROR, "Bad dot character in number.\n",
	"Bad dot character in number (351,7).");
clean();

# Test.
eval {
	parse('78.089 (123)');
};
is($EVAL_ERROR, "Whitespace is not allowed in UDC string.\n",
	"Whitespace is not allowed in UDC string (78.089 (123)).");
clean();

# Test.
eval {
	parse('677.062 +65.01] :687.1(082)');
};
is($EVAL_ERROR, "Whitespace is not allowed in UDC string.\n",
	"Whitespace is not allowed in UDC string (677.062 +65.01] :687.1(082)).");
clean();

# Test.
eval {
	parse(decode_utf8('94(437.13 Jičín) "1939/1945"'));
};
is($EVAL_ERROR, "Whitespace is not allowed in UDC string.\n",
	'Whitespace is not allowed in UDC string (94(437.13 Jičín) "1939/1945").');
clean();

# Test.
eval {
	parse(decode_utf8("94(437.13 Jičín) ''1939/1945''"));
};
is($EVAL_ERROR, "Whitespace is not allowed in UDC string.\n",
	"Whitespace is not allowed in UDC string (94(437.13 Jičín) ''1939/1945'').");
clean();
