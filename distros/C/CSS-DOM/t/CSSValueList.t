#!/usr/bin/perl -T

use strict; use warnings;
our $tests;
BEGIN { ++$INC{'tests.pm'} }
sub tests'VERSION { $tests += pop };
use Test::More;
plan tests => $tests;

use CSS'DOM'Constants ':primitive';
use CSS'DOM'Value'List;

use tests 1; # DOES
ok +CSS'DOM'Value'List->DOES('CSS::DOM::Value'), 'DOES';

my $v = new CSS'DOM'Value'List values => [
 [ type => CSS_STRING, value => 'sphed' ],
 [ type => CSS_STRING, value => 'flit' ],
];

use tests 3; # item
isa_ok $v->item(0), "CSS::DOM::Value::Primitive", "retval of item";
like $v->item(0)->cssText, qr/^(['"])sphed\1\z/,
  'which item item(0) returns';
like $v->item(1)->cssText, qr/^(['"])flit\1\z/,
  'which item item(1) returns';

use tests 1; # length
is $v->length, 2, 'length';

use tests 3; # @{}
is @$v, 2, '@{ value list }';
like $v->[0]->cssText, qr/^(['"])sphed\1\z/,
  'value list ->[0]';
like $v->[01]->cssText, qr/^(['"])flit\1\z/,
  'value list ->[1]';
