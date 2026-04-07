#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time sleep);

plan tests => 28;

use_ok('Chandra::Socket::Token');

# === Zero grace period — previous never valid ===
{
	my $tm = Chandra::Socket::Token->new(grace => 0);
	my $old = $tm->current;
	$tm->rotate;
	my $new = $tm->current;
	ok($tm->validate($new), 'new token valid with zero grace');
	ok(!$tm->validate($old), 'old rejected with zero grace');
	ok(!$tm->in_grace, 'not in grace with zero grace');
}

# === Very short TTL — rapid expiry ===
{
	my $tm = Chandra::Socket::Token->new(ttl => 0.05);
	my $tok = $tm->current;
	ok($tm->validate($tok), 'valid before short ttl');
	sleep(0.1);
	ok($tm->expired, 'expired after short ttl');
	ok(!$tm->validate($tok), 'rejected after short ttl');
}

# === Multiple rapid rotations ===
{
	my $tm = Chandra::Socket::Token->new(grace => 5);
	my $t1 = $tm->current;
	$tm->rotate;
	my $t2 = $tm->current;
	$tm->rotate;
	my $t3 = $tm->current;

	ok($tm->validate($t3), 'latest token valid');
	ok($tm->validate($t2), 'previous token valid during grace');
	ok(!$tm->validate($t1), 'two-back token rejected (only one previous kept)');
	is($tm->previous, $t2, 'previous is most recent old token');
}

# === Rotation resets rotation_at ===
{
	my $tm = Chandra::Socket::Token->new(rotation => 0.1);
	sleep(0.15);
	ok($tm->rotation_due, 'rotation due before rotate');
	$tm->rotate;
	ok(!$tm->rotation_due, 'rotation not due after rotate');
}

# === Rotation resets expires_at ===
{
	my $tm = Chandra::Socket::Token->new(ttl => 0.2);
	sleep(0.1);
	ok(!$tm->expired, 'not expired before rotation');
	$tm->rotate;
	ok(!$tm->expired, 'not expired after rotation (ttl reset)');
	sleep(0.25);
	ok($tm->expired, 'expired after new ttl elapses');
}

# === Token lengths ===
{
	for my $len (8, 16, 32, 64) {
		my $tm = Chandra::Socket::Token->new(length => $len);
		is(length($tm->current), $len * 2,
			"length $len bytes = " . ($len * 2) . " hex chars");
	}
}

# === info after rotation ===
{
	my $tm = Chandra::Socket::Token->new(grace => 5);
	$tm->rotate;
	my $info = $tm->info;
	ok(defined $info->{previous}, 'info has previous after rotation');
	ok($info->{grace_until} > 0, 'grace_until set after rotation');
}

# === on_rotate called each time ===
{
	my $tm = Chandra::Socket::Token->new();
	my @tokens;
	$tm->on_rotate(sub { push @tokens, $_[0] });
	$tm->rotate;
	$tm->rotate;
	$tm->rotate;
	is(scalar @tokens, 3, 'on_rotate called 3 times');
	is($tokens[2], $tm->current, 'last callback has current token');
}

# === Validate with wrong length token ===
{
	my $tm = Chandra::Socket::Token->new(length => 16);
	ok(!$tm->validate('abc'), 'short token rejected');
	ok(!$tm->validate('x' x 200), 'long token rejected');
}

# === Default 32-byte token is 64 hex chars ===
{
	my $tm = Chandra::Socket::Token->new();
	is(length($tm->current), 64, 'default token is 64 hex chars');
}

# === Grace period starts only after rotation ===
{
	my $tm = Chandra::Socket::Token->new(grace => 10);
	ok(!$tm->in_grace, 'not in grace before any rotation');
}
