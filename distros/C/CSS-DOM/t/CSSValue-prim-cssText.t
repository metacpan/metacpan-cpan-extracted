#!/usr/bin/perl -T

# This is in a separate file to make sure that CSS::DOM::Value::Primitive
# remembers to require CSS::DOM::Exception.

use strict; use warnings; no warnings qw 'qw regexp once utf8 parenthesis';
our $tests;
BEGIN { ++$INC{'tests.pm'} }
sub tests'VERSION { $tests += pop };
use Test::More;
plan tests => $tests;

use tests 1;

use CSS::DOM::Value::Primitive ':all';
eval{
 new CSS::DOM::Value::Primitive type=>CSS_STRING, value=>'drare'
  =>->cssText("foo")
};
isa_ok $@, 'CSS::DOM::Exception',
  'CSS::DOM::Value::Primitive ->cssText loads CSS::DOM::Exception';
