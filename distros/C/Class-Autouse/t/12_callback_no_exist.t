#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

# try 2 basic loaders
# after using Class::Autouse, make sure non-existent class/method
# calls fail

use Test::More;

plan tests => 8;

my %already_loaded;

sub foo_loader {
	my $class = shift;
	return if $already_loaded{$class};
	return unless ( $class =~ /^Foo/ );
	eval qq(
		package $class;

		sub foo {
			return "foo in package $class";
		}
	);
	die $@ if $@;
	$already_loaded{$class} = 1;
	return 1;
}

sub bar_loader {
	my $class = shift;
	return if $already_loaded{$class};
	return unless ( $class =~ /^Bar/ );
	eval qq(
		package $class;

		sub bar {
			return "bar in package $class";
		}
		
	);
	die $@ if $@;
	$already_loaded{$class} = 1;
	return 1;
}

use Class::Autouse \&foo_loader;
use Class::Autouse \&bar_loader;

is( Foo->foo,      "foo in package Foo" );
is( Foo->foo,      "foo in package Foo" );
is( Bar->bar,      "bar in package Bar" );
is( Foo::Bar->foo, "foo in package Foo::Bar" );
is( Bar::Foo->bar, "bar in package Bar::Foo" );

eval { Baz->baz; };
like( $@, qr/locate object method \"baz\" via package \"Baz\"/ );

eval { Foo->bar };
like( $@, qr/locate object method \"bar\" via package \"Foo\"/ );

eval { Foo::Baz->bar };
like( $@, qr/locate object method \"bar\" via package \"Foo::Baz\"/ );


