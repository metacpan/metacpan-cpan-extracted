#!/usr/bin/env perl

use Test::More;

use Moose::Util::TypeConstraints qw/find_type_constraint/;

use strict;
use warnings;
use Cfn;

my $tests = [];

my $tc = find_type_constraint('Cfn::Value');
my $val = $tc->coerce('XXXX');
isa_ok($val, 'Cfn::Value::Primitive');

$val = $tc->coerce(1);
isa_ok($val, 'Cfn::Value::Primitive');

$val = $tc->coerce([2, 'YYYY']);
isa_ok($val, 'Cfn::Value::Array');
isa_ok($val->Value->[0], 'Cfn::Value::Primitive');
isa_ok($val->Value->[1], 'Cfn::Value::Primitive');

$val = $tc->coerce({ Ref => 'XXXX' });
isa_ok($val, 'Cfn::Value::Function');

$val = $tc->coerce([ 1, { Ref => 'X' }, 2 ]);
isa_ok($val, 'Cfn::Value::Array');
isa_ok($val->Value->[0], 'Cfn::Value::Primitive');
isa_ok($val->Value->[1], 'Cfn::Value::Function');
isa_ok($val->Value->[2], 'Cfn::Value::Primitive');


$val = $tc->coerce({ 'Fn::Join' => [ '.', [ 'A', 'B', { Ref => 'C' } ] ] });
isa_ok($val, 'Cfn::Value::Function');
my $cfn_array = $val->Value;
isa_ok($cfn_array, 'Cfn::Value::Array');
isa_ok($cfn_array->Value->[0], 'Cfn::Value::Primitive');
isa_ok($cfn_array->Value->[1], 'Cfn::Value::Array');
isa_ok($cfn_array->Value->[1]->Value->[0], 'Cfn::Value::Primitive');
isa_ok($cfn_array->Value->[1]->Value->[1], 'Cfn::Value::Primitive');
isa_ok($cfn_array->Value->[1]->Value->[2], 'Cfn::Value::Function');

$val = $tc->coerce({ 
  Key1 => "Value1",
  Key2 => "Value2",
  Key3 => "Value3"
});
isa_ok($val, 'Cfn::Value::Hash');

done_testing();
