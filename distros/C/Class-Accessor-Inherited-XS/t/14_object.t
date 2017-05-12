use strict;
use Test::More;

use Class::Accessor::Inherited::XS {
    object => 'foo',
    accessors => 'bar',
};

my $o = bless {foo => 66, bar => 23};
my $z = bless {};

is($o->bar, 23);

is($o->foo, 66);
is($o->foo(12), 12);

is($z->foo, undef);
is(exists $z->{foo}, '');

is($o->foo, 12);

is($z->foo(42), 42);
is($o->foo, 12);
is($z->foo, 42);

done_testing;
