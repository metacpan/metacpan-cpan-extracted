#!/usr/bin/perl -T

use strict; use warnings;
our $tests;
BEGIN { ++$INC{'tests.pm'} }
sub tests'VERSION { $tests += pop };
use Test::More;
plan tests => $tests;


use tests 1; # use
use_ok 'CSS::DOM::Rule::Page',;


require CSS::DOM;
my $rule = (
	my $ss = CSS::DOM'parse( '@page:first{ margin-top: 3in }')
)-> cssRules->[0];

use tests 1; # isa
isa_ok $rule, 'CSS::DOM::Rule::Page';

use tests 7; #constructor
{
	(my $ss = new CSS::DOM)->insertRule('@media screen{}',0);
	my $rule = $ss->cssRules->[0];
	my $empty_rule = new CSS::DOM::Rule::Page $rule;
	isa_ok $empty_rule,'CSS::DOM::Rule::Page',
		'result of new CSS::DOM::Rule::Page (empty rule)';
	is $empty_rule->parentRule, $rule, 'parentRule of empty rule';
	is $empty_rule->parentStyleSheet, $ss,
		'parentStyleSheet of empty rule';
	is $empty_rule->type, &CSS::DOM::Rule::PAGE_RULE,
		'type of empty rule';

	$empty_rule = new CSS::DOM::Rule::Page $ss;
	isa_ok $empty_rule, 'CSS::DOM::Rule::Page',
		'empty rule with no parent rule';
	is +()=$empty_rule->parentRule, 0,
		'parentRule of empty rule without parent rule';
	is $empty_rule->parentStyleSheet, $ss,
		'parentStyleSheet of empty rule w/no parent rule';
}

use tests 5; # selectorText
{
	$ss->insertRule('@page:first{}',
	0);
	is +(my $rule = $ss->cssRules->[0])->selectorText,
		'@page:first',
	   'selectorText';
	is $rule->selectorText('@page'),
		'@page:first',
	   'get/set selectorText';
	is $rule->selectorText, '@page', 'get selectorText again';
	ok !eval{$rule->selectorText('body');1},
	  'setting selectorText to something other than @page... dies';
	cmp_ok $@, '==', &CSS::DOM::Exception::SYNTAX_ERR;
}


use tests 2; # style
isa_ok style $rule, 'CSS::DOM::Style', 'ret val of style';
is style $rule ->marginTop, '3in',
	'the style decl does have the css stuff, so it’s the right one';
