package Point;
use Class::Slot;
slot 'x', rw => 1;
slot 'y', rw => 1;
1;

package main;

use strict;
use warnings;

use Test::More;
use Class::Slot;

subtest 'quote_identifier' => sub{
  is slot::quote_identifier('a-b^c'), 'a_b_c', 'individual chars';
  is slot::quote_identifier('a----b'), 'a_b', 'multiple chars';
};

subtest 'install_sub' => sub{
  slot::install_sub('Point', 'foo', "return 42;");
  ok(Point->can('foo'), 'sub installed');
  is(Point->foo, 42, 'expected return value');
};

subtest 'install_method' => sub{
  slot::install_method('Point', 'bar', 'return $self->x;');
  ok my $p = Point->new(x => 10), 'ctor';
  ok $p->can('bar'), 'method installed';
  is $p->bar, 10, 'expected return value';
};

done_testing;
