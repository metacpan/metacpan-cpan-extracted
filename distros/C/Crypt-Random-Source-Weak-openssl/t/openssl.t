#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use File::Which;

BEGIN {
	plan skip_all => "no openssl command found" unless File::Which::which("openssl");
	plan 'no_plan';
}

use ok 'Crypt::Random::Source::Weak::openssl';

{
	my $p = Crypt::Random::Source::Weak::openssl->new;

	isa_ok( $p, "Crypt::Random::Source::Weak" );
	isa_ok( $p, "Crypt::Random::Source::Base::Proc" );
	isa_ok( $p, "Crypt::Random::Source::Weak::openssl" );

	cmp_ok( $p->default_chunk_size, '>=', 1, "got some chunk size" );

	is_deeply( $p->command, [ $p->openssl, qw(rand), $p->default_chunk_size ], "command" );

	$p->openssl("foo");

	is_deeply( $p->command, [ qw(foo rand), $p->default_chunk_size ], "command updated with trigger" );

	$p->openssl("openssl");

	ok( !$p->has_handle, "no handle yet" );

	my $buf = $p->get(100);

	is( length($buf), 100, "got requested bytes" );

	# this test should fail around every few universes or so ;-)
	cmp_ok( $buf, 'ne', $p->get(length($buf)), "random data differs" );

	ok( $p->has_handle, "handle now open" );

	ok( $p->close, "close" );

	$p->default_chunk_size(3);

	$buf = $p->get(10);

	is( length($buf), 10, "got 10 byteswith really small chunk size" );
}

