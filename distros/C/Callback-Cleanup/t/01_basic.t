#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use Callback::Cleanup;

can_ok("Callback::Cleanup", "new");

{
	my ( $callback, $cleanup ) = ( 0, 0 );
	my $c = Callback::Cleanup->new( sub { $callback++ }, sub { $cleanup++ } );

	is( $callback, 0, "callback not triggered" );
	is( $cleanup, 0, "cleanup not triggered" );

	$c->();

	is( $callback, 1, "callback triggered" );
	is( $cleanup, 0, "cleanup not triggered" );

	$c->();

	is( $callback, 2, "callback triggered" );
	is( $cleanup, 0, "cleanup not triggered" );

	undef $c;

	is( $callback, 2, "callback not triggered" );
	is( $cleanup, 1, "cleanup triggered" );
}

{
	my ( $callback, $cleanup ) = ( 0, 0 );
	my $c = callback {
		$callback++;
	} cleanup {
		$cleanup++;
	};

	is( $callback, 0, "callback not triggered" );
	is( $cleanup, 0, "cleanup not triggered" );

	$c->();

	is( $callback, 1, "callback triggered" );
	is( $cleanup, 0, "cleanup not triggered" );

	$c->();

	is( $callback, 2, "callback triggered" );
	is( $cleanup, 0, "cleanup not triggered" );

	undef $c;

	is( $callback, 2, "callback not triggered" );
	is( $cleanup, 1, "cleanup triggered" );
}

{
	my ( $callback, $cleanup ) = ( 0, 0 );
	my $c = cleanup {
		$cleanup++;
	} sub {
		$callback++;
	};

	is( $callback, 0, "callback not triggered" );
	is( $cleanup, 0, "cleanup not triggered" );

	$c->();

	is( $callback, 1, "callback triggered" );
	is( $cleanup, 0, "cleanup not triggered" );

	$c->();

	is( $callback, 2, "callback triggered" );
	is( $cleanup, 0, "cleanup not triggered" );

	undef $c;

	is( $callback, 2, "callback not triggered" );
	is( $cleanup, 1, "cleanup triggered" );
}

{
	our ( $callback, $cleanup ) = ( 0, 0 );
	my $c = cleanup {
		$cleanup++
	} sub {
		$callback++;
	};

	is( $callback, 0, "callback not triggered" );
	is( $cleanup, 0, "cleanup not triggered" );

	$c->();

	is( $callback, 1, "callback triggered" );
	is( $cleanup, 0, "cleanup not triggered" );

	$c->();

	is( $callback, 2, "callback triggered" );
	is( $cleanup, 0, "cleanup not triggered" );

	undef $c;

	is( $callback, 2, "callback not triggered" );
	is( $cleanup, 1, "cleanup triggered" );
}
