#!/usr/bin/perl -T

use strict; use warnings;
our $tests;
BEGIN { ++$INC{'tests.pm'} }
sub tests'VERSION { $tests += pop };
use Test::More;
plan tests => $tests;


use tests 1; # use
use_ok 'CSS::DOM::Rule::Style',;


require CSS::DOM;
my $rule = (
	my $ss = CSS::DOM'parse('a{text-decoration: none} p { margin: 0 }')
)-> cssRules->[0];

use tests 1; # isa
isa_ok $rule, 'CSS::DOM::Rule::Style';

use tests 7; #constructor
{
	(my $ss = new CSS::DOM)->insertRule('a{}',0);
	my $rule = $ss->cssRules->[0];
	my $empty_rule = new CSS::DOM::Rule::Style $rule;
	isa_ok $empty_rule,'CSS::DOM::Rule::Style',
		'result of new CSS::DOM::Rule::Style (empty rule)';
	is $empty_rule->parentRule, $rule, 'parentRule of empty rule';
	is $empty_rule->parentStyleSheet, $ss,
		'parentStyleSheet of empty rule';
	is $empty_rule->type, &CSS::DOM::Rule::STYLE_RULE,
		'type of empty rule';

	$empty_rule = new CSS::DOM::Rule::Style $ss;
	isa_ok $empty_rule, 'CSS::DOM::Rule::Style',
		'empty rule with no parent rule';
	is +()=$empty_rule->parentRule, 0,
		'parentRule of empty rule without parent rule';
	is $empty_rule->parentStyleSheet, $ss,
		'parentStyleSheet of empty rule w/no parent rule';
}

use tests 3; # selectorText
{
	$ss->insertRule('*, a, b i, p > ul, div:first-child, a:link,
		a:visited, a:active, a:hover, a:focus, em:lang(en), tr+td,
		html[version], body[style="margin: 0"],
		table[class~=\'foo\'], strong[lang|="en"], a.bbbb, .ed,
		img#foo, #bar{}',
	0);
	is +(my $rule = $ss->cssRules->[0])->selectorText,
		'*, a, b i, p > ul, div:first-child, a:link,
		a:visited, a:active, a:hover, a:focus, em:lang(en), tr+td,
		html[version], body[style="margin: 0"],
		table[class~=\'foo\'], strong[lang|="en"], a.bbbb, .ed,
		img#foo, #bar',
	   'selectorText';
	is $rule->selectorText('address'),
		'*, a, b i, p > ul, div:first-child, a:link,
		a:visited, a:active, a:hover, a:focus, em:lang(en), tr+td,
		html[version], body[style="margin: 0"],
		table[class~=\'foo\'], strong[lang|="en"], a.bbbb, .ed,
		img#foo, #bar',
	   'get/set selectorText';
	is $rule->selectorText, 'address', 'get selectorText again';
}


use tests 2; # style
isa_ok style $rule, 'CSS::DOM::Style', 'ret val of style';
is style $rule ->textDecoration, 'none',
	'the style decl does have the css stuff, so it’s the right one';
