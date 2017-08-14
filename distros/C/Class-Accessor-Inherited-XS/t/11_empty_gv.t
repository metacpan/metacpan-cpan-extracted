use Test::More;
use strict;

sub __cag_foo;

use parent qw/Class::Accessor::Inherited::XS::Compat/;
__PACKAGE__->mk_inherited_accessors('foo');

is(__PACKAGE__->foo(12), 12);

done_testing;
