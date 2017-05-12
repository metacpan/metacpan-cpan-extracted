#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 9;
use Time::HiRes ();
use Aspect;

my $RECURSION = 0;

# Set up the aspect
my @TIMING   = ();
my $pointcut = call qr/^Foo::/;
my $handler  = sub {
	if ( $RECURSION++ ) {
		die "Recursion in timer handler";
	}
	Foo::bar();
	push @TIMING, [ @_ ];
	$RECURSION--;
};
aspect Timer => $pointcut, $handler;

Foo::bar();
eval {
	Foo::foo();
};
like( $@, qr/Exception in foo/, 'Got expected exception' );

is( scalar(@TIMING), 3, 'Three timing hooks fired'    );
is( $TIMING[0]->[0], 'Foo::bar', 'First call is bar'  );
is( $TIMING[1]->[0], 'Foo::bar', 'Second call is bar' );
is( $TIMING[2]->[0], 'Foo::foo', 'Third call is foo'  );
is( ref($TIMING[0]->[1]), 'ARRAY', 'Second param is an ARRAY' );
is( ref($TIMING[0]->[2]), 'ARRAY', 'Second param is an ARRAY' );
like( $TIMING[0]->[3], qr/^1\.?/, 'Fourth param is a time' );
is( scalar(@{$TIMING[0]}), 4, 'Only 4 params are provided' );

package Foo;

sub foo {
	bar();
	die "Exception in foo";
}

sub bar {
	Time::HiRes::sleep(1.1);
}

1;
