use strict;
use Test::More;

use Class::Accessor::Inherited::XS inherited => [qw/foo bar/];

my $o = bless {};

is(__PACKAGE__->foo(12), 12);
is($o->foo, 12);
is(__PACKAGE__->foo, 12);

is(__PACKAGE__->bar(42), 42);
is(__PACKAGE__->foo, 12);
is($o->foo, 12);
is($o->bar, 42);

is($o->foo("oops"), "oops");
is($o->foo, "oops");
is(__PACKAGE__->foo, 12);
is(__PACKAGE__->bar, 42);

done_testing;
