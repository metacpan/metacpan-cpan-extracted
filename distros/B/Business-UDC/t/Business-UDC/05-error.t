use strict;
use warnings;

use Business::UDC;
use Test::More 'tests' => 30;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Test.
my $obj = Business::UDC->new('0/9');
is($obj->error, undef, 'Get error (no error).');

# Test.
$obj = Business::UDC->new('bad');
is($obj->error, "Alphabetical specification cannot appear standalone.",
	'Get error (Alphabetical specification cannot appear standalone.).');
# TODO Check error parameters

# Test.
$obj = Business::UDC->new;
is($obj->error, 'No input provided.', 'No input provided.');

# Test.
$obj = Business::UDC->new('');
is($obj->error, 'Empty input.', 'Empty input.');

# Test.
$obj = Business::UDC->new("811`373");
is($obj->error, 'Bad apostrophe character.', 'Bad apostrophe character (`).');
my ($error, %params) = $obj->error;
is($error, 'Bad apostrophe character.', 'Bad apostrophe character (`).');
is($params{'character'}, '`', 'Bad apostrophe character parameter (`).');
is($params{'position'}, 3, 'Bad apostrophe position parameter (`).');

# Test.
$obj = Business::UDC->new("811&apos;373");
($error, %params) = $obj->error;
is($error, 'Bad apostrophe character.', 'Bad apostrophe character (&apos;).');
is($params{'character'}, '&apos;', 'Bad apostrophe character parameter (&apos;).');
is($params{'position'}, 3, 'Bad apostrophe position parameter (&apos;).');

# Test.
$obj = Business::UDC->new(decode_utf8("811’373"));
($error, %params) = $obj->error;
is($error, 'Bad apostrophe character.', 'Bad apostrophe character (right single quote).');
is($params{'character'}, decode_utf8('’'), 'Bad apostrophe character parameter (right single quote).');
is($params{'position'}, 3, 'Bad apostrophe position parameter (right single quote).');

# Test.
$obj = Business::UDC->new(decode_utf8("81´37-021.6"));
($error, %params) = $obj->error;
is($error, 'Bad apostrophe character.', 'Bad apostrophe character (acute accent).');
is($params{'character'}, decode_utf8('´'), 'Bad apostrophe character parameter (acute accent).');
is($params{'position'}, 2, 'Bad apostrophe position parameter (acute accent).');

# Test.
$obj = Business::UDC->new(decode_utf8("355.483(966.2)“1944”"));
($error, %params) = $obj->error;
is($error, 'Bad quotation mark character.', 'Bad quotation mark character (left double quote).');
is($params{'character'}, decode_utf8('“'), 'Bad quotation mark character parameter (left double quote).');
is($params{'position'}, 14, 'Bad quotation mark position parameter (left double quote).');

# Test.
$obj = Business::UDC->new("94(437.13 Jicin)''1939/1945''");
($error, %params) = $obj->error;
is($error, 'Bad quotation mark character.', "Bad quotation mark character ('').");
is($params{'character'}, "''", "Bad quotation mark character parameter ('').");
is($params{'position'}, 16, "Bad quotation mark position parameter ('').");

# Test.
$obj = Business::UDC->new(qq("17''(075.8)));
($error, %params) = $obj->error;
is($error, 'Bad quotation mark character.', 'Bad quotation mark character (closing quote).');
is($params{'character'}, "''", 'Bad quotation mark character parameter (closing quote).');
is($params{'position'}, 3, 'Bad quotation mark position parameter (closing quote).');

# Test.
$obj = Business::UDC->new('351,7');
($error, %params) = $obj->error;
is($error, 'Bad dot character in number.',
	'Bad dot character in number (comma).');
is($params{'character'}, ',', "Bad dot character in number 'character' parametr (,).");
is($params{'position'}, 3, "Bad dot character in number 'position' parameter (3).");
