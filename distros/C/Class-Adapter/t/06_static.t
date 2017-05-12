#!/usr/bin/perl

# Main testing for Class::Adapter::Builder

use strict;
BEGIN {
	$DB::single = $DB::single = 1;
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 5;

# Can we use methods statically
ok( Foo::Bar->isa('File::Spec'),        'Positive static isa ok' );
ok( ! Foo::Bar->isa('Something::Else'), 'Negative static isa ok' );
ok( Foo::Bar->can('catfile'),           'Positive static can ok' );
ok( ! Foo::Bar->can('fubared'),         'Negative static can ok' );

# Can we isa to a notional class
ok( Foo::Baz->isa('Bar'), 'Positive static isa ok' );





#####################################################################
# Testing Package

# This implements a Bubble for a specific class
SCOPE: {
	package Foo::Bar;

	use Class::Adapter::Builder
		NEW      => 'File::Spec',
		ISA      => 'File::Spec',
		AUTOLOAD => 1;

	package Bar;

	sub new { bless {}, $_[0] }

	package Foo::Baz;

	use Class::Adapter::Builder
		NEW      => 'Bar',
		ISA      => 'Bar',
		AUTOLOAD => 1;
}
