use strict;
use warnings;

use Business::UDC::Tokenizer qw(tokenize);
use Test::More 'tests' => 35;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

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
$ret_ar = tokenize('351,7');
is_deeply(
	$ret_ar,
	[
		{
			'pos' => 0,
			'type' => 'NUMBER',
			'value' => '351,7',
		},
	],
	'Tokenize bad decimal number with comma (351,7).',
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

# Test.
$ret_ar = tokenize('330.5+338');
is_deeply(
	$ret_ar,
	[
		{
			'pos' => 0,
			'type' => 'NUMBER',
			'value' => '330.5',
		},
		{
			'pos' => 5,
			'type' => 'OP',
			'value' => '+',
		},
		{
			'pos' => 6,
			'type' => 'NUMBER',
			'value' => '338',
		},
	],
	'Tokenize decimal numbers with + operator (330.5+338).',
);

# Test.
$ret_ar = tokenize('(47+57)');
is_deeply(
	$ret_ar,
	[
		{
			'pos' => 0,
			'type' => 'AUX_GROUP',
			'value' => '(47+57)',
		},
	],
	'Tokenize group ((47+57)).',
);

# Test.
$ret_ar = tokenize('591.5-755.43Abramis brama=20');
is_deeply(
	$ret_ar,
	[
		{
			'pos' => 0,
			'type' => 'NUMBER',
			'value' => '591.5',
		},
		{
			'pos' => 5,
			'type' => 'FORM',
			'value' => '-755.43',
		},
		{
			'pos' => 12,
			'type' => 'ALPHA_SPEC',
			'value' => 'Abramis brama',
		},
		{
			'pos' => 25,
			'type' => 'AUX_LANG',
			'value' => '=20',
		},
	],
	'Tokenize string with valid name (591.5-755.43Abramis brama=20).',
);

# Test.
$ret_ar = tokenize('597.554.3Abramis brama-15=20');
is_deeply(
	$ret_ar,
	[
		{
			'pos' => 0,
			'type' => 'NUMBER',
			'value' => '597.554.3',
		},
		{
			'pos' => 9,
			'type' => 'ALPHA_SPEC',
			'value' => 'Abramis brama',
		},
		{
			'pos' => 22,
			'type' => 'FORM',
			'value' => '-15',
		},
		{
			'pos' => 25,
			'type' => 'AUX_LANG',
			'value' => '=20',
		},
	],
	'Tokenize string with valid name (591.5-755.43Abramis brama=20).',
);

# Test.
$ret_ar = tokenize('004.42 Photo Studio');
is_deeply(
	$ret_ar,
	[
		{
			'pos' => 0,
			'type' => 'NUMBER',
			'value' => '004.42',
		},
		{
			'pos' => 6,
			'type' => 'ALPHA_SPEC',
			'value' => ' Photo Studio',
		},
	],
	'Tokenize string with valid name (004.42 Photo Studio).',
);

# Test.
$ret_ar = tokenize('004.42 Photo Studio ');
is_deeply(
	$ret_ar,
	[
		{
			'pos' => 0,
			'type' => 'NUMBER',
			'value' => '004.42',
		},
		{
			'pos' => 6,
			'type' => 'ALPHA_SPEC',
			'value' => ' Photo Studio ',
		},
	],
	'Tokenize string with valid name (004.42 Photo Studio ).',
);

# Test.
$ret_ar = tokenize('004.438C++');
is_deeply(
	$ret_ar,
	[
		{
			'pos' => 0,
			'type' => 'NUMBER',
			'value' => '004.438',
		},
		{
			'pos' => 7,
			'type' => 'ALPHA_SPEC',
			'value' => 'C++',
		},
	],
	'Tokenize string with + in name (004.438C++).',
);

# Test.
$ret_ar = tokenize('004.451.9CP/M');
is_deeply(
	$ret_ar,
	[
		{
			'pos' => 0,
			'type' => 'NUMBER',
			'value' => '004.451.9',
		},
		{
			'pos' => 9,
			'type' => 'ALPHA_SPEC',
			'value' => 'CP/M',
		},
	],
	'Tokenize string with / in name (004.451.9CP/M).',
);

# Test.
$ret_ar = tokenize('004.438C#');
is_deeply(
	$ret_ar,
	[
		{
			'pos' => 0,
			'type' => 'NUMBER',
			'value' => '004.438',
		},
		{
			'pos' => 7,
			'type' => 'ALPHA_SPEC',
			'value' => 'C#',
		},
	],
	'Tokenize string with # in name (004.438C#).',
);

# Test.
$ret_ar = tokenize(decode_utf8('929Komenský,J.A.'));
is_deeply(
	$ret_ar,
	[
		{
			'pos' => 0,
			'type' => 'NUMBER',
			'value' => '929',
		},
		{
			'pos' => 3,
			'type' => 'ALPHA_SPEC',
			'value' => decode_utf8('Komenský,J.A.'),
		},
	],
	'Tokenize string with , in name (929Komenský,J.A.).',
);

# Test.
$ret_ar = tokenize(decode_utf8('92 Fučík,J. "1942/1943"(0:8-94)'));
is_deeply(
	$ret_ar,
	[
		{
			'pos' => 0,
			'type' => 'NUMBER',
			'value' => 92,
		},
		{
			'pos' => 2,
			'type' => 'ALPHA_SPEC',
			'value' => decode_utf8(' Fučík,J. '),
		},
		{
			'pos' => 12,
			'type' => 'AUX_TIME',
			'value' => '"1942/1943"',
		},
		{
			'pos' => 23,
			'type' => 'AUX_GROUP',
			'value' => '(0:8-94)',
		},
	],
	'Tokenize string with space on the end of name (92 Fučík,J. "1942/1943"(0:8-94)).',
);

# Test.
$ret_ar = tokenize('1 DM (075.8)');
is_deeply(
	$ret_ar,
	[
		{
			'pos' => 0,
			'type' => 'NUMBER',
			'value' => 1,
		},
		{
			'pos' => 1,
			'type' => 'ALPHA_SPEC',
			'value' => ' DM ',
		},
		{
			'pos' => 5,
			'type' => 'AUX_GROUP',
			'value' => '(075.8)',
		},
	],
	'Tokenize string with space on the end of name (1 DM (075.8)).',
);

# Test.
$ret_ar = tokenize('728.82(437.1 Kozel)(083.85)');
is_deeply(
	$ret_ar,
	[
		{
			'pos' => 0,
			'type' => 'NUMBER',
			'value' => '728.82',
		},
		{
			'pos' => 6,
			'type' => 'AUX_GROUP',
			'value' => '(437.1 Kozel)',
		},
		{
			'pos' => 19,
			'type' => 'AUX_GROUP',
			'value' => '(083.85)',
		},
	],
	'Tokenize string with name in group (728.82(437.1 Kozel)(083.85)).',
);

# Test.
$ret_ar = tokenize('784.96:061.2 "Bojan"');
is_deeply(
	$ret_ar,
	[
		{
			'pos' => 0,
			'type' => 'NUMBER',
			'value' => '784.96',
		},
		{
			'pos' => 6,
			'type' => 'OP',
			'value' => ':',
		},
		{
			'pos' => 7,
			'type' => 'NUMBER',
			'value' => '061.2',
		},
		{
			'pos' => 12,
			'type' => 'ALPHA_SPEC',
			'value' => ' "Bojan"',
		},
	],
	'Tokenize string with quotes in name (784.96:061.2 "Bojan").',
);

# Test.
$ret_ar = tokenize("81'24");
is_deeply(
	$ret_ar,
	[
		{
			'pos' => 0,
			'type' => 'NUMBER',
			'value' => '81',
		},
		{
			'pos' => 2,
			'type' => 'APOS_AUX',
			'value' => "'24",
		},
	],
	"Tokenize string with apostrophe (81'24).",
);

# Test.
$ret_ar = tokenize("81`24");
is_deeply(
	$ret_ar,
	[
		{
			'pos' => 0,
			'type' => 'NUMBER',
			'value' => '81',
		},
		{
			'pos' => 2,
			'type' => 'APOS_AUX',
			'value' => "`24",
		},
	],
	"Tokenize string with apostrophe (81`24).",
);

# Test.
$ret_ar = tokenize(decode_utf8("81’24"));
is_deeply(
	$ret_ar,
	[
		{
			'pos' => 0,
			'type' => 'NUMBER',
			'value' => '81',
		},
		{
			'pos' => 2,
			'type' => 'APOS_AUX',
			'value' => decode_utf8("’24"),
		},
	],
	"Tokenize string with bad apostrophe (81’24).",
);

# Test.
$ret_ar = tokenize(decode_utf8("81´37-021.6"));
is_deeply(
	$ret_ar,
	[
		{
			'pos' => 0,
			'type' => 'NUMBER',
			'value' => '81',
		},
		{
			'pos' => 2,
			'type' => 'APOS_AUX',
			'value' => decode_utf8("´37"),
		},
		{
			'pos' => 5,
			'type' => 'FORM',
			'value' => '-021.6',
		},
	],
	"Tokenize string with bad acute apostrophe (81´37-021.6).",
);

# Test.
$ret_ar = tokenize("81'42'373.46");
is_deeply(
	$ret_ar,
	[
		{
			'pos' => 0,
			'type' => 'NUMBER',
			'value' => '81',
		},
		{
			'pos' => 2,
			'type' => 'APOS_AUX',
			'value' => "'42",
		},
		{
			'pos' => 5,
			'type' => 'APOS_AUX',
			'value' => "'373.46",
		},
	],
	"Tokenize string with multiple apostrophes (81'42'373.46).",
);

# Test.
$ret_ar = tokenize("81&apos;24");
is_deeply(
	$ret_ar,
	[
		{
			'pos' => 0,
			'type' => 'NUMBER',
			'value' => '81',
		},
		{
			'pos' => 2,
			'type' => 'APOS_AUX',
			'value' => "&apos;24",
		},
	],
	"Tokenize string with bad apostrophe (81&apos;24).",
);

# Test.
$ret_ar = tokenize(decode_utf8("355.483(966.2)“1944”"));
is_deeply(
	$ret_ar,
	[
		{
			'pos' => 0,
			'type' => 'NUMBER',
			'value' => '355.483',
		},
		{
			'pos' => 7,
			'type' => 'AUX_GROUP',
			'value' => '(966.2)',
		},
		{
			'pos' => 14,
			'type' => 'AUX_TIME',
			'value' => decode_utf8("“1944”"),
		},
	],
	"Tokenize string with bad quotation marks (“355.483(966.2)1944”).",
);

# Test.
$ret_ar = tokenize("94(437.13 Jičín)''1939/1945''");
is_deeply(
	$ret_ar,
	[
		{
			'pos' => 0,
			'type' => 'NUMBER',
			'value' => '94',
		},
		{
			'pos' => 2,
			'type' => 'AUX_GROUP',
			'value' => '(437.13 Jičín)',
		},
		{
			'pos' => 18,
			'type' => 'AUX_TIME',
			'value' => "''1939/1945''",
		},
	],
	"Tokenize string with bad quotation marks (94(437.13 Jičín)''1939/1945'').",
);

# Test.
$ret_ar = tokenize(qq("17''(075.8)));
is_deeply(
	$ret_ar,
	[
		{
			'pos' => 0,
			'type' => 'AUX_TIME',
			'value' => qq("17''),
		},
		{
			'pos' => 5,
			'type' => 'AUX_GROUP',
			'value' => '(075.8)',
		},
	],
	qq(Tokenize string with bad quotation marks ("17''(075.8)).),
);

# Test.
$ret_ar = tokenize(decode_utf8('populárně-naučné publikace'));
is_deeply(
	$ret_ar,
	[
		{
			'pos' => 0,
			'type' => 'ALPHA_SPEC',
			'value' => decode_utf8('populárně-naučné publikace'),
		},
	],
	'Tokenize bad UDC string, which is ALPHA_SPEC only (populárně-naučné publikace).',
);

# Test.
$ret_ar = tokenize('78.089 (123)');
is_deeply(
	$ret_ar,
	[
		{
			'pos' => 0,
			'type' => 'NUMBER',
			'value' => '78.089',
		},
		{
			'pos' => 6,
			'type' => 'WHITESPACE',
			'value' => ' ',
		},
		{
			'pos' => 7,
			'type' => 'AUX_GROUP',
			'value' => '(123)',
		},
	],
	"Tokenize string with whitespace (78.089 (123)).",
);

# Test.
$ret_ar = tokenize('677.062 +65.01] :687.1(082)');
is_deeply(
	$ret_ar,
	[
		{
			'pos' => 0,
			'type' => 'NUMBER',
			'value' => '677.062',
		},
		{
			'pos' => 7,
			'type' => 'WHITESPACE',
			'value' => ' ',
		},
		{
			'pos' => 8,
			'type' => 'OP',
			'value' => '+',
		},
		{
			'pos' => 9,
			'type' => 'NUMBER',
			'value' => '65.01',
		},
		{
			'pos' => 14,
			'type' => 'RBRACK',
			'value' => ']',
		},
		{
			'pos' => 15,
			'type' => 'WHITESPACE',
			'value' => ' ',
		},
		{
			'pos' => 16,
			'type' => 'OP',
			'value' => ':',
		},
		{
			'pos' => 17,
			'type' => 'NUMBER',
			'value' => '687.1',
		},
		{
			'pos' => 22,
			'type' => 'AUX_GROUP',
			'value' => '(082)',
		},
	],
	"Tokenize string with whitespace (677.062 +65.01] :687.1(082)).",
);

# Test.
$ret_ar = tokenize(decode_utf8('94(437.13 Jičín) "1939/1945"'));
is_deeply(
	$ret_ar,
	[
		{
			'pos' => 0,
			'type' => 'NUMBER',
			'value' => '94',
		},
		{
			'pos' => 2,
			'type' => 'AUX_GROUP',
			'value' => decode_utf8('(437.13 Jičín)'),
		},
		{
			'pos' => 16,
			'type' => 'WHITESPACE',
			'value' => ' ',
		},
		{
			'pos' => 17,
			'type' => 'AUX_TIME',
			'value' => '"1939/1945"',
		},
	],
	'Tokenize string with whitespace (94(437.13 Jičín) "1939/1945").',
);

# Test.
$ret_ar = tokenize(decode_utf8("94(437.13 Jičín) ''1939/1945''"));
is_deeply(
	$ret_ar,
	[
		{
			'pos' => 0,
			'type' => 'NUMBER',
			'value' => '94',
		},
		{
			'pos' => 2,
			'type' => 'AUX_GROUP',
			'value' => decode_utf8('(437.13 Jičín)'),
		},
		{
			'pos' => 16,
			'type' => 'WHITESPACE',
			'value' => ' ',
		},
		{
			'pos' => 17,
			'type' => 'AUX_TIME',
			'value' => "''1939/1945''",
		},
	],
	"Tokenize string with whitespace (94(437.13 Jičín) ''1939/1945'').",
);
