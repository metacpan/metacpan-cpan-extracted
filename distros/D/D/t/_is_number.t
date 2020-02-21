use strict;
use warnings;
use Test::More;
use D;

# Copy from Data::Recursive::Encode test case
ok   D::_is_number(0);
ok   D::_is_number(1);
ok   D::_is_number(-1);
ok   D::_is_number(1.0);
ok   D::_is_number(-1.0);
ok   D::_is_number(11111111111111111111111111111111111111111111);
ok   D::_is_number(-11111111111111111111111111111111111111111111);

ok ! D::_is_number("foo");
ok ! D::_is_number({});
ok ! D::_is_number([]);
ok ! D::_is_number(Foo->new);
ok ! D::_is_number(undef);

done_testing;

package Foo;
sub new { bless {}, $_[0] }
