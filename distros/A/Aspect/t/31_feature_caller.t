#!/usr/bin/perl

# This test checks that caller continues to work as expected in code that has
# been Aspect-hooked.

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 52;
use Test::NoWarnings;
use Aspect;





######################################################################
# Check for before advice

SCOPE: {
	my @CALLER   = ();
	my $POINTS   = 0;
	my $EXPECTED = 0;

	# Set up the Aspect
	before { $POINTS++ } call 'Bar1::bar';              # Single
	before { $POINTS++ } call 'Foo1::two';              # Multiple
	before { $POINTS++ } call 'Foo1::three' & wantlist; # Nonmatched hook
	is( $POINTS,         0, '$POINTS is false' );
	is( scalar(@CALLER), 0, '@CALLER is empty' );

	# Call methods above the wrapped method
	my @EXPECTED = ( one => 1, two => 3, three => 4 );
	while ( @EXPECTED ) {
		my $method = shift @EXPECTED;
		my $points = shift @EXPECTED;
		my $result = Foo1->$method();
		is( $result, 'value', "->$method is ok" );
		is( $POINTS, $points, '$POINTS is correct' );
		is( scalar(@CALLER), 2, '@CALLER is full' );
		is( $CALLER[0]->[0], 'Foo1', 'First caller is Foo1'  );
		is( $CALLER[1]->[0], 'main', 'Second caller is main' );
	}

	# Test package
	package Foo1;

	sub one {
		Bar1->bar;
	}

	sub two {
		Bar1->bar;
	}

	sub three {
		Bar1->bar;
	}

	package Bar1;

	sub bar {
		@CALLER = (
			[ caller(0) ],
			[ caller(1) ],
		);
		return 'value';
	}
}





######################################################################
# Check for after advice

SCOPE: {
	my @CALLER   = ();
	my $POINTS   = 0;
	my $EXPECTED = 0;

	# Set up the Aspect
	after { $POINTS++ } call 'Bar2::bar';              # Single
	after { $POINTS++ } call 'Foo2::two';              # Multiple
	after { $POINTS++ } call 'Foo2::three' & wantlist; # Nonmatched hook
	is( $POINTS,         0, '$POINTS is false' );
	is( scalar(@CALLER), 0, '@CALLER is empty' );

	# Call methods above the wrapped method
	my @EXPECTED = ( one => 1, two => 3, three => 4 );
	while ( @EXPECTED ) {
		my $method = shift @EXPECTED;
		my $points = shift @EXPECTED;
		my $result = Foo2->$method();
		is( $result, 'value', "->$method is ok" );
		is( $POINTS, $points, '$POINTS is correct' );
		is( scalar(@CALLER), 2, '@CALLER is full' );
		is( $CALLER[0]->[0], 'Foo2', 'First caller is Foo2'  );
		is( $CALLER[1]->[0], 'main', 'Second caller is main' );
	}

	# Test package
	package Foo2;

	sub one {
		Bar2->bar;
	}

	sub two {
		Bar2->bar;
	}

	sub three {
		Bar2->bar;
	}

	package Bar2;

	sub bar {
		@CALLER = (
			[ caller(0) ],
			[ caller(1) ],
		);
		return 'value';
	}
}





######################################################################
# Check for around advice

SCOPE: {
	my @CALLER   = ();
	my $POINTS   = 0;
	my $EXPECTED = 0;

	# Set up the Aspect
	around { $POINTS++; $_->proceed } call 'Bar3::bar';              # Single
	around { $POINTS++; $_->proceed } call 'Foo3::two';              # Multiple
	around { $POINTS++; $_->proceed } call 'Foo3::three' & wantlist; # Nonmatched hook
	is( $POINTS,         0, '$POINTS is false' );
	is( scalar(@CALLER), 0, '@CALLER is empty' );

	# Call methods above the wrapped method
	my @EXPECTED = ( one => 1, two => 3, three => 4 );
	while ( @EXPECTED ) {
		my $method = shift @EXPECTED;
		my $points = shift @EXPECTED;
		my $result = Foo3->$method();
		is( $result, 'value', "->$method is ok" );
		is( $POINTS, $points, '$POINTS is correct' );
		is( scalar(@CALLER), 2, '@CALLER is full' );
		is( $CALLER[0]->[0], 'Foo3', 'First caller is Foo3'  );
		is( $CALLER[1]->[0], 'main', 'Second caller is main' );
	}

	# Test package
	package Foo3;

	sub one {
		Bar3->bar;
	}

	sub two {
		Bar3->bar;
	}

	sub three {
		Bar3->bar;
	}

	package Bar3;

	sub bar {
		@CALLER = (
			[ caller(0) ],
			[ caller(1) ],
		);
		return 'value';
	}
}
