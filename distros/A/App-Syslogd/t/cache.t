#!/usr/bin/env perl

# Tests for App::Syslogd::Cache, the built-in cache for host names.
#
# Strategy: the clock is replaced (mock_core, before the module is
# compiled) so that expiry can be tested to the exact second without
# sleeping.  Size accounting, eviction order and the age queue are checked
# against the documented rules: each entry costs length(key) +
# length(value) + 64, the total never exceeds max_bytes, and the oldest
# entries go first.

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Readonly;
use Scalar::Util qw(weaken);
use Test::Memory::Cycle;
use Test::Mockingbird;
use Test::Most;
use Test::Returns;

# A clock the tests move by hand
our $NOW = 1_000_000;
BEGIN { mock_core('time' => sub { return $main::NOW }) }

use App::Syslogd::Cache;

Readonly my %CONFIG => (
	overhead => 64,			# the documented cost of each entry
	default_max => 262_144,
	ttl => 300,
);

# The documented size of an entry
sub size_of { my ($key, $value) = @_; return length($key) + length($value // '') + $CONFIG{overhead} }

# A code ref that counts how often it is called and returns $value
sub counter { my ($count_ref, $value) = @_; return sub { ${$count_ref}++; return $value } }

subtest 'new' => sub {
	my $cache = App::Syslogd::Cache->new();
	returns_ok($cache, { type => 'object', isa => 'App::Syslogd::Cache' }, 'an App::Syslogd::Cache');
	is($cache->{max_bytes}, $CONFIG{default_max}, 'default size limit');
	is(App::Syslogd::Cache->new(max_bytes => 1)->{max_bytes}, 1, 'the smallest limit');
	throws_ok { App::Syslogd::Cache->new(max_bytes => 0) } qr/Parameter 'max_bytes'/, 'a limit of 0 is refused';
	throws_ok { App::Syslogd::Cache->new(max_bytes => 'lots') } qr/Parameter 'max_bytes'/, 'text is refused';
	throws_ok { App::Syslogd::Cache->new(size => 1) } qr/Unknown parameter 'size'/, 'a misspelt option is refused';
};

subtest 'compute: a hit does not compute again' => sub {
	my $cache = App::Syslogd::Cache->new();
	my $calls = 0;
	is($cache->compute('k', $CONFIG{ttl}, counter(\$calls, 'v')), 'v', 'a miss computes');
	is($cache->compute('k', $CONFIG{ttl}, counter(\$calls, 'other')), 'v', 'a hit returns the remembered value');
	is($calls, 1, 'computed once');

	# undef and "" are values like any other
	my $undef_calls = 0;
	$cache->compute('u', $CONFIG{ttl}, counter(\$undef_calls, undef)) for 1 .. 2;
	is($undef_calls, 1, 'undef is remembered');
	my $empty_calls = 0;
	$cache->compute('e', $CONFIG{ttl}, counter(\$empty_calls, '')) for 1 .. 2;
	is($empty_calls, 1, '"" is remembered');
};

subtest 'compute: expiry to the second' => sub {
	# A value stored at T with ttl N is used until T + N - 1 and is
	# computed again at T + N
	local $NOW = $NOW;
	my $cache = App::Syslogd::Cache->new();
	my $calls = 0;
	my $code = counter(\$calls, 'v');
	$cache->compute('k', $CONFIG{ttl}, $code);
	$NOW += $CONFIG{ttl} - 1;
	$cache->compute('k', $CONFIG{ttl}, $code);
	is($calls, 1, 'one second before expiry: still remembered');
	$NOW += 1;
	$cache->compute('k', $CONFIG{ttl}, $code);
	is($calls, 2, 'at expiry: computed again');
	is($cache->{bytes}, size_of('k', 'v'), 'the expired entry was replaced, not added to');
};

subtest 'compute: ttl 0 or less is never remembered' => sub {
	my $cache = App::Syslogd::Cache->new();
	foreach my $ttl (0, -1) {
		my $calls = 0;
		$cache->compute("t$ttl", $ttl, counter(\$calls, 'v')) for 1 .. 3;
		is($calls, 3, "ttl $ttl: computed every time");
	}
	is($cache->{bytes}, 0, 'nothing stored');
	is_deeply($cache->{entries}, {}, 'no entries');
};

subtest 'size: accounting, eviction oldest first, too big' => sub {
	# Room for exactly three entries of this size
	my $entry = size_of('k1', 'value');
	my $cache = App::Syslogd::Cache->new(max_bytes => 3 * $entry);
	$cache->compute("k$_", $CONFIG{ttl}, sub { 'value' }) foreach(1 .. 3);
	is($cache->{bytes}, 3 * $entry, 'bytes counts every entry');
	is_deeply([sort keys %{$cache->{entries}}], [qw(k1 k2 k3)], 'all three fit exactly');

	$cache->compute('k4', $CONFIG{ttl}, sub { 'value' });
	is_deeply([sort keys %{$cache->{entries}}], [qw(k2 k3 k4)], 'a fourth pushes out the oldest');
	cmp_ok($cache->{bytes}, '<=', $cache->{max_bytes}, 'still within the limit');

	my $big = 'x' x (4 * $entry);
	is($cache->compute('big', $CONFIG{ttl}, sub { $big }), $big, 'a value too big to keep is still returned');
	ok(!exists($cache->{entries}{big}), '...but not remembered');
	is_deeply([sort keys %{$cache->{entries}}], [qw(k2 k3 k4)], '...and nothing was pushed out for it');
};

subtest 'compute: an error is passed on and nothing is kept' => sub {
	my $cache = App::Syslogd::Cache->new();
	throws_ok { $cache->compute('k', $CONFIG{ttl}, sub { die "resolver down\n" }) } qr/\Aresolver down\n\z/, 'the error is passed on';
	ok(!exists($cache->{entries}{k}), 'nothing remembered');
	is($cache->{bytes}, 0, 'nothing counted');
};

subtest 'the age queue stays bounded' => sub {
	# One key replaced again and again (each time it expires) would leave
	# a stale queue item every time; the queue must not grow without end
	local $NOW = $NOW;
	my $cache = App::Syslogd::Cache->new();
	$cache->compute('other', 1_000_000, sub { 'o' });
	foreach (1 .. 1000) {
		$NOW += $CONFIG{ttl};
		$cache->compute('k', $CONFIG{ttl}, sub { 'v' });
	}
	cmp_ok(scalar(@{$cache->{order}}), '<=', 2 * keys(%{$cache->{entries}}) + 1, 'queue bounded by the number of entries');
	is($cache->compute('other', 1_000_000, sub { 'recomputed' }), 'o', 'the other entry survived the rebuilds');

	# And eviction still goes oldest first after a rebuild
	my $entry = size_of('a', 'v');
	my $small = App::Syslogd::Cache->new(max_bytes => 2 * $entry);
	$small->compute('a', $CONFIG{ttl}, sub { 'v' });
	foreach (1 .. 10) {
		$NOW += $CONFIG{ttl};
		$small->compute('b', $CONFIG{ttl}, sub { 'v' });
	}
	$small->compute('c', $CONFIG{ttl}, sub { 'v' });
	is_deeply([sort keys %{$small->{entries}}], [qw(b c)], 'the oldest (a) went first');
};

subtest 'invariant: bytes always matches the entries and never exceeds the limit' => sub {
	# A long mixed sequence of keys, values, lifetimes and clock moves
	local $NOW = $NOW;
	my $cache = App::Syslogd::Cache->new(max_bytes => 2000);
	my $ok = 1;
	foreach my $step (1 .. 2000) {
		my $key = 'k' . ($step * 7 % 53);
		my $value = 'v' x ($step % 97);
		$NOW += $step % 3;
		$cache->compute($key, ($step % 11) - 1, sub { $value });
		my $sum = 0;
		$sum += $_->[2] foreach(values %{$cache->{entries}});
		$ok &&= ($sum == $cache->{bytes} && $cache->{bytes} <= $cache->{max_bytes});
	}
	ok($ok, 'held after every one of 2000 operations');
};

subtest 'memory' => sub {
	my $cache = App::Syslogd::Cache->new();
	$cache->compute('k', $CONFIG{ttl}, sub { 'v' });
	memory_cycle_ok($cache, 'no reference cycles');
	my $weak = $cache;
	weaken($weak);
	undef $cache;
	ok(!defined($weak), 'freed when the last reference goes');
};

done_testing();
