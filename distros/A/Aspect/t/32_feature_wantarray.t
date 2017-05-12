#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use Test::NoWarnings;
use Aspect;

my @CONTEXT  = ();

SCOPE: {
	package Foo;

	sub before {
		if ( wantarray ) {
			push @CONTEXT, 'array';
		} elsif ( defined wantarray ) {
			push @CONTEXT, 'scalar';
		} else {
			push @CONTEXT, 'void';
		}
	}

	sub after {
		if ( wantarray ) {
			push @CONTEXT, 'array';
		} elsif ( defined wantarray ) {
			push @CONTEXT, 'scalar';
		} else {
			push @CONTEXT, 'void';
		}
	}
}

# Before the aspects
SCOPE: {
	() = Foo->before;
	my $dummy = Foo->before;
	Foo->before;
}
SCOPE: {
	() = Foo->after;
	my $dummy = Foo->after;
	Foo->after;
}

# Enable the aspects
my $before = before {
	if ( $_[0]->wantarray ) {
		push @CONTEXT, 'ARRAY';
	} elsif ( defined $_[0]->wantarray ) {
		push @CONTEXT, 'SCALAR';
	} else {
		push @CONTEXT, 'VOID';
	}
	if ( wantarray ) {
		push @CONTEXT, 'ARRAY';
	} elsif ( defined wantarray ) {
		push @CONTEXT, 'SCALAR';
	} else {
		push @CONTEXT, 'VOID';
	}
} call 'Foo::before';

my $after = after {
	if ( $_[0]->wantarray ) {
		push @CONTEXT, 'ARRAY';
	} elsif ( defined $_[0]->wantarray ) {
		push @CONTEXT, 'SCALAR';
	} else {
		push @CONTEXT, 'VOID';
	}
	if ( wantarray ) {
		push @CONTEXT, 'ARRAY';
	} elsif ( defined wantarray ) {
		push @CONTEXT, 'SCALAR';
	} else {
		push @CONTEXT, 'VOID';
	}
} call 'Foo::after';

# During the aspects
SCOPE: {
	() = Foo->before;
	my $dummy = Foo->before;
	Foo->before;
}
SCOPE: {
	() = Foo->after;
	my $dummy = Foo->after;
	Foo->after;
}

# Disable the aspects
undef $before;
undef $after;

# After the aspects
SCOPE: {
	() = Foo->before;
	my $dummy = Foo->before;
	Foo->before;
}
SCOPE: {
	() = Foo->after;
	my $dummy = Foo->after;
	Foo->after;
}

# Check the results in aggregate
is_deeply(
	\@CONTEXT,
	[ qw{
		array
		scalar
		void
		array
		scalar
		void
		ARRAY VOID array
		SCALAR VOID scalar
		VOID VOID void
		array ARRAY VOID
		scalar SCALAR VOID
		void VOID VOID
		array
		scalar
		void
		array
		scalar
		void
	} ],
	'All wantarray contexts worked as expected for before',
);
