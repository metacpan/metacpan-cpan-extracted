#!perl
use warnings FATAL => 'all';
use strict;

use Test::More tests => 10;

use Acme::Lvalue qw(:builtins), [succ => sub { $_[0] + 1 }, sub { $_[0] - 1 }];

is sqrt(9), 3;
sqrt(my $x) = 2;
is $x, 4;

is reverse("abcd"), "dcba";
reverse($x) = "ypnftm";
is $x, "mtfnpy";

is length("foobar"), 6;
length($x = "truism") = 4;
is $x, "trui";
length($x) = 10;
is $x, "trui\0\0\0\0\0\0";

is succ(3), 4;
succ($x) = 43;
is $x, 42;

my $r = \sqrt($x);
$$r = 3;
is $x, 9;
