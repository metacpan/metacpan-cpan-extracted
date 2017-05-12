#!/usr/bin/perl

# Test that zone timing capture is still correct when an exception
# fires inside a zone timer.

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 5;
use Time::HiRes ();
use Aspect;

# Set up the aspect
my @TIMING = ();

my $foo = call 'Foo::foo' | call 'Foo::baz';
my $bar = call 'Foo::bar';

aspect ZoneTimer => (
	zones => {
		foo => $foo,
		bar => $bar,
	},
	handler => sub {
		push @TIMING, [ @_ ];
	},
);

eval {
	Foo::foo();
};
like( $@, qr/Deep zone exception/, 'Fired an exception' );
is( scalar(@TIMING), 1, 'Timing hook fired despite exception' );
is( $TIMING[0]->[0], 'foo', 'Second call starts in zone foo' );
is( ref($TIMING[0]->[3]), 'HASH',  'Fourth param is a HASH' );
is( keys(%{$TIMING[0]->[3]}), 2, 'Third entry has two keys' );

package Foo;

sub foo {
	bar();
}

sub bar {
	baz();
}

sub baz {
	Time::HiRes::sleep(0.2);
	die "Deep zone exception";
}
