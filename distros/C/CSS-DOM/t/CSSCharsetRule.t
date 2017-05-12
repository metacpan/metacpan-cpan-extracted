#!/usr/bin/perl -T

use strict; use warnings;
our $tests;
BEGIN { ++$INC{'tests.pm'} }
sub tests'VERSION { $tests += pop };
use Test::More;
plan tests => $tests;

use tests 1; # use
use_ok 'CSS::DOM::Rule::Charset',;


require CSS::DOM;
my $rule = (
	my $ss = CSS::DOM'parse(
		'@charset "utf-8";'
	)
)-> cssRules->[0];

use tests 1; # isa
isa_ok $rule, 'CSS::DOM::Rule::Charset';
diag $@ if $@;

use tests 7; #constructor
{
	(my $ss = new CSS::DOM)->insertRule('@import "stuff"',0);
	my $rule = $ss->cssRules->[0];
	my $empty_rule = new CSS::DOM::Rule::Charset $rule;
	isa_ok $empty_rule,'CSS::DOM::Rule::Charset',
		'result of new CSS::DOM::Rule::Charset (empty rule)';
	is $empty_rule->parentRule, $rule, 'parentRule of empty rule';
	is $empty_rule->parentStyleSheet, $ss,
		'parentStyleSheet of empty rule';
	is $empty_rule->type, &CSS::DOM::Rule::CHARSET_RULE,
		'type of empty rule';

	$empty_rule = new CSS::DOM::Rule::Charset $ss;
	isa_ok $empty_rule, 'CSS::DOM::Rule::Charset',
		'empty rule with no parent rule';
	is +()=$empty_rule->parentRule, 0,
		'parentRule of empty rule without parent rule';
	is $empty_rule->parentStyleSheet, $ss,
		'parentStyleSheet of empty rule w/no parent rule';
}

use tests 5; # encoding
is encoding $rule, 'utf-8', 'encoding';
is $rule->encoding('"'), 'utf-8', 'get/set encoding';
is encoding $rule, '"', 'get encoding again';
is $rule->cssText, "\@charset \"\\\"\";\n",
	'cssText after setting encoding';
$rule->cssText('@charset "utf\-8";');
is encoding $rule, 'utf-8', 'the encoding name is unescaped';
