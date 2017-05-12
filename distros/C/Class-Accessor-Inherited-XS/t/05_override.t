use strict;
use Test::More;

use Class::Accessor::Inherited::XS inherited => [qw/foo/];
our $foo = 12;

is(__PACKAGE__->foo(42), 42);
is($foo, 12);
is(__PACKAGE__->foo, 42);

done_testing;
