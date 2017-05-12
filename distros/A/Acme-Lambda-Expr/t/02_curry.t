#!perl -w
use strict;

use Test::More tests => 8;
use Test::Exception;

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

sub div{
	$_[0] / $_[1];
}


my $f = curry \&div, $x, 2;
is $f->(4), 2, 'curry';

$f = curry \&div, 10, $x;
is $f->(2), 5;

$f = curry 'value', $x;
is $f->(Foo->new(value => 42)), 42;

my $o = Foo->new(vlaue => 10);
$f = curry 'value', $o, $x;
$f->(20);

is $o->value, 20;

$f = curry $x - $y, 10, $x;
is $f->(6), 4;

$f = curry undefined_method => $x;

throws_ok{
	$f->($o);
} qr/Can't locate object method/;
throws_ok{
	$f->(undef);
} qr/Can't call method/;
