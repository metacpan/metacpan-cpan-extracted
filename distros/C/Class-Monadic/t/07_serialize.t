#!perl -w

use strict;
use Test::More tests => 4;
use Test::Exception;

use Storable qw(freeze);
use Class::Monadic qw(:all);

{
	package T;

	sub new{
		my $class =  shift;
		return bless {@_}, $class;
	}

	sub clone{
		Storable::dclone($_[0]);
	}
}

my $t = T->new(foo => 42);
is_deeply $t->clone, $t;

monadic($t)->add_method(pi => sub{ 3.14 });

lives_and{
	my $x = $t->clone;
	isa_ok $t, 'T';
	can_ok $t, 'pi';
};

dies_ok{
	freeze($t);
};
