#!/usr/bin/env perl
use v5.36;
use Test::More;

BEGIN {
    eval {
        require Math::BigInt;
        require Digest::SHA;
    };
    if ($@) {
        plan skip_all => 'Required modules not available';
    }
}

use_ok('Protocol::HAP::Pairing');
use_ok('Protocol::HAP::Store::Memory');
use_ok('Protocol::HAP::Crypto');
use_ok('Protocol::HAP::Session');

sub have_ed25519 {
    return eval { require Crypt::Ed25519; 1 } ? 1 : 0;
}

my $next_session_id = 1;

# new_pairing(%extra):
#	One pairing instance over a fresh in-memory store.
sub new_pairing (%extra) {
    my ($ltsk, $ltpk) = Protocol::HAP::Crypto->ed25519_keypair;

    return Protocol::HAP::Pairing->new(
        pin            => '123-45-678',
        store          => Protocol::HAP::Store::Memory->new,
        accessory_ltsk => $ltsk,
        accessory_ltpk => $ltpk,
        %extra,
    );
}

sub new_session {
    return Protocol::HAP::Session->new(id => $next_session_id++);
}

# Test pairing object creation
SKIP: {
    skip 'Crypt::Ed25519 not available', 2 unless have_ed25519();

    my $pairing = new_pairing();

    ok(defined $pairing, 'Pairing object created');
    isa_ok($pairing, 'Protocol::HAP::Pairing');
}

# The store is required: the attempt counter of HAP-Pairing.md §8
# needs persistence, and a silent in-memory fallback would fail open
{
    ok(!eval { Protocol::HAP::Pairing->new(pin => '123-45-678'); 1 },
        'a pairing without a store is a programming error');
}

# Test TLV constants are defined
{
    ok(defined &Protocol::HAP::Pairing::kTLVType_Method, 'kTLVType_Method defined');
    ok(defined &Protocol::HAP::Pairing::kTLVType_State, 'kTLVType_State defined');
    ok(defined &Protocol::HAP::Pairing::kTLVType_Error, 'kTLVType_Error defined');
    ok(defined &Protocol::HAP::Pairing::kTLVType_PublicKey, 'kTLVType_PublicKey defined');
    ok(defined &Protocol::HAP::Pairing::kTLVType_Proof, 'kTLVType_Proof defined');
    ok(defined &Protocol::HAP::Pairing::kTLVType_EncryptedData, 'kTLVType_EncryptedData defined');
}

# Test error constants
{
    ok(defined &Protocol::HAP::Pairing::kTLVError_Unknown, 'kTLVError_Unknown defined');
    ok(defined &Protocol::HAP::Pairing::kTLVError_Authentication, 'kTLVError_Authentication defined');
    ok(defined &Protocol::HAP::Pairing::kTLVError_Backoff, 'kTLVError_Backoff defined');
    ok(defined &Protocol::HAP::Pairing::kTLVError_MaxPeers, 'kTLVError_MaxPeers defined');
}

# Test error response generation
SKIP: {
    skip 'Crypt::Ed25519 not available', 2 unless have_ed25519();

    my $pairing = new_pairing();

    my $error_response = $pairing->_error_response(
        Protocol::HAP::Pairing::kTLVError_Authentication(),
        2
    );

    ok(defined $error_response, 'Error response generated');
    ok(length($error_response) > 0, 'Error response has content');
}

# Test handle_pair_setup with invalid state
SKIP: {
    skip 'Crypt::Ed25519 not available', 1 unless have_ed25519();

    my $pairing = new_pairing();
    my $session = new_session();

    # Create a TLV with an invalid state (99)
    require Protocol::HAP::TLV;
    my $body = Protocol::HAP::TLV::encode(
        Protocol::HAP::Pairing::kTLVType_State(), pack('C', 99),
    );

    my $response = $pairing->handle_pair_setup($body, $session);
    ok(defined $response, 'Invalid state returns error response');
}

# Test handle_pair_verify with invalid state
SKIP: {
    skip 'Crypt::Ed25519 not available', 1 unless have_ed25519();

    my $pairing = new_pairing();
    my $session = new_session();

    # Create a TLV with an invalid state (99)
    require Protocol::HAP::TLV;
    my $body = Protocol::HAP::TLV::encode(
        Protocol::HAP::Pairing::kTLVType_State(), pack('C', 99),
    );

    my $response = $pairing->handle_pair_verify($body, $session);
    ok(defined $response, 'Invalid state returns error response');
}

# Test kTLVError_MaxTries constant
{
    ok(defined &Protocol::HAP::Pairing::kTLVError_MaxTries, 'kTLVError_MaxTries defined');
    is(Protocol::HAP::Pairing::kTLVError_MaxTries(), 0x05, '[HAP-TLV8 §7] kTLVError_MaxTries is 0x05');
}

# Test invalid pairing method rejection
SKIP: {
    skip 'Crypt::Ed25519 not available', 2 unless have_ed25519();

    my $pairing = new_pairing();
    my $session = new_session();

    # Create a TLV with an invalid method (99)
    require Protocol::HAP::TLV;
    my $body = Protocol::HAP::TLV::encode(
        Protocol::HAP::Pairing::kTLVType_State(), pack('C', 1),
        Protocol::HAP::Pairing::kTLVType_Method(), pack('C', 99),
    );

    my $response = $pairing->handle_pair_setup($body, $session);
    ok(defined $response, 'Invalid method returns response');

    # Decode the response to check for an error
    my %resp_tlv = Protocol::HAP::TLV::decode($response);
    my $error = unpack('C', $resp_tlv{ Protocol::HAP::Pairing::kTLVType_Error() } // '');
    is($error, Protocol::HAP::Pairing::kTLVError_Unknown(),
        '[HAP-TLV8 §6] invalid pairing method returns kTLVError_Unknown');
}

# Test already-paired rejection
SKIP: {
    skip 'Crypt::Ed25519 not available', 2 unless have_ed25519();

    my $pairing = new_pairing();

    # Add an existing pairing
    $pairing->{store}->save_pairing('test-controller', 'X' x 32, 1);

    my $session = new_session();

    require Protocol::HAP::TLV;
    my $body = Protocol::HAP::TLV::encode(
        Protocol::HAP::Pairing::kTLVType_State(), pack('C', 1),
        Protocol::HAP::Pairing::kTLVType_Method(), pack('C', 0),  # PairSetup
    );

    my $response = $pairing->handle_pair_setup($body, $session);
    my %resp_tlv = Protocol::HAP::TLV::decode($response);
    my $error = unpack('C', $resp_tlv{ Protocol::HAP::Pairing::kTLVType_Error() } // '');
    is($error, Protocol::HAP::Pairing::kTLVError_Unavailable(),
        '[HAP-Pairing §2.4] already paired returns kTLVError_Unavailable in M2');

    # The accessory must allow PairSetupWithAuth (method=1) even
    # when paired
    $pairing->clear_pairing_state();
    my $session2 = new_session();
    my $body_auth = Protocol::HAP::TLV::encode(
        Protocol::HAP::Pairing::kTLVType_State(), pack('C', 1),
        Protocol::HAP::Pairing::kTLVType_Method(), pack('C', 1),  # PairSetupWithAuth
    );

    my $response_auth = $pairing->handle_pair_setup($body_auth, $session2);
    my %resp_auth = Protocol::HAP::TLV::decode($response_auth);
    my $state = unpack('C', $resp_auth{ Protocol::HAP::Pairing::kTLVType_State() } // '');
    is($state, 2,
        '[HAP-Pairing §2.3] PairSetupWithAuth allowed when already paired (returns M2)');
}

# Test concurrent pairing protection
SKIP: {
    skip 'Crypt::Ed25519 not available', 1 unless have_ed25519();

    my $pairing = new_pairing();

    require Protocol::HAP::TLV;
    my $body = Protocol::HAP::TLV::encode(
        Protocol::HAP::Pairing::kTLVType_State(), pack('C', 1),
        Protocol::HAP::Pairing::kTLVType_Method(), pack('C', 0),
    );

    # The first session starts the pairing
    my $session1 = new_session();
    my $response1 = $pairing->handle_pair_setup($body, $session1);

    # The second session tries to start the pairing and must get Busy
    my $session2 = new_session();
    my $response2 = $pairing->handle_pair_setup($body, $session2);
    my %resp2 = Protocol::HAP::TLV::decode($response2);
    my $error2 = unpack('C', $resp2{ Protocol::HAP::Pairing::kTLVType_Error() } // '');
    is($error2, Protocol::HAP::Pairing::kTLVError_Busy(),
        '[HAP-Pairing §2.4] concurrent pairing returns kTLVError_Busy in M2');
}

# Test failed attempt counting
SKIP: {
    skip 'Crypt::Ed25519 not available', 1 unless have_ed25519();

    my $pairing = new_pairing();
    $pairing->reset_auth_attempts;
    is($pairing->get_failed_attempts, 0,
        '[HAP-Pairing §8] failed attempt counter starts at 0');
}

# The counter and the lock are instance state: two Pairing instances
# in one process are independent
SKIP: {
    skip 'Crypt::Ed25519 not available', 4 unless have_ed25519();

    my $a = new_pairing();
    my $b = new_pairing();

    require Protocol::HAP::TLV;
    my $body = Protocol::HAP::TLV::encode(
        Protocol::HAP::Pairing::kTLVType_State(), pack('C', 1),
        Protocol::HAP::Pairing::kTLVType_Method(), pack('C', 0),
    );

    # Instance A takes its lock
    my $session_a = new_session();
    $a->handle_pair_setup($body, $session_a);

    # Instance B pairs a different accessory: A's lock must not
    # apply to it
    my $session_b = new_session();
    my $response = $b->handle_pair_setup($body, $session_b);
    my %resp = Protocol::HAP::TLV::decode($response);
    my $state = unpack('C', $resp{ Protocol::HAP::Pairing::kTLVType_State() } // '');
    is($state, 2, 'the second instance pairs while the first holds its lock');
    ok(!defined $resp{ Protocol::HAP::Pairing::kTLVType_Error() },
        'no Busy error crosses instances');

    # The counters are independent too
    $a->_auth_failure('test probe');
    $a->_auth_failure('test probe');
    is($a->get_failed_attempts, 2, 'instance A counts its own failures');
    is($b->get_failed_attempts, 0, 'instance B is untouched');
}

# The attempt counter survives a rebuilt instance over the same store
SKIP: {
    skip 'Crypt::Ed25519 not available', 1 unless have_ed25519();

    my ($ltsk, $ltpk) = Protocol::HAP::Crypto->ed25519_keypair;
    my $store = Protocol::HAP::Store::Memory->new;

    my $first = Protocol::HAP::Pairing->new(
        pin            => '123-45-678',
        store          => $store,
        accessory_ltsk => $ltsk,
        accessory_ltpk => $ltpk,
    );
    $first->_auth_failure(q{test probe}) for 1 .. 3;

    my $second = Protocol::HAP::Pairing->new(
        pin            => '123-45-678',
        store          => $store,
        accessory_ltsk => $ltsk,
        accessory_ltpk => $ltpk,
    );
    is($second->get_failed_attempts, 3,
        '[HAP-Pairing §8] the limit survives a rebuilt instance');
}

# Test that the M2 public key does not contain a '0x' prefix (bug fix)
SKIP: {
    skip 'Crypt::Ed25519 not available', 3 unless have_ed25519();

    my $pairing = new_pairing();
    my $session = new_session();

    require Protocol::HAP::TLV;
    my $body = Protocol::HAP::TLV::encode(
        Protocol::HAP::Pairing::kTLVType_State(), pack('C', 1),
        Protocol::HAP::Pairing::kTLVType_Method(), pack('C', 0),
    );

    my $response = $pairing->handle_pair_setup($body, $session);
    my %resp = Protocol::HAP::TLV::decode($response);

    ok(defined $resp{ Protocol::HAP::Pairing::kTLVType_PublicKey() }, 'M2 contains PublicKey');

    my $public_key = $resp{ Protocol::HAP::Pairing::kTLVType_PublicKey() };
    my $hex = unpack('H*', $public_key);

    # Make sure that the hex does not start with '30', which is
    # ASCII '0'. With the bug, the hex would start with '307830...'
    # (0x30='0', 0x78='x').
    isnt(substr($hex, 0, 4), '3078',
        '[HAP-Pairing §2.4] public key does not start with ASCII "0x"');

    # The public key must be 384 bytes (3072 bits)
    is(length($public_key), 384,
        '[HAP-Pairing §2.4] M2 public key B is 384 bytes (3072 bits)');
}

done_testing();
