#!/usr/bin/perl -T

use strict; use warnings;
our $tests;
BEGIN { ++$INC{'tests.pm'} }
sub tests'VERSION { $tests += pop };
use Test::More;
plan tests => $tests;

use tests 1; # use
use_ok 'CSS::DOM::Rule::FontFace',;


require CSS::DOM;
my $rule = (
	my $ss = CSS::DOM'parse(
		'@font-face { font-family: "foo";src:url(bar) }'
	)
)-> cssRules->[0];
warn $@ if $@;

use tests 1; # isa
isa_ok $rule, 'CSS::DOM::Rule::FontFace';

use tests 7; #constructor
{
	(my $ss = new CSS::DOM)->insertRule('@media screen{}',0);
	my $rule = $ss->cssRules->[0];
	my $empty_rule = new CSS::DOM::Rule::FontFace $rule;
	isa_ok $empty_rule,'CSS::DOM::Rule::FontFace',
		'result of new CSS::DOM::Rule::FontFace (empty rule)';
	is $empty_rule->parentRule, $rule, 'parentRule of empty rule';
	is $empty_rule->parentStyleSheet, $ss,
		'parentStyleSheet of empty rule';
	is $empty_rule->type, &CSS::DOM::Rule::FONT_FACE_RULE,
		'type of empty rule';

	$empty_rule = new CSS::DOM::Rule::FontFace $ss;
	isa_ok $empty_rule, 'CSS::DOM::Rule::FontFace',
		'empty rule with no parent rule';
	is +()=$empty_rule->parentRule, 0,
		'parentRule of empty rule without parent rule';
	is $empty_rule->parentStyleSheet, $ss,
		'parentStyleSheet of empty rule w/no parent rule';
}

use tests 2; # style
isa_ok style $rule, 'CSS::DOM::Style', 'ret val of style';
is style $rule ->fontFamily, '"foo"',
	'the style decl does have the css stuff, so it’s the right one';
