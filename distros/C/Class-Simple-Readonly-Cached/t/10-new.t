#!/usr/bin/env perl

use strict;
use warnings;
use autodie qw(:all);

use Test::Most tests => 5;

BEGIN { use_ok('Class::Simple::Readonly::Cached') }

isa_ok(
	Class::Simple::Readonly::Cached->new(cache => {}),
	'Class::Simple::Readonly::Cached',
	'new() with hash-ref cache returns correct class',
);

isa_ok(
	Class::Simple::Readonly::Cached->new(cache => {})->new(),
	'Class::Simple::Readonly::Cached',
	'clone via ->new() on an instance returns correct class',
);

# Calling ::new() (function style, not method style) should carp and return
# undef.  We intercept the expected warning to keep the test output clean.
{
	my $warned = 0;
	local $SIG{__WARN__} = sub { $warned++ };
	ok(!defined(Class::Simple::Readonly::Cached::new()),
		'::new() function call returns undef');
	is($warned, 1, '::new() function call produces exactly one warning');
}
