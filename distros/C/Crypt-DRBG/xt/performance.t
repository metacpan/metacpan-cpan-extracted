#!perl

use strict;
use warnings;

use FindBin;

use lib "$FindBin::Bin/../lib";

use Crypt::DRBG::HMAC;
use Crypt::DRBG::Hash;
use IO::File;
use Time::HiRes;

use Test::More;

my %base_params = (
	seed => "\x00" x 111,
	nonce => "\x01" x 111,
	personalize => '',
);
my @tests = (
	{
		desc => '1024 bytes (1 chunk)',
		repeat => 1,
		count => 1024,
		timeout => 3,
	},
	{
		desc => '1024 bytes (16 chunks)',
		repeat => 16,
		count => 64,
		timeout => 3,
	},
	{
		desc => '1 MiB (16 chunks)',
		repeat => 16,
		count => 65536,
		timeout => 240,
	},
);
my $has_blake2 = eval { require Digest::HMAC; require Digest::BLAKE2; 1 };
my %objs;
my @functions = (
	{
		func => \&urandom,
		name => 'urandom',
	},
	{
		func => sub { return hash_drbg(@_, %base_params) },
		name => 'uncached Hash',
	},
	{
		func => sub { return hmac_drbg(@_, %base_params) },
		name => 'uncached HMAC',
	},
	{
		func => sub { return hmac_drbg(@_, auto => 1) },
		name => 'uncached HMAC (auto)',
	},
	{
		func => sub {
			return hmac_drbg(@_, %base_params, cache => 1024)
		},
		name => 'cached HMAC',
	},
	{
		func => sub {
			return hmac_drbg(@_, auto => 1, cache => 1024)
		},
		name => 'cached HMAC (auto)',
	},
	{
		func => sub {
			return hmac_drbg(@_, %base_params, cache => 65536)
		},
		name => 'cached HMAC (large)',
	},
	($has_blake2 ? (
		{
			func => sub {
				return hmac_drbg(@_, %base_params, cache => 65536,
					func => sub {
						return Digest::HMAC::hmac(@_, \&Digest::BLAKE2::blake2b);
					},
				)
			},
			name => 'cached HMAC (large BLAKE2b)',
		},
		{
			func => sub {
				return hmac_drbg(@_, %base_params,
					func => sub {
						return Digest::HMAC::hmac(@_, \&Digest::BLAKE2::blake2b);
					},
				)
			},
			name => 'uncached HMAC (BLAKE2b)',
		},
	) : ()),
);

foreach my $test (@tests) {
	subtest $test->{desc} => sub {
		plan tests => 2 * scalar @functions;
		foreach my $routine (@functions) {
			my $timeout = $test->{timeout};
			my $func = $routine->{func};
			my $t0 = [Time::HiRes::gettimeofday];
			my $bytes = '';
			my $iters = 100;
			foreach (1..$iters) {
				foreach (1..$test->{repeat}) {
					$bytes .= $func->($test->{count}, $routine->{name});
				}
			}
			my $t1 = [Time::HiRes::gettimeofday];
			my $secs = Time::HiRes::tv_interval($t0, $t1);
			is(length($bytes), $test->{count} * $test->{repeat} * $iters, 'Got the correct number of bytes');
			cmp_ok($secs, '<', $timeout,
				"$routine->{name} completed in less than $timeout seconds");
			diag "$routine->{name} took $secs seconds";
		}
	};
}

done_testing();

sub urandom {
	my ($bytes) = @_;
	my $fh = IO::File->new('/dev/urandom', 'r');

	$fh->read(my $buf, $bytes);
	return $buf;
}

sub hmac_drbg {
	my ($bytes, $cache_id, %params) = @_;

	my $drbg = $objs{$cache_id} ||= Crypt::DRBG::HMAC->new(%params);
	return $drbg->generate($bytes);
}

sub hash_drbg {
	my ($bytes, $cache_id, %params) = @_;

	my $drbg = $objs{$cache_id} ||= Crypt::DRBG::Hash->new(%params);
	return $drbg->generate($bytes);
}
