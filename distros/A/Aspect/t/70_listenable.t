#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 24;
use Test::NoWarnings;
use Test::Exception;
use Aspect;
use Aspect::Library::Listenable;

# Set up the Listenable relationship types
aspect Listenable => (
	Erase => call "Foo::set_erased",
);
aspect Listenable => (
	Color => call "Foo::set_color",
	color => 'get_color',
);

# Create a temporary lexical aspect to make sure we create lexical advice
SCOPE: {
	my $lexical = aspect Listenable => (
		Foo => call 'Baz::one',
	);
	isa_ok( $lexical, 'Aspect::Library::Listenable' );
}





######################################################################
# Main Tests

SCOPE: {
	my $has_been_called = 0;
	my $point = Foo->new;
	add_listener( $point, Erase => my $listener = sub { $has_been_called = 1 } );
	$point->set_erased;
	ok( $point->get_erased, 'has been erased' );
	ok( $has_been_called, 'has been called' );
	remove_listener( $point, Erase => $listener );
}

SCOPE: {
	my $has_been_called1 = 0;
	my $has_been_called2 = 0;
	my $point = Foo->new;
	add_listener( $point, Erase => my $listener1 = sub { $has_been_called1 = 1 } );
	add_listener( $point, Erase => my $listener2 = sub { $has_been_called2 = 1 } );
	$point->set_erased;
	ok( $has_been_called1, 'listener 1' );
	ok( $has_been_called2, 'listener 2' );
	remove_listener( $point, Erase => $listener1 );
	remove_listener( $point, Erase => $listener2 );
}

SCOPE: {
	my $has_been_called1 = 0;
	my $has_been_called2 = 0;
	my $point1 = Foo->new;
	my $point2 = Foo->new;
	add_listener( $point1, Erase => my $listener1 = sub { $has_been_called1 = 1 } );
	add_listener( $point2, Erase => my $listener2 = sub { $has_been_called2 = 1 } );
	$point2->set_erased;
	ok( !$point1->get_erased, 'point 1'  );
	ok( $point2->get_erased, 'point 2'   );
	ok( !$has_been_called1, 'listener 1' );
	ok( $has_been_called2, 'listener 2'  );
	remove_listener( $point1, Erase => $listener1 );
	remove_listener( $point2, Erase => $listener2 );
}

SCOPE: {
	my $has_been_called1 = 0;
	my $has_been_called2 = 0;
	my $point = Foo->new;
	add_listener( $point, Erase => my $listener1 = sub { $has_been_called1 = 1 } );
	add_listener( $point, Erase => my $listener2 = sub { $has_been_called2 = 1 } );
	remove_listener( $point, Erase => $listener1 );
	$point->set_erased;
	ok( !$has_been_called1, 'listener 1' );
	ok( $has_been_called2, 'listener 2'  );
	remove_listener( $point, Erase => $listener2 );
}

SCOPE: {
	my $event = 0;
	my $point = Foo->new;
	add_listener( $point, Color => my $listener = sub { $event = shift } );
	$point->set_color('red');
	is( $point->get_color, 'red', 'point color' );
	ok( $event, 'event fired' );
	is( ref $event, 'Aspect::Library::Listenable::Event', 'event class' );
	is( $event->name, 'Color', 'name' );
	is( $event->source, $point, 'source' );
	is( $event->color, 'red', 'color' );
	is( $event->old_color, 'blue', 'old_color' );
	is_deeply( $event->params, [ 'red' ], 'args' );
	remove_listener( $point, Color => $listener );
}

SCOPE: {
	my $hasnt_been_called = 1;
	my $point = Foo->new;
	add_listener( $point, Color => my $listener = sub { $hasnt_been_called = 0 } );
	$point->set_color('blue');
	ok( $hasnt_been_called );
	remove_listener( $point, Color => $listener );
}

SCOPE: {
	my $listenable = bless [], 'SomePackage';
	throws_ok(
		sub { add_listener( $listenable, Event => sub {} ) },
		qr/not a hash based object/,
	);
}

SCOPE: {
	my $point = Foo->new;
	add_listener( $point, Erase => [do_call =>
		my $listener = Bar->new,
		[qw(source)],
	] );
	ok( !$listener->has_been_called, 'before erased' );
	$point->set_erased;
	is( $listener->has_been_called, $point, 'after erased' );
	remove_listener( $point, Erase => $listener );
}





######################################################################
# Support Classes

package Foo;

sub new {
	bless {
		color  => 'blue',
		erased => 0,
	}, shift;
}

sub get_erased {
	shift->{erased}
}

sub set_erased {
	shift->{erased} = 1;
}

sub get_color {
	shift->{color};
}

sub set_color {
	shift->{color} = pop;
}

package Bar;

sub new {
	bless {
		has_been_called => 0,
	}, shift;
}

sub do_call {
	shift->{has_been_called} = pop;
}

sub has_been_called {
	shift->{has_been_called};
}

package Baz;

sub one {
	return 'one';
}
