#!/usr/bin/perl

# Validates that the type of closures used in Aspect.pm work properly on every
# Perl version we care about.

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}
use Test::More tests => 43;
use Test::NoWarnings;

# Create the variable we plan to share
my $foo = 0;

# The initial declaration
sub foo () {
	++$foo;
}
is( foo(), 1, 'foo() ok' );
is( $foo,  1, '$foo ok'  );
is( foo(), 2, 'foo() ok' );
is( $foo,  2, '$foo ok'  );

# Since the bug reports seem to refer to needing nested named subs,
# we run the entire test inside a subroutine.
my $run = 0;
sub parent {
	# Test the creation of an anonymous sub with a prototype
	my $anon1 = sub () {
		$foo += 2;
	};
	is( $anon1->(), 28 * $run + 4, 'foo() ok' );
	is( $foo, 28 * $run + 4, '$foo ok'  );
	is( $anon1->(), 28 * $run + 6, 'foo() ok' );
	is( $foo, 28 * $run + 6, '$foo ok'  );

	# Replace the function
	eval <<'END_PERL';
no warnings 'redefine';
sub foo () {
	$foo += 3;
}
END_PERL
	is( $@, '', 'Built new function without error' );
	is( foo(), 28 * $run + 9, 'foo() ok' );
	is( $foo, 28 * $run + 9, '$foo ok'  );
	is( foo(), 28 * $run + 12, 'foo() ok' );
	is( $foo, 28 * $run + 12, '$foo ok'  );

	# Test a string-compiled anonymous sub
	my $anon2 = eval <<'END_PERL';
no warnings 'redefine';
sub () {
	$foo += 4;
};
END_PERL
	is( $@, '', 'Built new function without error' );
	is( $anon2->(), 28 * $run + 16, 'foo() ok' );
	is( $foo, 28 * $run + 16, '$foo ok'  );
	is( $anon2->(), 28 * $run + 20, 'foo() ok' );
	is( $foo, 28 * $run + 20, '$foo ok'  );

	# Replace with a string-compiled false-named anonymous sub
	# Test a string-compiled anonymous sub with no prototype
	eval <<'END_PERL';
no warnings 'redefine';
*foo = sub () {
	$foo += 5;
};
END_PERL
	is( $@, '', 'Built new function without error' );
	is( foo(), 28 * $run + 25, 'foo() ok' );
	is( $foo,  28 * $run + 25, '$foo ok'  );
	is( foo(), 28 * $run + 30, 'foo() ok' );
	is( $foo,  28 * $run + 30, '$foo ok'  );

	$run++;
}

# Run this twice so we're sure we trigger the bug
# that we're trying to avoid.
parent();
parent();
