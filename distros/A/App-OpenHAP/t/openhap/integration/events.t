#!/usr/bin/env perl
# ex:ts=8 sw=4:
# Integration test: EVENT/1.0 notifications over paired sessions.

use v5.36;
use Test::More tests => 8;
use FindBin qw($RealBin);
use lib "$RealBin/../../../lib";

use App::OpenHAP::Test::Integration;
use JSON::PP qw(decode_json encode_json);

my $env = App::OpenHAP::Test::Integration->new;
$env->setup;
$env->ensure_unpaired or die "Cannot reset pairing state\n";

# Subscriber controller: pairs, verifies, subscribes
my $subscriber = $env->get_controller;
$subscriber->pair_setup
    or die 'pair-setup failed: ' . ( $subscriber->last_error // '?' ) . "\n";
$subscriber->pair_verify
    or die 'pair-verify failed: ' . ( $subscriber->last_error // '?' ) . "\n";

# Locate an event-capable writable characteristic (On, type 25)
my $result   = $subscriber->request('GET', '/accessories');
my $database = decode_json($result->{body});
my ($aid, $iid) = $env->find_char($database, '25', ev => 1);
ok(defined $iid, 'found an event-capable On characteristic') or do {
	$env->teardown;
	die "No event-capable characteristic found\n";
};

# Test 1: Subscribe with ev:true
$result = $subscriber->request('PUT', '/characteristics',
	encode_json({ characteristics =>
		[ { aid => $aid, iid => $iid, ev => \1 } ] }),
	{ 'Content-Type' => 'application/hap+json' });
is($result->{status}, 204, '[HAP-HTTP §14] subscription accepted');

# Second controller on its own connection: the admin adds it as a
# pairing, and then it verifies its own session. It does NOT
# subscribe.
my $bystander = $env->get_controller(controller_id => 'bystander-ctrl');
$subscriber->add_pairing('bystander-ctrl', $bystander->{ltpk}, 1)
    or die 'add_pairing failed: ' . ( $subscriber->last_error // '?' ) . "\n";
$bystander->{accessory_ltpk} = $subscriber->{accessory_ltpk};
ok($bystander->pair_verify, 'second controller verifies its own session')
    or diag('pair_verify error: ' . ($bystander->last_error // 'none'));

# Test 2: A write from the second controller triggers an event to the
# subscriber with the new value
$result = $bystander->request('PUT', '/characteristics',
	encode_json({ characteristics =>
		[ { aid => $aid, iid => $iid, value => \1 } ] }),
	{ 'Content-Type' => 'application/hap+json' });
is($result->{status}, 204, 'value changed from the second connection');

# Positive wait: bounded by the session timeout (OPENHAP_TEST_TIMEOUT)
my $event = $subscriber->next_event;
ok(defined $event, '[HAP-HTTP §14] EVENT/1.0 message received')
    or diag('no event; buffered plaintext: '
	. unpack('H*', $subscriber->{inbuf} // '')
	. ' raw: ' . unpack('H*', $subscriber->{rawbuf} // ''));

# Decode only a received event. Then a miss stays a normal failure,
# and the unpair teardown below still runs.
is($event ? $event->{headers}{'content-type'} : undef,
   'application/hap+json', '[HAP-HTTP §14] event content type');
my $payload = $event ? eval { decode_json($event->{body}) } : undef;
diag("event body undecodable: $@") if $event && !$payload;
my ($change) = grep { $_->{aid} == $aid && $_->{iid} == $iid }
    @{ $payload ? $payload->{characteristics} : [] };
ok($change, '[HAP-HTTP §14] event carries the changed characteristic');

# Test 3: Subscriptions are per-connection. The unsubscribed
# controller receives nothing.
my $stray = $bystander->next_event(2);
ok(!defined $stray,
   '[HAP-HTTP §14] unsubscribed connection receives no events');

# Teardown: unpair everything so the next file starts clean
$subscriber->remove_pairing('bystander-ctrl');
$subscriber->remove_pairing;
$env->teardown;
