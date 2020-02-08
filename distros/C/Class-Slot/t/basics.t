BEGIN{ $ENV{CLASS_SLOT_NO_XS} = 1 };

package Class_A;

use strict;
use warnings;

use Class::Slot;
use Scalar::Util qw(looks_like_number);
sub defined_nonref{ defined($_[0]) && !ref($_[0]) }

slot foo => \&looks_like_number, rw => 1, def => 42;
slot bar => \&defined_nonref, req => 1;
slot baz => req => 1, def => 'fnord';
slot 'foo $bar' => sub{ !defined $_[0] };

1;


package main;

use Test2::V0;
no warnings 'once';

is \@Class_A::SLOTS, [qw(bar baz foo foo_bar)], '@SLOTS';

# Constructor
ok my $o = Class_A->new(foo => 1, bar => 'slack', baz => 'bat'), 'ctor';

# Getters
is $o->foo, 1, 'get slot';
is $o->bar, 'slack', 'get slot';
is $o->baz, 'bat', 'get slot';
ok $o->can('foo_bar'), 'quoted slot accessor';

# Setters
is $o->foo(4), 4, 'set slot';
is $o->foo, 4, 'slot remains set';

# Validation
ok dies{ Class_A->new(foo => 1, baz => 2) }, 'ctor dies w/o req arg';
ok dies{ Class_A->new(bar => 'bar', foo => 'not an int') }, 'ctor dies on invalid type';
ok dies{ Class_A->new(foo => 1, bar => 'two', foo_bar => 1) }, 'ctor dies on invalid anon type';

ok $o = Class_A->new(bar => 'asdf'), 'ctor w/o def args';
is $o->foo, 42, 'get slot w/ def';
is $o->baz, 'fnord', 'get slot w/ def';
is $o->bar, 'asdf', 'get slot w/o def';

done_testing;
