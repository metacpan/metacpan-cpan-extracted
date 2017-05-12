#!perl -w

use strict;
use Test::More tests => 11;
use Test::Exception;
use Class::Monadic qw(:all);

{
	package T;

	sub new{
		return bless {}, shift;
	}
}

my $t1 = T->new;
my $t2 = T->new;

monadic($t1)->add_field(qw(foo));
monadic($t2)->add_field(qw(bar baz));

is(T->can('get_foo'), undef);
is(T->can('get_bar'), undef);
is(T->can('get_baz'), undef);

lives_and{
	$t1->set_foo(42);
	is $t1->get_foo(), 42;
};

lives_and{
	$t2->set_bar(3.14);
	is $t2->get_bar(), 3.14;

	$t2->set_baz('xyzzy');
	is $t2->get_baz, 'xyzzy';
};

dies_ok{
	monadic($t1)->add_field(undef);
};

dies_ok{
	$t1->set_bar();
};
dies_ok{
	$t2->set_foo();
};

throws_ok{
	$t1->get_foo(1);
} qr/Too many arguments for get_foo/;

throws_ok{
	$t1->set_foo(1, 2, 3);
} qr/Cannot set multiple values for set_foo/;
