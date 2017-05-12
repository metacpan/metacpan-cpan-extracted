#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
	plan skip_all => "Moose is required for this test" unless eval { require Moose };
	plan tests => 25;
}

{
	package Foo;
	use Moose;

	package Bar;
	use Moose::Role;
	
	package Gorch;
	use Moose;

	extends qw(Foo);

	with qw(Bar);

}

use ok 'Check::ISA' => qw(obj obj_does inv);

ok( obj(Foo->new), "Foo->new is an obj" );
ok( obj(Foo->new, "Foo"), "of class Foo" );
ok( obj(Foo->new, "Moose::Object"), "and Moose::Object" );
ok( inv(Foo->new, "Foo"), "inv works too" );

ok( !obj("Foo"), "the class is not an object" );
ok( !obj("Foo", "Foo"), "the class is not an object" );
ok( inv("Foo"), "Foo is a class" );
ok( inv("Foo", "Foo"), "class is itself" );
ok( inv("Foo", "Moose::Object"), "class is Moose::Object" );

ok( obj(Gorch->new), "Gorch->new is an obj" );
ok( obj(Gorch->new, "Gorch"), "of class Gorch" );
ok( obj(Gorch->new, "Foo"), "and class Foo" );
ok( obj(Gorch->new, "Moose::Object"), "and Moose::Object" );

SKIP: {
	skip "Moose 0.52 required for roles", 3 unless eval { Moose->VERSION("0.52") };
	ok( Gorch->new->does("Bar"), "does Bar" );
	ok( Gorch->new->DOES("Bar"), "DOES Bar" );
	ok( obj_does(Gorch->new, "Bar"), "does Bar in obj test" );
}

ok( inv(Gorch->new, "Gorch"), "inv works too" );

ok( !obj("Gorch"), "the class is not an object" );
ok( !obj("Gorch", "Gorch"), "the class is not an object" );
ok( inv("Gorch"), "Gorch is a class" );
ok( inv("Gorch", "Gorch"), "class is itself" );
ok( inv("Gorch", "Foo"), "class is Foo" );
ok( inv("Gorch", "Moose::Object"), "class is Moose::Object" );

SKIP: {
	plan skip "No DOES in this version of Perl", 1 unless UNIVERSAL->can("DOES");
	skip "Moose 0.52 required for roles", 1 unless eval { Moose->VERSION("0.52") };
	ok( inv("Gorch", "Bar"), "class does Bar" );
}
