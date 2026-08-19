#!/usr/bin/env perl
# ex:ts=8 sw=4:
# Integration test: the complete HAP pairing workflow against the
# live daemon. Protocol::HAP::Controller drives the workflow.

use v5.36;
use Test::More tests => 18;
use FindBin qw($RealBin);
use lib "$RealBin/../../../lib";

use App::OpenHAP::Test::Integration;
use Protocol::HAP::Pairing;

my $env = App::OpenHAP::Test::Integration->new;
$env->setup;
$env->ensure_unpaired or die "Cannot reset pairing state\n";

# Test 1: Pairing data directory exists and is readable
my $storage_dir = '/var/db/openhapd';
ok(-d $storage_dir && -r $storage_dir, 'pairing storage directory exists');

# Test 2: Pair-setup M1 rejects a stale "0x"-prefixed public key.
# This is a regression guard: Math::BigInt->as_hex once leaked its
# 0x prefix.
my $response = $env->http_request('POST', '/pair-setup',
	"\x06\x01\x01\x00\x01\x00",
	{'Content-Type' => 'application/pairing+tlv8'});
my ($status, undef, $body) =
	App::OpenHAP::Test::Integration::parse_http_response($response);
is($status, 200, 'pair-setup M1 accepted');
my $hex = unpack('H*', $body);
unlike($hex, qr/03..0130783078/,
    '[HAP-Pairing §2.4] M2 public key does not contain ASCII "0x" prefix');

# Close the raw M1 probe's connection now. Do not leave it
# registered with the daemon until teardown.
$env->close_sockets;

# Restart cleanly so the M1 probe above does not hold the pairing lock
$env->ensure_daemon_stopped or die "Cannot stop daemon\n";
$env->ensure_daemon_running or die "Cannot start daemon\n";

# Test 3: Full pair-setup with the real PIN
my $controller = $env->get_controller;
ok($controller->pair_setup,
   '[HAP-Pairing §2] full pair-setup M1-M6 with the configured PIN')
    or diag('pair_setup error: ' . ($controller->last_error // 'none'));
ok(defined $controller->{accessory_ltpk},
   '[HAP-Pairing §2.8] accessory LTPK received in M6');

# Test 4: Pair-verify establishes an encrypted session
ok($controller->pair_verify,
   '[HAP-Pairing §3] pair-verify M1-M4 completes')
    or diag('pair_verify error: ' . ($controller->last_error // 'none'));
ok($controller->is_encrypted, 'session switched to encrypted framing');

# Test 5: Authenticated endpoint works over the session
my $result = $controller->request('GET', '/accessories');
is($result->{status}, 200,
   '[HAP-HTTP §7] paired GET /accessories returns 200');

# Test 6: Add, list, and remove an additional pairing over the wire
ok($controller->add_pairing('extra-ctrl', 'X' x 32, 0),
   '[HAP-Pairing §7.1] add pairing accepted');
my $pairings = $controller->list_pairings;
is(scalar @$pairings, 2, '[HAP-Pairing §7.3] both pairings listed');
ok($controller->remove_pairing('extra-ctrl'),
   '[HAP-Pairing §7.2] remove pairing accepted');
$pairings = $controller->list_pairings;
is(scalar @$pairings, 1, 'extra pairing removed');

# Test 7: Removing a nonexistent pairing returns success
ok($controller->remove_pairing('ghost-ctrl'),
   '[HAP-Pairing §7.4] removing nonexistent pairing succeeds');

# Test 8: The daemon rejects and counts a wrong-PIN attempt after
# unpairing.
$controller->close;
$env->ensure_unpaired or die "Cannot reset pairing state\n";

my $bad = $env->get_controller(pin => '876-54-321',
	controller_id => 'bad-ctrl');
ok(!$bad->pair_setup, 'pair-setup fails with the wrong PIN');
is($bad->last_error,
   Protocol::HAP::Pairing::kTLVError_Authentication(),
   '[HAP-Pairing §2.6] M4 returns kTLVError_Authentication');
$bad->close;

# Test 9: Re-pair after the failed attempt
$env->ensure_unpaired or die "Cannot reset pairing state\n";
my $again = $env->get_controller(controller_id => 're-pair-ctrl');
ok($again->pair_setup, '[HAP-Pairing §2.4] re-pair succeeds after unpair');
ok($again->pair_verify, 'pair-verify succeeds on the new pairing');

# Teardown: leave the daemon unpaired for the next test file
ok($again->remove_pairing, 'unpaired in teardown');
$env->teardown;
