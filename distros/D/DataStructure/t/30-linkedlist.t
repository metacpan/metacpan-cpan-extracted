use strict;
use warnings;
use utf8;

use Scalar::Util qw(weaken);
use Test2::Bundle::More;
use Test2::Tools::Target 'DataStructure::LinkedList';

my $l = DataStructure::LinkedList->new();
isa_ok($l, 'DataStructure::LinkedList');
is_deeply([$l->values()], []);
ok($l->empty(), 'empty');

cmp_ok($l->size(), '==', 0, 'empty size');
ok(!defined($l->first()), 'no first on empty list');
ok(!defined($l->shift()), 'cannot shift empty list');

my $f = $l->unshift('abc');
is_deeply([$l->values()], [qw(abc)]);
isa_ok($f, 'DataStructure::LinkedList::Node');
cmp_ok($l->size(), '==', 1, 'size 1');
ok(!$l->empty(), 'not empty');

my $g = $l->first();
isa_ok($g, 'DataStructure::LinkedList::Node');
cmp_ok($f, '==', $g, 'node compare');
is($f->value(), 'abc', 'value abc');

$f = $l->unshift('def');
is_deeply([$l->values()], [qw(def abc)]);
cmp_ok($l->size(), '==', 2, 'size 2');
$g = $l->first();
cmp_ok($f, '==', $g, 'node compare 2');
is($f->value(), 'def', 'value def');
$f = $f->next();
is($f->value(), 'abc', 'value abc again');

is($l->shift(), 'def', 'shift def');
is_deeply([$l->values()], [qw(abc)]);
cmp_ok($l->size(), '==', 1, 'size 1 again');
is($f->value(), 'abc', 'node still works');
$g = $l->first();
cmp_ok($f, '==', $g, 'node compare 2');

ok(!defined $f->next(), 'no next after last node');
is($l->pop(), 'abc', 'pop abc');
is_deeply([$l->values()], [qw()]);
cmp_ok($l->size(), '==', 0, 'size 0');
ok(!defined $l->shift(), 'shift after last');
cmp_ok($l->size(), '==', 0, 'size 0 again');
ok($l->empty(), 'empty again');

{
  my $l = DataStructure::LinkedList->new();
  $l->_self_check('');
  is_deeply([$l->values()], [qw()]);
  ok(!defined $l->shift());
  ok(!defined $l->pop());
  cmp_ok($l->size(), '==', 0);
  $l->_self_check('');

  $l->unshift('a');
  $l->_self_check('a');
  is_deeply([$l->values()], [qw(a)]);
  cmp_ok($l->size(), '==', 1);

  $l->unshift('b');
  $l->_self_check('b a');
  is_deeply([$l->values()], [qw(b a)]);
  cmp_ok($l->size(), '==', 2);

  $l->push('c');
  $l->_self_check('b a c');
  is_deeply([$l->values()], [qw(b a c)]);
  cmp_ok($l->size(), '==', 3);

  is($l->shift(), 'b');
  $l->_self_check('a c');
  is_deeply([$l->values()], [qw(a c)]);
  is($l->pop(), 'a');
  $l->_self_check('c');
  is_deeply([$l->values()], [qw(c)]);
  is($l->shift(), 'c');
  $l->_self_check('');
  is_deeply([$l->values()], []);
  cmp_ok($l->size(), '==', 0);

  $l->push('d');
  $l->_self_check('d');
  is_deeply([$l->values()], [qw(d)]);
  cmp_ok($l->size(), '==', 1);
}

{
  my $l = DataStructure::LinkedList->new(reverse => 1);
  $l->_self_check('');
  is_deeply([$l->values()], [qw()]);
  ok(!defined $l->shift());
  ok(!defined $l->pop());
  cmp_ok($l->size(), '==', 0);
  $l->_self_check('');

  $l->unshift('a');
  $l->_self_check('a');
  is_deeply([$l->values()], [qw(a)]);
  cmp_ok($l->size(), '==', 1);

  $l->unshift('b');
  $l->_self_check('a b');
  is_deeply([$l->values()], [qw(a b)]);
  cmp_ok($l->size(), '==', 2);

  $l->push('c');
  $l->_self_check('c a b');
  is_deeply([$l->values()], [qw(c a b)]);
  cmp_ok($l->size(), '==', 3);

  is($l->shift(), 'c');
  $l->_self_check('a b');
  is_deeply([$l->values()], [qw(a b)]);
  is($l->pop(), 'a');
  $l->_self_check('b');
  is_deeply([$l->values()], [qw(b)]);
  is($l->shift(), 'b');
  $l->_self_check('');
  is_deeply([$l->values()], []);
  cmp_ok($l->size(), '==', 0);

  $l->push('d');
  $l->_self_check('d');
  is_deeply([$l->values()], [qw(d)]);
  cmp_ok($l->size(), '==', 1);
}

my $weak_ref;
my $weak_node;
{
  my $l = DataStructure::LinkedList->new();
  $l->unshift('abc');
  $l->unshift('def');
  my $f = $l->first;
  $weak_ref = $l;
  $weak_node = $f;
  weaken($weak_ref);
  weaken($weak_node);
}
ok(!defined $weak_ref, 'garbage collection');
ok(!defined $weak_node, 'garbage collection 2');

done_testing();
