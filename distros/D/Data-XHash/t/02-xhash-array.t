#!perl -T

### This file tests primarily array-related functionality

use Test::More tests => 35;
use Data::XHash qw/xh xhr/;

my $xh;

## Array-related methods check

can_ok('Data::XHash', qw/
  pop shift push pushref unshift unshiftref
  as_array as_arrayref as_hash as_hashref
  reorder remap renumber
  /);

# Tests: 1

## Test keys, index keys, and values

$xh = xh({one=>'first'},{2=>'second'},'third');
is_deeply([keys %$xh], [qw/one 2 3/], 'keys %$xh are OK');
is_deeply([$xh->keys()], [qw/one 2 3/], '$xh->keys are OK');
is_deeply([$xh->keys(index_only => 1)], [qw/2 3/], 'index keys are OK');
is_deeply([values %$xh], [qw/first second third/], 'values %$xh are OK');
is_deeply([$xh->values()], [qw/first second third/], '$xh->values are OK');
is_deeply([$xh->values(['one', 3])], [qw/first third/],
  '$xh->values([keys]) are OK');

# Tests: 6

## Test shift and pop

is($xh->shift(), 'first', 'shift returns first value');
is_deeply($xh->as_hashref(), [{2=>'second'},{3=>'third'}],
  'XHash is correct after shift');
is($xh->pop(), 'third', 'pop returns last value');
is_deeply($xh->as_hashref(), [{2=>'second'}], 'XHash is correct after pop');

# Tests: 4

$xh = xh(1, 2, 3);
is_deeply([map {scalar $xh->pop()} 0..2], [3, 2, 1], 'pop all numerics is OK');
is($xh->pop(), undef, 'pop empty former numeric is undef');
$xh = xh(1, 2, 3);
is_deeply([map {scalar $xh->shift()} 0..2], [1, 2, 3],
  'shift all numerics is OK');
is($xh->shift(), undef, 'shift empty former numeric is undef');

# Tests: 4

$xh = xh({one=>'one'},{two=>'two'},{three=>'three'});
is_deeply([map {scalar $xh->pop()} 0..2], [qw/three two one/],
  'pop all strings is OK');
is($xh->pop(), undef, 'pop empty former string is undef');
$xh = xh({one=>'one'},{two=>'two'},{three=>'three'});
is_deeply([map {scalar $xh->shift()} 0..2], [qw/one two three/],
  'shift all strings is OK');
is($xh->shift(), undef, 'shift empty former string is undef');

# Tests: 4

is_deeply([xh({foo=>'bar'})->shift()], [qw/foo bar/],
  'shift returns (key, value) in list context');
is_deeply([xh()->shift()], [], 'shift empty returns () in list context');
is_deeply([xh({foo=>'bar'})->pop()], [qw/foo bar/],
  'pop returns (key, value) in list context');
is_deeply([xh()->pop()], [], 'pop empty returns () in list context');

# Tests: 4

## Test push and unshift

$xh->clear()->push({z=>'zero'},{1=>'one'});
is_deeply($xh->as_hashref(), [{z=>'zero'},{1=>'one'}],
  'XHash is correct after first push');
$xh->unshift('two', 'three');
is_deeply($xh->as_hashref(), [{2=>'two'},{3=>'three'},{z=>'zero'},{1=>'one'}],
  'XHash is correct after first unshift');
$xh->push('four');
is_deeply($xh->as_hashref(),
  [{2=>'two'},{3=>'three'},{z=>'zero'},{1=>'one'},{4=>'four'}],
  'XHash is correct after second push');
$xh->unshift('five');
is_deeply($xh->as_hashref(),
  [{5=>'five'},{2=>'two'},{3=>'three'},{z=>'zero'},{1=>'one'},{4=>'four'}],
  'XHash is correct after second unshift');
is_deeply([$xh->keys()], [qw/5 2 3 z 1 4/],
  'keys are correct after push/unshift');
is_deeply([$xh->keys(index_only => 1)], [qw/5 2 3 1 4/],
  'index keys are correct after push/unshift');
is_deeply([$xh->keys(index_only => 1, sorted => 1)], [qw/1 2 3 4 5/],
  'sorted index keys are correct after push/unshift');

# Tests: 7

## Test reorder

$xh = xh(0, 1, 2, 3, 4, 5);
$xh->reorder(5, 3, 4);
is_deeply($xh->as_hashref(), [{0=>0},{1=>1},{2=>2},{5=>5},{3=>3},{4=>4}],
  'XHash is correct after reorder to end');
$xh->reorder(0, 1, 2, 0);
is_deeply($xh->as_hashref(), [{1=>1},{2=>2},{0=>0},{5=>5},{3=>3},{4=>4}],
  'XHash is correct after reorder to beginning');
$xh->reorder(2, 0..5);
is_deeply($xh->as_hashref(), [{0=>0},{1=>1},{2=>2},{3=>3},{4=>4},{5=>5}],
  'XHash is correct after reorder around refkey');
$xh->reorder(1, 2, 0, 5, 3, 4);

# Tests: 3

## Test renumber

$xh->renumber(from => 3, sorted => 1);
is_deeply($xh->as_hashref(), [{4=>1},{5=>2},{3=>0},{8=>5},{6=>3},{7=>4}],
  'XHash is correct after renumber(from => 3, sorted => 1)');
$xh->renumber(from => -6);
is_deeply($xh->as_hashref(), [{-6=>1},{-5=>2},{-4=>0},{-3=>5},{-2=>3},{-1=>4}],
  'XHash is correct after renumber(from => -6)');

# Tests: 2

# END
