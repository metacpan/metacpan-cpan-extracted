use strict;
use warnings;

use Business::UDC::Parser qw(parse);
use English;
use Error::Pure::Utils qw(clean err_msg_hr);
use Test::More 'tests' => 95;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

my $err_msg_hr;

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
$ret_hr = parse("81'36/'37-022.212");
is($ret_hr->{'ast'}{'type'}, 'APOS_RANGE',
	'Parse apostrophe auxiliary range.');
is($ret_hr->{'ast'}{'modifiers'}[0]{'value'}, '-022.212',
	'Parse form after apostrophe auxiliary range.');

# Test.
eval {
	parse('578.82./.83');
};
is($EVAL_ERROR, "Extra dot '.'.\n",
	"Extra dot '.' (578.82./.83).");
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'position'}, 6, 'Get extra dot position (position = 6).');
is($err_msg_hr->{'character'}, '.', "Get extra dot character (character = '.').");
clean();

# Test.
eval {
	parse(decode_utf8('92 Brežněv,L.I.:[329(47).15+327(47)(042 5)"1970/1972"(081)'));
};
is($EVAL_ERROR,
	"Whitespace is not allowed in UDC string with alphabetical specification.\n",
	'Whitespace with alphabetical specification in nested AUX_GROUP.');
clean();

# Test.
eval {
	parse('608.3(083.1"1962"');
};
is($EVAL_ERROR, "Missing closing parenthesis ')'.\n",
	"Missing closing parenthesis ')' before time auxiliary.");
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'position'}, 11, 'Get missing closing parenthesis position (position = 11).');
is($err_msg_hr->{'character'}, ')', "Get missing closing parenthesis character (character = ')').");
clean();

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
	parse('885-32-322,1');
};
is($EVAL_ERROR, "Bad dot character in number.\n",
	"Bad dot character in number (885-32-322,1).");
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'position'}, 10, 'Get bad dot position (position = 10).');
is($err_msg_hr->{'character'}, ',', "Get bad dot character (character = ',').");
clean();

# Test.
eval {
	parse('323.22(437)"1939/1945":943.7"1939/1945"940.5:329.15(437)(082)');
};
is($EVAL_ERROR, "Missing operator.\n",
	'Missing operator after time auxiliary.');
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'position'}, 39, 'Get missing operator position (position = 39).');
clean();

# Test.
eval {
	parse('016:355.01(43:436)"1866"+943.7"1866"943.07+943.6.08+92 Simon, J.');
};
is($EVAL_ERROR, "Missing operator.\n",
	'Missing operator in term sequence.');
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'position'}, 36, 'Get missing operator position (position = 36).');
clean();

# Test.
eval {
	parse(decode_utf8('727.7 + 728.82(437.2Valašské Meziříčí)(083.85)'));
};
is($EVAL_ERROR,
	"Whitespace is not allowed in UDC string with alphabetical specification.\n",
	'Whitespace with alphabetical specification in AUX_GROUP.');
clean();

# Test.
eval {
	parse('951.0+951.73+951.9+959.7+972.91"1945/1975"(075. 8)');
};
is($EVAL_ERROR, "Whitespace is not allowed in UDC string.\n",
	'Whitespace in numeric AUX_GROUP.');
clean();

# Test.
eval {
	parse('016:794.1"1960/1972');
};
is($EVAL_ERROR, "Missing closing quotation mark '\"'.\n",
	'Missing closing quotation mark (016:794.1"1960/1972).');
clean();

# Test.
eval {
	parse('355.48(100)"1914/1918');
};
is($EVAL_ERROR, "Missing closing quotation mark '\"'.\n",
	'Missing closing quotation mark (355.48(100)"1914/1918).');
clean();

# Test.
eval {
	parse('355.48(436+560)"1716/1718');
};
is($EVAL_ERROR, "Missing closing quotation mark '\"'.\n",
	'Missing closing quotation mark (355.48(436+560)"1716/1718).');
clean();

# Test.
eval {
	parse('91(437)"1918/1939)(091)');
};
is($EVAL_ERROR, "Missing closing quotation mark '\"'.\n",
	'Missing closing quotation mark (91(437)"1918/1939)(091)).');
clean();

# Test.
eval {
	parse('94(436+560)"1716/1718');
};
is($EVAL_ERROR, "Missing closing quotation mark '\"'.\n",
	'Missing closing quotation mark (94(436+560)"1716/1718).');
clean();

# Test.
eval {
	parse('92Gottwald,K.:323(437)"1948.02=4');
};
is($EVAL_ERROR, "Missing closing quotation mark '\"'.\n",
	'Missing closing quotation mark before language auxiliary.');
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'position'}, 30, 'Get missing quotation mark position (position = 30).');
is($err_msg_hr->{'character'}, '"', "Get missing quotation mark character (character = '\"').");
clean();

# Test.
eval {
	parse('929.3:378.961(437.11)"1657/178.3=71');
};
is($EVAL_ERROR, "Invalid year in time auxiliary.\n",
	'Invalid ending year in time auxiliary.');
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'position'}, 27, 'Get invalid year position (position = 27).');
is($err_msg_hr->{'character'}, '1', "Get invalid year character (character = '1').");
clean();

# Test.
eval {
	parse('323.272(5-15)+(6-17)"2011/...');
};
is($EVAL_ERROR, "Missing closing quotation mark '\"'.\n",
	'Missing closing quotation mark before incomplete time auxiliary.');
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'position'}, 25, 'Get missing quotation mark position (position = 25).');
is($err_msg_hr->{'character'}, '"', "Get missing quotation mark character (character = '\"').");
clean();

# Test.
eval {
	parse("81' 367.625.44");
};
is($EVAL_ERROR, "Whitespace is not allowed in UDC string.\n",
	"Whitespace is not allowed in UDC string (81' 367.625.44).");
clean();

# Test.
$ret_hr = parse('(73)339.5');
is($ret_hr->{'ast'}{'prefixes'}[0]{'value'}, '(73)',
	'Parse place auxiliary before main number ((73)339.5).');

# Test.
foreach my $input ('((437.3)', '(94(437)', '913((437.31-15)',
	'913((437.319)', '913((437.313)') {
	eval {
		parse($input);
	};
	is($EVAL_ERROR, "Extra opening parenthesis '('.\n",
		"Extra opening parenthesis '('. ($input)");
	clean();
}

# Test.
eval {
	parse('808.5(0-093.5:669(075)');
};
is($EVAL_ERROR, "Missing closing parenthesis ')'.\n",
	"Missing closing parenthesis ')' (808.5(0-093.5:669(075)).");
clean();

# Test.
eval {
	parse(decode_utf8('92Slaměník,F.(021):069(437.2Přerov+92Komenský,J.A.(021)'));
};
is($EVAL_ERROR, "Missing closing parenthesis ')'.\n",
	'Missing closing parenthesis in geographical auxiliary.');
clean();

# Test.
eval {
	parse('/048.8)');
};
is($EVAL_ERROR,
	"Expected NUMBER, subgroup, or standalone auxiliary but got OP ('/').\n",
	"Invalid leading character '/' (/048.8)).");
clean();

# Test.
eval {
	parse('323.272(729.1("1959"(042)=2=6=85');
};
is($EVAL_ERROR, "Extra opening parenthesis '('.\n",
	"Extra opening parenthesis '(' (323.272(729.1(\"1959\"(042)=2=6=85).");
clean();

# Test.
eval {
	parse(decode_utf8('77.04:05 Photographik"1933/1940"]:061.43(437.2-2 Brno"1986"(036:084.1)'));
};
is($EVAL_ERROR, "Missing closing parenthesis ')'.\n",
	'Missing closing parenthesis in geographical auxiliary before time auxiliary.');
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'position'}, 53, 'Get error (position = 53).');
is($err_msg_hr->{'character'}, ')', "Get error (character = ')').");
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
	parse(decode_utf8('82‑343'));
};
is($EVAL_ERROR, "Bad hyphen character.\n",
	'Bad hyphen character (82‑343).');
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'position'}, 2, 'Get bad hyphen position (position = 2).');
is($err_msg_hr->{'character'}, decode_utf8('‑'), 'Get bad hyphen character.');
clean();

# Test.
eval {
	parse('27--243.37');
};
is($EVAL_ERROR, "Extra dash '-'.\n",
	"Extra dash '-' (27--243.37).");
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'position'}, 3, 'Get extra dash position (position = 3).');
is($err_msg_hr->{'character'}, '-', "Get extra dash character (character = '-').");
clean();

# Test.
eval {
	parse('373/378-');
};
is($EVAL_ERROR, "Extra dash '-'.\n",
	"Extra dash '-' (373/378-).");
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'position'}, 7, 'Get trailing dash position (position = 7).');
is($err_msg_hr->{'character'}, '-', "Get trailing dash character (character = '-').");
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
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'position'}, 3, 'Get error (position = 3).');
is($err_msg_hr->{'character'}, ' ', "Get error (character = ' ').");
clean();

# Test.
eval {
	parse('048.8)');
};
is($EVAL_ERROR, "Missing opening parenthesis '('.\n",
	"Missing opening parenthesis '(' (048.8)).");
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'position'}, 0, 'Get error (position = 0).');
is($err_msg_hr->{'character'}, '(', "Get error (character = '(').");
clean();

# Test.
eval {
	parse('086.7)08');
};
is($EVAL_ERROR, "Missing opening parenthesis '('.\n",
	"Missing opening parenthesis '(' (086.7)08).");
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'position'}, 0, 'Get error (position = 0).');
is($err_msg_hr->{'character'}, '(', "Get error (character = '(').");
clean();

# Test.
eval {
	parse('(035');
};
is($EVAL_ERROR, "Missing closing parenthesis ')'.\n",
	"Missing closing parenthesis ')' ((035).");
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'position'}, 4, 'Get error (position = 4).');
is($err_msg_hr->{'character'}, ')', "Get error (character = ')').");
clean();

# Test.
eval {
	parse('(437.3))');
};
is($EVAL_ERROR, "Extra closing parenthesis ')'.\n",
	"Extra closing parenthesis ')' ((437.3))).");
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'position'}, 7, 'Get error (position = 7).');
is($err_msg_hr->{'character'}, ')', "Get error (character = ')').");
clean();

# Test.
eval {
	parse('677.062 +65.01] :687.1(082)');
};
is($EVAL_ERROR, "Whitespace is not allowed in UDC string.\n",
	"Whitespace is not allowed in UDC string (677.062 +65.01] :687.1(082)).");
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'position'}, 7, 'Get error (position = 7).');
is($err_msg_hr->{'character'}, ' ', "Get error (character = ' ').");
clean();

# Test.
eval {
	parse(decode_utf8('94(437.13 Jičín) "1939/1945"'));
};
is($EVAL_ERROR,
	"Whitespace is not allowed in UDC string with alphabetical specification.\n",
	'Whitespace is not allowed in UDC string (94(437.13 Jičín) "1939/1945").');
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'position'}, 16, 'Get error (position = 16).');
is($err_msg_hr->{'character'}, ' ', "Get error (character = ' ').");
clean();

# Test.
eval {
	parse(decode_utf8("94(437.13 Jičín) ''1939/1945''"));
};
is($EVAL_ERROR,
	"Whitespace is not allowed in UDC string with alphabetical specification.\n",
	"Whitespace is not allowed in UDC string (94(437.13 Jičín) ''1939/1945'').");
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'position'}, 16, 'Get error (position = 16).');
is($err_msg_hr->{'character'}, ' ', "Get error (character = ' ').");
clean();
