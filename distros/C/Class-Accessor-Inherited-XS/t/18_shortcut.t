use strict;
use Test::More;

use CAIXS inherited => [qw/foo/];

is(__PACKAGE__->foo(42), 42);
is(__PACKAGE__->foo, 42);

done_testing;
