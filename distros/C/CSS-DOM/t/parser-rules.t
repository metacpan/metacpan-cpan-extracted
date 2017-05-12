#!/usr/bin/perl -T

# Note:  The serialisation tests in the script are not strictly normative.
# If the implementation changes, they can be tweaked. The point is to make
# sure that the parser provides the rule object with all the info it needs,
# without omitting anything.

use strict; use warnings; no warnings qw 'utf8 parenthesis';
our $tests;
BEGIN { ++$INC{'tests.pm'} }
sub tests'VERSION { $tests += pop };
use Test::More;
plan tests => $tests;

use utf8;

use CSS::DOM;
use CSS::DOM::Rule ':all';
use CSS::DOM::Style;

use tests 2; # miscellaneous CSS::DOM::parse stuff
{            # not sure if it belongs in this test script
	my $x;
	styleSheet $_  # styleSheet triggers the url fetch
		for CSS::DOM::parse '@import ""; @import ""',
			url_fetcher => sub{++$x;''}
		  =>-> cssRules;
	is $x, 2, 'parser passes args to new CSS::DOM';

	$x = 0;
	local $SIG{__WARN__} = sub { ++ $x; };
	CSS::DOM::parse('');
	is $x, 0, 'empty stylesheet doesn\'t cause warnings';
}

use tests 7; # <!-- -->
{
	my $sheet = CSS'DOM'parse '
		<!-- /* --> /* /**/
		@at-rule {/*<!--*/ } <!--
		-->
		{ style/*-->*/: rule } -->
		<!--	
	';
	is join('', map cssText$_,cssRules$sheet),
		'@at-rule {/*<!--*/ }' . "\n" .
		"{ style: rule }\n",
		'<!-- -->';
	CSS'DOM'parse 'a { --> }';
	ok $@, 'invalid -->';
	CSS'DOM'parse 'a { <!-- }';
	ok $@, 'invalid <!--';
	ok !eval{$sheet->insertRule('--> a { }');1},
		'invalid --> before statement';
	ok !eval{$sheet->insertRule('<!-- a { }');1},
		'invalid <!-- before statement';
	ok !eval{$sheet->insertRule('a { }-->');1},
		'invalid --> after statement';
	ok !eval{$sheet->insertRule('a { }<!--');1},
		'invalid <!-- after statement';
}

use tests 5; # single statement parser
{
	my $sheet = new CSS'DOM;
	$sheet->insertRule('phoo { bar : baz} ',0);
	isa_ok cssRules$sheet->[0], 'CSS::DOM::Rule::Style',
		'ruleset created by insertRule';
	is cssRules$sheet->[0]->cssText, "phoo { bar: baz }\n",
		'ruleset created by insertRule';
	$sheet->insertRule('@media print {}',0);
	isa_ok cssRules$sheet->[0], 'CSS::DOM::Rule::Media',
		'@media rule created by insertRule';
	is cssRules$sheet->[0]->cssText, "\@media print {\n}\n",
		'@media rule created by insertRule';
	ok !eval{$sheet->insertRule('foo { bar: baz } @Media print {');1},
		'statement parser chokes on multiple statements'
}

use tests 9; # styledecl parser
{
	my $style = CSS'DOM'Style'parse  ' foo : bar ';
	is $style->cssText, 'foo: bar', 'style parser';
	CSS'DOM'Style'parse 'foo: bar}';
	ok $@, 'style parser chokes on }';
	is CSS'DOM'Style'parse  ' ; ;;;;;foo : bar ;;;; ; ',->cssText,
		'foo: bar', 'style wit extra semicolons';
	is CSS'DOM'Style'parse  'foo:bar',->cssText,
		'foo: bar', 'style with no space';
	is CSS'DOM'Style'parse  'foo:bar;;;baz:bonk;;',->cssText,
		'foo: bar; baz: bonk',
		'style with no space & extra semicolons';
	is CSS'DOM'Style'parse  'foo:bar;;;!baz:bonk;;',->cssText,
		'foo: bar',
		'style with delimiter+ident for property name';
	is CSS'DOM'Style'parse  '\70\41 dding:0;;;;;',->cssText,
		'padding: 0',
		'style with escaped property name';

	is CSS'DOM'Style'parse '\a\z\A\Z\)\a a :bar',
		->getPropertyValue("\nz\nZ)\na"), 'bar',
		'style with both kinds of ident escapes';

	{ package Phoo; use overload '""'=>sub{'foo:bar'}}
	is CSS'DOM'Style'parse(bless [], 'Phoo')->cssText, 'foo: bar',
		'::Style::parse\'s force stringification';
}

use tests 121; # @media
{
	my $sheet = new CSS'DOM; my $rule;

	$sheet->insertRule('@media print{a{color:blue}}',0);
	isa_ok $rule=pop@{$sheet->cssRules}, 'CSS::DOM::Rule::Media',
		'lc @media rule with one medium not followed by ws';
	is $rule->cssText, "\@media print {\n\ta { color: blue }\n}\n",
		'serialised lc @media rule w/1 medium not followed by ws';

	$sheet->insertRule('@media print { a{color:blue} } ',0);
	isa_ok $rule=pop@{$sheet->cssRules}, 'CSS::DOM::Rule::Media',
		'lc @media rule with one medium followed by ws';
	is $rule->cssText, "\@media print {\n\ta { color: blue }\n}\n",
		'serialised lc @media rule w/1 medium followed by ws';

	$sheet->insertRule('@media print,screen,tv{a{color:blue}}',0);
	isa_ok $rule=pop@{$sheet->cssRules}, 'CSS::DOM::Rule::Media',
		'lc @media rule with multiple media without ws';
	is $rule->cssText, "\@media print, screen, tv {\n"
		."\ta { color: blue }\n}\n",
		'serialised lc @media rule with multiple media without ws';

	$sheet->insertRule('@media print , screen , tv { a{color:blue} }
		 ',0);
	isa_ok $rule=pop@{$sheet->cssRules}, 'CSS::DOM::Rule::Media',
		'lc @media rule with multiple media and ws';
	is $rule->cssText, "\@media print, screen, tv {\n"
		."\ta { color: blue }\n}\n",
		'serialised lc @media rule with multiple media and ws';

	$sheet->insertRule('@meDIa print{a{color:blue}}',0);
	isa_ok $rule=pop@{$sheet->cssRules}, 'CSS::DOM::Rule::Media',
		'@meDIa rule with one medium not followed by ws';
	is $rule->cssText, "\@media print {\n\ta { color: blue }\n}\n",
		'serialised @meDIa rule w/1 medium not followed by ws';

	$sheet->insertRule('@meDIa print { a{color:blue} } ',0);
	isa_ok $rule=pop@{$sheet->cssRules}, 'CSS::DOM::Rule::Media',
		'@meDIa rule with one medium followed by ws';
	is $rule->cssText, "\@media print {\n\ta { color: blue }\n}\n",
		'serialised @meDIa rule w/1 medium followed by ws';

	$sheet->insertRule('@meDIa print,screen,tv{a{color:blue}}',0);
	isa_ok $rule=pop@{$sheet->cssRules}, 'CSS::DOM::Rule::Media',
		'@meDIa rule with multiple media without ws';
	is $rule->cssText, "\@media print, screen, tv {\n"
		."\ta { color: blue }\n}\n",
		'serialised @meDIa rule with multiple media without ws';

	$sheet->insertRule('@meDIa print , screen , tv { a{color:blue} }
		 ',0);
	isa_ok $rule=pop@{$sheet->cssRules}, 'CSS::DOM::Rule::Media',
		'@meDIa rule with multiple media and ws';
	is $rule->cssText, "\@media print, screen, tv {\n"
		."\ta { color: blue }\n}\n",
		'serialised @meDIa rule with multiple media and ws';

	$sheet->insertRule('@media print{a{color:blue',0);
	isa_ok $rule=pop@{$sheet->cssRules}, 'CSS::DOM::Rule::Media',
		'unclosed lc @media rule w/one medium without ws';
	is $rule->cssText, "\@media print {\n\ta { color: blue }\n}\n",
		'serialised unclosed lc @media rule w/1 medium without ws';

	$sheet->insertRule('@media print { a{color:blue  ',0);
	isa_ok $rule=pop@{$sheet->cssRules}, 'CSS::DOM::Rule::Media',
		'unclosed lc @media rule with one medium and ws';
	is $rule->cssText, "\@media print {\n\ta { color: blue }\n}\n",
		'serialised unclosed lc @media rule w/1 medium and ws';

	$sheet->insertRule('@media print,screen,tv{a{color:blue',0);
	isa_ok $rule=pop@{$sheet->cssRules}, 'CSS::DOM::Rule::Media',
		'unclosed lc @media rule with multiple media without ws';
	is $rule->cssText, "\@media print, screen, tv {\n"
		."\ta { color: blue }\n}\n",
		'serialised unclosed lc @media w/multiple media w/o ws';

	$sheet->insertRule('@media print , screen , tv { a{color:blue ',0);
	isa_ok $rule=pop@{$sheet->cssRules}, 'CSS::DOM::Rule::Media',
		'unclosed lc @media rule with multiple media and ws';
	is $rule->cssText, "\@media print, screen, tv {\n"
		."\ta { color: blue }\n}\n",
		'serialised unclosed lc @media rule w/multiple media & ws';

	$sheet->insertRule('@meDIa print{a{color:blue',0);
	isa_ok $rule=pop@{$sheet->cssRules}, 'CSS::DOM::Rule::Media',
		'unclosed @meDIa rule with one medium not followed by ws';
	is $rule->cssText, "\@media print {\n\ta { color: blue }\n}\n",
		'serialised unclosed @meDIa rule w/1 medium without ws';

	$sheet->insertRule('@meDIa print { a{color:blue ',0);
	isa_ok $rule=pop@{$sheet->cssRules}, 'CSS::DOM::Rule::Media',
		'unclosed @meDIa rule with one medium followed by ws';
	is $rule->cssText, "\@media print {\n\ta { color: blue }\n}\n",
		'serialised unclosed @meDIa rule w/1 medium and ws';

	$sheet->insertRule('@meDIa print,screen,tv{a{color:blue',0);
	isa_ok $rule=pop@{$sheet->cssRules}, 'CSS::DOM::Rule::Media',
		'unclosed @meDIa rule with multiple media without ws';
	is $rule->cssText, "\@media print, screen, tv {\n"
		."\ta { color: blue }\n}\n",
		'serialised unclosed @meDIa rule w/multiple media w/o ws';

	$sheet->insertRule('@meDIa print , screen , tv { a{color:blue ',0);
	isa_ok $rule=pop@{$sheet->cssRules}, 'CSS::DOM::Rule::Media',
		'unclosed @meDIa rule with multiple media and ws';
	is $rule->cssText, "\@media print, screen, tv {\n"
		."\ta { color: blue }\n}\n",
		'serialised unclosed @meDIa rule w/multiple media and ws';

	$sheet->insertRule('@media print{}',0);
	isa_ok $rule=pop@{$sheet->cssRules}, 'CSS::DOM::Rule::Media',
		'empty lc @media rule with one medium not followed by ws';
	is $rule->cssText, "\@media print {\n}\n",
		'serialised empty lc @media rule w/1 medium without ws';

	$sheet->insertRule('@media print {  } ',0);
	isa_ok $rule=pop@{$sheet->cssRules}, 'CSS::DOM::Rule::Media',
		'empty lc @media rule with one medium followed by ws';
	is $rule->cssText, "\@media print {\n}\n",
		'serialised empty lc @media rule w/1 medium and ws';

	$sheet->insertRule('@media print,screen,tv{}',0);
	isa_ok $rule=pop@{$sheet->cssRules}, 'CSS::DOM::Rule::Media',
		'empty lc @media rule with multiple media without ws';
	is $rule->cssText, "\@media print, screen, tv {\n}\n",
		'serialised empty lc @media rule w/multiple media w/o ws';

	$sheet->insertRule('@media print , screen , tv { }	 ',0);
	isa_ok $rule=pop@{$sheet->cssRules}, 'CSS::DOM::Rule::Media',
		'empty lc @media rule with multiple media and ws';
	is $rule->cssText, "\@media print, screen, tv {\n}\n",
		'serialised empty lc @media rule w/multiple media and ws';

	$sheet->insertRule('@meDIa print{}',0);
	isa_ok $rule=pop@{$sheet->cssRules}, 'CSS::DOM::Rule::Media',
		'empty @meDIa rule with one medium not followed by ws';
	is $rule->cssText, "\@media print {\n}\n",
		'serialised empty @meDIa rule w/1 medium without  ws';

	$sheet->insertRule('@meDIa print {  } ',0);
	isa_ok $rule=pop@{$sheet->cssRules}, 'CSS::DOM::Rule::Media',
		'empty @meDIa rule with one medium followed by ws';
	is $rule->cssText, "\@media print {\n}\n",
		'serialised empty @meDIa rule w/1 medium followed by ws';

	$sheet->insertRule('@meDIa print,screen,tv{}',0);
	isa_ok $rule=pop@{$sheet->cssRules}, 'CSS::DOM::Rule::Media',
		'empty @meDIa rule with multiple media without ws';
	is $rule->cssText, "\@media print, screen, tv {\n}\n",
		'serialised empty @meDIa rule w/multiple media without ws';

	$sheet->insertRule('@meDIa print , screen , tv {  }	 ',0);
	isa_ok $rule=pop@{$sheet->cssRules}, 'CSS::DOM::Rule::Media',
		'empty @meDIa rule with multiple media and ws';
	is $rule->cssText, "\@media print, screen, tv {\n}\n",
		'serialised empty @meDIa rule with multiple media and ws';

	$sheet->insertRule('@media print{',0);
	isa_ok $rule=pop@{$sheet->cssRules}, 'CSS::DOM::Rule::Media',
		'empty unclosed lc @media rule w/one medium without ws';
	is $rule->cssText, "\@media print {\n}\n",
		'serialised empty unclosed lc @media w/1 medium w/o ws';

	$sheet->insertRule('@media print {  ',0);
	isa_ok $rule=pop@{$sheet->cssRules}, 'CSS::DOM::Rule::Media',
		'empty unclosed lc @media rule with one medium and ws';
	is $rule->cssText, "\@media print {\n}\n",
		'serialised empty unclosed lc @media rule w/1 medium & ws';

	$sheet->insertRule('@media print,screen,tv{',0);
	isa_ok $rule=pop@{$sheet->cssRules}, 'CSS::DOM::Rule::Media',
		'empty unclosed lc @media rule w/multiple media w/o ws';
	is $rule->cssText, "\@media print, screen, tv {\n}\n",
		'serialised empty unclosed @media w/multiple media w/o ws';

	$sheet->insertRule('@media print , screen , tv {  ',0);
	isa_ok $rule=pop@{$sheet->cssRules}, 'CSS::DOM::Rule::Media',
		'empty unclosed lc @media rule with multiple media and ws';
	is $rule->cssText, "\@media print, screen, tv {\n}\n",
		'serialised empty unclosed lc @media w/multiple media +ws';

	$sheet->insertRule('@meDIa print{',0);
	isa_ok $rule=pop@{$sheet->cssRules}, 'CSS::DOM::Rule::Media',
		'empty unclosed @meDIa rule w/one medium without ws';
	is $rule->cssText, "\@media print {\n}\n",
		'serialised empty unclosed @meDIa w/1 medium without ws';

	$sheet->insertRule('@meDIa print { a{ ',0);
	isa_ok $rule=pop@{$sheet->cssRules}, 'CSS::DOM::Rule::Media',
		'empty unclosed @meDIa rule w/one medium followed by ws';
	is $rule->cssText, "\@media print {\n\ta {  }\n}\n",
		'serialised empty unclosed @meDIa rule w/1 medium and ws';

	$sheet->insertRule('@meDIa print,screen,tv{',0);
	isa_ok $rule=pop@{$sheet->cssRules}, 'CSS::DOM::Rule::Media',
		'empty unclosed @meDIa rule w/multiple media without ws';
	is $rule->cssText, "\@media print, screen, tv {\n}\n",
		'serialised empty unclosed @meDIa w/multiple media w/o ws';

	$sheet->insertRule('@meDIa print , screen , tv {  ',0);
	isa_ok $rule=pop@{$sheet->cssRules}, 'CSS::DOM::Rule::Media',
		'empty unclosed @meDIa rule with multiple media and ws';
	is $rule->cssText, "\@media print, screen, tv {\n}\n",
		'serialised empty unclosed @meDIa w/multiple media and ws';

	$sheet->insertRule('@media print{@a{color:blue}}',0);
	is +($rule=pop@{$sheet->cssRules})->type, UNKNOWN_RULE,
		'type of fake @media with one medium without ws';
	is $rule->cssText, "\@media print{\@a{color:blue}}\n",
		'serialised fake @media rule w/1 medium w/o ws';

	$sheet->insertRule('@media print { @a{color:blue} } ',0);
	is +($rule=pop@{$sheet->cssRules})->type, UNKNOWN_RULE,
		'type of fake @media rule with one medium followed by ws';
	is $rule->cssText, "\@media print { \@a{color:blue} }\n",
		'serialised lc fake @media rule w/1 medium followed by ws';

	$sheet->insertRule('@media print,screen,tv{@a{color:blue}}',0);
	is +($rule=pop@{$sheet->cssRules})->type, UNKNOWN_RULE,
		'type of fake @media rule with multiple media without ws';
	is $rule->cssText, "\@media print,screen,tv{\@a{color:blue}}\n",
		'serialised fake @media rule w/multiple media without ws';

	$sheet->insertRule('@media print , screen , tv { @a{color:blue} }
		 ',0);
	is +($rule=pop@{$sheet->cssRules})->type, UNKNOWN_RULE,
		'type of lc fake @media rule with multiple media and ws';
	is $rule->cssText, "\@media print , screen , tv { "
		."\@a{color:blue} }\n",
		'serialised fake @media rule with multiple media and ws';

	$sheet->insertRule('@meDIa print{@a{color:blue}}',0);
	is +($rule=pop@{$sheet->cssRules})->type, UNKNOWN_RULE,
		'type of fake @meDIa with one medium without ws';
	is $rule->cssText, "\@meDIa print{\@a{color:blue}}\n",
		'serialised fake @meDIa rule w/1 medium w/o ws';

	$sheet->insertRule('@meDIa print { @a{color:blue} } ',0);
	is +($rule=pop@{$sheet->cssRules})->type, UNKNOWN_RULE,
		'type of fake @meDIa rule with one medium followed by ws';
	is $rule->cssText, "\@meDIa print { \@a{color:blue} }\n",
		'serialised fake @meDIa rule w/1 medium followed by ws';

	$sheet->insertRule('@meDIa print,screen,tv{@a{color:blue}}',0);
	is +($rule=pop@{$sheet->cssRules})->type, UNKNOWN_RULE,
		'type of fake @meDIa rule with multiple media without ws';
	is $rule->cssText, "\@meDIa print,screen,tv{\@a{color:blue}}\n",
		'serialised fake @meDIa rule w/multiple media without ws';

	$sheet->insertRule('@meDIa print , screen , tv { @a{color:blue} }
		 ',0);
	is +($rule=pop@{$sheet->cssRules})->type, UNKNOWN_RULE,
		'type of fake @meDIa rule with multiple media and ws';
	is$rule->cssText,"\@meDIa print , screen , tv "
		."{ \@a{color:blue} }\n",
		'serialised fake @meDIa rule with multiple media and ws';

	$sheet->insertRule('@media print{@a{color:blue',0);
	is +($rule=pop@{$sheet->cssRules})->type, UNKNOWN_RULE,
		'type of unclosed fake @media w/one medium without ws';
	is $rule->cssText, "\@media print{\@a{color:blue}}\n",
		'serialised unclosed fake @media rule w/1 medium w/o ws';

	$sheet->insertRule('@media print { @a{color:blue  ',0);
	is +($rule=pop@{$sheet->cssRules})->type, UNKNOWN_RULE,
		'type of unclosed fake @media rule with one medium and ws';
	is $rule->cssText, "\@media print { \@a{color:blue  }}\n",
		'serialised unclosed fake @media rule w/1 medium and ws';

	$sheet->insertRule('@media print,screen,tv{@a{color:blue',0);
	is +($rule=pop@{$sheet->cssRules})->type, UNKNOWN_RULE,
		'type of unclosed fake @media w/multiple media without ws';
	is $rule->cssText, "\@media print,screen,tv{\@a{color:blue}}\n",
		'serialised unclosed fake @media w/multiple media w/o ws';

	$sheet->insertRule('@media print , screen , tv { @a{color:blue ',
		0);
	is +($rule=pop@{$sheet->cssRules})->type, UNKNOWN_RULE,
		'type of unclosed fake @media with multiple media and ws';
	is $rule->cssText, "\@media print , screen , tv"
		." { \@a{color:blue }}\n",
		'serialised unclosed fake @media w/multiple media & ws';

	$sheet->insertRule('@meDIa print{@a{color:blue',0);
	is +($rule=pop@{$sheet->cssRules})->type, UNKNOWN_RULE,
		'type of unclosed fake @meDIa rule w/1 medium without ws';
	is $rule->cssText, "\@meDIa print{\@a{color:blue}}\n",
		'serialised unclosed fake @meDIa rule w/1 medium w/o ws';

	$sheet->insertRule('@meDIa print { @a{color:blue ',0);
	is +($rule=pop@{$sheet->cssRules})->type, UNKNOWN_RULE,
		'type of unclosed fake @meDIa with one medium and ws';
	is $rule->cssText, "\@meDIa print { \@a{color:blue }}\n",
		'serialised unclosed fake @meDIa rule w/1 medium and ws';

	$sheet->insertRule('@meDIa print,screen,tv{@a{color:blue',0);
	is +($rule=pop@{$sheet->cssRules})->type, UNKNOWN_RULE,
		'type of unclosed fake @meDIa w/multiple media without ws';
	is $rule->cssText, "\@meDIa print,screen,tv{\@a{color:blue}}\n",
		'serialised unclosed fake @meDIa w/multiple media w/o ws';

	$sheet->insertRule('@meDIa print , screen , tv { @a{color:blue ',
		0);
	is +($rule=pop@{$sheet->cssRules})->type, UNKNOWN_RULE,
		'type of unclosed fake @meDIa with multiple media and ws';
	is $rule->cssText, "\@meDIa print , screen , tv "
		."{ \@a{color:blue }}\n",
		'serialised unclosed fake @meDIa w/multiple media and ws';

	$sheet->insertRule('@media{}',0);
	is +($rule=pop@{$sheet->cssRules})->type, UNKNOWN_RULE,
		'type of empty lc fake @media rule without ws';
	is $rule->cssText, "\@media{}\n",
		'serialised empty fake @media rule without ws';

	$sheet->insertRule('@media {  } ',0);
	is +($rule=pop@{$sheet->cssRules})->type, UNKNOWN_RULE,
		'type of empty lc fake @media rule with ws';
	is $rule->cssText, "\@media {  }\n",
		'serialised empty lc fake @media rule and ws';

	$sheet->insertRule('@meDIa{}',0);
	is +($rule=pop@{$sheet->cssRules})->type, UNKNOWN_RULE,
		'type of empty fake @meDIa with no ws';
	is $rule->cssText, "\@meDIa{}\n",
		'serialised empty fake @meDIa rule without  ws';

	$sheet->insertRule('@meDIa {  } ',0);
	is +($rule=pop@{$sheet->cssRules})->type, UNKNOWN_RULE,
		'type of empty fake @meDIa rule with ws';
	is $rule->cssText, "\@meDIa {  }\n",
		'serialised empty fake @meDIa w/ ws';

	$sheet->insertRule('@media{',0);
	is +($rule=pop@{$sheet->cssRules})->type, UNKNOWN_RULE,
		'type of empty unclosed lc fake @media rule without ws';
	is $rule->cssText, "\@media{}\n",
		'serialised empty unclosed lc fake @media w/o ws';

	$sheet->insertRule('@media {  ',0);
	is +($rule=pop@{$sheet->cssRules})->type, UNKNOWN_RULE,
		'type of empty unclosed lc fake @media rule with ws';
	is $rule->cssText, "\@media {  }\n",
		'serialised empty unclosed lc fake @media rule with ws';

	$sheet->insertRule('@meDIa{',0);
	is +($rule=pop@{$sheet->cssRules})->type, UNKNOWN_RULE,
		'type of empty unclosed fake @meDIa rule without ws';
	is $rule->cssText, "\@meDIa{}\n",
		'serialised empty unclosed fake @meDIa without ws';

	$sheet->insertRule('@meDIa { ',0);
	is +($rule=pop@{$sheet->cssRules})->type, UNKNOWN_RULE,
		'type of empty unclosed fake @meDIa rule w/ws';
	is $rule->cssText, "\@meDIa { }\n",
		'serialised empty unclosed fake @meDIa rule w/ws';

	$sheet = CSS'DOM'parse '
		@media print { a { color: blue } "stuff"}
		td { padding: 0 }
	';
	is +($rule=pop@{$sheet->cssRules})->type, STYLE_RULE,
		'type of style rule following invalid media rule';
	is $rule->cssText, "td { padding: 0 }\n",
		'serialised style rule following invalid media rule';
	is +($rule=pop@{$sheet->cssRules})->type, UNKNOWN_RULE,
		'type of invalid media rule followed by another rule';
	is $rule->cssText,qq'\@media print { a { color: blue } "stuff"}\n',
		'serialised invalid media rule followed by another rule';

	$sheet->insertRule('@media print  ',0);
	is +($rule=pop@{$sheet->cssRules})->type, UNKNOWN_RULE,
		'invalid media rule without block or semicolon';
	is $rule->cssText, "\@media print;\n",
		'serialised invalid media rule without block or semicolon';

	$sheet->insertRule('@\00006dedi\41  print{',0);
	is +($rule=pop@{$sheet->cssRules})->type, MEDIA_RULE,
		'@media rule with escape in the @media part';
	is $rule->cssText, "\@media print {\n}\n",
		'serialised @media rule no longer with escape in "@media"';

	$sheet->insertRule('@\00006dedi\41  \70rint{',0);
	is pop(@{$sheet->cssRules})->media->[0], "print",
		'@media with escape in medium';
}

use tests 1; # bracket closure
{
	my $sheet = new CSS'DOM; my $rule;

	$sheet->insertRule('@unknown {(rect([',0);
	is +($rule=pop@{$sheet->cssRules})->cssText,
		"\@unknown {(rect([]))}\n",
		'bracket closure';
}

use tests 14; # @page
{
	my $sheet = new CSS'DOM; my $rule;

	$sheet->insertRule('@page{color:blue}',0);
	is +($rule=pop@{$sheet->cssRules})->type, PAGE_RULE,
		'@page with no ws';
	is $rule->cssText, "\@page { color: blue }\n",
		'serialised @page with no ws';

	$sheet->insertRule('@page:left{color:blue}',0);
	is +($rule=pop@{$sheet->cssRules})->type, PAGE_RULE,
		'@page with pseudo-class and no ws';
	is $rule->cssText, "\@page:left { color: blue }\n",
		'serialised @page with pseudo-class and no ws';

	$sheet->insertRule(' @page { color : blue } ',0);
	is +($rule=pop@{$sheet->cssRules})->type, PAGE_RULE,
		'@page with ws';
	is $rule->cssText, "\@page { color: blue }\n",
		'serialised @page with ws';

	$sheet->insertRule(' @page :left { color : blue } ',0);
	is +($rule=pop@{$sheet->cssRules})->type, PAGE_RULE,
		'@page with pseudo-class and ws';
	is $rule->cssText, "\@page :left { color: blue }\n",
		'serialised @page with pseudo-class and ws';

	$sheet->insertRule(' @PaGe :left { color : blue } ',0);
	is +($rule=pop@{$sheet->cssRules})->type, PAGE_RULE,
		'@PaGe';
	is $rule->cssText, "\@page :left { color: blue }\n",
		'serialised @PaGe';

	$sheet->insertRule(' @PaGe : left { color : blue } ',0);
	is +($rule=pop@{$sheet->cssRules})->type, UNKNOWN_RULE,
		'@PaGe with invalid selector';
	is $rule->cssText, "\@PaGe : left { color : blue }\n",
		'serialised @PaGe with invalid selector';

	$sheet->insertRule('@\70 age {',0);
	is +($rule=pop@{$sheet->cssRules})->type, PAGE_RULE,
		'@page rule with escape in the @page part';
	is $rule->cssText, "\@page {  }\n",
		'serialised @page rule no longer w/escape in "@page"';
}

use tests 6; # unrecognised at-rules
{
	my $sheet = new CSS'DOM; my $rule;

	$sheet->insertRule('@unknown \ / \ / :-P {...}',0);
	is +($rule=pop@{$sheet->cssRules})->type, UNKNOWN_RULE,
		'unknown at-rule with block';
	is $rule->cssText,
		"\@unknown \\ / \\ / :-P {...}\n",
		'serialisation of unknown at-rule wiv block';

	$sheet->insertRule(' @unknoWn \ / \ / :-P ',0);
	is +($rule=pop@{$sheet->cssRules})->type, UNKNOWN_RULE,
		'unknown at-rule with no block or ;';
	is $rule->cssText,
		"\@unknoWn \\ / \\ / :-P;\n",
		'serialisation of unknown at-rule wiv no block or ;';

	$sheet->insertRule(' @uNknown \ / \ / :-P ;',0);
	is +($rule=pop@{$sheet->cssRules})->type, UNKNOWN_RULE,
		'unknown at-rule with ;';
	is $rule->cssText,
		"\@uNknown \\ / \\ / :-P ;\n",
		'serialisation of unknown at-rule wiv ;';
}

use tests 6; # ruselet pasrer
{
	my $sheet = new CSS'DOM; my $rule;

	$sheet->insertRule('a{text-decoration:none;color:blue}',0);
	is +($rule=pop@{$sheet->cssRules})->type, STYLE_RULE,
		'spaceless ruleset';
	is $rule->cssText,
		"a { text-decoration: none; color: blue }\n",
		'serialisation of spaceless ruleset';

	$sheet->insertRule('a { text-decoration:none;color:blue ; } ',0);
	is +($rule=pop@{$sheet->cssRules})->type, STYLE_RULE,
		'spacy ruleset';
	is $rule->cssText,
		"a { text-decoration: none; color: blue }\n",
		'serialisation of spacy ruleset';

	$sheet->insertRule('a...b/+-$. ..!![()]([]){; } ',0);
	is +($rule=pop@{$sheet->cssRules})->type, STYLE_RULE,
		'ruleset with funny selector';
	is $rule->cssText,
		"a...b/+-\$. ..!![()]([]) {  }\n",
		'serialisation of ruleset with funny selector';
}

use tests 1; # invaldi strings
{
	my $sheet = CSS'DOM'parse q*
	      p { 
	        color: green; 
	        font-family: 'Courier New Times 
	        background: red; 
	        text-size: 20px; 
	      }
	      @bling;
	      @blah blah blah "ooooo 
	      blong  { a: q }
	      @blung;
	
	      a."oh dear
	      :link { text-decoration: none }

	      @page { margin: '1px
	              background: white;
	              margin-top: 1.5in }
	*;

	is join('',map $_->cssText, $sheet->cssRules),
		 "p { color: green; text-size: 20px }\n"
		."\@bling;\n\@blung;\n"
		."\@page { margin-top: 1.5in }\n",
		'ingoring of invalid strings';
}

use tests 10; # invalid closing brackets
{
	is CSS'DOM'parse q" @eotetet ]" =>-> cssRules->length,0,
		'invalid closing bracket in unknown rule';
	ok $@, '$@ is set by invalid closing bracket in unknown rule';
	is CSS'DOM'parse q" @media { ]" =>-> cssRules->length, 0,
		'invalid closing bracket in media rule';
	ok $@, '$@ is set by invalid closing bracket in media rule';
	is CSS'DOM'parse q" @page { ]" =>-> cssRules->length, 0,
		'invalid closing bracket in page rule';
	ok $@, '$@ is set by invalid closing bracket in page rule';
	is CSS'DOM'parse q" page ( ]" =>-> cssRules->length, 0,
		'invalid closing bracket in selector';
	ok $@, '$@ is set by invalid closing bracket in selector';
	is CSS'DOM'parse q" a {  (}" =>-> cssRules->length, 0,
		'invalid closing bracket in style declaration';
	ok $@, '$@ is set by invalid closing bracket in selector';
}

use tests 14; # invalid [\@;]
{
	is CSS'DOM'parse q" @eotetet @aa ]" =>-> cssRules->length,0,
		'invalid @ in unknown rule';
	ok $@, '$@ is set by invalid @ in unknown rule';
	is CSS'DOM'parse q" @eotetet aa (;" =>-> cssRules->length,0,
		'invalid ; in unknown rule';
	ok $@, '$@ is set by invalid ; in unknown rule';
	is CSS'DOM'parse q" @media {(; { " =>-> cssRules->length,0,
		'invalid ; in media rule';
	ok $@, '$@ is set by invalid ; in media rule';
	is CSS'DOM'parse q" @page { (;fooo" =>-> cssRules->length,0,
		'invalid ; in page rule';
	ok $@, '$@ is set by invalid ; in page rule';
	is CSS'DOM'parse q" page @oo " =>-> cssRules->length,0,
		'invalid @ in selector';
	ok $@, '$@ is set by invalid @ in selector';
	is CSS'DOM'parse q" page ;( " =>-> cssRules->length,0,
		'invalid ; in selector';
	ok $@, '$@ is set by invalid ; in selector';
	is CSS'DOM'parse q" a { ( ;( " =>-> cssRules->length,0,
		'invalid ; in style declaration';
	ok $@, '$@ is set by invalid ; in style declaration';
}

use tests 14; # @import
{
	my $sheet = new CSS'DOM; my $rule;

	$sheet->insertRule('@import"foo.css"print,screen;',0);
	is +($rule=pop@{$sheet->cssRules})->type, IMPORT_RULE,
		'@import with no ws';
	is $rule->href, 'foo.css', 'href property of @import rule w/o ws';
	is $rule->media->mediaText, 'print, screen',
		'media property of @import rule without ws';

	$sheet->insertRule(' @import "foo.css" print , screen ; ',0);
	is +($rule=pop@{$sheet->cssRules})->type, IMPORT_RULE,
		'@import with ws';
	is $rule->href, 'foo.css', 'href property of @import rule with ws';
	is $rule->media->mediaText, 'print, screen',
		'media property of @import rule with ws';

	$sheet->insertRule('@import "foo.css" ',0);
	is +($rule=pop@{$sheet->cssRules})->type, IMPORT_RULE,
		'@import with string and without ;';
	is $rule->href, "foo.css",
		'href of @import with string and without ;';

	$sheet->insertRule(' @import url(foo.css); ',0);
	is +($rule=pop@{$sheet->cssRules})->type, IMPORT_RULE,
		'@import with url';
	is $rule->href, "foo.css",
		'href of @import with url';
	is $rule->media->length, 0, '@import without media';

	$sheet->insertRule('@im\70ort url(f,,coeetet)',0);
	is +($rule=pop@{$sheet->cssRules})->type, IMPORT_RULE,
		'@import with escapes';

	$sheet->insertRule('@import "foo.css" {',0);
	is +($rule=pop@{$sheet->cssRules})->type, UNKNOWN_RULE,
		'invalid @import rule';

	$sheet->insertRule('@import "foo"  \70rint',0);
	is pop(@{$sheet->cssRules})->media->[0], "print",
		'@import with escape in medium';
}

use tests 8; # @font-face
{
	my $sheet = new CSS'DOM; my $rule;

	$sheet->insertRule('@font-face{color:blue}',0);
	is +($rule=pop@{$sheet->cssRules})->type, FONT_FACE_RULE,
		'@font-face with no ws';
	is $rule->cssText, "\@font-face { color: blue }\n",
		'serialised @font-face with no ws';

	$sheet->insertRule(' @font-face { color : blue } ',0);
	is +($rule=pop@{$sheet->cssRules})->type, FONT_FACE_RULE,
		'@font-face with ws';
	is $rule->cssText, "\@font-face { color: blue }\n",
		'serialised @font-face with ws';

	$sheet->insertRule(' @FOnT-fAce { color : blue } ',0);
	is +($rule=pop@{$sheet->cssRules})->type, FONT_FACE_RULE,
		'@FOnT-fAce';
	is $rule->cssText, "\@font-face { color: blue }\n",
		'serialised @FOnT-fAce';

	$sheet->insertRule('@fOnt\-f\061 ce {',0);
	is +($rule=pop@{$sheet->cssRules})->type, FONT_FACE_RULE,
		'@font-face rule with escapes in the @font-face part';
	is $rule->cssText, "\@font-face {  }\n",
	  'serialised @font-face rule no longer w/escapes in "@font-face"';
}

use tests 13; # @charset
{
	my $sheet = new CSS'DOM; my $rule;

	$sheet->insertRule('@charset "utf-8";',0);
	is +($rule=pop@{$sheet->cssRules})->type, CHARSET_RULE,
		'@charset';
	is $rule->cssText, "\@charset \"utf-8\";\n",
		'serialised @charset';

	$sheet->insertRule(' @charset "utf-7"; ',0);
	is +($rule=pop@{$sheet->cssRules})->type, CHARSET_RULE,
		'@charset with ws fore and aft';
	is $rule->cssText, "\@charset \"utf-7\";\n",
		'serialised @charset with ws';

	$sheet->insertRule(' @charset "utf\-7"; ',0);
	is +($rule=pop@{$sheet->cssRules})->type, CHARSET_RULE,
		'@charset with escapes in the charset name';
	is $rule->encoding, "utf-7",
		'encoding parsed out of the @charset with escapes';

	$sheet->insertRule('@chArset "utf-8";',0);
	is +($rule=pop@{$sheet->cssRules})->type, UNKNOWN_RULE,
		'@chArset makes it an unknown rule';

	$sheet->insertRule('@chArset "utf-8"',0);
	is +($rule=pop@{$sheet->cssRules})->type, UNKNOWN_RULE,
		'missing semicolor makes @charset an unknown rule';

	$sheet->insertRule('@\63harset "utf-8";',0);
	is +($rule=pop@{$sheet->cssRules})->type, UNKNOWN_RULE,
		'@\63harset is an unknown rule';

	$sheet->insertRule('@charset \'utf-8\';',0);
	is +($rule=pop@{$sheet->cssRules})->type, UNKNOWN_RULE,
		'@charset \'...\' is an unknown rule';

	$sheet->insertRule('@charset  "utf-8";',0);
	is +($rule=pop@{$sheet->cssRules})->type, UNKNOWN_RULE,
		'@charset w/dbl space is an unknown rule';

	$sheet->insertRule('@charset"utf-8";',0);
	is +($rule=pop@{$sheet->cssRules})->type, UNKNOWN_RULE,
		'@charset w/no space is an unknown rule';

	$sheet->insertRule('@charset "utf-8" ;',0);
	is +($rule=pop@{$sheet->cssRules})->type, UNKNOWN_RULE,
		'@charset w/space b4 ; is an unknown rule';
}

