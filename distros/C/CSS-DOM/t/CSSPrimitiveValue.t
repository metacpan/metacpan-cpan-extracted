#!/usr/bin/perl -T

use strict; use warnings;
no warnings<utf8 parenthesis regexp once qw bareword syntax>;
our $tests;
BEGIN { ++$INC{'tests.pm'} }
sub tests'VERSION { $tests += pop };
sub tests'import  { $tests += pop if @_ > 1 };
use Test::More;
plan tests => $tests;

use tests 1; # use
use_ok 'CSS::DOM::Value::Primitive', ':all';

use tests 26; # constants
{
	my $x;

	for (qw/ UNKNOWN NUMBER PERCENTAGE EMS EXS PX CM MM IN PT PC DEG
	         RAD GRAD MS S HZ KHZ DIMENSION STRING URI IDENT ATTR
	         COUNTER RECT RGBCOLOR /) {
		eval "is CSS_$_, " . $x++ . ", '$_'";
	}
}

use CSS::DOM;

#use tests 1; # unknown
# ~~~ How do we get an unknown primitive value? If we have a value that is
#     unrecognised, what determines whether it becomes a custom value or
#     an unknown primitive value? What should I test for?

# This sub runs two tests
sub test_isa {
 isa_ok $_[0], 'CSS::DOM::Value::Primitive', $_[1];
 ok $_[0]->DOES('CSS::DOM::Value'), "$_[1] DOES CSS::DOM::Value";
}

# -------------------------------------
# Tests for isa, primitiveType and get*

use tests 7; # numbers
for(CSS::DOM::Value::Primitive->new(type => &CSS_NUMBER, value => 73)) {
 test_isa $_, 'number value';
 is $_->primitiveType, &CSS_NUMBER, 'number->primitiveType';
 is $_->getFloatValue, 73, 'number->getFloatValue';
 ok !eval{ $_->getStringValue;1}, 'number->getStringValue dies';
 isa_ok $@, 'CSS::DOM::Exception',
  'class of error after number->getStringValue dies';
 cmp_ok $@, '==', &CSS::DOM::Exception::INVALID_ACCESS_ERR,
  'error code after number->getStringValue dies';
}

use tests 7; # %
for(
 CSS::DOM::Value::Primitive->new(type => &CSS_PERCENTAGE, value => 73)
) {
 test_isa $_, '% value';
 is $_->primitiveType, &CSS_PERCENTAGE, '%->primitiveType';
 is $_->getFloatValue, 73, '%->getFloatValue';
 ok !eval{ $_->getStringValue;1}, '%->getStringValue dies';
 isa_ok $@, 'CSS::DOM::Exception',
  'class of error after %->getStringValue dies';
 cmp_ok $@, '==', &CSS::DOM::Exception::INVALID_ACCESS_ERR,
  'error code after %->getStringValue dies';
}

use tests 7; # M
for(CSS::DOM::Value::Primitive->new(type => &CSS_EMS, value => 73)) {
 test_isa $_, 'em value';
 is $_->primitiveType, &CSS_EMS, 'em->primitiveType';
 is $_->getFloatValue, 73, 'em->getFloatValue';
 ok !eval{ $_->getStringValue;1}, 'em->getStringValue dies';
 isa_ok $@, 'CSS::DOM::Exception',
  'class of error after em->getStringValue dies';
 cmp_ok $@, '==', &CSS::DOM::Exception::INVALID_ACCESS_ERR,
  'error code after em->getStringValue dies';
}

use tests 7; # X
for(CSS::DOM::Value::Primitive->new(type => &CSS_EXS, value => 73)) {
 test_isa $_, 'ex value';
 is $_->primitiveType, &CSS_EXS, 'ex->primitiveType';
 is $_->getFloatValue, 73, 'ex>getFloatValue';
 ok !eval{ $_->getStringValue;1}, 'ex->getStringValue dies';
 isa_ok $@, 'CSS::DOM::Exception',
  'class of error after ex->getStringValue dies';
 cmp_ok $@, '==', &CSS::DOM::Exception::INVALID_ACCESS_ERR,
  'error code after ex->getStringValue dies';
}

use tests 7; # pixies
for(CSS::DOM::Value::Primitive->new(type => &CSS_PX, value => 73)) {
 test_isa $_, 'pixel value';
 is $_->primitiveType, &CSS_PX, 'pixel->primitiveType';
 is $_->getFloatValue, 73, 'px->getFloatValue';
 ok !eval{ $_->getStringValue;1}, 'pixel->getStringValue dies';
 isa_ok $@, 'CSS::DOM::Exception',
  'class of error after pixel->getStringValue dies';
 cmp_ok $@, '==', &CSS::DOM::Exception::INVALID_ACCESS_ERR,
  'error code after pixel->getStringValue dies';
}

use tests 7; # cm
for(CSS::DOM::Value::Primitive->new(type => &CSS_CM, value => 73)) {
 test_isa $_, 'cm value';
 is $_->primitiveType, &CSS_CM, 'cm->primitiveType';
 is $_->getFloatValue, 73, 'cm->getFloatValue';
 ok !eval{ $_->getStringValue;1}, 'cm->getStringValue dies';
 isa_ok $@, 'CSS::DOM::Exception',
  'class of error after cm->getStringValue dies';
 cmp_ok $@, '==', &CSS::DOM::Exception::INVALID_ACCESS_ERR,
  'error code after cm->getStringValue dies';
}

use tests 7; # mm
for(CSS::DOM::Value::Primitive->new(type => &CSS_MM, value => 73)) {
 test_isa $_, 'millimetre value';
 is $_->primitiveType, &CSS_MM, 'mm->primitiveType';
 is $_->getFloatValue, 73, 'mm->getFloatValue';
 ok !eval{ $_->getStringValue;1}, 'mm->getStringValue dies';
 isa_ok $@, 'CSS::DOM::Exception',
  'class of error after mm->getStringValue dies';
 cmp_ok $@, '==', &CSS::DOM::Exception::INVALID_ACCESS_ERR,
  'error code after mm->getStringValue dies';
}

use tests 7; # inch
for(CSS::DOM::Value::Primitive->new(type => &CSS_IN, value => 73)) {
 test_isa $_, 'inch value';
 is $_->primitiveType, &CSS_IN, 'inch->primitiveType';
 is $_->getFloatValue, 73, 'inch->getFloatValue';
 ok !eval{ $_->getStringValue;1}, 'inch->getStringValue dies';
 isa_ok $@, 'CSS::DOM::Exception',
  'class of error after inch->getStringValue dies';
 cmp_ok $@, '==', &CSS::DOM::Exception::INVALID_ACCESS_ERR,
  'error code after inch->getStringValue dies';
}

use tests 7; # points
for(CSS::DOM::Value::Primitive->new(type => &CSS_PT, value => 73)) {
 test_isa $_, 'pointy value';
 is $_->primitiveType, &CSS_PT, 'pointy->primitiveType';
 is $_->getFloatValue, 73, 'pointy->getFloatValue';
 ok !eval{ $_->getStringValue;1}, 'pointy->getStringValue dies';
 isa_ok $@, 'CSS::DOM::Exception',
  'class of error after pointy->getStringValue dies';
 cmp_ok $@, '==', &CSS::DOM::Exception::INVALID_ACCESS_ERR,
  'error code after pointy->getStringValue dies';
}

use tests 7; # pica
for(CSS::DOM::Value::Primitive->new(type => &CSS_PC, value => 73)) {
 test_isa $_, 'pica value';
 is $_->primitiveType, &CSS_PC, 'pica->primitiveType';
 is $_->getFloatValue, 73, 'pica->getFloatValue';
 ok !eval{ $_->getStringValue;1}, 'pica->getStringValue dies';
 isa_ok $@, 'CSS::DOM::Exception',
  'class of error after pica->getStringValue dies';
 cmp_ok $@, '==', &CSS::DOM::Exception::INVALID_ACCESS_ERR,
  'error code after pica->getStringValue dies';
}

use tests 7; # degrease
for(CSS::DOM::Value::Primitive->new(type => &CSS_DEG, value => 73)) {
 test_isa $_, 'degree value';
 is $_->primitiveType, &CSS_DEG, 'degree->primitiveType';
 is $_->getFloatValue, 73, 'degree->getFloatValue';
 ok !eval{ $_->getStringValue;1}, 'degree->getStringValue dies';
 isa_ok $@, 'CSS::DOM::Exception',
  'class of error after degree->getStringValue dies';
 cmp_ok $@, '==', &CSS::DOM::Exception::INVALID_ACCESS_ERR,
  'error code after degree->getStringValue dies';
}

use tests 7; # radians
for(CSS::DOM::Value::Primitive->new(type => &CSS_RAD, value => 73)) {
 test_isa $_, 'radian value';
 is $_->primitiveType, &CSS_RAD, 'radian->primitiveType';
 is $_->getFloatValue, 73, 'radian->getFloatValue';
 ok !eval{ $_->getStringValue;1}, 'radian->getStringValue dies';
 isa_ok $@, 'CSS::DOM::Exception',
  'class of error after radian->getStringValue dies';
 cmp_ok $@, '==', &CSS::DOM::Exception::INVALID_ACCESS_ERR,
  'error code after radian->getStringValue dies';
}

use tests 7; # grad
for(CSS::DOM::Value::Primitive->new(type => &CSS_GRAD, value => 73)) {
 test_isa $_, 'grad value';
 is $_->primitiveType, &CSS_GRAD, 'grad->primitiveType';
 is $_->getFloatValue, 73, 'grad->getFloatValue';
 ok !eval{ $_->getStringValue;1}, 'grad->getStringValue dies';
 isa_ok $@, 'CSS::DOM::Exception',
  'class of error after grad->getStringValue dies';
 cmp_ok $@, '==', &CSS::DOM::Exception::INVALID_ACCESS_ERR,
  'error code after grad->getStringValue dies';
}

use tests 7; # seconds
for(CSS::DOM::Value::Primitive->new(type => &CSS_S, value => 73)) {
 test_isa $_, 'sec. value';
 is $_->primitiveType, &CSS_S, 'sec.->primitiveType';
 is $_->getFloatValue, 73, 'sec.->getFloatValue';
 ok !eval{ $_->getStringValue;1}, 'sec.->getStringValue dies';
 isa_ok $@, 'CSS::DOM::Exception',
  'class of error after sec.->getStringValue dies';
 cmp_ok $@, '==', &CSS::DOM::Exception::INVALID_ACCESS_ERR,
  'error code after sec.->getStringValue dies';
}

use tests 7; # ms
for(CSS::DOM::Value::Primitive->new(type => &CSS_MS, value => 73)) {
 test_isa $_, 'ms value';
 is $_->primitiveType, &CSS_MS, 'ms->primitiveType';
 is $_->getFloatValue, 73, 'ms->getFloatValue';
 ok !eval{ $_->getStringValue;1}, 'ms->getStringValue dies';
 isa_ok $@, 'CSS::DOM::Exception',
  'class of error after ms->getStringValue dies';
 cmp_ok $@, '==', &CSS::DOM::Exception::INVALID_ACCESS_ERR,
  'error code after ms->getStringValue dies';
}

use tests 7; # hurts
for(CSS::DOM::Value::Primitive->new(type => &CSS_HZ, value => 73)) {
 test_isa $_, 'hurts value';
 is $_->primitiveType, &CSS_HZ, 'hurts->primitiveType';
 is $_->getFloatValue, 73, 'hurts->getFloatValue';
 ok !eval{ $_->getStringValue;1}, 'hurts->getStringValue dies';
 isa_ok $@, 'CSS::DOM::Exception',
  'class of error after hurts->getStringValue dies';
 cmp_ok $@, '==', &CSS::DOM::Exception::INVALID_ACCESS_ERR,
  'error code after hurts->getStringValue dies';
}

use tests 7; # killer hurts
for(CSS::DOM::Value::Primitive->new(type => &CSS_KHZ, value => 73)) {
 test_isa $_, 'killer hurts value';
 is $_->primitiveType, &CSS_KHZ, 'killer hurts->primitiveType';
 is $_->getFloatValue, 73, 'killer hurts->getFloatValue';
 ok !eval{ $_->getStringValue;1}, 'killer hurts->getStringValue dies';
 isa_ok $@, 'CSS::DOM::Exception',
  'class of error after killer hurts->getStringValue dies';
 cmp_ok $@, '==', &CSS::DOM::Exception::INVALID_ACCESS_ERR,
  'error code after killer hurts->getStringValue dies';
}

use tests 7; # misc dim
for(
 CSS::DOM::Value::Primitive->new(
  type => &CSS_DIMENSION, value => [73, 'things']
 )
) {
 test_isa $_, 'misc dim value';
 is $_->primitiveType, &CSS_DIMENSION, 'misc dim->primitiveType';
 is $_->getFloatValue, 73, 'misc dim->getFloatValue';
 ok !eval{ $_->getStringValue;1}, 'misc dim->getStringValue dies';
 isa_ok $@, 'CSS::DOM::Exception',
  'class of error after misc dim->getStringValue dies';
 cmp_ok $@, '==', &CSS::DOM::Exception::INVALID_ACCESS_ERR,
  'error code after misc dim->getStringValue dies';
}

use tests 7; # string
for(CSS::DOM::Value::Primitive->new(type => &CSS_STRING, value => 73)) {
 test_isa $_, 'string value';
 is $_->primitiveType, &CSS_STRING, 'string->primitiveType';
 ok !eval{ $_->getFloatValue;1}, 'string->getFloatValue dies';
 isa_ok $@, 'CSS::DOM::Exception',
  'class of error after string->getFloatValue dies';
 cmp_ok $@, '==', &CSS::DOM::Exception::INVALID_ACCESS_ERR,
  'error code after string->getFloatValue dies';
 is $_->getStringValue, 73, 'string->getStringValue';
}

use tests 7; # url
for(CSS::DOM::Value::Primitive->new(type => &CSS_URI, value => 73)) {
 test_isa $_, 'uri value';
 is $_->primitiveType, &CSS_URI, 'uri->primitiveType';
 ok !eval{ $_->getFloatValue;1}, 'uri->getFloatValue dies';
 isa_ok $@, 'CSS::DOM::Exception',
  'class of error after uri->getFloatValue dies';
 cmp_ok $@, '==', &CSS::DOM::Exception::INVALID_ACCESS_ERR,
  'error code after uri->getFloatValue dies';
 is $_->getStringValue, 73, 'url->getStringValue';
}

use tests 7; # identifier
for(CSS::DOM::Value::Primitive->new(type => &CSS_IDENT, value => 73)) {
 test_isa $_, 'identifier value';
 is $_->primitiveType, &CSS_IDENT, 'identifier->primitiveType';
 ok !eval{ $_->getFloatValue;1}, 'identifier->getFloatValue dies';
 isa_ok $@, 'CSS::DOM::Exception',
  'class of error after identifier->getFloatValue dies';
 cmp_ok $@, '==', &CSS::DOM::Exception::INVALID_ACCESS_ERR,
  'error code after identifier->getFloatValue dies';
 is $_->getStringValue, 73, 'identifier->getStringValue';
}

use tests 7; # attr
for(CSS::DOM::Value::Primitive->new(type => &CSS_ATTR, value => 73)) {
 test_isa $_, 'attr value';
 is $_->primitiveType, &CSS_ATTR, 'attr->primitiveType';
 ok !eval{ $_->getFloatValue;1}, 'attr->getFloatValue dies';
 isa_ok $@, 'CSS::DOM::Exception',
  'class of error after attr->getFloatValue dies';
 cmp_ok $@, '==', &CSS::DOM::Exception::INVALID_ACCESS_ERR,
  'error code after attr->getFloatValue dies';
 is $_->getStringValue, 73, 'attr->getStringValue';
}

use tests 9; # counter
for(CSS::DOM::Value::Primitive->new(type => &CSS_COUNTER, value => [73])) {
 test_isa $_, 'counter value';
 is $_->primitiveType, &CSS_COUNTER, 'counter->primitiveType';
 ok !eval{ $_->getFloatValue;1}, 'counter->getFloatValue dies';
 isa_ok $@, 'CSS::DOM::Exception',
  'class of error after counter->getFloatValue dies';
 cmp_ok $@, '==', &CSS::DOM::Exception::INVALID_ACCESS_ERR,
  'error code after counter->getFloatValue dies';
 ok !eval{ $_->getStringValue;1}, 'counter->getStringValue dies';
 isa_ok $@, 'CSS::DOM::Exception',
  'class of error after counter->getStringValue dies';
 cmp_ok $@, '==', &CSS::DOM::Exception::INVALID_ACCESS_ERR,
  'error code after counter->getStringValue dies';
}

use tests 9; # counters
for(CSS::DOM::Value::Primitive->new(
 type => &CSS_COUNTER, value => [73,'breen']
)) {
 test_isa $_, 'counters value';
 is $_->primitiveType, &CSS_COUNTER, 'counters->primitiveType';
 ok !eval{ $_->getFloatValue;1}, 'counters->getFloatValue dies';
 isa_ok $@, 'CSS::DOM::Exception',
  'class of error after counters->getFloatValue dies';
 cmp_ok $@, '==', &CSS::DOM::Exception::INVALID_ACCESS_ERR,
  'error code after counters->getFloatValue dies';
 ok !eval{ $_->getStringValue;1}, 'counters->getStringValue dies';
 isa_ok $@, 'CSS::DOM::Exception',
  'class of error after counters->getStringValue dies';
 cmp_ok $@, '==', &CSS::DOM::Exception::INVALID_ACCESS_ERR,
  'error code after counters->getStringValue dies';
}

use tests 9; # rectangle
for(CSS::DOM::Value::Primitive->new(
 type => &CSS_RECT, value => [
     [type => &CSS_PX, value => 20],
     [type => &CSS_PERCENTAGE, value => 50],
     [type => &CSS_PERCENTAGE, value => 50],
     [type => &CSS_PX, value => 50],
 ]
)) {
 test_isa $_, 'rectangle value';
 is $_->primitiveType, &CSS_RECT, 'rectangle->primitiveType';
 ok !eval{ $_->getFloatValue;1}, 'rectangle->getFloatValue dies';
 isa_ok $@, 'CSS::DOM::Exception',
  'class of error after rectangle->getFloatValue dies';
 cmp_ok $@, '==', &CSS::DOM::Exception::INVALID_ACCESS_ERR,
  'error code after rectangle->getFloatValue dies';
 ok !eval{ $_->getStringValue;1}, 'rectangle->getStringValue dies';
 isa_ok $@, 'CSS::DOM::Exception',
  'class of error after rectangle->getStringValue dies';
 cmp_ok $@, '==', &CSS::DOM::Exception::INVALID_ACCESS_ERR,
  'error code after rectangle->getStringValue dies';
}

use tests 9; #bed colour
for(CSS::DOM::Value::Primitive->new(
 type => &CSS_RGBCOLOR, value => '#bed',
)) {
 test_isa $_, '#bed colour value';
 is $_->primitiveType, &CSS_RGBCOLOR, '#bed colour->primitiveType';
 ok !eval{ $_->getFloatValue;1}, '#bed colour->getFloatValue dies';
 isa_ok $@, 'CSS::DOM::Exception',
  'class of error after #bed colour->getFloatValue dies';
 cmp_ok $@, '==', &CSS::DOM::Exception::INVALID_ACCESS_ERR,
  'error code after #bed colour->getFloatValue dies';
 ok !eval{ $_->getStringValue;1}, '#bee colour->getStringValue dies';
 isa_ok $@, 'CSS::DOM::Exception',
  'class of error after #bee colour->getStringValue dies';
 cmp_ok $@, '==', &CSS::DOM::Exception::INVALID_ACCESS_ERR,
  'error code after #bee colour->getStringValue dies';
}

use tests 9; #c0ffee colour
for(CSS::DOM::Value::Primitive->new(
 type => &CSS_RGBCOLOR, value => '#c0ffee',
)) {
 test_isa $_, '#c0ffee colour value';
 is $_->primitiveType, &CSS_RGBCOLOR, '#c0ffee colour->primitiveType';
 ok !eval{ $_->getFloatValue;1}, '#c0ffee colour->getFloatValue dies';
 isa_ok $@, 'CSS::DOM::Exception',
  'class of error after #c0ffee colour->getFloatValue dies';
 cmp_ok $@, '==', &CSS::DOM::Exception::INVALID_ACCESS_ERR,
  'error code after #c0ffee colour->getFloatValue dies';
 ok !eval{ $_->getStringValue;1}, '#c0ffee->getStringValue dies';
 isa_ok $@, 'CSS::DOM::Exception',
  'class of error after #c0ffee->getStringValue dies';
 cmp_ok $@, '==', &CSS::DOM::Exception::INVALID_ACCESS_ERR,
  'error code after #c0ffee->getStringValue dies';
}

use tests 9; # rgb colour
for(CSS::DOM::Value::Primitive->new(
 type => &CSS_RGBCOLOR, value => [ ([type => &CSS_NUMBER, value => 0])x3 ]
)) {
 test_isa $_, 'rgb value';
 is $_->primitiveType, &CSS_RGBCOLOR, 'rgb->primitiveType';
 ok !eval{ $_->getFloatValue;1}, 'rgb->getFloatValue dies';
 isa_ok $@, 'CSS::DOM::Exception',
  'class of error after rgb->getFloatValue dies';
 cmp_ok $@, '==', &CSS::DOM::Exception::INVALID_ACCESS_ERR,
  'error code after rgb->getFloatValue dies';
 ok !eval{ $_->getStringValue;1}, 'rgb->getStringValue dies';
 isa_ok $@, 'CSS::DOM::Exception',
  'class of error after rgb->getStringValue dies';
 cmp_ok $@, '==', &CSS::DOM::Exception::INVALID_ACCESS_ERR,
  'error code after rgb->getStringValue dies';
}

use tests 9; # rgba colour
for(CSS::DOM::Value::Primitive->new(
 type => &CSS_RGBCOLOR, value => [ ([type => &CSS_NUMBER, value => 0])x4 ]
)) {
 test_isa $_, 'rgba value';
 is $_->primitiveType, &CSS_RGBCOLOR, 'rgba->primitiveType';
 ok !eval{ $_->getFloatValue;1}, 'rgba->getFloatValue dies';
 isa_ok $@, 'CSS::DOM::Exception',
  'class of error after rgba->getFloatValue dies';
 cmp_ok $@, '==', &CSS::DOM::Exception::INVALID_ACCESS_ERR,
  'error code after rgba->getFloatValue dies';
 ok !eval{ $_->getStringValue;1}, 'rgba->getStringValue dies';
 isa_ok $@, 'CSS::DOM::Exception',
  'class of error after rgba->getStringValue dies';
 cmp_ok $@, '==', &CSS::DOM::Exception::INVALID_ACCESS_ERR,
  'error code after rgba->getStringValue dies';
}

# ------------------------------------------
# Tests for setFloatValue and setStringValue

use CSS'DOM'Style;
require CSS::DOM::PropertyParser;
my $s = new CSS'DOM'Style
 property_parser => $CSS::DOM::PropertyParser::Default;

for my $meth ('setFloatValue' ,'setStringValue'){

use tests 6; # read-only properties
 my $v = new CSS::DOM::Value::Primitive
  type => &CSS::DOM::Value::Primitive::CSS_NUMBER, value => 43;
 ok !eval{ $v->$meth(&CSS_IN, 1); 1 },
  qq'calling $meth on an unowned primitive value object dies';
 isa_ok $@, 'CSS::DOM::Exception',
  qq'class of error after primitive->$meth dies';
 cmp_ok $@, '==', &CSS::DOM::Exception::NO_MODIFICATION_ALLOWED_ERR,
  qq'and the right type of error, too (after primitive->$meth dies)';

use tests +26*3*2; # errors for invalid types
 $s->backgroundImage('url(scrat)');
 $v = $s->getPropertyCSSValue('background-image');
 for(qw<UNKNOWN NUMBER PERCENTAGE EMS EXS PX CM MM IN PT PC DEG RAD GRAD MS
        S HZ KHZ DIMENSION STRING IDENT ATTR COUNTER RECT RGBCOLOR>) {
  ok !eval{ $v->$meth(eval"CSS_$_", 1); 1 },
   qq '$meth(CSS_$_) dies when the property does not support it';
  isa_ok $@, 'CSS::DOM::Exception',
   qq'class of error after primitive->$meth(&CSS_$_) dies';
  cmp_ok $@, '==', &CSS::DOM::Exception::INVALID_ACCESS_ERR,
   qq'and the right type of error, too (after $meth(&CSS_$_) dies)';
 }
 $s->backgroundColor('#bad');
 $v = $s->getPropertyCSSValue('background-color');
 ok !eval{ $v->$meth(&CSS_URI, 1); 1 },
    qq'setFloatValue(CSS_URI) dies when the property does not support it';
 isa_ok $@, 'CSS::DOM::Exception',
        qq'class of error after primitive->$meth(&CSS_URI) dies';
 cmp_ok $@, '==', &CSS::DOM::Exception::INVALID_ACCESS_ERR,
        qq'and the right type of error, too (after $meth(&CSS_URI) dies)';

use tests 4; # retval and CSS_NUMBER
 $s->marginTop('4px');
 is +()=$s->getPropertyCSSValue('margin-top')->$meth(&CSS_NUMBER, 0), 0,
    "$meth returns nothing";
 is $s->marginTop, 0, "successful $meth(CSS_NUMBER)";

use tests 2; # CSS_PERCENTAGE
 $s->height('4px');
 ($v = $s->getPropertyCSSValue('height'))->$meth(&CSS_PERCENTAGE, 50);
 is $s->height, '50%', "successful $meth(CSS_PERCENTAGE)";

use tests 2; # CSS_EMS
 $v->$meth(&CSS_EMS, 50);
 is $s->height, '50em', "successful $meth(CSS_EMS)";

use tests 2; # CSS_EXS
 $v->$meth(&CSS_EXS, 50);
 is $s->height, '50ex', "successful $meth(CSS_EXS)";

use tests 2; # CSS_PX
 $v->$meth(&CSS_PX, 50);
 is $s->height, '50px', "successful $meth(CSS_PX)";

use tests 2; # CSS_CM
 $v->$meth(&CSS_CM, 50);
 is $s->height, '50cm', "successful $meth(CSS_CM)";

use tests 2; # CSS_MM
 $v->$meth(&CSS_MM, 50);
 is $s->height, '50mm', "successful $meth(CSS_MM)";

use tests 2; # CSS_IN
 $v->$meth(&CSS_IN, 50);
 is $s->height, '50in', "successful $meth(CSS_IN)";

use tests 2; # CSS_PT
 $v->$meth(&CSS_PT, 50);
 is $s->height, '50pt', "successful $meth(CSS_PT)";

use tests 2; # CSS_PC
 $v->$meth(&CSS_PC, 50);
 is $s->height, '50pc', "successful $meth(CSS_PC)";

use tests 2; # CSS_DEG
 $s->azimuth('5rad');
 ($v = $s->getPropertyCSSValue('azimuth'))->$meth(&CSS_DEG, 50);
 is $s->azimuth, '50deg', "successful $meth(CSS_DEG)";

use tests 2; # CSS_RAD
 $v->$meth(&CSS_RAD, 50);
 is $s->azimuth, '50rad', "successful $meth(CSS_RAD)";

use tests 2; # CSS_GRAD
 $v->$meth(&CSS_GRAD, 50);
 is $s->azimuth, '50grad', "successful $meth(CSS_GRAD)";

use tests 2; # CSS_MS
 $s->pauseAfter('5s');
 ($v = $s->getPropertyCSSValue('pause-after'))->$meth(&CSS_MS, 50);
 is $s->pauseAfter, '50ms', "successful $meth(CSS_MS)";

use tests 2; # CSS_S
 $v->$meth(&CSS_S, 50);
 is $s->pauseAfter, '50s', "successful $meth(CSS_S)";

use tests 2; # CSS_HZ
 $s->pitch('5khz');
 ($v = $s->getPropertyCSSValue('pitch'))->$meth(&CSS_HZ, 50);
 is lc $s->pitch, '50hz', "successful $meth(CSS_HZ)";

use tests 2; # CSS_KHZ
 $v->$meth(&CSS_KHZ, 30);
 is lc $s->pitch, '30khz', "successful $meth(CSS_KHZ)";

use tests 2; # CSS_STRING
 $s->quotes('"‘" "’"');
 $s->getPropertyCSSValue('quotes')->[0]->$meth(&CSS_STRING, 50);
 like $s->quotes, qr/^(['"])50\1\s+(['"])’\2\z/,
     "successful $meth(CSS_STRING)";

use tests 2; # CSS_URI
 $s->content('""');
 ($v = $s->getPropertyCSSValue('content')->[0])->$meth(&CSS_URI, 50);
 is $s->content, 'url(50)',
     "successful $meth(CSS_URI)";

use tests 2; # CSS_IDENT
 # This test also checks that sub-values of a list do not lose their inter-
 # nal owner attribute when they change type (bug in 0.08 and 0.09).
 $v->$meth(&CSS_IDENT, 'open-quote');
 is $s->content, 'open-quote', "successful $meth(CSS_IDENT)";

use tests 2; # CSS_ATTR
 $v->$meth(&CSS_ATTR, 'open-quote');
 is $s->content, 'attr(open-quote)', "successful $meth(CSS_attr)";

}

__END__ ~~~ I need to finish converting the rest of these tests



 $s->backgroundImage('url(dwow)');
 $v = $s->getPropertyCSSValue('background-image');
 is $v->cssText('none'), 'url(dwow)',
  'setting cssText returns the old value';
 is $s->backgroundImage, 'none',
  'prim_value->cssText("...") sets the owner CSS property';
 is $v->primitiveType, &CSS::DOM::Value::Primitive::CSS_IDENT,
  ' prim->cssText sets the “primitive” type';
 is $v->cssText, 'none',
  ' prim->cssText sets the value object\'s own cssText';

 # We re-use the same value on purpose, to make sure the change in type did
 # not discard the internal owner attribute.
 $v->cssText('inherit');
 is $s->backgroundImage, 'inherit',
  'setting the cssText of a primitive value to inherit changes the prop';
 is $v->cssText, 'inherit',
  'setting the cssText of a prim val to inherit changes its cssText';
 is $v->cssValueType, &CSS_INHERIT,
  'value type after setting a primitive value to inherit';
 isa_ok $v, "CSS::DOM::Value",
  'object class after setting a primitive value to inherit';

 $s->clip('rect(0,0,0,0)');
 $v = $s->getPropertyCSSValue('clip')->top;
 $v->cssText('red');
 is $v->cssText, 0,
  'setting cssText on a sub-value of a rect to a colour does nothing';
 $v->cssText(50);
 is $v->cssText, 0,
  'setting cssText on a rect’s sub-value to a non-zero num does nothing';
 $v->cssText('5px');
 is $v->cssText, '5px',
  'setting cssText on a sub-value of a rect to 5px works';
 is $v->primitiveType, &CSS::DOM::Value::Primitive::CSS_PX,
  'setting cssText on a sub-value of a rect to 5px changes the prim type';
 like $s->clip, qr/^rect\(5px,\s*0,\s*0,\s*0\)\z/,
  'setting cssText on a sub-value of a rect changes the prop that owns it';
 $v->cssText('auto');
 is $v->cssText, 'auto', 'rect sub-values can be set to auto';
 $v->cssText('bdelp');
 is $v->cssText, 'auto', 'but not to any other identifier';

 $s->color('#c0ffee');
 $v = (my $clr = $s->getPropertyCSSValue('color'))->red;
 $v->cssText('red');
 is $v->cssText, 192,
  'setting cssText on a sub-value of a colour to a colour does nothing';
 $v->cssText('255');
 is $v->cssText, '255',
  'setting cssText on a sub-value of a colour to 255 works';
 is $clr->cssText, '#ffffee',
  'changing a colour’s sub-value sets the colour’s cssText';
 $v->cssText('50%');
 is $v->cssText, '50%',
  'setting cssText on a sub-value of a colour to 50% works';
 is $v->primitiveType, &CSS::DOM::Value::Primitive::CSS_PERCENTAGE,
  'changing the cssText of a colour’s sub-value changes the prim type';
 like $clr->cssText, qr/^rgb\(127.5,\s*255,\s*238\)\z/,
  'the colour’s cssText after making the subvalues mixed numbers & %’s';
 $v = $clr->alpha;
 $v->cssText('50%');
 is $v->cssText, 1,
  'alpha values ignore assignments of percentage values to cssText';
 $v->cssText(.5);
 is $v->cssText, .5,
  'but number assignments (to alpha values’ cssText) work';
 like $clr->cssText, qr/^rgba\(127.5,\s*255,\s*238,\s*0.5\)\z/,
  'the colour’s cssText after making the subvalues mixed numbers & %’s';

 $v = $s->getPropertyCSSValue('color');
 $v->cssText('activeborder');;
 is $v->primitiveType, &CSS::DOM::Value::Primitive::CSS_IDENT,
  'setting a colour property’s cssText to a sys. colour makes it an ident';

 $s->backgroundColor('red');
 my $called;
 $s->modification_handler(sub { ++$called });
 $s->getPropertyCSSValue('background-color')->cssText('white');
 is $called, 1,
  "modification_handler is called when a ‘primitive’ value changes";
}


# Methods that still need testing:
# ~~~ getCounterValue getRectValue getRGBColorValue
