#!perl

use strict;
use warnings;

use FindBin;

use lib "$FindBin::Bin/../lib";

use Crypt::DRBG::HMAC;
use Time::HiRes;

use Test::More;

my %base_params = (
	seed => "\x00" x 111,
	nonce => "\x01" x 111,
	personalize => '',
);
my @tests = (
	{
		count => 1024,
		desc => 'randbytes 1024 alphanumeric',
		seq => ['A'..'Z', 'a'..'z', 0..9],
	},
	{
		count => 1024,
		desc => 'randbytes 1024 base64',
		seq => ['A'..'Z', 'a'..'z', 0..9, '+', '/'],
	},
	{
		count => 65536,
		desc => 'randbytes 65536 alphanumeric',
		seq => ['A'..'Z', 'a'..'z', 0..9],
	},
	{
		count => 65536,
		desc => 'randbytes 65536 base64',
		seq => ['A'..'Z', 'a'..'z', 0..9, '+', '/'],
	},
);
my %objs;
my @functions = (
	{
		func => sub { return hmac_drbg(@_, %base_params) },
		name => 'uncached HMAC',
	},
	{
		func => sub {
			return hmac_drbg(@_, %base_params, cache => 1024)
		},
		name => 'cached HMAC',
	},
	{
		func => sub {
			return hmac_drbg(@_, %base_params, cache => 65536)
		},
		name => 'cached HMAC (large)',
	},
);

foreach my $test (@tests) {
	subtest $test->{desc} => sub {
		foreach my $routine (@functions) {
			my $func = $routine->{func};
			my $risecs = do_timed($test->{count}, $routine->{name}, $func, 'randitems', $test->{seq});
			my $rbsecs = do_timed($test->{count}, $routine->{name}, $func, 'randbytes', $test->{seq});
			cmp_ok($risecs, '<', 60,
				"randitems completed in less than 60 seconds");
			cmp_ok($rbsecs, '<', 60,
				"randbytes completed in less than 60 seconds");
			diag "randitems took $risecs seconds";
			diag "randbytes took $rbsecs seconds";
		}
	};
}

done_testing();

sub hmac_drbg {
	my ($bytes, $func, $cache_id, $seq, %params) = @_;

	my $drbg = $objs{$cache_id} ||= Crypt::DRBG::HMAC->new(%params);
	return $drbg->$func($bytes, $seq);
}

sub do_timed {
	my ($count, $name, $drbg, $func, $seq) = @_;
	my $t0 = [Time::HiRes::gettimeofday];
	my $bytes = '';
	my $iters = 100;
	foreach (1..$iters) {
		$bytes .= join('', $drbg->($count, $func, $name, $seq));
	}
	my $t1 = [Time::HiRes::gettimeofday];
	my $secs = Time::HiRes::tv_interval($t0, $t1);
	is(length($bytes), $count * $iters, 'Got the correct number of bytes');
	return $secs;
}
