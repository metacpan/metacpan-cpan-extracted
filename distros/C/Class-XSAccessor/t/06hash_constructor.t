use strict;
use warnings;

package Class::XSAccessor::Test;

use Class::XSAccessor
  constructor => 'new',
  accessors => { bar => 'bar', blubber => 'blubber' },
  getters   => { get_foo => 'foo' },
  setters   => { set_foo => 'foo' };

our $DESTROYED = 0;

sub DESTROY { $DESTROYED = 1 }

package main;

use Test::More tests => 23;

ok (Class::XSAccessor::Test->can('new'));

my $obj = Class::XSAccessor::Test->new(bar => 'baz', 'blubber' => 'blabber');

ok ($obj->can('bar'));
is ($obj->set_foo('bar'), 'bar');
is ($obj->get_foo(), 'bar');
is ($obj->bar(), 'baz');
is ($obj->bar('quux'), 'quux');
is ($obj->bar(), 'quux');
is ($obj->blubber(), 'blabber');

my $obj2 = $obj->new(bar => 'baz', 'blubber' => 'blabber');
ok ($obj2->can('bar'));
is ($obj2->set_foo('bar'), 'bar');
is ($obj2->get_foo(), 'bar');
is ($obj2->bar(), 'baz');
is ($obj2->bar('quux'), 'quux');
is ($obj2->bar(), 'quux');
is ($obj2->blubber(), 'blabber');

eval 'Class::XSAccessor::Test->new("uneven_no_of_args")';
ok ($@);

# make sure the object refcount is valid (i.e. it's not reaped at the end of an inner scope if it's
# referenced in an outer scope)
{
    my $obj3;
    {
        is($Class::XSAccessor::Test::DESTROYED, 0);
        $obj3 = do { Class::XSAccessor::Test->new(bar => 'baz', 'blubber' => 'blabber') };
        is($Class::XSAccessor::Test::DESTROYED, 0);
    }
    is($Class::XSAccessor::Test::DESTROYED, 0);
    ok($obj3, 'object not reaped in outer scope');
    isa_ok($obj3, 'Class::XSAccessor::Test');
    can_ok($obj3, qw(bar blubber get_foo set_foo));
}

is($Class::XSAccessor::Test::DESTROYED, 1);
