#!/usr/bin/env perl
use v5.36;
use Test::More;

BEGIN {
    eval {
        require CryptX;
    };
    if ($@) {
        plan skip_all => 'CryptX not available';
    }
}

use_ok('Protocol::HAP::Session');
use_ok('Protocol::HAP::Crypto');

# Test session creation
{
    my $session = Protocol::HAP::Session->new(id => 1);
    ok(defined $session, 'Session object created');
    isa_ok($session, 'Protocol::HAP::Session');
    is($session->id, 1, 'Session carries the id the server gave it');
    ok(!$session->is_encrypted(), 'Session not encrypted by default');
    ok(!$session->is_verified(), 'Session not verified by default');
}

# The id is required: the server allocates it, the session never
# invents one
{
    ok(!eval { Protocol::HAP::Session->new; 1 },
        'a session without an id is a programming error');
}

# Test encryption setup
{
    my $session = Protocol::HAP::Session->new(id => 2);

    my $encrypt_key = Protocol::HAP::Crypto->random_bytes(32);
    my $decrypt_key = Protocol::HAP::Crypto->random_bytes(32);

    $session->set_encryption($encrypt_key, $decrypt_key);

    ok($session->is_encrypted(), 'Session is encrypted after setup');
}

# Test verification
{
    my $session = Protocol::HAP::Session->new(id => 3);

    $session->set_verified('controller-123');

    ok($session->is_verified(), 'Session is verified');
    is($session->controller_id(), 'controller-123', 'Controller ID stored');
}

# Test encryption/decryption
SKIP: {
    eval {
        require Crypt::AuthEnc::ChaCha20Poly1305;
    };
    skip 'ChaCha20Poly1305 not available', 4 if $@;

    my $session = Protocol::HAP::Session->new(id => 4);

    my $key = Protocol::HAP::Crypto->random_bytes(32);
    $session->set_encryption($key, $key);

    my $plaintext = "Test message";
    my $encrypted = $session->encrypt($plaintext);

    ok(defined $encrypted, 'Data encrypted');
    isnt($encrypted, $plaintext, 'Encrypted data differs from plaintext');

    # Create a new session with the same keys for decryption
    my $session2 = Protocol::HAP::Session->new(id => 5);
    $session2->set_encryption($key, $key);

    my $decrypted = $session2->decrypt($encrypted);
    ok(defined $decrypted, 'Data decrypted');
    is($decrypted, $plaintext, 'Decrypted data matches original');
}

# Test encryption of longer data (multiple chunks)
SKIP: {
    eval {
        require Crypt::AuthEnc::ChaCha20Poly1305;
    };
    skip 'ChaCha20Poly1305 not available', 2 if $@;

    my $session = Protocol::HAP::Session->new(id => 6);
    my $key = Protocol::HAP::Crypto->random_bytes(32);
    $session->set_encryption($key, $key);

    # Data larger than chunk size (1024 bytes)
    my $long_plaintext = "A" x 2500;
    my $encrypted = $session->encrypt($long_plaintext);

    ok(defined $encrypted, 'Long data encrypted');

    my $session2 = Protocol::HAP::Session->new(id => 7);
    $session2->set_encryption($key, $key);
    my $decrypted = $session2->decrypt($encrypted);

    is($decrypted, $long_plaintext, 'Long data decrypted correctly');
}

# Test pairing state storage
{
    my $session = Protocol::HAP::Session->new(id => 8);

    $session->{pairing_state}{test_key} = 'test_value';
    is($session->{pairing_state}{test_key}, 'test_value', 'Pairing state stored');
}

# The session holds no socket: the server owns descriptors, the
# session owns protocol state
{
    my $session = Protocol::HAP::Session->new(id => 9);
    ok(!exists $session->{socket}, 'the session holds no socket');
}

done_testing();
