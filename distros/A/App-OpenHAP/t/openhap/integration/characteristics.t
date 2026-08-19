#!/usr/bin/env perl
# ex:ts=8 sw=4:
# Integration test: authenticated accessory data plane over a paired,
# encrypted session.

use v5.36;
use Test::More tests => 16;
use FindBin qw($RealBin);
use lib "$RealBin/../../../lib";

use App::OpenHAP::Test::Integration;
use JSON::PP qw(decode_json encode_json);

my $env = App::OpenHAP::Test::Integration->new;
$env->setup;
$env->ensure_unpaired or die "Cannot reset pairing state\n";

my $controller = $env->get_controller;
$controller->pair_setup
    or die 'pair-setup failed: ' . ( $controller->last_error // '?' ) . "\n";
$controller->pair_verify
    or die 'pair-verify failed: ' . ( $controller->last_error // '?' ) . "\n";

# Test 1: Paired GET /accessories returns the accessory database
my $result = $controller->request('GET', '/accessories');
is($result->{status}, 200, '[HAP-HTTP §7] paired GET /accessories is 200');

my $database = decode_json($result->{body});
ok(ref $database->{accessories} eq 'ARRAY',
   '[HAP-HTTP §7] accessories array present');

# Test 2: Bridge accessory has aid 1
my ($bridge) = grep { $_->{aid} == 1 } @{ $database->{accessories} };
ok($bridge, '[HAP §3.1] bridge accessory has aid 1');

# Test 3: All configured devices appear with aid > 1
my @device_topics = $env->get_device_topics;
my @bridged = grep { $_->{aid} > 1 } @{ $database->{accessories} };
is(scalar @bridged, scalar @device_topics,
   'all configured devices have accessory objects');

# Find a readable/writable bool characteristic (On, type 25)
my ($aid, $iid) = $env->find_char($database, '25');
ok(defined $iid, 'found an On characteristic to exercise') or do {
	$env->teardown;
	die "No On characteristic found in the accessory database\n";
};

# Test 4: GET /characteristics with real values
$result = $controller->request('GET', "/characteristics?id=$aid.$iid");
is($result->{status}, 200,
   '[HAP-HTTP §8] paired characteristic read returns 200');
my $read = decode_json($result->{body});
is($read->{characteristics}[0]{aid}, $aid, 'response aid matches');
ok(exists $read->{characteristics}[0]{value}, 'value present');

# Test 5: PUT /characteristics succeeds with 204
$result = $controller->request('PUT', '/characteristics',
	encode_json({ characteristics =>
		[ { aid => $aid, iid => $iid, value => \1 } ] }),
	{ 'Content-Type' => 'application/hap+json' });
is($result->{status}, 204,
   '[HAP-HTTP §9] successful write returns 204 No Content');

# Test 6: The written value reads back
$result = $controller->request('GET', "/characteristics?id=$aid.$iid");
like($result->{body}, qr/"value"\s*:\s*true/,
   '[HAP-HTTP §8] written value reads back as true');

# Test 7: Invalid iid returns 207 with HAP status -70409
$result = $controller->request('GET', '/characteristics?id=999.999');
is($result->{status}, 207,
   '[HAP-HTTP §9] invalid id returns 207 Multi-Status');
is(decode_json($result->{body})->{characteristics}[0]{status}, -70409,
   '[HAP-HTTP §12] invalid iid has HAP status -70409');

# Test 8: Timed write through /prepare with a pid
$result = $controller->request('PUT', '/prepare',
	encode_json({ ttl => 2500, pid => 424242 }),
	{ 'Content-Type' => 'application/hap+json' });
is($result->{status}, 200, '[HAP-HTTP §10] /prepare accepted');
is(decode_json($result->{body})->{status}, 0, '/prepare status 0');

# Test 9: The daemon answers a mixed write with 207 and per-item status
$result = $controller->request('PUT', '/characteristics',
	encode_json({ characteristics => [
		{ aid => $aid, iid => $iid,  value => \0 },
		{ aid => $aid, iid => 9999, value => \0 },
	] }),
	{ 'Content-Type' => 'application/hap+json' });
is($result->{status}, 207,
   '[HAP-HTTP §9] partial failure returns 207');
my @statuses =
    map { $_->{status} } @{ decode_json($result->{body})->{characteristics} };
is_deeply([ sort { $a <=> $b } @statuses ], [ -70409, 0 ],
   'per-item status codes reported');

# Teardown: unpair so the next file starts clean
$controller->remove_pairing;
$env->teardown;
