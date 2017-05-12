#!/usr/bin/perl -T

# This file contains tests for CSS::DOM::Style’s methods that are not part
# of the CSSStyleDeclaration interface.

use strict; use warnings;
our $tests;
BEGIN { ++$INC{'tests.pm'} }
sub tests'VERSION { $tests += pop };
use Test::More;
plan tests => $tests;

use tests 4; # modification_handler
require CSS::DOM::Style;
my $style = CSS::DOM::Style'parse('margin-top: 2px');
$style->modification_handler(sub { ++$}; ${{} .= shift});
$style->cssText('margin-bottom: 600%');
is $}, 1, 'cssText triggers mod hander';
is ${{}, $style, '$style is passed to the handler';
$style->setProperty('foo' => 'bar');
is $}, 2, 'setProperty triggers th ohnadler';
$style->fooBar('baz');
is $}, 3, 'AUTOLOAD triggers the handler';

# ~~~ We also needs tests for modification_handler triggered by:
#  • removeProperty
#  • modifications to CSSValue objects and their sub-objects (RGBColor etc

