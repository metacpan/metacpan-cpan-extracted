#!/usr/bin/env perl
# ex:ts=8 sw=4:
# Integration test: Configuration loading and validation
#
# The hapctl surface itself (check exits 0, meaningful output) lives
# in hapctl.t. The daemon lifecycle (restart works) lives in daemon.t.
# This file covers what neither does: openhapd -n, the required
# settings, and the agreement between hapctl and the parsed file.

use v5.36;
use Test::More tests => 5;
use FindBin qw($RealBin);
use lib "$RealBin/../../../lib";

use App::OpenHAP::Test::Integration;

my $env = App::OpenHAP::Test::Integration->new;
$env->setup;

my $config_file = $env->{config_file};

# Test 1: openhapd -n validates configuration
my $daemon_check = system("openhapd -n -c $config_file >/dev/null 2>&1");
is($daemon_check, 0, 'openhapd -n validates configuration');

# Test 2: Configuration contains required HAP settings
my $hap_name = $env->get_config_value('hap_name');
my $hap_port = $env->get_config_value('hap_port');
ok(defined $hap_name, 'configuration has hap_name');
ok(defined $hap_port, 'configuration has hap_port');

# Test 3: HAP port is valid
ok($hap_port =~ /^\d+$/ && $hap_port >= 1024 && $hap_port <= 65535,
   'hap_port is valid');

# Test 4: The hapctl device count matches the parsed configuration
my $check_output = `hapctl -c $config_file check 2>&1`;
my ($reported_count) = $check_output =~ /Configured devices:\s*(\d+)/;
my @device_topics = $env->get_device_topics;
is($reported_count, scalar @device_topics,
   'hapctl device count matches parsed device topics');

$env->teardown;
