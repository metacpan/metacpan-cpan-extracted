#!/usr/bin/perl

# Unfortunately, since the original class from Aspect.pm only had a
# compilation test, and I'm not a Test::Class user, this new distribution
# only has a compilation test as well.

# Feel free to request a commit bit to write some more tests.

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}
use Test::More tests => 1;

use_ok( 'Aspect::Library::TestClass' );
