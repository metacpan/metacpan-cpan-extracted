#!perl -w


use strict;
use Test::More;

use Data::Util qw(is_instance);

BEGIN{
	if(exists $INC{'Data/Util/PurePerl.pm'}){
		plan skip_all => 'For XS only';
	}
	else{
		plan tests => 26;
	}
}

local $SIG{__WARN__} = sub{}; # ignore

BEGIN{
	no warnings;

	sub UNIVERSAL::new{
		bless {} => shift;
	}
	package Foo;
	our @ISA = (undef, 1, [], \&new, 'Base');

	sub new{
		bless {} => shift;
	}


	package X;
	our @ISA = qw(A);

	package Y;
	package Z;

	package Bar;
	our @ISA = qw(::X main::Y ::main::main::Z);

	my $instance = bless {} => '::main::main::Bar';
	sub instance{ $instance }

	package main::Ax;
	package ::Bx;
	our @ISA = qw(Ax);
	package ::main::main::Cx;
	our @ISA = qw(Bx);
}

my $o = Foo->new();

ok  is_instance($o, 'Foo');
ok  is_instance($o, 'Base');
ok  is_instance($o, 'UNIVERSAL');

@Foo::ISA = ();

ok  is_instance($o, 'Foo');
ok!(is_instance($o, 'Base'));
ok  is_instance($o, 'UNIVERSAL');

ok is_instance($o, '::Foo');
ok is_instance($o, 'main::Foo');
ok is_instance($o, 'main::main::Foo');
ok is_instance($o, '::main::main::UNIVERSAL');
ok!is_instance($o, '::::Foo');
ok!is_instance($o, 'Fooo');
ok!is_instance($o, 'FoO');
ok!is_instance($o, 'foo');
ok!is_instance($o, 'mai');
ok!is_instance($o, 'UNIVERSA');


$o = Bar->instance;

ok is_instance($o, 'Bar');
ok is_instance($o, 'X');
ok is_instance($o, 'Y');
ok is_instance($o, 'Z');
ok is_instance($o, '::Z');

ok!is_instance($o, 'main');
ok!is_instance($o, 'main::');


ok is_instance(Cx->new, 'Ax');
ok is_instance(Cx->new, 'Bx');
ok is_instance(Cx->new, 'Cx');
