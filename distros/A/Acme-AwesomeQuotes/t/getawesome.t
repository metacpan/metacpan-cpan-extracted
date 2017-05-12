#!/usr/bin/perl

use strict;
use warnings;
use utf8;

binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

use lib qw(../lib);

use Test::More;

BEGIN {
	plan tests => (22);
	use_ok ('Acme::AwesomeQuotes') or diag("Cannot load module Acme::AwesomeQuotes!");
}

#Acme::AwesomeQuotes::getawesome;
# Tests to run:
can_ok ('Acme::AwesomeQuotes', qw(GetAwesome)) or diag("Cannot call function GetAwesome!");

is (Acme::AwesomeQuotes::GetAwesome('awesome quotes'), '`àwesome quoteś´', 'Handles basic strings correctly.');
is (Acme::AwesomeQuotes::GetAwesome('d'), '`ď´', 'Handles single letters.');
is (Acme::AwesomeQuotes::GetAwesome(" ; , awesome quotes- . "), '`àwesome quoteś´', 'Strips leading/trailing whitespace and punctuation correctly.');

eval {
	Acme::AwesomeQuotes::GetAwesome('`àwesome quoteś´');
	1;
} && diag ('Did not reject already-awesome text!')
  or like ($@, qr/^String '.+' is \*already\* awesome!/, 'Rejects already-awesome text.');

eval {
	Acme::AwesomeQuotes::GetAwesome('7awesome quotes');
	1;
} && diag ('Did not reject text beginning with a non-letter character!')
  or like ($@, qr/^String '.+' begins with a non-letter character\./, 'Rejects text beginning with a non-letter character.');

eval {
	Acme::AwesomeQuotes::GetAwesome('awesome quotes7');
	1;
} && diag ('Did not reject text terminating in a non-letter character!')
  or like ($@, qr/^String '.+' terminates with a non-letter character\./, 'Rejects text terminating in a non-letter character.');

eval {
	Acme::AwesomeQuotes::GetAwesome('7');
	1;
} && diag ('Did not reject a single non-letter character!')
  or like ($@, qr/^String '.+' (?:terminates|begins) with a non-letter character\./, 'Rejects a single non-letter character.');

eval {
	Acme::AwesomeQuotes::GetAwesome('  ; .- ');
	1;
} && diag ('Did not reject all-whitespace/punctuation string!')
  or like ($@, qr/^String is empty!/, 'Rejects an all-whitespace/punctuation string.');

is (Acme::AwesomeQuotes::GetAwesome('awesome7quotes'), '`àwesome7quoteś´', 'Handles infixed non-letter strings correctly.');
is (Acme::AwesomeQuotes::GetAwesome('àwesome quotes'), '`àwesome quoteś´', 'Handles extant grave prefix correctly.');
is (Acme::AwesomeQuotes::GetAwesome('awesome quoteś'), '`àwesome quoteś´', 'Handles extant acute suffix correctly.');
is (Acme::AwesomeQuotes::GetAwesome('awesome quotes̀'), '`àwesome quoteš´', 'Handles extant grave suffix correctly.');
is (Acme::AwesomeQuotes::GetAwesome('áwesome quotes'), '`ǎwesome quoteś´', 'Handles extant acute prefix correctly.');
is (Acme::AwesomeQuotes::GetAwesome('ǒ'), '`ǒ´', 'Handles extant caron correctly for single letters.');
is (Acme::AwesomeQuotes::GetAwesome('ȟǯ'), '`ȟǯ´', 'Handles extant caron correctly for character strings.');
is (Acme::AwesomeQuotes::GetAwesome('ǻ'), '`å̌´', 'Handles other diacritics correctly for single letters.');
is (Acme::AwesomeQuotes::GetAwesome('ǽĸǻ'), '`æ̌ĸǻ´', 'Handles other diacritics correctly for character strings.');
is (Acme::AwesomeQuotes::GetAwesome('аα'), '`а̀ά´', 'Handles non-latin character strings correctly.');
is (Acme::AwesomeQuotes::GetAwesome('άѝ'), '`α̌и̌´', 'Handles non-latin character strings with extant diacritics correctly.');
is (Acme::AwesomeQuotes::GetAwesome('プログラミング言語'), '`プ̀ログラミング言語́´', 'Handles non-alphabetic character strings correctly.');
