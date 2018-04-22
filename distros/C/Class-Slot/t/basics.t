package A;

use Class::Slot;
use Types::Standard -types;

slot foo => Int, rw => 1, def => 42;
slot bar => Str, req => 1;
slot baz => req => 1, def => 'fnord';
slot 'foo $bar' => sub{ !defined $_[0] };

1;


package main;

use strict;
use warnings;
no warnings 'once';

use Test::More;

is_deeply \@A::SLOTS, [qw(bar baz foo foo_bar)], '@SLOTS';

# Constructor
ok my $o = A->new(foo => 1, bar => 'slack', baz => 'bat'), 'ctor';

# Getters
is $o->foo, 1, 'get slot';
is $o->bar, 'slack', 'get slot';
is $o->baz, 'bat', 'get slot';
ok $o->can('foo_bar'), 'quoted slot accessor';

# Setters
is $o->foo(4), 4, 'set slot';
is $o->foo, 4, 'slot remains set';

# Validation
ok do{ local $@; eval{ A->new(foo => 1, baz => 2) }; $@ }, 'ctor dies w/o req arg';
ok do{ local $@; eval{ A->new(bar => 'bar', foo => 'not an int') }; $@ }, 'ctor dies on invalid type';
ok do{ local $@; eval{ A->new(foo => 1, bar => 'two', foo_bar => 1) }; $@ }, 'ctor dies on invalid anon type';

ok $o = A->new(bar => 'asdf'), 'ctor w/o def args';
is $o->foo, 42, 'get slot w/ def';
is $o->baz, 'fnord', 'get slot w/ def';
is $o->bar, 'asdf', 'get slot w/o def';

done_testing;
