#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Digest::MultiHash;

BEGIN {
	plan skip_all => "No hash modules found"
		unless eval { Digest::MultiHash->new }
			and $@ !~ /^Can't find any digest module/;

	plan tests => 5;
}

my $d = Digest::MultiHash->new;

isa_ok( $d , "Digest::base" );

$d->width( 8 );

$d->add("foo bar gorch");

my $d2 = Digest::MultiHash->new( width => 8 );

$d2->add("foo bar moose");

my $hash2 = $d2->digest;

cmp_ok( $d->digest, "ne", $hash2, "digests differ" );

is( length($hash2), 8, "the hash width is 8" );

throws_ok {
	my $d = Digest::MultiHash->new(
		width => 1024, # only 20 bytes in sha1
	);

	$d->add("foo");

	$d->digest;
} qr/insufficient.*width/, "Insufficient width causes error";

throws_ok {
	Digest::MultiHash->new( hashes => [] );
} qr/No digest module specified/, "Can't construct without hashes";

