#!/usr/bin/perl

# Test the recursive feature

use strict;
use File::Spec ();
BEGIN {
	$|  = 1;
	$^W = 1;
	require lib;
	lib->import(
		File::Spec->catdir(
			File::Spec->curdir, 't', 'modules',
		)
	);
}

use Test::More tests => 5;
use Class::Autouse ();





# Load the T test module recursively
ok( Class::Autouse->autouse_recursive('T'), '->autouse_recursive returns true' );
ok( T->method, 'T is loaded' );
ok( T::A->method, 'T::A is loaded' );
ok( T::B->method, 'T::B is loaded' );
ok( T::B::G->method, 'T::B::G is loaded' );
