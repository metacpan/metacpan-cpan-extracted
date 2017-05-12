#!/usr/bin/perl -T

use strict; use warnings; no warnings qw 'utf8 parenthesis';
our $tests;
BEGIN { ++$INC{'tests.pm'} }
sub tests'VERSION { $tests += pop };
use Test::More;
plan tests => $tests;

use utf8;

use CSS::DOM;
use CSS::DOM::Rule::Import;
use CSS::DOM::Style;
use CSS::DOM::Value::Primitive ':all';

use tests 370; # identifiers
for('_', 'a'..'z', 'A'.."Z", map(chr,0x80..0x100) ,"\x{2003}","\x{3000}"){
	my $style = CSS::DOM::Style::parse($_ . 
		"\\20\\10fFfff-_abcABC\\}\\7d\\7d \\7d\t\\7d\r\n\\7d\n"
		. "\\7d\r\\7d\f\xff\x{2003}\x{100}\\\t"
		. ": 65"
	);
	is $style->getPropertyValue(
		"$_ \x{10ffff}f-_abcABC}}}}}}}}\xff\x{2003}\x{100}\t"
	), 65, 'identifier beginning with ' . (ord()<127 ? $_ :"chr ".ord);

	$style = CSS::DOM::Style::parse("-$_" . 
		"\\20\\10fFfff-_abcABC\\}\\7d\\7d \\7d\t\\7d\r\n\\7d\n"
		. "\\7d\r\\7d\f\xff\x{2003}\x{100}\\\t"
		. ": 65"
	);
	is $style->getPropertyValue(
		"-$_ \x{10ffff}f-_abcABC}}}}}}}}\xff\x{2003}\x{100}\t"
	), 65, 'identifier beginning with -'. (ord()<127 ? $_ :"chr ".ord);
}
{
	my $style = CSS::DOM::Style::parse("--a: 65");
	is $style->cssText, '', 'identifier can\'t begin with --';
	$style = CSS'DOM'Style'parse"-0b:-0b";
	is $style->cssText, '', 'nor with -0';
}

use tests 8; # strings
{
	my $nasty_escaped_string =
		"\\20\\10fFfff-_abcABC\\}\\7d\\7d \\7d\t\\7d\r\n\\7d\n"
		. "\\7d\r\\7d\f\xff\x{2003}\x{100}\\\r\n\\\n\\\r\\\t\\\f"
		. q/\'\"/;
	my $expect =
		qq/ \x{10ffff}f-_abcABC}}}}}}}}\xff\x{2003}\x{100}\t'"/;
	my $rule = new CSS::DOM::Rule'Import; 

	$rule->cssText('@import ' . "'$nasty_escaped_string'");
	is $rule->href, $expect, "'...'";
	$rule->cssText('@import ' . qq'"$nasty_escaped_string"');
	is $rule->href, $expect, '"..."';
	$rule->cssText('@import ' . "'$nasty_escaped_string");
	is $rule->href, $expect, "'...";
	$rule->cssText('@import ' . qq'"$nasty_escaped_string');
	is $rule->href, $expect, '"...';
	$rule->cssText('@import ' . q"'\'");
	is $rule->href, "'", q"'\'";
	$rule->cssText('@import ' . q'"\"');
	is $rule->href, '"', '"\"';
	$rule->cssText('@import ' . q"'");
	is $rule->href, "", q"'";
	$rule->cssText('@import ' . q'"');
	is $rule->href, '', '"';
}


# ~~~ once both selectors mean something and getCSSPropertyValue is imple-
#     mented, we need #hash tests

# ~~~ numbers
# ~~~ percent
# ~~~ dimensions


use tests 23; # urls
{
	my $rule = new CSS'DOM'Rule::Import;

	$rule->cssText('@import url(!$#%&][\\\}|{*~foo/bar.gif)');
	is $rule->href, '!$#%&][\}|{*~foo/bar.gif', 'unquoted url';
	$rule->cssText('@import url(/*foo*/foo/bar.gif/*bar)');
	is $rule->href, '/*foo*/foo/bar.gif/*bar', 
		'unquoted url w/"comments"';
	$rule->cssText('@import url("\"\'foo")');
	is $rule->href, q/"'foo/, 'double-quoted url';
	$rule->cssText('@import url(\'\\\'"foo\')');
	is $rule->href, q/'"foo/, 'single-quoted url';
	$rule->cssText("\@import url(\n \t\f\rstuff   \r\n\t \f)");
	is $rule->href, "stuff",
		'unquoted url with ws';
	$rule->cssText("\@import url(\n \t\f\r'stuff'   \r\n\t \f)");
	is $rule->href, "stuff",
		'single-quoted url with ws';
	$rule->cssText(qq'\@import url(\n \t\f\r"stuff"   \r\n\t \f)');
	is $rule->href, "stuff",
		'double-quoted url with ws';
	$rule->cssText('@import '.
		"url(\x{2000}\\2000\r\n\\a\n\\20 0\\20\r\\20\f\\)\\z)"
	);
	is $rule->href, "\x{2000}\x{2000}\n 0  )z",
		'unquoted url with escapes';
	$rule->cssText('@import '.
		"url('\x{2000}\\2000\r\n\\a\n\\20 0\\20\r\\20\f\\)"
		."\\\r\n\\\n\\\r\\\t\\\f\\z')"
	);
	is $rule->href, "\x{2000}\x{2000}\n 0  )\tz",
		'single-quoted  url with escapes';
	$rule->cssText('@import '.
		"url(\"\x{2000}\\2000\r\n\\a\n\\20 0\\20\r\\20\f\\)"
		."\\\r\n\\\n\\\r\\\t\\\f\\z\")"
	);
	is $rule->href, "\x{2000}\x{2000}\n 0  )\tz",
		'double-quoted url with escapes';

	my $style = new CSS'DOM'Style;

	$style->name('url(foo');
	is $style->name, 'url(foo)', 'unquoted, unterminated url';
	$style->name('url(\'goo');
	is $style->name, 'url(\'goo\')',
		'single-quoted, unterminated url';
	$style->name('url("foo');
	is $style->name, 'url("foo")',
		'double-quoted, unterminated url';
	$style->name('url(');
	is $style->name, 'url()', 'blank unquoted, unterminated url';
	$style->name('url(\'');
	is $style->name, 'url(\'\')',
		'blank single-quoted, unterminated url';
	$style->name('url("');
	is $style->name, 'url("")',
		'blank double-quoted, unterminated url';
	$style->name('url(');
	is $style->name, 'url()',
		'unterminated unquoted url, ending with \)';
	$style->name(q"url('\'");
	is $style->name, q"url('\'')",
		'unterminated single-quoted url, ending with \\\'';
	$style->name('url("\"');
	is $style->name, 'url("\"")',
		'unterminated double-quoted url, ending with \"';
	$style->name(q"url('foo'");
	is $style->name, q"url('foo')",
		'single-quoted url without )';
	$style->name('url("foo"');
	is $style->name, 'url("foo")',
		'double-quoted url without )';
	$style->name(q"url('foo' ");
	is $style->name, q"url('foo' )",
		'single-quoted url without ) but with ws';
	$style->name('url("foo" ');
	is $style->name, 'url("foo" )',
		'double-quoted url without ) but with ws';
}

# ~~~ unicode range
# Come to think of it, if we didn’t support this as a separate token,
# U+abcd-U+012a would be interpreted as
# ident [U], delim [+], ident [abcd], delim [-], dim [012a]
# which would still become a CSS_UNKNOWN value whose cssText value returned
# exactly the same. So a test for it would pass whether unirange were a
# token or not. (Or would it become a primitive with a type of CSS_CUSTOM?)

use tests 3; # spaces and comments
{
	my $style = CSS::DOM::Style::parse(
		"name/*fooo*/  :"
		." \t\r\n\f/*etet*/ /**oo**//*oo** * **/\n/*/** /*/"
		. 'value/*eeeee'
	);
	is $style->name, 'value', 'whitespace and comments';
	$style = CSS::DOM::Style::parse(
		"name:valu  /*eeeee "  
	);
	is $style->name, 'valu', 'another ws /**/ test';
	$style = CSS'DOM'Style'parse( "name: /*\n*/valu");
	is $style->name, 'valu', 'multiline comments';
}

# ~~~ function

use tests 6; # <!-- -->
{
	my $sheet = CSS'DOM'parse ' <!--{ name: value }--> @media print{}';
	is join('',map cssText$_,cssRules$sheet),
		"{ name: value }\n\@media print {\n}\n",
		'ignored <!-- -->';
	is CSS'DOM'parse"{}{name: <!-- value; n:v}" =>->
		cssRules->length,
	   1,
		'invalid <!--';
	ok $@, '$@ after invalid <!--';
	is CSS'DOM'parse"{}{name: --> value; n:v}" =>->
		cssRules->length,
	   1,
		'invalid -->';
	ok $@, '$@ after invalid -->';
	is CSS'DOM'Style'parse"name:'<!--value-->",->name,
		"'<!--value-->'", '<!-- --> in a string';
}

use tests 1; # miscellaneous tokens
{
	my $sheet = CSS'DOM'parse  '@foo ()[~=:,./+-]{[("\"';
	is $sheet->cssRules->[0]->cssText,
		'@foo ()[~=:,./+-]{[("\"")]}'. "\n",
		'miscellaneous tokens'
}
