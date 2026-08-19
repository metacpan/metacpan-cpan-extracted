#!/usr/bin/env perl
# ex:ts=8 sw=4:
# Integration test: hapctl control utility functionality

use v5.36;
use Test::More tests => 14;
use FindBin qw($RealBin);
use lib "$RealBin/../../../lib";

use App::OpenHAP::Test::Integration;

my $env = App::OpenHAP::Test::Integration->new;
$env->setup;

my $config_file = $env->{config_file};
my $hapctl = '/usr/local/bin/hapctl';

# Test 1: hapctl without arguments shows usage
my $no_args_output = `$hapctl 2>&1`;
my $shows_usage = $no_args_output =~ /(Usage|help|command)/i;
ok($shows_usage, 'shows usage without arguments');

# Test 2: hapctl check validates configuration
my $check_result = system("$hapctl -c $config_file check >/dev/null 2>&1");
is($check_result, 0, 'check command validates configuration');

# Test 3: hapctl check provides meaningful output
my $check_output = `$hapctl -c $config_file check 2>&1`;
my $check_meaningful = $check_output =~ /(Configuration.*valid|Configured devices:\s*\d+)/i;
ok($check_meaningful, 'check output is meaningful');

# Test 4: hapctl status reports daemon state
my $status_output = `$hapctl -c $config_file status 2>&1`;
my $status_works = $? == 0 && length($status_output) > 0;
ok($status_works, 'status command works');

# Test 5: status tells a running daemon from a stopped one. The
# report comes from the daemon over its control socket, so it names
# the bridge and what the daemon holds, not a PID from a file.
like($status_output, qr/openhapd is running/,
   'status reports the running daemon');
like($status_output, qr/Pairing status:/,
   'and it reports the pairing state');
like($status_output, qr/Configuration num:\s*\d+/,
   'and the configuration number, which only the daemon knows');

# Test 6: the reply carries no secret. openhapd.conf holds the setup
# code and the MQTT password, and neither may reach a terminal.
my $pin = $env->get_config_value('hap_pin') // '';
my $pass = $env->get_config_value('mqtt_pass') // '';
my $leaked = 0;
for my $secret (grep { length } $pin, $pass) {
	$leaked = 1 if index($status_output, $secret) >= 0;
}
ok(!$leaked, 'status carries no setup code and no broker password');

# Test 7: with the daemon stopped, status says the opposite, and it
# names the file it fell back to
system('rcctl stop openhapd >/dev/null 2>&1');
my $stopped_output = `$hapctl -c $config_file status 2>&1`;
system('rcctl start openhapd >/dev/null 2>&1');
$env->wait_for_hap_port;
like($stopped_output, qr/openhapd is not running/,
   'status reports the stopped daemon');
like($stopped_output, qr{read from /var/run/openhapd\.pid},
   'and it says which source answered');

# Test 8: hapctl devices lists the devices
my $devices_output = `$hapctl -c $config_file devices 2>&1`;
my $devices_works = $? == 0
    && $devices_output =~ /(Loaded devices|Configured devices|No devices)/i;
ok($devices_works, 'devices command works');

# Test 9: hapctl rejects unknown commands
my $unknown_output = `$hapctl unknown_command_xyz 2>&1`;
my $unknown_rejected = $? != 0 || $unknown_output =~ /(Unknown|invalid)/i;
ok($unknown_rejected, 'unknown commands rejected');

# Test 10: hapctl survives a missing config file without crashing
my $invalid_config = "/nonexistent/openhapd-test-$$.conf";
my $invalid_exit = system("$hapctl -c $invalid_config status >/dev/null 2>&1");
ok($invalid_exit != -1 && ($invalid_exit & 127) == 0,
   'missing config file does not crash hapctl (no signal, command ran)');

# Test 11: hapctl check reports zero devices for an empty configuration
my $temp_config = "/tmp/openhapd-empty-$$.conf";
open my $tmp, '>', $temp_config
    or die "Cannot create temp config: $!\n";
print $tmp "hap_name = \"Empty Bridge\"\n";
close $tmp;

my $empty_output = `$hapctl -c $temp_config check 2>&1`;
unlink $temp_config;
like($empty_output, qr/Configured devices:\s*0/,
   'check reports zero devices for device-less configuration');

$env->teardown;
