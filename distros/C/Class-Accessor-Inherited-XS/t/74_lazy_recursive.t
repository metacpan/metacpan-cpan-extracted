use strict;
use Test::More;

use Class::Accessor::Inherited::XS {
    class       => {
        foo => sub { __PACKAGE__->foo(12); __PACKAGE__->foo },
    },
};

is(__PACKAGE__->foo, 12);
is(__PACKAGE__->foo, 12);

done_testing;
