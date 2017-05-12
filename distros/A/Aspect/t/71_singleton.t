#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;
use Test::NoWarnings;
use Aspect;

# Convert Foo into a singleton class
aspect Singleton => 'Foo::new';

my $foo1 = Foo->new;
my $foo2 = Foo->new;
is( "$foo1", "$foo2", 'there can only be one' );

# Create a lexical singleton to ensure it handles global vs lexical properly
SCOPE: {
	my $aspect = aspect Singleton => 'Bar::new';
	isa_ok( $aspect, 'Aspect::Library::Singleton' );
}





######################################################################
# Test Class

package Foo;

sub new {
	bless {}, shift;
};

package Bar;

sub new {
	bless {}, shift;
}
