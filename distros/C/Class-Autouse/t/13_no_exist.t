#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

# after using Class::Autouse, make sure non-existent class/method
# calls fail

use Test::More tests => 2;
use Class::Autouse;

eval { Foo->bar; };
like( $@, qr/locate object method \"bar\" via package \"Foo\"/ );

eval qq{ package Foo; };

eval { Foo->bar; };
like( $@, qr/locate object method \"bar\" via package \"Foo\"/ );

