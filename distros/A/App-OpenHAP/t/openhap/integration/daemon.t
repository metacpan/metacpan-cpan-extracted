#!/usr/bin/env perl
# ex:ts=8 sw=4:
# Integration test: Daemon lifecycle management

use v5.36;
use Test::More tests => 13;
use FindBin qw($RealBin);
use lib "$RealBin/../../../lib";

use Fugu::Pidfile;
use App::OpenHAP::Test::Integration;
use Time::HiRes qw(sleep);

my $env = App::OpenHAP::Test::Integration->new;
$env->setup;

my $pidfile = Fugu::Pidfile->new(path => '/var/run/openhapd.pid');

# Test 1: Daemon is running after setup
my $running = system('rcctl check openhapd >/dev/null 2>&1') == 0;
ok($running, 'daemon is running');

# Test 2: The PID file holds the PID of the running daemon. The daemon
# takes the file itself, while it is still root.
my $pid = $pidfile->read_pid;
ok(defined $pid && $pid =~ /^\d+$/, 'PID file holds a PID');
is($pidfile->is_running, $pid, 'that PID names a live process');

# Test 3: The PID file stays root-owned. It is the trust anchor that
# hapctl and rc.d read, so the dropped daemon must not rewrite it.
my $owner = (stat '/var/run/openhapd.pid')[4];
is($owner, 0, 'the PID file is root-owned');

# Test 4: Daemon responds to connections
ok($env->wait_for_hap_port, 'daemon accepts connections');

# Test 5: Daemon restart works
ok($env->restart_daemon, 'daemon restarts successfully');

# Test 6: The restarted daemon owns the file
my $new_pid = $pidfile->read_pid;
ok(defined $new_pid && $new_pid ne $pid, 'the PID file names the new daemon');
is($pidfile->is_running, $new_pid, 'and that daemon is alive');

# Test 7: Daemon stop works
system('rcctl stop openhapd >/dev/null 2>&1');
sleep 1;
my $stopped = system('rcctl check openhapd >/dev/null 2>&1') != 0;
ok($stopped, 'daemon stops successfully');

# Test 8: The PID file stays after the stop, and it is stale. An
# unlink in root-owned /var/run needs a directory permission that the
# daemon gives up at the privilege drop. Thus the file is a leftover by
# design, and the stale check is what tells a reader it means nothing.
ok(-e '/var/run/openhapd.pid', 'PID file remains after stop');
ok($pidfile->is_stale, 'and it is stale');

# Test 9: Daemon start works
system('rcctl start openhapd >/dev/null 2>&1');
sleep 1;
$running = system('rcctl check openhapd >/dev/null 2>&1') == 0;
ok($running, 'daemon starts successfully');

# Test 10: Daemon responds after restart. The listener opens only
# after the mDNS publish conversation completes. Thus wait for the
# port. Do not use a fixed sleep.
ok($env->wait_for_hap_port, 'daemon responds after restart');

$env->teardown;
