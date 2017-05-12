#!/usr/bin/perl -T

use strict; use warnings;
our $tests;
BEGIN { ++$INC{'tests.pm'} }
sub tests'VERSION { $tests += pop };
use Test::More;
plan tests => $tests;

use CSS::DOM::Exception;

use tests 1; # use
use_ok 'CSS::DOM::Rule::Media';


require CSS::DOM;
my $rule = (
	my $ss = CSS::DOM'parse(
		'@media print { body { background: none } }'
	)
)-> cssRules->[0];

use tests 1; # isa
isa_ok $rule, 'CSS::DOM::Rule::Media';

use tests 7; #constructor
{
	(my $ss = new CSS::DOM)->insertRule('@media print {}',0);
	my $rule = $ss->cssRules->[0];
	my $empty_rule = new CSS::DOM::Rule::Media $rule;
	isa_ok $empty_rule,'CSS::DOM::Rule::Media',
		'result of new CSS::DOM::Rule::Media (empty rule)';
	is $empty_rule->parentRule, $rule, 'parentRule of empty rule';
	is $empty_rule->parentStyleSheet, $ss,
		'parentStyleSheet of empty rule';
	is $empty_rule->type, &CSS::DOM::Rule::MEDIA_RULE,
		'type of empty rule';

	$empty_rule = new CSS::DOM::Rule::Media $ss;
	isa_ok $empty_rule, 'CSS::DOM::Rule::Media',
		'empty rule with no parent rule';
	is +()=$empty_rule->parentRule, 0,
		'parentRule of empty rule without parent rule';
	is $empty_rule->parentStyleSheet, $ss,
		'parentStyleSheet of empty rule w/no parent rule';
}

use tests 2; # media
{
	isa_ok $rule->media, 'CSS::DOM::MediaList';
	$rule->media->mediaText('screen, printer');
	is_deeply [$rule->media], [screen=>printer=>],
		'media in list context';
}

use tests 2; # cssRules
{
	my $rule = (
		CSS::DOM::parse(
			'@media print {
				a{text-decoration: none} p { margin: 0 }
			 }'
		)
	)-> cssRules->[0];

	is +()=$rule->cssRules, 2, 'cssRules in list context';
	isa_ok my $rules = cssRules $rule, 'CSS::DOM::RuleList',
		'cssRules in scalar context';
}

use tests 13; # insertRule
{
	my $rule = (
		my $ss = CSS::DOM::parse(
			'@media print {
				a{text-decoration: none} p { margin: 0 }
			 }'
		)
	)-> cssRules->[0];
	
	is $rule->insertRule('b { font-weight: bold }', 0), 0,
		'retval of insertRule';
	is_deeply [map $_->selectorText, $rule->cssRules], [qw/ b a p /],
		'result of insertRule with 0 for the index';
	is $rule->cssRules->[0]->style->cssText, 'font-weight: bold',
		'Are the contents of insertRule\'s new rule present?';
	isa_ok $rule->cssRules->[0], 'CSS::DOM::Rule';

	is $rule->insertRule('i {}', -1), 2,
		'retval of insertRule with negative index';
	is_deeply [map $_->selectorText, $rule->cssRules], [qw/ b a i p /],
		'result of insertRule with negative index';

	{
		local $SIG{__WARN__} = sub{};
		is $rule->insertRule('u {}', 27), 4,
			'retval of insertRule with large index';
	}
	is_deeply [map $_->selectorText, $rule->cssRules],
		 [qw/ b a i p u /],
		'result of insertRule with large index';

	is +()=eval{$rule->insertRule(' two{} rules{}',0)}, 0,
		'insertRule fails with two rules';
	isa_ok $@, 'CSS::DOM::Exception','$@';
	cmp_ok $@, '==', CSS::DOM::Exception::SYNTAX_ERR,
		'$@ is a SYNTAX_ERR';

	my $subrule = $rule->cssRules->[
		$rule->insertRule('foo{bar:baz}',0)
	];
	is $subrule->parentStyleSheet, $ss,
		'parentStyleSheet is set by insertRule';
	is $subrule->parentRule, $rule, 'insertRule sets teh parentRule';
}

use tests 4; # deleteRule
{
	my $rule = (
		CSS::DOM::parse(
			'@media print {
			  a{text-decoration: none} p { margin: 0 } i {}
			 }'
		)
	)-> cssRules->[0];
	is +()=$rule->deleteRule(1), 0, 'retval of deleteRule';
	is_deeply [map $_->selectorText, $rule->cssRules], [qw/ a i /],
		'result of deleteRule';
	eval {
		$rule->deleteRule(79);
	};
	isa_ok $@, 'CSS::DOM::Exception', 'exception thrown by deleteRule';
	cmp_ok $@, '==', CSS::DOM::Exception::INDEX_SIZE_ERR,
		'error raised by deleteRule';

}