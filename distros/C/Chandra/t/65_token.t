#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time sleep);

plan tests => 141;

use_ok('Chandra::Socket::Token');

# === Constructor defaults ===
{
	my $tm = Chandra::Socket::Token->new();
	ok(defined $tm, 'new() returns object');
	isa_ok($tm, 'Chandra::Socket::Token');
	is($tm->ttl, 3600, 'default ttl is 3600');
	is($tm->rotation_interval, 1800, 'default rotation is 1800');
	is($tm->grace_period, 60, 'default grace is 60');
}

# === Custom parameters ===
{
	my $tm = Chandra::Socket::Token->new(
		ttl      => 120,
		rotation => 60,
		grace    => 10,
		length   => 16,
	);
	is($tm->ttl, 120, 'custom ttl');
	is($tm->rotation_interval, 60, 'custom rotation');
	is($tm->grace_period, 10, 'custom grace');
}

# === Token generation ===
{
	my $tm = Chandra::Socket::Token->new(length => 16);
	my $tok = $tm->current;
	ok(defined $tok, 'current token defined');
	is(length($tok), 32, '16 bytes = 32 hex chars');
	like($tok, qr/^[0-9a-f]+$/i, 'token is hex');
}

# === Generate standalone ===
{
	my $tm = Chandra::Socket::Token->new(length => 8);
	my $tok = $tm->generate;
	ok(defined $tok, 'generate returns token');
	is(length($tok), 16, '8 bytes = 16 hex chars');
	like($tok, qr/^[0-9a-f]+$/i, 'generated token is hex');
	isnt($tok, $tm->current, 'generate does not change current');
}

# === Validate current token ===
{
	my $tm = Chandra::Socket::Token->new();
	my $tok = $tm->current;
	ok($tm->validate($tok), 'current token validates');
	ok(!$tm->validate('badtoken'), 'bad token rejected');
	ok(!$tm->validate(''), 'empty token rejected');
	ok(!$tm->validate(undef), 'undef token rejected');
}

# === No previous before rotation ===
{
	my $tm = Chandra::Socket::Token->new();
	ok(!defined $tm->previous, 'no previous before rotation');
}

# === Rotation ===
{
	my $tm = Chandra::Socket::Token->new(grace => 5);
	my $old = $tm->current;
	$tm->rotate;
	my $new = $tm->current;
	isnt($new, $old, 'current changed after rotate');
	is($tm->previous, $old, 'previous is old current');
	ok($tm->validate($new), 'new token validates');
	ok($tm->validate($old), 'old token validates during grace');
	ok($tm->in_grace, 'in_grace is true after rotate');
}

# === on_rotate callback ===
{
	my $tm = Chandra::Socket::Token->new();
	my $called_with;
	$tm->on_rotate(sub { $called_with = $_[0] });
	$tm->rotate;
	is($called_with, $tm->current, 'on_rotate callback fires with new token');
}

# === rotation_due ===
{
	my $tm = Chandra::Socket::Token->new(rotation => 0.1);
	ok(!$tm->rotation_due, 'not due immediately');
	sleep(0.15);
	ok($tm->rotation_due, 'due after interval');
}

# === expired ===
{
	my $tm = Chandra::Socket::Token->new(ttl => 0.1);
	ok(!$tm->expired, 'not expired immediately');
	sleep(0.15);
	ok($tm->expired, 'expired after ttl');
}

# === Expired token rejected ===
{
	my $tm = Chandra::Socket::Token->new(ttl => 0.1);
	my $tok = $tm->current;
	sleep(0.15);
	ok(!$tm->validate($tok), 'expired token rejected');
}

# === info ===
{
	my $tm = Chandra::Socket::Token->new(ttl => 300, rotation => 150, grace => 30);
	my $info = $tm->info;
	ok(ref $info eq 'HASH', 'info returns hashref');
	ok(defined $info->{current}, 'info has current');
	ok($info->{created_at} > 0, 'info has created_at');
	ok($info->{expires_at} > $info->{created_at}, 'expires_at > created_at');
	ok($info->{rotation_at} > $info->{created_at}, 'rotation_at > created_at');
}

# === Unique tokens ===
{
	my $tm = Chandra::Socket::Token->new();
	my %seen;
	for (1..100) {
		my $t = $tm->generate;
		ok(!$seen{$t}++, "token $_ is unique") or last;
	}
	# Just check uniqueness without adding 100 test points
	is(scalar keys %seen, 100, '100 unique tokens generated');
}

# === Grace period expiry ===
{
	my $tm = Chandra::Socket::Token->new(grace => 0.1);
	my $old = $tm->current;
	$tm->rotate;
	ok($tm->validate($old), 'old valid during grace');
	sleep(0.15);
	ok(!$tm->in_grace, 'grace period ended');
	ok(!$tm->validate($old), 'old rejected after grace');
}
