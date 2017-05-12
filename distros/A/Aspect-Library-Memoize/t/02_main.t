#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 16;
use Aspect;

# Convert Foo into a Memoized class that emulates a kind of Singleton
aspect Memoize => call 'Foo::new';

SCOPE: {
	# No param case should return the same object twice
	my $foo1 = Foo->new;
	my $foo2 = Foo->new;
	is( "$foo1", "$foo2", 'null: There can only be one' );

	# Since param case should also return the same object twice
	my $foo3 = Foo->new('foo');
	my $foo4 = Foo->new('foo');
	is( "$foo3", "$foo4", 'foo: There can only be one' );

	# But they shouldn't be the same as the null ones
	ok( "$foo1" ne "$foo3", 'null and foo do not match' );
}

# Repeat as a lexical to ensure it handles global vs lexical properly
my ($bar1, $bar2);
SCOPE: {
	my $aspect = aspect Memoize => call 'Bar::new';
	isa_ok( $aspect, 'Aspect::Library::Memoize' );

	# No param case should return the same object twice
	$bar1 = Bar->new;
	$bar2 = Bar->new;
	isa_ok( $bar1, 'Bar' );
	isa_ok( $bar2, 'Bar' );
	is( "$bar1", "$bar2", 'null: There can only be one' );

	# Since param case should also return the same object twice
	my $bar3 = Bar->new('foo'); isa_ok( $bar1, 'Bar' );
	my $bar4 = Bar->new('foo');
	isa_ok( $bar3, 'Bar' );
	isa_ok( $bar4, 'Bar' );
	is( "$bar3", "$bar4", 'foo: There can only be one' );

	# But they shouldn't be the same as the null ones
	ok( "$bar1" ne "$bar3", 'null and foo do not match' );
}

# Now we have left the lexical scope, does it work normally again
my $bar5 = Bar->new;
my $bar6 = Bar->new;
isa_ok( $bar5, 'Bar' );
isa_ok( $bar6, 'Bar' );
ok( "$bar5" ne "$bar6", 'bar: There can now be more than one again' );
ok( "$bar1" ne "$bar5", 'Method stops memoizing on scope exit' );





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
