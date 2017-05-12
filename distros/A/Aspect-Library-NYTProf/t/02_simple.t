#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;
use Aspect;

aspect NYTProf => call 'Foo::bar';

is( $Aspect::Library::NYTProf::DEPTH, 0, 'NYTProf depth initially 0' );
Foo::bar();
is( $Aspect::Library::NYTProf::DEPTH, 0, 'NYTProf depth finally 0' );

package Foo;

sub bar {
	Test::More::is( $Aspect::Library::NYTProf::DEPTH, 1, 'DEPTH increments inside match' );
}

1;
