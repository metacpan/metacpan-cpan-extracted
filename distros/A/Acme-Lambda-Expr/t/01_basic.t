#!perl -w
use strict;

use Test::More tests => 24;

use warnings FATAL => 'all';

BEGIN {
	use_ok 'Acme::Lambda::Expr', qw(:all);
}
BEGIN{
	package Foo;
	use Moose;

	has value => (
		is => 'rw',
	);
}

ok $x, '$x as boolean';
ok $y, '$y as boolean';

my $add_10 = $x + 10;

is $add_10->(0),  10, '$x + 10';
is $add_10->(10), 20;
is $add_10->(-1),  9;

$add_10 = 10 + $x;

is $add_10->(0),  10, '10 + $x';
is $add_10->(10), 20;
is $add_10->(-1),  9;

my $add_x_y = $x + $y;

is $add_x_y->(0, 0), 0, '$x + $y';
is $add_x_y->(2, 3), 5;
is $add_x_y->(2, -3), -1;

my $neg_x = -$x;

is $neg_x->(42), -42, '-$x';

is -($x + 10)->(10), -20,    '-($x + 10)';
is -($x + $y)->(10, 5), -15, '-($x + $y)';

is sqrt($x * $x)->(10), 10, 'sqrt($x * $x)';

is abs($x / 2)->(-42), 21, 'abs($x / 2)';
ok +($x == 42)->(42), '($x == 42)';
ok +($x eq 'foo')->('foo'), q{($x eq 'foo')};

is value(10)->(), 10, 'value()';
is value($x)->(10), 10;
is value($x / 2)->(10), 5;

my $foo = Foo->new(value => 42);

is $x->value->($foo), 42, 'method call';
$x->value($y)->($foo, 21);
is $foo->value, 21, 'method call with an argument';
