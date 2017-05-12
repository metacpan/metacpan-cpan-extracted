#!/usr/bin/perl

# The foo functions should appear, the bar functions should not

use strict;
BEGIN {
	package Foo;

	sub foo1 {
		foo2();
	}

	sub foo2 {
		bar1();
	}

	sub bar1 {
		foo3();
	}

	sub foo3 {
		return 1;
	}

	1;
}

use Aspect::Library::Trace qr/^Foo::foo/;

Foo::foo1();
Foo::foo2();
Foo::foo2();
