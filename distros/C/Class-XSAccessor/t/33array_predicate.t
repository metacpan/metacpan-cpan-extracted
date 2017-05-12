use strict;
use warnings;

package Class::XSAccessor::Test;

use Class::XSAccessor::Array
  accessors  => { bar => 0 },
  getters    => { get_foo => 1 },
  setters    => { set_foo => 1 },
  predicates => { has_foo => 1, has_bar => 0 };

sub new {
  my $class = shift;
  bless [ 'baz' ], $class;
}

package main;

use Test::More tests => 12;

my $obj = Class::XSAccessor::Test->new();

ok($obj->can('has_foo'));
ok($obj->can('has_bar'));

ok(!$obj->has_foo());
ok($obj->has_bar());

is($obj->set_foo('bar'), 'bar');
is($obj->bar('quux'), 'quux');

ok($obj->has_foo());
ok($obj->has_bar());

is($obj->set_foo(undef), undef);
is($obj->bar(undef), undef);

ok(!$obj->has_foo());
ok(!$obj->has_bar());

