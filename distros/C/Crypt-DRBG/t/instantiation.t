#!perl

use strict;
use warnings;

use FindBin;

use lib "$FindBin::Bin/../lib";

use Crypt::DRBG::Hash;
use Crypt::DRBG::HMAC;
use Test::More;

# The spec for HMAC and Hash requires that the seed, nonce, and personalization
# string just be concatenated.  This makes it convenient to test the interface
# parameters.
test_instantiation({seed => 'abc', nonce => 'def'}, 'seed/nonce');
test_instantiation({
		seed => sub { 'abc' },
		nonce => sub { 'def' },
	},
	'seed/nonce as coderefs'
);
test_instantiation({
		seed => sub { 'ab' },
		nonce => sub { 'cd' },
		personalize => sub { 'ef' },
	},
	'seed/nonce/personalize as coderefs'
);
test_instantiation({seed => 'abcdef'}, 'seed');
test_instantiation({seed => sub { 'abcdef' }}, 'seed as coderef');

done_testing();

sub test_instantiation {
	my ($params, $desc) = @_;
	test_hmac_instantiation($params, $desc);
	test_hash_instantiation($params, $desc);
	return;
}

sub test_hash_instantiation {
	my ($params, $desc) = @_;
	my $expected = 'c7dfc3a61d94f45d0570';
	my $obj = Crypt::DRBG::Hash->new(%$params);
	my $hex = unpack 'H*', $obj->generate(10);
	is($hex, $expected, "Generates expected value for $desc");
	return;
}

sub test_hmac_instantiation {
	my ($params, $desc) = @_;
	my $expected = '10a912824b76baaec94b';
	my $obj = Crypt::DRBG::HMAC->new(%$params);
	my $hex = unpack 'H*', $obj->generate(10);
	is($hex, $expected, "Generates expected value for $desc");
	return;
}
