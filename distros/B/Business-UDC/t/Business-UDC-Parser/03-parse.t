use strict;
use warnings;

use Business::UDC::Parser qw(parse);
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 24;
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
$ret_hr = parse('061.22::61');
is($ret_hr->{'ast'}{'operator'}, '::',
	'Parse fixed relation operator.');
is($ret_hr->{'tokens'}[1]{'value'}, '::',
	'Tokenize fixed relation operator.');

# Test.
$ret_hr = parse('913((6-11)+(5-13)+(9-15))');
is($ret_hr->{'tokens'}[1]{'value'}, '((6-11)+(5-13)+(9-15))',
	'Parse nested parentheses in parenthesized auxiliary.');

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
	parse('(123,34)');
};
is($EVAL_ERROR, "Bad dot character in number.\n",
	"Bad dot character in number ((123,34)).");
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
	parse(decode_utf8('908.437.138 Babiččino údolí: 502.6/.7(036)'));
};
is($EVAL_ERROR,
	"Whitespace is not allowed in UDC string with alphabetical specification.\n",
	'Whitespace with alphabetical specification (908.437.138 Babiččino údolí: 502.6/.7(036)).');
clean();

# Test.
eval {
	parse('54 (075.2)');
};
is($EVAL_ERROR, "Whitespace is not allowed in UDC string.\n",
	'Whitespace is not allowed in UDC string (54 (075.2)).');
clean();

# Test.
eval {
	parse('141.82 :323.381.2:323.4(100)');
};
is($EVAL_ERROR, "Whitespace is not allowed in UDC string.\n",
	'Whitespace is not allowed in UDC string (141.82 :323.381.2:323.4(100)).');
clean();

# Test.
eval {
	parse('784.71- 044.357');
};
is($EVAL_ERROR, "Whitespace is not allowed in UDC string.\n",
	'Whitespace is not allowed in UDC string (784.71- 044.357).');
clean();

# Test.
eval {
	parse('885-93-343.4 = 393');
};
is($EVAL_ERROR, "Whitespace is not allowed in UDC string.\n",
	'Whitespace is not allowed in UDC string (885-93-343.4 = 393).');
clean();

# Test.
eval {
	parse('840-94 :910.45 :92 Bombard, A.');
};
is($EVAL_ERROR,
	"Whitespace is not allowed in UDC string with alphabetical specification.\n",
	'Whitespace with alphabetical specification (840-94 :910.45 :92 Bombard, A.).');
clean();

# Test.
eval {
	parse('830 (430.2)-311.6-321.2+92 Bobrowski, J.');
};
is($EVAL_ERROR,
	"Whitespace is not allowed in UDC string with alphabetical specification.\n",
	'Whitespace with alphabetical specification (830 (430.2)-311.6-321.2+92 Bobrowski, J.).');
clean();

# Test.
eval {
	parse('048.8)');
};
is($EVAL_ERROR, "Missing opening parenthesis '('.\n",
	"Missing opening parenthesis '(' (048.8)).");
clean();

# Test.
eval {
	parse('086.7)08');
};
is($EVAL_ERROR, "Missing opening parenthesis '('.\n",
	"Missing opening parenthesis '(' (086.7)08).");
clean();

# Test.
eval {
	parse('(035');
};
is($EVAL_ERROR, "Missing closing parenthesis ')'.\n",
	"Missing closing parenthesis ')' ((035).");
clean();

# Test.
eval {
	parse('(437.3))');
};
is($EVAL_ERROR, "Extra closing parenthesis ')'.\n",
	"Extra closing parenthesis ')' ((437.3))).");
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
