#!/usr/bin/perl

# Tests for the regular expression usage

use strict;
use File::Spec::Functions ':ALL';
use lib catdir('t', 'lib');
BEGIN {
	$|  = 1;
	$^W = 1;
        $Class::Autouse::DEBUG = $Class::Autouse::DEBUG = 1;
}

use Test::More tests => 3;

use_ok( 'Class::Autouse', qr/::B$/ );

# We should be able to load A::B
is( A::B->foo, 'bar', 'Loaded A::B' );

# We shouldn't be able to load C
eval {
	C->method;
};
like(
	$@,
	qr/Can't locate object method/,
	"Got expected error from unloadable class C",
);
