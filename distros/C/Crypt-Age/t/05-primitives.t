#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Crypt::AuthEnc::ChaCha20Poly1305;
use Crypt::PK::X25519;
use Digest::SHA qw( sha256_hex );
use Crypt::Age::Primitives;

# Sanity: a normal exchange still works and both sides agree
{
    my ($pub_a, $priv_a) = Crypt::Age::Primitives->x25519_generate_keypair;
    my ($pub_b, $priv_b) = Crypt::Age::Primitives->x25519_generate_keypair;

    my $secret_a = Crypt::Age::Primitives->x25519_shared_secret($priv_a, $pub_b);
    my $secret_b = Crypt::Age::Primitives->x25519_shared_secret($priv_b, $pub_a);

    is(length($secret_a), 32, 'shared secret is 32 bytes');
    is($secret_a, $secret_b, 'both sides derive the same shared secret');
    isnt($secret_a, "\x00" x 32, 'a normal shared secret is not all zero');
}

# c2sp.org/age, X25519 recipient type: "If the shared secret is all 0x00
# bytes, the identity implementation MUST abort."
#
# The peer keys that trigger this are the low-order points of Curve25519. A
# recent CryptX/libtomcrypt rejects them one layer down, inside
# shared_secret(), so on such a build our own check is never reached with a
# real key. The cpanfile pins no minimum CryptX version and the spec puts the
# duty on us, so the check has to hold on its own: stub the backend out to
# hand us the all-zero secret an older CryptX would have returned, and assert
# that we abort on it.
{
    my ($pub, $priv) = Crypt::Age::Primitives->x25519_generate_keypair;

    my $secret = do {
        no warnings 'redefine';
        local *Crypt::PK::X25519::shared_secret = sub { return "\x00" x 32 };
        eval { Crypt::Age::Primitives->x25519_shared_secret($priv, $pub) };
    };
    my $error = $@;

    ok(!defined $secret, 'all-zero shared secret is not returned to the caller');
    ok($error, 'x25519_shared_secret aborts on an all-zero shared secret');
    like($error, qr/all zero/, 'error names the all-zero shared secret');

    # Keys, identities and secrets never appear in an error message.
    unlike($error, qr/\Q$priv\E/, 'error does not leak the private key');
    unlike($error, qr/\Q$pub\E/,  'error does not leak the peer public key');
    unlike($error, qr/\x00{8}/,   'error does not leak the shared secret');
}

# Defense in depth: the real thing. On CryptX 0.091 this dies inside
# shared_secret() before our check is reached, so this assertion does not
# distinguish the fixed from the unfixed code here -- it pins down that an
# all-zero peer key never yields a usable secret, whoever refuses it.
{
    my ($pub, $priv) = Crypt::Age::Primitives->x25519_generate_keypair;

    my $secret = eval {
        Crypt::Age::Primitives->x25519_shared_secret($priv, "\x00" x 32);
    };

    ok(!defined $secret, 'an all-zero peer key yields no shared secret');
    ok($@, 'an all-zero peer key is rejected');
}

# STREAM nonce, spec: "The first 11 bytes are a big endian chunk counter
# starting at zero and incrementing by one for each subsequent chunk; the last
# byte is 0x01 for the final chunk and 0x00 for all preceding ones."
#
# Wire format, so the expected values are written out literally rather than
# rebuilt from the same construction the code uses.
{
    my @cases = (
        [0,          0, '000000000000000000000000', 'counter 0, not final'],
        [0,          1, '000000000000000000000001', 'counter 0, final'],
        [1,          0, '000000000000000000000100', 'counter 1, not final'],
        [1,          1, '000000000000000000000101', 'counter 1, final'],
        [255,        0, '00000000000000000000ff00', 'counter 255, not final'],
        [2**32,      0, '000000000000010000000000', 'counter 2**32, not final'],
    );

    for my $case (@cases) {
        my ($counter, $is_final, $expect_hex, $name) = @$case;
        my $nonce = Crypt::Age::Primitives->_make_nonce($counter, $is_final);
        is(length($nonce), 12, "nonce is 12 bytes ($name)");
        is(unpack('H*', $nonce), $expect_hex, "nonce bytes ($name)");
    }
}

# The payload chunking uses those nonces. Build the expected ciphertext from
# ChaCha20-Poly1305 and literal nonces, independently of _make_nonce, so this
# fails if the nonce construction or the chunk boundary moves.
{
    my $payload_key = pack('H*', '00' x 32);

    # Single chunk: counter 0, final.
    my $plaintext = 'age';
    my $expected  = _seal($payload_key, pack('H*', '000000000000000000000001'), $plaintext);

    is(
        Crypt::Age::Primitives->encrypt_payload($payload_key, $plaintext),
        $expected,
        'single chunk uses the final-flag nonce at counter 0'
    );

    # Two chunks: a full 64 KiB chunk (counter 0, not final) plus one byte
    # (counter 1, final).
    my $chunk_size = 64 * 1024;
    my $first      = 'a' x $chunk_size;
    my $second     = 'b';
    my $expected_2 =
        _seal($payload_key, pack('H*', '000000000000000000000000'), $first) .
        _seal($payload_key, pack('H*', '000000000000000000000101'), $second);

    is(
        Crypt::Age::Primitives->encrypt_payload($payload_key, $first . $second),
        $expected_2,
        'a 64 KiB + 1 byte payload splits into two chunks with counter 0 and 1'
    );
}

# STREAM finality, spec: "the last byte is 0x01 for the final chunk and 0x00
# for all preceding ones", "The final chunk MAY be shorter than 64 KiB but
# MUST NOT be empty unless the whole payload is empty", and "Streaming
# decryption MUST signal an error if the end of file is reached without
# successfully decrypting a final chunk."
#
# Which chunk is final is therefore stated by the nonce the writer
# authenticated it with -- never by "the file happened to end here" -- and a
# chunk that does authenticate as final has to be the last thing in the file.
#
# Every ciphertext below is built literally from Crypt::AuthEnc::ChaCha20Poly1305
# and hand-written nonces rather than through encrypt_payload_fh, because our
# own writer cannot produce any of these shapes: it always marks its true last
# chunk final and never appends anything after it. That is precisely why no
# round trip through this library -- unit or interop -- ever caught them.
{
    my $payload_key = pack('H*', '00' x 32);
    my $chunk_size  = 64 * 1024;

    my $nonce_0     = pack('H*', '000000000000000000000000');  # counter 0, not final
    my $nonce_0_fin = pack('H*', '000000000000000000000001');  # counter 0, final
    my $nonce_1_fin = pack('H*', '000000000000000000000101');  # counter 1, final

    my $full = 'a' x $chunk_size;

    # A full final chunk followed by bytes that are not a chunk at all.
    {
        my ($released, $error) = _decrypt_payload_capture(
            $payload_key,
            _seal($payload_key, $nonce_0_fin, $full) . 'garbage'
        );
        ok($error, 'trailing garbage after a final chunk is rejected');
        _released_is($released, $full, 'the final chunk was still released before the error');
    }

    # A full final chunk followed by another well-formed chunk.
    {
        my ($released, $error) = _decrypt_payload_capture(
            $payload_key,
            _seal($payload_key, $nonce_0_fin, $full) .
            _seal($payload_key, $nonce_1_fin, 'tail')
        );
        ok($error, 'a second chunk after a final chunk is rejected');
        _released_is($released, $full, 'only the final chunk was released, never the one after it');
    }

    # A full chunk carrying the NOT-final nonce with nothing after it: the file
    # ends without a final chunk, so it must fail -- but that chunk did
    # authenticate under the nonce it was written with, so its plaintext is
    # released first. Deciding finality from eof() instead would decrypt it
    # under the final-flag nonce, fail the tag check, and release nothing.
    {
        my ($released, $error) = _decrypt_payload_capture(
            $payload_key,
            _seal($payload_key, $nonce_0, $full)
        );
        ok($error, 'a file ending without a final chunk is rejected');
        _released_is($released, $full, 'the authenticated non-final chunk was released before the error');
    }

    # An empty final chunk is legal only when the whole payload is empty.
    {
        my ($released, $error) = _decrypt_payload_capture(
            $payload_key,
            _seal($payload_key, $nonce_0, $full) .
            _seal($payload_key, $nonce_1_fin, '')
        );
        ok($error, 'an empty final chunk that is not the only chunk is rejected');
        _released_is($released, $full, 'the preceding chunk was released before the error');
    }

    # The two shapes right next door, which must keep working: a full chunk
    # that really is marked final and really does end the file, and the empty
    # payload, the one case where an empty final chunk is required.
    {
        my ($released, $error) = _decrypt_payload_capture(
            $payload_key,
            _seal($payload_key, $nonce_0_fin, $full)
        );
        is($error, undef, 'a full final chunk at end of file still decrypts');
        _released_is($released, $full, 'a full final chunk releases its plaintext');
    }

    {
        my ($released, $error) = _decrypt_payload_capture(
            $payload_key,
            _seal($payload_key, $nonce_0_fin, '')
        );
        is($error, undef, 'an empty payload is a single empty final chunk and still decrypts');
        _released_is($released, '', 'an empty payload releases nothing');
    }

    # No error message may carry key or plaintext material.
    {
        my (undef, $error) = _decrypt_payload_capture(
            $payload_key,
            _seal($payload_key, $nonce_0_fin, $full) . 'garbage'
        );
        unlike($error, qr/\Q$payload_key\E/, 'error does not leak the payload key');
        unlike($error, qr/aaaaaaaa/,         'error does not leak plaintext');
    }
}

# Runs decrypt_payload_fh over a ciphertext held in memory and reports both
# halves of its contract: what reached the output handle, and whether it died.
# Reading that handle after a die is the point -- partial release is part of
# the documented behaviour here, not an accident.
sub _decrypt_payload_capture {
    my ($payload_key, $ciphertext) = @_;

    open my $ifh, '<:raw', \$ciphertext or die "open input scalar fh: $!";
    my $released = '';
    open my $ofh, '>:raw', \$released or die "open output scalar fh: $!";

    my $error;
    unless (eval { Crypt::Age::Primitives->decrypt_payload_fh($payload_key, $ifh, $ofh); 1 }) {
        $error = $@;
    }

    close $ofh;
    close $ifh;

    return ($released, $error);
}

# 64 KiB of plaintext in a Test::More diff is unreadable, so compare the length
# and a digest rather than the bytes.
sub _released_is {
    my ($released, $expected, $name) = @_;
    is(length($released), length($expected), "$name (length)");
    is(sha256_hex($released), sha256_hex($expected), "$name (content)");
}

sub _seal {
    my ($key, $nonce, $plaintext) = @_;
    my $ae = Crypt::AuthEnc::ChaCha20Poly1305->new($key, $nonce);
    my $ciphertext = $ae->encrypt_add($plaintext);
    return $ciphertext . $ae->encrypt_done;
}

done_testing;
