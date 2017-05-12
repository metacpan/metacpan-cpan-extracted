use strict;
use warnings;

package Class::XSAccessor::Test;

use Class::XSAccessor::Array
  constructor => 'new',
  accessors => { bar => 0, blubber => 2 },
  getters   => { get_foo => 1 },
  setters   => { set_foo => 1 };

our $DESTROYED = 0;

sub DESTROY { $DESTROYED = 1 }

package main;

use Test::More tests => 21;

ok (Class::XSAccessor::Test->can('new'));

my $obj = Class::XSAccessor::Test->new( bar => 'baz' );

ok ($obj->can('bar'));
is ($obj->set_foo('bar'), 'bar');
is ($obj->get_foo(), 'bar');
ok (!defined($obj->bar()));
is ($obj->bar('quux'), 'quux');
is ($obj->bar(), 'quux');

my $obj2 = $obj->new(bar => 'baz', 'blubber' => 'blabber');
ok ($obj2->can('bar'));
is ($obj2->set_foo('bar'), 'bar');
is ($obj2->get_foo(), 'bar');
ok (!defined($obj2->bar()));
is ($obj2->bar('quux'), 'quux');
is ($obj2->bar(), 'quux');
ok (!defined($obj2->blubber()));

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
