#!perl -w

use strict;
use Test::More tests => 10;
use Test::Exception;

use Class::Monadic qw(:all);

{
	package T;

	sub new{
		my $class =  shift;
		return bless {@_}, $class;
	}

	sub clone{
		my($self) = @_;

		bless { %{$self} }, ref $self;
	}

	package Tx;

	package X;

	sub new{
		my $class =  shift;
		return bless {@_}, $class;
	}
	
}

my $t = T->new(foo => 42);

monadic($t)->add_method(pi => sub{ 3.14 });
monadic($t)->add_field(age => qr/^\d+$/);
monadic($t)->inject_base('Tx');

$t->set_age(10);

my $x = $t->clone;
isa_ok $x, 'T';
isa_ok $x, 'Tx' or do{
	require Data::Dumper;
	diag(Data::Dumper::Dumper(monadic($x)));
};

can_ok $x, 'pi';
can_ok $x, 'get_age';

is $x->pi, 3.14;

is $x->get_age, 10;
$t->set_age(12);
is $x->get_age, 10;


my $z = X->new;
monadic($t)->bless($z);

isa_ok $z, 'X';
isa_ok $z, 'Tx';

ok(!$z->isa('T')) or do{
	require Data::Dumper;
	diag(Data::Dumper::Dumper(monadic($z)));
};
