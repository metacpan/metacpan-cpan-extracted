#!perl -w

use strict;
use Test::More tests => 25;
use Test::Exception;

use Class::Monadic qw(:all);

{
	package T;

	sub new{
		return bless {}, shift;
	}
}

for(1 .. 2){
	my $x = T->new;
	my $y = T->new;

	Class::Monadic->initialize($x)->add_method(foo => sub{ 'foo' });
	Class::Monadic->initialize($x)->add_method(bar => sub{ 'bar' });

	is(Class::Monadic->initialize($x)->name, 'T', 'name');

	lives_and{
		is $x->foo, 'foo', '$x->foo';
	};
	lives_and{
		is $x->bar, 'bar', '$x->bar';
	};

	throws_ok{
		isnt $y->foo, 'foo';
	} qr/Can't locate object method "foo"/;
	throws_ok{
		isnt $y->bar, 'bar';
	} qr/Can't locate object method "bar"/;
	
}

for(1 .. 2){
	my $x = T->new;
	my $y = T->new;

	monadic($x)->add_method(foo => sub{ 'foo' });
	monadic($x)->add_method(bar => sub{ 'bar' });

	is monadic($x)->name, 'T';

	lives_and{
		is $x->foo, 'foo', '$x->foo';
	};
	lives_and{
		is $x->bar, 'bar', '$x->bar';
	};

	throws_ok{
		isnt $y->foo, 'foo';
	} qr/Can't locate object method "foo"/;
	throws_ok{
		isnt $y->bar, 'bar';
	} qr/Can't locate object method "bar"/;
	
}

throws_ok{
	Class::Monadic->initialize('T')->add_method(foo => sub{ 'foo' });
} qr/Cannot initialize/, 'install into a class (not an instance)';
dies_ok{
	monadic('T');
};
dies_ok{
	monadic({});
};


throws_ok{
	my $t = T->new();

	no warnings 'uninitialized';
	monadic($t)->add_method(undef, sub{});
} qr/failed/;

throws_ok{
	my $t = T->new();
	monadic($t)->add_method(qw(foo bar));
} qr/failed/;
