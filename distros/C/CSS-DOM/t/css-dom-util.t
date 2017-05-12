#!/usr/bin/perl -T

use strict; use warnings; no warnings qw 'utf8 parenthesis';
our $tests;
BEGIN { ++$INC{'tests.pm'} }
sub tests'VERSION { $tests += pop };
use Test::More;
plan tests => $tests;

use CSS::DOM::Util ':all';

use tests 7; # escape
is escape(join('', map chr, 0..256), qq'["\x80]'),
	  "\0\01\02\03\04\05\06\07\ch\ci\\a\ck\\c\\d\cn\co"
	. join('',map chr, 0x10..0x1f)
	. ' !\"#$%&\'()*+,-./'
	. join('', map chr, ord 0 ... 0x7f)
	. '\80' . join('',map chr, 0x81..0x100),
	'escape with second arg';
is escape("abcde", "a"), '\61 bcde',
    'escape puts a space after an escape that has a hex digit after it';
is escape("\x{10f008}bcde",qr/\W/), '\10f008bcde',
	'but doesn’t bother with that space if the escape is long enough';
is escape("abcde", "e"), 'abcd\65 ',
    'escape puts a space after an escape that occurs at end of string';
is escape("a bcde", "a"), '\61  bcde',
    'escape puts a space after an escape that is followed by a space';
is escape("a	bcde", "a"), '\61 	bcde',
    'escape puts a space after an escape that is followed by a tab';
is escape(" \t", "[ \t]"), '\ \9 ',
    'escape adds no space after \.. if the following char will be escaped';

use tests 1; #unesacpe
is unescape "\\20\\10fFfff-_abcABC\\}\\7d\\7d \\7d\t\\7d\r\n\\7d\n"
		. "\\7d\r\\7d\f\xff\x{2003}\x{100}\\\t",
	" \x{10ffff}f-_abcABC}}}}}}}}\xff\x{2003}\x{100}\t",
	'unescape';


use tests 5; # escape_ident
is escape_ident(join '', map chr, 0..256),
	  '\0\1\2\3\4\5\6\7\8\9\a\b\c\d\e\f'
	. '\10\11\12\13\14\15\16\17\18\19\1a\1b\1c\1d\1e\1f'
	. '\ \!\"\#\$\%\&\\\'\(\)\*\+\,-\.\/'
	. '0123456789\:\;\<\=\>\?'
	. '\@ABCDEFGHIJKLMNOPQRSTUVWXYZ\[\\\\\]\^_'
	. '\`abcdefghijklmnopqrstuvwxyz\{\|\}\~\7f'
	. join('',map chr, 0x80..0x100),
	'escape_ident';
is escape_ident('-01'), '-\30 1', 'escape_ident "-<digits>..."';
is escape_ident('_01'), '_01', 'escape_ident "_<digits>..."';
is escape_ident('1ab'), '\31 ab', 'escape_ident "<digit><hexdigit>..."';
is escape_ident('1-b'), '\31-b', 'escape_ident "<digit>-..."';

use tests 3; # unescape_url
is unescape_url "url( \f\t \\)()\\20 \n\r )", ")() ",
	'unescape_url with ws but no quotes'; 
is unescape_url "url( \f\t '\\)()\\20\\'' \n\r )", ")() '",
	'unescape_url with single quotes'; 
is unescape_url qq'url( \f\t "\\)()\\20\\"" \n\r )', ')() "',
	'unescape_url with double quotes'; 

use tests 1; # escape_str
is escape_str(join '', map chr, 0..256),
	  "'\0\1\2\3\4\5\6\7\b\t\\a\ck\\c\\d"
	. join('',map chr, 14..ord("'")-1)
	. "\\'"
	. join('', map chr, ord("'")+1..256)
	. "'",
	'escape_str';

use tests 2; # unescape_str
is unescape_str q|'"\'\20'|, q|"' |, 'unescape_str with single quotes';
is unescape_str q|"'\"\20"|, q|'" |, 'unesacpe_srt with double quotes';
