use strict;
use warnings;

package Class::XSAccessor::Test;

use Class::XSAccessor
  accessors => { bar => "b\0ar" },
  getters   => { get_foo => 'foo' },
  setters   => { set_foo => 'foo' };

use Class::XSAccessor
  accessors => 'single';

use Class::XSAccessor
  accessors => [qw/mult iple/];

sub new {
  my $class = shift;
  bless { "b\0ar" => 'baz' }, $class;
}

package main;

use Test::More tests => 31;

my $obj = Class::XSAccessor::Test->new();

ok ($obj->can('bar'));
is ($obj->set_foo('bar'), 'bar');
is ($obj->get_foo(), 'bar');
is ($obj->bar(), 'baz');
is ($obj->bar('quux'), 'quux');
is ($obj->bar(), 'quux');

ok ($obj->can($_)) for qw/single mult iple/;
is ($obj->single("elgnis"), "elgnis");
is ($obj->mult("tlum"), "tlum");
is ($obj->iple("elpi"), "elpi");
is ($obj->single(), "elgnis");
is ($obj->mult(), "tlum");
is ($obj->iple(), "elpi");

package Class::XSAccessor::Test2;
sub new {
  my $class = shift;
  bless { bar => 'baz' }, $class;
}

package main;
use Class::XSAccessor
  class     => 'Class::XSAccessor::Test2',
  accessors => { bar => 'bar' },
  getters   => { get_foo => 'foo' },
  setters   => { set_foo => 'foo' };

my $obj2 = Class::XSAccessor::Test2->new();
ok ($obj2->can('bar'));
is ($obj2->set_foo('bar'), 'bar');
is ($obj2->get_foo(), 'bar');
is ($obj2->bar(), 'baz');
is ($obj2->bar('quux'), 'quux');
is ($obj2->bar(), 'quux');

# test shorthand accessor mixed with getters/setters
# for that same key
package Class::XSAccessor::Test3;
use Class::XSAccessor 
    accessors => [ 'foo', 'bar' ],
    getters   => { get_foo => 'foo',
                   get_bar => 'bar',
                 },
    setters   => { set_foo => 'foo',
                   set_bar => 'bar',
                 };
sub new {
    my $class = shift;
    bless {}, $class;
}

package main;

my $obj3 = Class::XSAccessor::Test3->new;
is($obj3->set_foo(3), 3);
is($obj3->get_foo, 3);
is($obj3->foo, 3);
is($obj3->foo(4), 4);
is($obj3->foo, 4);
is($obj3->get_foo, 4);

is($obj3->bar(33), 33);
is($obj3->get_bar, 33);
is($obj3->set_bar(44), 44);
is($obj3->bar, 44);



