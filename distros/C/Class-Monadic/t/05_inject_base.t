#!perl -w

use strict;
use Test::More tests => 16;
use Test::Exception;
use Class::Monadic qw(:all);

{
	package T;

	sub new{
		return bless {}, shift;
	}
	package TX;
	package TXX;
}

for(1 .. 2){
	my $x = T->new;
	my $y = T->new;

	ok !($x->isa('TX')), '$x is not injected';
	ok !($x->isa('TXX')), '$x is not injected';

	monadic($x)->inject_base(qw(TX TXX));
	isa_ok $x, 'T',   '$x';
	isa_ok $x, 'TX',  '$x';
	isa_ok $x, 'TXX', '$x';

	#use Data::Dumper; print Dumper monadic($x);

	isa_ok $y, 'T', '$y';
	ok !($y->isa('TX')), '$y is not injected';
	ok !($y->isa('TXX')), '$y is not injected';
}


