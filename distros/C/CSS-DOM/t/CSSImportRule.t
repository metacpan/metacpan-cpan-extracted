#!/usr/bin/perl -T

use strict; use warnings;
our $tests;
BEGIN { ++$INC{'tests.pm'} }
sub tests'VERSION { $tests += pop };
use Test::More;
plan tests => $tests;

use CSS::DOM::Exception;


use tests 1; # use
use_ok 'CSS::DOM::Rule::Import';

require CSS::DOM;
my $rule = (
	my $ss = CSS::DOM'parse(
		'@import "foo.css" tv, screen'
	)
)-> cssRules->[0];

use tests 1; # isa
isa_ok $rule, 'CSS::DOM::Rule::Import';

use tests 7; #constructor
{
	(my $ss = new CSS::DOM)->insertRule('@Import "print"',0);
	my $rule = $ss->cssRules->[0];
	my $empty_rule = new CSS::DOM::Rule::Import $rule;
	isa_ok $empty_rule,'CSS::DOM::Rule::Import',
		'result of new CSS::DOM::Rule::Import (empty rule)';
	is $empty_rule->parentRule, $rule, 'parentRule of empty rule';
	is $empty_rule->parentStyleSheet, $ss,
		'parentStyleSheet of empty rule';
	is $empty_rule->type, &CSS::DOM::Rule::IMPORT_RULE,
		'type of empty rule';

	$empty_rule = new CSS::DOM::Rule::Import $ss;
	isa_ok $empty_rule, 'CSS::DOM::Rule::Import',
		'empty rule with no parent rule';
	is +()=$empty_rule->parentRule, 0,
		'parentRule of empty rule without parent rule';
	is $empty_rule->parentStyleSheet, $ss,
		'parentStyleSheet of empty rule w/no parent rule';
}

use tests 2; # href
{
	(my $ss =new CSS::DOM)->insertRule('@Import "foo.css"',0);
	my $rule = $ss->cssRules->[0];
	is $rule->href, "foo.css", 'href when its a string in the source';

	($ss =new CSS::DOM)->insertRule('@Import url("har.css")',0);
	$rule = $ss->cssRules->[0];
	is $rule->href, "har.css", 'href when its a url in the source';
}

use tests 2; # media
{
	isa_ok $rule->media, 'CSS::DOM::MediaList';
	$rule->media->mediaText('tv, screen');
	is_deeply [$rule->media], [tv=>screen=>],
		'media in list context';
}


use tests 5; # styleSheet
{
	(my $ss = new CSS::DOM) ->insertRule('@Import "foo.css"',0);
	my $rule = $ss->cssRules->[0];
	is +()=$rule->styleSheet, 0, 'null styleSheet';

	($ss = new CSS::DOM url_fetcher =>
		sub {return "a { color:red}" }
	)->insertRule('@Import "foo.css"',0);
	$rule = $ss->cssRules->[0];

	isa_ok $rule->styleSheet, 'CSS::DOM', 'styleSheet';
	is join('', map $_->cssText, $rule->styleSheet->cssRules),	
		"a { color: red }\n",
		'seralised styleSheet';

	($ss = new CSS::DOM url_fetcher => sub { })
		->insertRule('@Import "foo.css"',0);
	$rule = $ss->cssRules->[0];

	$rule->styleSheet; # keep this line here; multiple calls to
	                   # styleSheet were making it return (0) in list
	                   # context instead of ()
	is +()=$rule->styleSheet, 0, 
		'null styleSheet when callback returns undef';

	my %urls = (
		'foo.css' => '@import "bar.css"',
		'bar.css' => 'a { color: blue }',
	);
	is CSS'DOM'parse('@import "foo.css',url_fetcher=>sub{$urls{$_[0]}})
		->cssRules->[0]->styleSheet
		->cssRules->[0]->styleSheet
		->cssRules->[0]->style->color,
		'blue',
	 'styleSheet of a recursive/nested @import, whatever you call it';
}
