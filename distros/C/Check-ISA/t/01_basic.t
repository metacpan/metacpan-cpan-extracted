#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok 'Check::ISA' => qw(obj obj_does inv obj_can inv_can);

{
	package Foo;
	sub new { bless {}, shift }

	package Bar;
	use base qw(Foo);

	package Gorch;
	use base qw(Foo);

	sub isa {
		my ( $self, $class ) = @_;

		$self->SUPER::isa($class)
			or
		$class eq 'Faked';
	}

	package Zot;
	use base qw(Foo);

	sub DOES {
		my ( $self, $role ) = @_;

		$self->SUPER::DOES($role)
			or
		$role eq 'FakedRole';
	}
}

ok( !inv("Class::Does::Not::Exist"), "a random string is not a class" );
ok( !inv(undef), "undef is not a class" );
ok( !inv(0), "0 is not a class" );
ok( !inv(1), "1 is not a class" );
ok( !inv("0"), "'0' is not a class" );
ok( !inv("00"), "'00' is not a class" );
ok( !inv("1"), "'1' is not a class" );
ok( !inv(""), "'' is not a class" );
ok( !inv("blah"), "'blah' is not a class" );
ok( !inv([]), "an array ref is not a class" );
ok( !inv({}), "a hash ref is not a class" );
ok( !inv(sub {}), "a subroutine is not a class" );

ok( !obj_can(undef, "foo"), "no foo method for undef" );
ok( !obj_can("blah", "foo"), "no foo method for string" );
ok( !obj_can("blah", "isa"), "no foo method for string" );
ok( !obj_can("", "foo"), "no foo method for empty" );
ok( !obj_can({}, "foo"), "no foo method for hash refs" );

ok( !inv_can("blah", "foo"), "inv_can on random class" );
ok( !inv_can("blah", "isa"), "no foo method for string" );
ok( !inv_can("Foo", "foo"), "inv_can on Foo for nonexistent method" );

no warnings 'once';
ok( !obj(\*RANDOMGLOB), "a globref without an IO is not an object");

ok( obj(\*STDIN), "a globref with an IO is an object" );
ok( obj("STDIN"), "a filehandle name is an object" );
ok( obj_can(\*STDIN, "print"), "STDIN can print" );
ok( obj_can("STDIN", "print"), "'STDIN' can print" );

ok( inv_can(\*STDIN, "print"), "STDIN can print" );
ok( inv_can("STDIN", "print"), "'STDIN' can print" );

ok( obj(Foo->new), "Foo->new is an obj" );
ok( obj(Foo->new, "Foo"), "of class Foo" );
ok( inv(Foo->new, "Foo"), "inv works too" );

is( obj_can(Foo->new, "new"), \&Foo::new, "obj_can on obj" );
ok( !obj_can("Foo", "new"), "obj_can on non obj" );
is( inv_can(Foo->new, "new"), \&Foo::new, "inv_can on obj" );
is( inv_can("Foo", "new"), \&Foo::new, "inv_can on on obj" );

ok( !obj("Foo"), "the class is not an object" );
ok( !obj("Foo", "Foo"), "the class is not an object" );
ok( inv("Foo"), "Foo is a class" );
ok( inv("Foo", "Foo"), "class is itself" );

ok( !obj("Bar"), "Bar is not an object" );
ok( inv("Bar"), "Bar is an invocant" );
ok( inv("Bar", "Bar"), "Bar is a Bar" );
ok( inv("Bar", "Foo"), "Bar is a Foo" );

ok( inv("Gorch", "Faked"), "faked isa" );
ok( obj(Gorch->new, "Faked"), "for instance too" );
ok( inv("Gorch", "Foo"), "SUPER isa" );
ok( obj(Gorch->new, "Foo"), "for instance too" );
ok( !inv("Gorch", "Blah"), "false case" );
ok( !obj(Gorch->new, "Blah"), "for instance too" );

SKIP: {
	plan skip "No DOES in this version of Perl", 6 unless UNIVERSAL->can("DOES");

	ok( inv("Zot", "FakedRole"), "faked DOES" );
	ok( obj_does(Zot->new, "FakedRole"), "for instance" );
	ok( inv("Zot", "Foo"), "DOES also answers isa" );
	ok( obj_does(Zot->new, "Foo"), "for instance" );
	ok( !inv("Zot", "OiVey"), "false case" );
	ok( !obj_does(Zot->new, "Blah"), "for instance too" );
}
