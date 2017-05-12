#!/usr/bin/perl

# Validates some assumptions built into the Aspect code about how context
# and return work.

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}
use Test::More tests => 28;
use Test::NoWarnings;

my $array  = 0;
my $scalar = 0;
my $void   = 0;

sub test {
	is( $array,  $_[0], "\$array = $_[0]"  );
	is( $scalar, $_[1], "\$scalar = $_[1]" );
	is( $void,   $_[2], "\$void = $_[2]"   );
}

# Direct usage
test( 1, 0, 0, context() );
test( 1, 1, 0, scalar(context()) );
context();
test( 1, 1, 1 );

# Plain single indirection
test( 2, 1, 1, one() );
test( 2, 2, 1, scalar(one()) );
one();
test( 2, 2, 2 );

# Plain explicit indirection
test( 3, 2, 2, two() );
test( 3, 3, 2, scalar(two()) );
two();
test( 3, 3, 3 );





######################################################################
# Test Functions

sub one {
	context();
}

sub two {
	return context();
}

sub context {
	if ( wantarray ) {
		$array++;
		return 'foo';
	} elsif ( defined wantarray ) {
		$scalar++;
		return 'bar';
	} else {
		$void++;
		return 'baz';
	}
}

1;
