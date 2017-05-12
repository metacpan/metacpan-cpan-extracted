#!perl -T

### This file tests primarily tree-related functionality

use Test::More tests => 16;
use Data::XHash qw/xh xhn xhr/;

my $xh;

## Test tree-related methods

can_ok('Data::XHash', qw/merge/);

# Tests: 1

## Test basic fetch

$xh = xh({ one => xh({ two => 'value' }) });

is($xh->{[]}, undef, '{[]} is undef');
isa_ok($xh->{one}, 'Data::XHash', '{one=>{two=>value}} => {one}');
is($xh->{[qw/one two/]}, 'value',
  '{one=>{two=>value}} => {[one two]} is value');
is($xh->{[qw/one tow/]}, undef, '{one=>{two=>value}} => {[one tow]} is undef');
is_deeply($xh->{['one', {}]}->as_hashref(), [{two=>'value'}],
   '{one=>{two=>value}} => {[one {}]} is {two=>value}');

# Tests: 5

# Test recursive as_hashref now so we can check other stuff easily

is_deeply($xh->as_hashref(nested=>1), [{one=>[{two=>'value'}]}],
  '{one=>{two=>value}} as_hashref(nested=>1) is OK');
$xh = xhr([{one=>{two=>'value'}}], nested => 1);
is_deeply($xh->as_hashref(nested=>1), [{one=>[{two=>'value'}]}],
  'xhr([{one=>{two=>value}}], nested => 1) as_hashref(nested=>1) is OK');
$xh = xhr([{one=>[{two=>'value'}]}], nested => 1);
is_deeply($xh->as_hashref(nested=>1), [{one=>[{two=>'value'}]}],
  'xhr([{one=>[{two=>value}]}], nested => 1) as_hashref(nested=>1) is OK');

# Tests: 3

## Test basic store

$xh->{[qw/one change/]} = 'is good';
is_deeply($xh->as_hashref(nested=>1),
  [{one=>[{two=>'value'},{change=>'is good'}]}],
  '{one=>{two=>value,change=>is good}} is OK');
$xh->{['one', undef]} = '#0';
$xh->{['one', undef]} = '#1';
is_deeply($xh->as_hashref(nested=>1),
  [{one=>[{two=>'value'},{change=>'is good'},{0=>'#0'},{1=>'#1'}]}],
  '{one=>{two=>value,change=>is good,0=>#0,1=>#1}} is OK');

# Tests: 2

## Test as_arrayref(nested=>1)

is_deeply($xh->as_arrayref(nested=>1),
  [{one=>[{two=>'value'},{change=>'is good'},'#0','#1']}],
  '{one=>{two=>value,change=>is good,#0,#1}} is OK');

# Tests: 1

## Test XHash vivification

$xh = xh();
$xh->{['one', {}]}->push(1, 2, 3);
is_deeply($xh->as_hashref(nested=>1), [{one=>[{0=>1},{1=>2},{2=>3}]}],
  '[one {}]->push(1, 2, 3) is OK');

# Tests: 1

## Test merges

my ($x2, $xm);
$xh = xhn('one', { nested => [ 'two', { key => 'value' }] }, 'three');
$x2 = xhn('one', { nested => [ 'two', { key => 'value' }] }, 'three');
$xm = xh()->merge($xh);
is_deeply($xm->as_hashref(nested=>1),
  [{0=>'one'},{nested=>[{0=>'two'},{key=>'value'}]},{1=>'three'}],
  'merge nested into empty is OK');
$xm = xh()->merge({indexed_as=>'array'}, $xh, $x2);
is_deeply($xm->as_hashref(nested=>1),
  [{0=>'one'},{nested=>[{0=>'two'},{key=>'value'},{1=>'two'}]},{1=>'three'},
  {2=>'one'},{3=>'three'}],
  'merge indexed as array is OK');
$xm = xh()->merge({indexed_as=>'hash'}, $xh, $x2);
is_deeply($xm->as_hashref(nested=>1),
  [{0=>'one'},{nested=>[{0=>'two'},{key=>'value'}]},{1=>'three'}],
  'merge indexed as hash is OK');

# Tests: 3

# END
