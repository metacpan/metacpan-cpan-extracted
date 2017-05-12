use strict;
use warnings;
use Test::More;
use Data::Recursive::Encode;

sub is_number { Data::Recursive::Encode::_is_number($_[0]) }

ok   is_number(0);
ok   is_number(1);
ok   is_number(-1);
ok   is_number(1.0);
ok   is_number(-1.0);
ok   is_number(11111111111111111111111111111111111111111111);
ok   is_number(-11111111111111111111111111111111111111111111);

ok ! is_number("foo");
ok ! is_number({});
ok ! is_number([]);
ok ! is_number(Foo->new);
ok ! is_number(undef);

done_testing;

package Foo;
sub new { bless {}, $_[0] }
