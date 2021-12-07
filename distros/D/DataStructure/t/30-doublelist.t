use strict;
use warnings;
use utf8;


use Scalar::Util qw(weaken);
use Test2::Bundle::More;
use Test2::Tools::Target 'DataStructure::DoubleList';

{
  my $l = DataStructure::DoubleList->new();
  isa_ok($l, 'DataStructure::DoubleList');

  cmp_ok($l->size(), '==', 0, 'empty size');
  ok(!defined($l->first()), 'no first on empty list');
  ok(!defined($l->last()), 'no last on empty list');
  ok(!defined($l->shift()), 'cannot shift empty list');
  ok(!defined($l->pop()), 'cannot pop empty list');
  ok($l->empty(), 'empty');

  my $f = $l->unshift('abc');
  isa_ok($f, 'DataStructure::DoubleList::Node');
  cmp_ok($l->size(), '==', 1, 'size 1');
  ok(!$l->empty(), 'not empty');

  my $g = $l->first();
  isa_ok($g, 'DataStructure::DoubleList::Node');
  cmp_ok($f, '==', $g, 'node compare with first');
  is($f->value(), 'abc', 'value abc');
  my $h = $l->last();
  isa_ok($h, 'DataStructure::DoubleList::Node');
  cmp_ok($f, '==', $h, 'node compare with last');

  $f = $l->unshift('def');
  cmp_ok($l->size(), '==', 2, 'size 2');
  $g = $l->first();
  cmp_ok($f, '==', $g, 'node compare 2');
  is($f->value(), 'def', 'value def');
  $f = $f->next();
  is($f->value(), 'abc', 'value abc again');
  cmp_ok($f, '==', $l->last(), 'compare with last direct');

  is($l->shift(), 'def', 'shift def');
  cmp_ok($l->size(), '==', 1, 'size 1 again');
  is($f->value(), 'abc', 'node still works');
  $g = $l->first();
  cmp_ok($f, '==', $g, 'node compare 2');

  ok(!defined $f->next(), 'no next after last node');
  is($l->shift(), 'abc', 'shift abc');
  cmp_ok($l->size(), '==', 0, 'size 0');
  ok(!defined $l->shift(), 'shift after last');
  cmp_ok($l->size(), '==', 0, 'size 0 again');
  ok($l->empty(), 'empty again');
}

{
  my $l = DataStructure::DoubleList->new();
  is_deeply([$l->values()], []);
  $l->unshift('abc');
  is_deeply([$l->values()], [qw(abc)]);
  $l->push('def');
  is_deeply([$l->values()], [qw(abc def)]);
  $l->unshift('123');
  is_deeply([$l->values()], [qw(123 abc def)]);
  my $n = $l->first();
  my $m = $n->insert_after('a');
  is_deeply([$l->values()], [qw(123 a abc def)]);
  $n->insert_before('b');
  is_deeply([$l->values()], [qw(b 123 a abc def)]);
  is($l->first()->value(), 'b');
  $m->insert_after('c');
  is_deeply([$l->values()], [qw(b 123 a c abc def)]);
  $m->insert_before('d');
  is_deeply([$l->values()], [qw(b 123 d a c abc def)]);
  $n = $l->first()->next();
  is($l->shift(), 'b');
  is_deeply([$l->values()], [qw(123 d a c abc def)]);
  ok(!defined $n->prev());
  $n = $l->last;
  $n->insert_before('u');
  is_deeply([$l->values()], [qw(123 d a c abc u def)]);
  $n->insert_after('v');
  is_deeply([$l->values()], [qw(123 d a c abc u def v)]);
  is($l->last()->value(), 'v');
  is($l->pop(), 'v');
  is_deeply([$l->values()], [qw(123 d a c abc u def)]);
  $l->push('x');
  is_deeply([$l->values()], [qw(123 d a c abc u def x)]);
  $l->unshift('e');
  is_deeply([$l->values()], [qw(e 123 d a c abc u def x)]);
  is($l->pop(), 'x');
  is_deeply([$l->values()], [qw(e 123 d a c abc u def)]);
  is($l->shift(), 'e');
  is_deeply([$l->values()], [qw(123 d a c abc u def)]);
  is($l->pop(), 'def');
  is_deeply([$l->values()], [qw(123 d a c abc u)]);
  is($l->shift(), '123');
  is_deeply([$l->values()], [qw(d a c abc u)]);
  is($l->pop(), 'u');
  is_deeply([$l->values()], [qw(d a c abc)]);
  is($l->shift(), 'd');
  is_deeply([$l->values()], [qw(a c abc)]);
  $l->unshift('a');
  $l->push('b');
  is_deeply([$l->values()], [qw(a a c abc b)]);
  $l->pop(); $l->pop(); $l->shift(); $l->shift();
  is_deeply([$l->values()], [qw(c)]);
  ok(!$l->empty());
  $l->pop();
  is_deeply([$l->values()], []);
  ok($l->empty());
  $n = $l->push('a');
  is_deeply([$l->values()], [qw(a)]);
  $n->insert_before('b');
  $n->insert_after('c');
  is_deeply([$l->values()], [qw(b a c)]);
}

my $weak_ref;
my $weak_node;
{
  my $l = DataStructure::DoubleList->new();
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
