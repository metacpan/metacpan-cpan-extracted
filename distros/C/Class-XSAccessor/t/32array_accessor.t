use strict;
use warnings;

package Class::XSAccessor::Test;

use Class::XSAccessor::Array
  accessors => { bar => 0 },
  getters   => { get_foo => 1 },
  setters   => { set_foo => 1 };

sub new {
  my $class = shift;
  bless [ 'baz' ], $class;
}

package main;

use Test::More tests => 12;

my $obj = Class::XSAccessor::Test->new();

ok ($obj->can('bar'));
is ($obj->set_foo('bar'), 'bar');
is ($obj->get_foo(), 'bar');
is ($obj->bar(), 'baz');
is ($obj->bar('quux'), 'quux');
is ($obj->bar(), 'quux');

package Class::XSAccessor::Test2;
sub new {
  my $class = shift;
  bless [ 'baz' ], $class;
}

package main;
use Class::XSAccessor::Array
  class     => 'Class::XSAccessor::Test2',
  accessors => { bar => 0 },
  getters   => { get_foo => 1 },
  setters   => { set_foo => 1 };

my $obj2 = Class::XSAccessor::Test2->new();

ok ($obj2->can('bar'));
is ($obj2->set_foo('bar'), 'bar');
is ($obj2->get_foo(), 'bar');
is ($obj2->bar(), 'baz');
is ($obj2->bar('quux'), 'quux');
is ($obj2->bar(), 'quux');

