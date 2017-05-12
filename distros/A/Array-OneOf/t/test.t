#!/usr/bin/perl -w
use strict;
use Array::OneOf ':all';
use Test;
BEGIN { plan tests => 4 };

# find a string in an array of strings
if ( oneof 'a', 'a', 'b', 'c', undef )
	{ ok(1) }
else
	{ ok(0) }

# fail to find a string in an array of strings
if ( oneof 'x', 'a', 'b', 'c', undef )
	{ ok(0) }
else
	{ ok(1) }

# find undef
if ( oneof undef, 'a', undef, 'c' )
	{ ok(1) }
else
	{ ok(0) }

# fail to find undef
if ( oneof undef, 'a', 'b', 'c' )
	{ ok(0) }
else
	{ ok(1) }
