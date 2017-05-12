#!/usr/bin/perl -T

# ~~~ This could be rewritten to load the modules and check that the
#     methods it finds are listed in ::Interface. And vice versa.

use strict; use warnings;
our $tests;
BEGIN { ++$INC{'tests.pm'} }
sub tests'VERSION { $tests += pop };
use Test::More;
plan tests => $tests;

use CSS::DOM::Interface ":all";

use tests 2;
ok *CSS::DOM::Interface{HASH}, 'the hash is there';
ok exists $CSS::DOM::Interface{CSSStyleSheet}, 'CSSStyleSheet',;
	# I almost missed this.

use tests 9; # changes in 0.02
ok exists $CSS::DOM::Interface{CSSStyleSheet}{title},'CSSStyleSheet title';
ok exists $CSS::DOM::Interface{CSSStyleSheet}{media},'CSSStyleSheet media';
ok exists $CSS::DOM::Interface{CSSStyleSheet}{ownerRule},
	'CSSStyleSheet ownerRule';
ok exists $CSS::DOM::Interface{CSSStyleSheet}{insertRule},
	'CSSStyleSheet insertRule';
ok exists $CSS::DOM::Interface{CSSStyleSheet}{deleteRule},
	'CSSStyleSheet deleteRule';
ok exists $CSS::DOM::Interface{MediaList}{mediaText}, 'MediaList';
ok exists $CSS::DOM::Interface{StyleSheetList}{length}, 'StyleSheetList';
ok exists $CSS::DOM::Interface{CSSRule}{type}, 'CSSRule.type';
ok exists $CSS::DOM::Interface{CSSRule}{cssText}, 'CSSRule.cssText';

use tests 14; # changes in 0.03
ok exists $CSS::DOM::Interface{CSSStyleRule}{selectorText},
	 'CSSStyleRule.selectorText';
ok exists $CSS::DOM::Interface{CSSRule}{parentRule}, 'CSSRule.parentRule';
ok exists $CSS::DOM::Interface{CSSRule}{parentStyleSheet},
	'CSSRule.parentStyleSheet';
ok exists $CSS::DOM::Interface{CSSValue}, 'CSSValue';
ok exists $CSS::DOM::Interface{CSSPrimitiveValue}, 'CSSPrimitiveValue';
ok exists $CSS::DOM::Interface{CSSMediaRule}{$_}, "CSSMediaRule.$_"
	for qw 'media cssRules insertRule deleteRule';
ok exists $CSS::DOM::Interface{CSSImportRule}{$_}, "CSSImportRule.$_"
	for qw 'href media styleSheet';
ok !exists $CSS::DOM::Interface{'CSS::DOM::Rule::Unknown'},
	'CSS::DOM::Rule::Unknown is gone';
is $CSS::DOM::Interface{'CSS::DOM::Rule'}, 'CSSRule';

use tests 1; # changes in 0.04
ok exists $CSS::DOM::Interface{'CSSFontFaceRule'}, 'CSSFontFaceRule';

use tests 7; # changes in 0.06
ok exists $CSS::DOM::Interface{'CSSCharsetRule'}, 'CSSCharsetRule';
ok exists $CSS::DOM::Interface{CSSStyleDeclaration}{getPropertyCSSValue},
	'getPropertyCSSValue';
ok exists $CSS::DOM::Interface{CSSStyleDeclaration}{removeProperty},
	'removeProperty';
ok exists $CSS::DOM::Interface{CSSStyleDeclaration}{getPropertyPriority},
	'getPropertyPriority';
ok exists $CSS::DOM::Interface{CSSStyleDeclaration}{length},
	'Style->length';
ok exists $CSS::DOM::Interface{CSSValue}{cssValueType}, 'cssValueType';
ok exists $CSS::DOM::Interface{CSSValue}{cssText}, 'Value->cssText';

use tests 13; # changes in 0.08
ok exists $CSS::DOM::Interface{CSSPrimitiveValue}{$_},
 "primitive value ->$_"
   for qw<
    top right bottom left red green blue alpha primitiveType
   >;
is $CSS::DOM::Interface{CSSPrimitiveValue}{getFloatValue}, METHOD | NUM,
 'getFloatValue';
ok exists $CSS::DOM::Interface{CSSValueList}{$_},
 "list value ->$_"
   for <item length>;
ok $CSS::DOM::Interface{CSSValueList}{_array};

use tests 2; # changes in 0.11 (that should have been made in 0.10)
ok exists $CSS::DOM::Interface{CSSPrimitiveValue}{setFloatValue},
 'setFloatValue';
ok exists $CSS::DOM::Interface{CSSPrimitiveValue}{setStringValue},
 'setStringValue';;

use tests 1; # another change in 0.11
ok exists $CSS::DOM::Interface{CSSStyleDeclaration}{opacity},
 'opacity';

use tests 1; # a change in 0.14
ok exists $CSS::DOM::Interface{CSSPrimitiveValue}{getStringValue};
