#!/usr/bin/perl -T

use strict; use warnings;
our $tests;
BEGIN { ++$INC{'tests.pm'} }
sub tests'VERSION { $tests += pop };
use Test::More;
plan tests => $tests;

use CSS::DOM::Exception;

use tests 1; # use
use_ok 'CSS::DOM::Rule', ':all';

use tests 7; # constants
{
	my $x;

	for (qw/ UNKNOWN_RULE STYLE_RULE CHARSET_RULE IMPORT_RULE
	         MEDIA_RULE FONT_FACE_RULE PAGE_RULE /) {
		eval "is $_, " . $x++ . ", '$_'";
	}
}


require CSS::DOM;
my $ss = CSS::DOM'parse( 'a{text-decoration: none} p { margin: 0 }');
my $rule = cssRules $ss ->[0];

use tests 1; # isa
isa_ok $rule, 'CSS::DOM::Rule';

use tests 2; #constructor
{
	my $rule = new CSS::DOM::Rule $rule;
	isa_ok $rule, 'CSS::DOM::Rule', 'isa after constructor';
	is type $rule, &UNKNOWN_RULE,
		'type after constructor';
}

use tests 7; # type
$ss->insertRule('@shingly blonged;', 0);
is $ss->cssRules->[0]->type, &UNKNOWN_RULE, 'type of unknown rule';
$ss->insertRule('a{}', 0);
is $ss->cssRules->[0]->type, &STYLE_RULE, 'type of style rule';
$ss->insertRule('@media print {}', 0);
is $ss->cssRules->[0]->type, &MEDIA_RULE, 'type of @media rule';
$ss->insertRule('@font-face {}', 0);
is $ss->cssRules->[0]->type, &FONT_FACE_RULE, 'type of @font-face rule';
$ss->insertRule('@page {}', 0);
is $ss->cssRules->[0]->type, &PAGE_RULE, 'type of @page rule';
$ss->insertRule('@import "', 0);
is $ss->cssRules->[0]->type, &IMPORT_RULE, 'type of @import rule';
$ss->insertRule('@charset "utf-7";', 0);
is $ss->cssRules->[0]->type, &CHARSET_RULE, 'type of @charset rule';

use tests 38; # cssText
{
	my $rule;

	$ss->insertRule('@shlumggom malunga clin drimp.', 0);
	$rule = $ss->cssRules->[0];

	is $rule->cssText, "\@shlumggom malunga clin drimp.;\n",
		'get cssText';
	is $rule->cssText("\@wisto{et [f ee( ( 'eee"),
		"\@shlumggom malunga clin drimp.;\n",
		'get/set cssText';
	is $rule->cssText, "\@wisto{et [f ee( ( 'eee'))]}\n",
		'get cssText again (and bracket closure)';
	$rule->cssText('@\}');
	is $rule->cssText, "\@\\};\n",
		'serialisation of unknown rule ending with \}';
	$rule->cssText('@\;');
	is $rule->cssText, "\@\\;;\n",
		'serialisation of unknown rule ending with \;';

	ok !eval{$rule->cssText('@media canvas {}');1},
		'$unwistrule->cssText dies when set to @media...';
	cmp_ok $@, '==', CSS::DOM::Exception::INVALID_MODIFICATION_ERR,
		'$@ is the correct type';

	
	$ss->insertRule('b{font-family: Monaco}', 0);
	$rule = $ss->cssRules->[0];

	is $rule->cssText, "b { font-family: Monaco }\n",
		'get cssText (ruleset)';
	is $rule->cssText("a{color: blue}"), "b { font-family: Monaco }\n",
		'get/set cssText (ruleset)';
	is $rule->cssText, "a { color: blue }\n",
		'get cssText again (ruleset)';
	$rule->cssText('{ foo: bar }');
	is $rule->cssText, "{ foo: bar }\n",
		'serialised ruleset with universal selector';
		# We don’t want it to have an initial space.


	ok !eval{$rule->cssText('@media canvas {}');1},
		'$stylerule->cssText dies when set to @media...';
	cmp_ok $@, '==', CSS::DOM::Exception::INVALID_MODIFICATION_ERR,
		'$@ is the correct type';

	
	$ss->insertRule('@media print,screen{b{font-family: Monaco}}', 0);
	$rule = $ss->cssRules->[0];

	is $rule->cssText,
	   "\@media print, screen {\n\tb { font-family: Monaco }\n}\n", 
	   'get cssText (@media)';
	is $rule->cssText("\@media screen { }"),
	   "\@media print, screen {\n\tb { font-family: Monaco }\n}\n", 
	   'get/set cssText (@media)';
	is $rule->cssText, "\@media screen {\n}\n",
		'get cssText again (@media)';


	ok !eval{$rule->cssText('a { text-decoration: none }');1},
		'$mediarule->cssText dies when set to a{...}';
	cmp_ok $@, '==', CSS::DOM::Exception::INVALID_MODIFICATION_ERR,
		'$@ is the correct type after cssText <- a {...}';


	$ss->insertRule('@page :left{margin-right:1.5in}', 0);
	$rule = $ss->cssRules->[0];

	is $rule->cssText,
	   "\@page :left { margin-right: 1.5in }\n", 
	   'get cssText (@page)';
	is $rule->cssText("\@page { margin: 1in }"),
	   "\@page :left { margin-right: 1.5in }\n", 
	   'get/set cssText (@page)';
	is $rule->cssText, "\@page { margin: 1in }\n",
		'get cssText again (@page)';


	ok !eval{$rule->cssText('a { text-decoration: none }');1},
		'$pagerule->cssText dies when set to a{...}';
	cmp_ok $@, '==', CSS::DOM::Exception::INVALID_MODIFICATION_ERR,
		'$@ is the correct type after setting cssText on @page';


	$ss->insertRule('@import "\a\2000 foo bar" \70rint, screen', 0);
	$rule = $ss->cssRules->[0];

	is $rule->cssText,
	   '@import "\a\2000 foo bar" print, screen;' . "\n", 
	   'get cssText (@import)';
	is $rule->cssText('@import url( foo.css\)'),
	   '@import "\a\2000 foo bar" print, screen;' . "\n", 
	   'get/set cssText (@import)';
	is $rule->cssText, "\@import url( foo.css\\));\n",
		'get cssText again (@import with url)';


	ok !eval{$rule->cssText('a { text-decoration: none }');1},
		'$importrule->cssText dies when set to a{...}';
	cmp_ok $@, '==', CSS::DOM::Exception::INVALID_MODIFICATION_ERR,
		'$@ is the correct type after setting cssText on @import';


	$ss->insertRule('@font-face{font-family: "ww"; src: url(.t)}', 0);
	$rule = $ss->cssRules->[0];

	is $rule->cssText,
	   "\@font-face { font-family: \"ww\"; src: url(.t) }\n", 
	   'get cssText (@font-face)';
	is $rule->cssText("\@font-face { margin: 1in }"),
	   "\@font-face { font-family: \"ww\"; src: url(.t) }\n", 
	   'get/set cssText (@font-face)';
	is $rule->cssText, "\@font-face { margin: 1in }\n",
		'get cssText again (@font-face)';


	ok !eval{$rule->cssText('a { text-decoration: none }');1},
		'$fontrule->cssText dies when set to a{...}';
	cmp_ok $@, '==', CSS::DOM::Exception::INVALID_MODIFICATION_ERR,
		'$@ is correct type after setting cssText on @font-face';


	$ss->insertRule('@charset "utf-7";', 0);
	$rule = $ss->cssRules->[0];

	is $rule->cssText,
	   "\@charset \"utf-7\";\n", 
	   'get cssText (@charset)';
	is $rule->cssText("\@charset \"\\\"\";"),
	   "\@charset \"utf-7\";\n", 
	   'get/set cssText (@charset)';
	is $rule->cssText, "\@charset \"\\\"\";\n",
		'get cssText again (@charset)';


	ok !eval{$rule->cssText('a { text-decoration: none }');1},
		'$charsetrule->cssText dies when set to a{...}';
	cmp_ok $@, '==', CSS::DOM::Exception::INVALID_MODIFICATION_ERR,
		'$@ is correct type after setting cssText on @charset';
}

use tests 4; # parentStyleSheet and parentRule
{
	is +()=$rule->parentRule, 0, 'null parentRule';
	is $rule->parentStyleSheet, $ss, 'parentStyleSheet';

	$ss->insertRule('@media print { body {background: none}}',0);
	my $media_rule = $ss->cssRules->[0];
	is $media_rule->cssRules->[0]->parentRule, $media_rule,
		'parentRule of child of @media rule';
	is $media_rule->cssRules->[0]->parentStyleSheet, $ss,
		'parentRule of child of @media rule';
}
