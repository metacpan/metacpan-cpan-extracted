#!/usr/bin/perl -T

use strict; use warnings; no warnings qw 'utf8 parenthesis regexp once qw';
our $tests;
BEGIN { ++$INC{'tests.pm'} }
sub tests'VERSION { $tests += pop };
use Test::More;
plan tests => $tests;


use tests 1; # use
use_ok 'CSS::DOM::Style',;

use tests 3; # first make sure we can use it without loading CSS::DOM
{
	my $owner = bless [], 'bext';
	sub bext::parentStyleSheet{}
	my $decl = new CSS::DOM::Style $owner;
	is $decl->parentRule, $owner, 'constructor sets the parentRule';
	undef $owner;
	is $decl->parentRule, undef, 'holds a weak ref to its parent';
	
	$decl->cssText('margin-top: 76in'); # Wow, what a big margin!
	is $decl->marginTop, '76in', 'seems to be working orphanedly';
}
	

require CSS::DOM;
my $ss = CSS::DOM'parse ('a{text-decoration: none} p { margin: 0 }');
my $rule = cssRules $ss ->[0];
my $decl = $rule->style;

use tests 1; # isa
isa_ok $decl, 'CSS::DOM::Style';

use tests 3; # cssText (there are more tests below under setProperty)
is $decl->cssText, 'text-decoration: none', 'get cssText';
is $decl->cssText('text-decoration: underline'), 'text-decoration: none',
	'get/set cssText';
is $decl->cssText, 'text-decoration: underline', 'get cssText again';

use tests 1; # getPropertyValue
is $decl->getPropertyValue('text-decoration'), 'underline',
	'getPropertyValue';

use tests 6; # getPropertyCSSValue and property_parser
is +()=$decl->getPropertyCSSValue('text-decoration'), '0',
	'retval of getPropertyCSSValue when prop parser is not in use';
{
 require CSS::DOM::PropertyParser;
 my $decl = CSS::DOM::Style::parse(
  'text-decoration: underline',
   property_parser =>$CSS::DOM::PropertyParser::Default
 );
 is $decl->property_parser, $CSS::DOM::PropertyParser::Default,
    'property_parser';
 ok $decl->getPropertyCSSValue('text-decoration')->DOES('CSS::DOM::Value'),
  'retval of getPropertyCSSValue with property parser';
 ok $decl->getPropertyCSSValue('text-decoration')->DOES('CSS::DOM::Value'),
  'retval of getPropertyCSSValue (2nd time)'; # weird caching bug in 0.06
 is +()=$decl->getPropertyCSSValue('background-color'), '0',
  'retval of getPropertyCSSValue when the prop doesn\'t exist';
 $decl->font(" bold 13px Times ");
 is +()=$decl->getPropertyCSSValue('font'), 0, 
  'getPropertyCSSValue always returns null for shorthand properties';
}

use tests 3; # removeProperty
is $decl->removeProperty('azimuth'), '',
	'removal of a non-existent property returns the empty string';
is $decl->removeProperty('text-decorAtion'), 'underline',
	'removeProperty returns the property’s value';
unlike $decl->cssText, qr/text-decoration/i,
	'removeProperty actually removes the property';

use tests 3; # getPropertyPriority
{
	my $decl = CSS::DOM::Style::parse('color: red !\69mportant');
	is $decl->getPropertyPriority('color'), important =>
		'getPropertyPriority';
	$decl = CSS::DOM::Style::parse("color: red !  imp0rtant");
	is $decl->getPropertyPriority('color'), imp0rtant =>
		'priority parsing when there is a space after the !';
	is $decl->getPropertyPriority('colour'), '' =>
		'getPropertyPriority when the property does not exist';
}

use tests 8; # setProperty
is +()=$decl->setProperty('color', 'red'), 0, 'setProperty ret val';
is $decl->getPropertyValue('color'), 'red', 'effect of setProperty';
ok!eval{$decl->setProperty('color', '}');1}, 'setProperty chokes on }';
cmp_ok $@,'==',&CSS::DOM::Exception::SYNTAX_ERR,
	'setProperty throws the right error';
$decl->setProperty('cOlOr', 'blue');
is $decl->color, 'blue', 'setProperty lcs the property names';
$decl->setProperty('color','red','important');
like $decl->cssText, qr/color: red !important/,
	'setting property priority';
$decl->setProperty('cOlOr', 'blue');
unlike $decl->cssText, qr/color: red !important/,
	'setProperty without a priority arg deletes the pri';
$decl->setProperty('color','blue','very important');
like $decl->cssText, qr/color: blue !very\\ important/,
	'setProperty with space in the priority (and cssText afterwards)';

use tests 4; # length
{
	my $decl = new CSS'DOM'Style;
	is eval { $decl->length }, 0,  # This used to die [RT #54810]
	  'length when no properties have been added';  # (fixed in 0.09).
	$decl = CSS::DOM::Style::parse(
		'color: red !\69mportant; foo:bar'
	);
	is $decl->length, 2, 'length';
	$decl->baz('nslv');
	is $decl->length, 3, 'length changes when a property is added';
	$decl->removeProperty('baz');
	is $decl->length, 2, '  and when one is removed';

use tests 3; # item

	is $decl->item(0), 'color', 'item';
	is $decl->item(1), 'foo', 'item again';
	is $decl->item(2), '', 'nonexistent item';
}

use tests 1; # parentRule
use Scalar::Util 'refaddr';
is refaddr $rule, refaddr $decl->parentRule, 'parentRule';
