#!perl -T

### This file tests primarily hash-related functionality

use Test::More tests => 62;
use Data::XHash qw/xhash xh/;

sub myxh {
    return Data::XHashSubclass->new()->push_ref(\@_);
}

my $xh;

## Hash-related methods check

can_ok('Data::XHash', qw/
  new xh xhash xhashref xhn xhr xhrn TIEHASH UNTIE DESTROY
  fetch FETCH store STORE clear CLEAR delete DELETE exists EXISTS
  /);
can_ok('Data::XHash', qw/
  first_key FIRSTKEY previous_key next_key NEXTKEY last_key next_index
  keys values foreach scalar SCALAR
  /);

# Tests: 2

## Ways to create an XHash

$xh = Data::XHashSubclass->new();
isa_ok($xh, 'Data::XHash', 'new() XHash tiedref');
isa_ok($xh, 'Data::XHashSubclass', 'new() Subclass tiedref');
isa_ok(tied(%$xh), 'Data::XHash', 'new() XHash object');
isa_ok(tied(%$xh), 'Data::XHashSubclass', 'new() Subclass object');

my $inew = $xh->new();
isa_ok($inew, 'Data::XHashSubclass', 'new() instance tiedref');
isa_ok(tied(%$xh), 'Data::XHashSubclass', 'new() instance object');

$xh = xhash();
isa_ok($xh, 'Data::XHash', 'xhash() tiedref');
isa_ok(tied(%$xh), 'Data::XHash', 'xhash() object');

ok(!scalar %$xh, 'scalar is false when hash is empty');
is($xh->next_index(), 0, 'next index is 0 when hash is empty');

# Tests: 10

## Hash-like ways to store numerically-indexed elements

$xh->{0} = 'tsrif';
is_deeply($xh->as_hashref(), [{0=>'tsrif'}], 'explicit num key assignment');
$xh->{0} = 'first';
is_deeply($xh->as_hashref(), [{0=>'first'}], 'explicit num key overwrite');
is($xh->next_index(), 1, 'next index is 1 after setting {0}');

$xh->{[]} = 'second';
is_deeply($xh->as_hashref(), [{0=>'first'},{1=>'second'}],
  'automatic num key assignment');
is($xh->next_index(), 2, 'next index is 2 after setting {[]} (1)');

$xh->STORE(5, 'third');
is_deeply($xh->as_hashref(), [{0=>'first'},{1=>'second'},{5=>'third'}],
  'explicit num key STORE');
$xh->store(5, 'third');
is_deeply($xh->as_hashref(), [{0=>'first'},{1=>'second'},{5=>'third'}],
  'explicit num key store');
is($xh->next_index(), 6, 'next index is 6 after STORE 5');

$xh->STORE([], 'fourth');
is_deeply($xh->as_hashref(),
  [{0=>'first'},{1=>'second'},{5=>'third'},{6=>'fourth'}],
  'automatic num key STORE');
is($xh->next_index(), 7, 'next index is 7 after STORE [] (6)');

# Tests: 10

## Hash-like ways to fetch numerically-indexed elements

is($xh->{0}, 'first', 'num key hashref access');
is($xh->FETCH(1), 'second', 'num key hashref FETCH');
is($xh->fetch(1), 'second', 'num key hashref fetch');
is(tied(%$xh)->FETCH(1), 'second', 'num key hashref FETCH');

# Tests: 4

## Test delete and exists for numeric keys

ok(exists $xh->{1}, 'existing num key exists');
ok(!exists $xh->{2}, 'non-existent num key !exists');

# Tests: 2

is(delete $xh->{1}, 'second', 'delete existing num key returns value');
is(delete $xh->{2}, undef, 'delete non-existent num key returns undef');
is(xh(1)->delete(0), 1, 'delete() returns scalar');
is(xh(0, 1)->delete(0, 1), 1, 'delete(0, 1) returns last scalar');
is_deeply(xh(2, 1)->delete({to=>{}}, 0, 1), {0=>2,1=>1},
  'delete(to {}) returns hash');
is_deeply(xh(2, 1)->delete({to=>[]}, 0, 1), [{0=>2},{1=>1}],
  'delete(to [], 0, 1) returns [{}] in correct order');
is_deeply(xh(2, 1)->delete({to=>[]}, 1, 0), [{1=>1},{0=>2}],
  'delete(to [], 1, 0) returns [{}] in correct order');
isa_ok(xh(2, 1)->delete({to=>xh()}, 1, 0), 'Data::XHash',
  'delete(to xh(), 1, 0)');
is_deeply(xh(2, 1)->delete({to=>xh()}, 1, 0)->as_hashref(), [{1=>1},{0=>2}],
  'delete(to xh(), 1, 0)->as_hashref is correct');

# Tests: 2

## Test SCALAR and CLEAR while we reset between tests

ok(scalar %$xh, 'scalar is true when hash is not empty');
$xh->CLEAR();
is_deeply($xh->as_hashref(), [], 'XHash is now empty after CLEAR');
$xh->push(1)->clear();
is_deeply($xh->as_hashref(), [], 'XHash is now empty after clear');

# Tests: 3

## Hash-like ways to store string-keyed elements

$xh->{'one'} = 'tsrif';
is_deeply($xh->as_hashref(), [{one=>'tsrif'}],
  'explicit string key assignment');
$xh->{'one'} = 'first';
is_deeply($xh->as_hashref(), [{one=>'first'}],
  'explicit string key overwrite');
$xh->STORE('two', 'second');
is_deeply($xh->as_hashref(), [{one=>'first'},{two=>'second'}],
  'explicit string key STORE');

# Tests: 3

## Hash-like ways to fetch string-keyed elements

is($xh->{one}, 'first', 'string key hashref access');
is($xh->FETCH('two'), 'second', 'string key hashref FETCH');
is($xh->fetch('two'), 'second', 'string key hashref fetch');

# Tests: 3

## Test delete and exists for string keys

ok(exists $xh->{one}, 'existing string key exists');
ok(!exists $xh->{three}, 'non-existent string key !exists');

# Tests: 2

is(delete $xh->{two}, 'second', 'delete existing string key returns value');
is(delete $xh->{three}, undef, 'delete non-existent string key returns undef');

# Tests: 2

## Test FIRSTKEY/NEXTKEY

$xh = xhash({one=>'first'},{2=>'second'},'third');
is_deeply($xh->as_hashref(), [{one=>'first'},{2=>'second'},{3=>'third'}],
  'xhash(simple elements) generated correctl');
is($xh->FIRSTKEY(), 'one', 'FIRSTKEY returns first key');
is($xh->NEXTKEY('one'), 2, 'NEXTKEY #1 returns second key');
is($xh->first_key(), 'one', 'first_key returns first key');
is($xh->NEXTKEY(2), 3, 'NEXTKEY #2 returns third & last key');
is($xh->NEXTKEY(3), undef, 'NEXTKEY after end returns undef');

# Tests: 6

## Test last_key, previous_key

is($xh->last_key(), 3, 'last_key returns last key');
is($xh->previous_key(3), 2, 'prev_key #1 returns second key');
is($xh->previous_key(2), 'one', 'prev_key #2 returns first key');
is($xh->previous_key('one'), undef, 'prev_key before start returns undef');

# Tests: 4

## Test foreach

is_deeply(xhash(1..5)->foreach(sub {
    my ($xh, $key, $value, $calc) = @_;
    return $calc unless defined($key);
    $calc->{sum} += $value; $calc->{product} *= $value;
    return ();
  }, { sum => 0, product => 1 }), { sum => 15, product => 120 },
  'foreach sum/product is OK');
is_deeply([xhash({hello => 'world'})->foreach(sub {
    my ($xh, $key, $value) = @_;
    return defined($key)? "$key, $value": ();
  })], ['hello, world'], 'foreach hello, world is OK');

# Tests: 2

package Data::XHashSubclass;

use base qw/Data::XHash/;

# (for empty sub-class testing)

# END
