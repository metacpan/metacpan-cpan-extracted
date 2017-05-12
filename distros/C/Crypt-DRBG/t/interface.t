#!perl

use strict;
use warnings;

use FindBin;

use lib "$FindBin::Bin/../lib";

use Crypt::DRBG::Hash;
use Crypt::DRBG::HMAC;
use IO::Handle;
use Test::More;

my @classes = map { "Crypt::DRBG::$_" } qw/HMAC Hash/;

foreach my $class (@classes) {
	subtest "Class $class" => sub {
		subtest 'Instantiating objects' => sub {
			my $obj = $class->new(auto => 1);
			isa_ok($obj, $class, 'auto => 1 object');
			isa_ok($obj, 'Crypt::DRBG', 'auto => 1 object');

			$obj = $class->new(seed => 'my very secret seed');
			isa_ok($obj, $class, 'manual seed object');
			isa_ok($obj, 'Crypt::DRBG', 'manual seed object');

			$obj = $class->new(
				seed => 'my very secret seed',
				autopersonalize => 1
			);
			isa_ok($obj, $class, 'manual seed object with autopersonalize');

			$obj = eval { $class->new };
			is($obj, undef, 'failed to instantiate without a seed');
			like($@, qr/no seed/i, 'failed to instantiate without a seed');
		};
	};
}

subtest 'randitems' => sub {
	my @tests = (
		{
			count => 100,
			range => [0..9],
			desc => 'digits',
			expected => '3778239228',
		},
		{
			count => 300,
			range => ['A'..'Z', 'a'..'z', '_'],
			desc =>'valid identifiers',
			expected => 'rmS_WNe_Wo',
		},
		{
			count => 500,
			range => ['0'..'9', 'A'..'Z', 'a'..'z', '+', '/'],
			desc =>'base64',
			expected => 'h5nUMDzqU0',
		},
	);
	if ($ENV{RELEASE_TESTING}) {
		push @tests, {
			count => 1_000_000,
			range => [map { sprintf '%02x', $_ } 0..65535],
			desc =>'two-byte hex values'
		};
		push @tests, {
			count => 2_000_000,
			range => [map { sprintf '%05d', $_ } 0..99999],
			desc =>'five-digit values'
		};
	}
	foreach my $test (@tests) {
		subtest "generate $test->{desc}" => sub {
			my $obj = new_obj();
			my @entries = $obj->randitems($test->{count}, $test->{range});
			is(scalar @entries, $test->{count}, 'correct number of items');
			my $buckets = {};
			$buckets->{$_}++ for @entries;
			my $total = 0;
			foreach my $item (@{$test->{range}}) {
				$total += $buckets->{$item};
				cmp_ok($buckets->{$item}, '>', 0, "At least one of $item");
			}
			is($total, scalar @entries, 'only expected characters exist');
		}
	}

	foreach my $test (@tests) {
		my $expected = $test->{expected};
		next unless defined $expected;

		subtest "expected restults $test->{desc}" => sub {
			my $obj = new_obj();
			my $got = join('', $obj->randitems(10, $test->{range}));
			is($got, $expected, 'expected results for generator');
			$obj = new_obj();
			$got = $obj->randbytes(10, $test->{range});
			is($got, $expected, 'expected results for randbytes');
		};
	}
};

subtest 'rand' => sub {
	my $obj = new_obj();

	my $max = 5;
	my $value = $obj->rand($max);
	is($value, 0x2bc5b19e / 2.0 / (2 ** 31) * $max, 'Value is as expected');

	$value = $obj->rand;
	cmp_ok($value, '<', 1, 'raw rand value is less than 1');
	cmp_ok($value, '>=', 0, 'raw rand value is non-negative');

	my @tests = (
		{
			count => 100,
			arg => 5,
			desc => 'digits'
		},
	);
	foreach my $test (@tests) {
		subtest "generate $test->{desc}" => sub {
			$obj = new_obj();
			my @entries = $obj->rand($test->{arg}, $test->{count});
			is(scalar @entries, $test->{count}, 'correct number of items');
			my $buckets = {};
			$buckets->{int($_)}++ for @entries;
			my $total = 0;
			foreach my $item (0..($test->{arg}-1)) {
				$total += $buckets->{$item};
				cmp_ok($buckets->{$item}, '>', 0, "At least one of $item");
			}
			is($total, scalar @entries, 'only expected numbers exist');
			is((grep { $_ >= $test->{arg} } @entries), 0, 'right range');
		}
	}
};

subtest 'Cache handling' => sub {
	my $cache_size = 1024;
	my $total_bytes = $cache_size * 2.5;
	my %params = (cache => $cache_size);
	my $obj = new_obj(%params);
	my $expected = $obj->generate($total_bytes);

	$obj = new_obj(%params);

	my $got = '';
	my $left = $total_bytes;
	foreach my $bytes (1..($cache_size * 2)) {
		my $to_get = $bytes < $left ? $bytes : $left;
		my $cur = $obj->generate($to_get);
		is(length($cur), $to_get, 'Proper number of bytes returned');
		$got .= $cur;
		$left -= $to_get;
		last unless $left;
	}
	is($got, $expected, 'Cached data is handled in chunks');
};

done_testing();

sub new_obj {
	my (%params) = @_;
	return Crypt::DRBG::HMAC->new(seed => 'my very secret seed', %params)
}
