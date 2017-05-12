use strict;
use Test::More;

use Class::Accessor::Inherited::XS inherited => [qw/foo/];
*bar = *foo;

is(__PACKAGE__->foo(42), 42);
is(__PACKAGE__->bar, 42);
__PACKAGE__->bar(17);
is(__PACKAGE__->foo, 17);

undef *{main::foo};
is(__PACKAGE__->bar, 17);

undef *{main::__cag_foo};
is(__PACKAGE__->bar, undef);

done_testing;
