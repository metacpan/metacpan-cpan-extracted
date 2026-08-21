package Crypt::Age::Primitives;
# ABSTRACT: Low-level cryptographic primitives for age encryption
our $VERSION = '0.002';
use Moo;
use Carp qw(croak);
use Crypt::PK::X25519;
use Crypt::AuthEnc::ChaCha20Poly1305;
use Crypt::KeyDerivation qw(hkdf);
use Crypt::Mac::HMAC qw(hmac);
use Crypt::PRNG qw(random_bytes);

use constant READ_ATTEMPTS => 3;

use namespace::clean;


# Constants from age spec
use constant {
    FILE_KEY_SIZE    => 16,
    X25519_KEY_SIZE  => 32,
    CHUNK_SIZE       => 64 * 1024,  # 64 KiB
    NONCE_SIZE       => 12,
    TAG_SIZE         => 16,
};

# HKDF labels from age spec
use constant {
    LABEL_X25519     => "age-encryption.org/v1/X25519",
    LABEL_HEADER     => "header",
    LABEL_PAYLOAD    => "payload",
};

sub generate_file_key {
    return random_bytes(FILE_KEY_SIZE);
}


sub x25519_generate_keypair {
    my ($class) = @_;
    my $pk = Crypt::PK::X25519->new;
    $pk->generate_key;
    return ($pk->export_key_raw('public'), $pk->export_key_raw('private'));
}


sub x25519_shared_secret {
    my ($class, $our_private, $their_public) = @_;

    my $our_pk = Crypt::PK::X25519->new;
    $our_pk->import_key_raw($our_private, 'private');

    my $their_pk = Crypt::PK::X25519->new;
    $their_pk->import_key_raw($their_public, 'public');

    my $shared_secret = $our_pk->shared_secret($their_pk);

    # c2sp.org/age, X25519 recipient type: "If the shared secret is all 0x00
    # bytes, the identity implementation MUST abort." That is the low-order
    # point check. The peer key is public, so this comparison does not need to
    # be constant time. Recent CryptX/libtomcrypt rejects such peer keys inside
    # shared_secret() with its own error, but the cpanfile pins no minimum
    # CryptX version and the spec puts the duty on us, so we check regardless.
    croak "X25519 shared secret is all zero: peer key is a low-order point"
        if $shared_secret !~ /[^\x00]/;

    return $shared_secret;
}


sub derive_wrap_key {
    my ($class, $shared_secret, $ephemeral_public, $recipient_public) = @_;

    # salt = ephemeral_public || recipient_public
    my $salt = $ephemeral_public . $recipient_public;

    # hkdf($secret, $salt, $hash, $length, $info)
    return hkdf($shared_secret, $salt, 'SHA256', 32, LABEL_X25519);
}


sub wrap_file_key {
    my ($class, $wrap_key, $file_key) = @_;

    croak "Wrap key must be 32 bytes" unless length($wrap_key) == 32;
    croak "File key must be 16 bytes" unless length($file_key) == FILE_KEY_SIZE;

    # ChaCha20-Poly1305 with zero nonce
    my $nonce = "\x00" x NONCE_SIZE;
    my $ae = Crypt::AuthEnc::ChaCha20Poly1305->new($wrap_key, $nonce);
    my $ciphertext = $ae->encrypt_add($file_key);
    my $tag = $ae->encrypt_done;

    return $ciphertext . $tag;
}


sub unwrap_file_key {
    my ($class, $wrap_key, $wrapped_key) = @_;

    croak "Wrap key must be 32 bytes" unless length($wrap_key) == 32;
    croak "Wrapped key must be 32 bytes" unless length($wrapped_key) == FILE_KEY_SIZE + TAG_SIZE;

    my $ciphertext = substr($wrapped_key, 0, FILE_KEY_SIZE);
    my $tag = substr($wrapped_key, FILE_KEY_SIZE, TAG_SIZE);

    my $nonce = "\x00" x NONCE_SIZE;
    my $ae = Crypt::AuthEnc::ChaCha20Poly1305->new($wrap_key, $nonce);
    my $file_key = $ae->decrypt_add($ciphertext);

    croak "Authentication failed" unless $ae->decrypt_done($tag);

    return $file_key;
}


sub derive_payload_key {
    my ($class, $file_key, $nonce) = @_;

    croak "nonce required" unless defined $nonce;
    croak "nonce must be 16 bytes" unless length($nonce) == 16;

    # Derive payload key using HKDF
    # hkdf($secret, $salt, $hash, $length, $info)
    # The nonce is used as salt, and "payload" is the info string
    return hkdf($file_key, $nonce, 'SHA256', 32, LABEL_PAYLOAD);
}

sub generate_payload_nonce {
    return random_bytes(16);
}


sub compute_header_mac {
    my ($class, $file_key, $header_bytes) = @_;

    # Derive MAC key using HKDF
    # hkdf($secret, $salt, $hash, $length, $info)
    my $mac_key = hkdf($file_key, '', 'SHA256', 32, LABEL_HEADER);

    return hmac('SHA256', $mac_key, $header_bytes);
}


sub encrypt_payload {
    my ($class, $payload_key, $plaintext) = @_;

    open my $ifh, '<:raw', \$plaintext or croak "Cannot open input string: $!";

    my $output = '';
    open my $ofh, '>:raw', \$output or croak "Cannot open output string: $!";

    $class->encrypt_payload_fh($payload_key, $ifh, $ofh);

    close $ofh or croak "Cannot close output string: $!";
    close $ifh  or croak "Cannot close input string: $!";

    return $output;
}


sub encrypt_payload_fh {
    my ($class, $payload_key, $ifh, $ofh) = @_;

    my $counter = 0;
    my $is_final = 0;
    while (! $is_final) {
        my $chunk = $class->paranoid_read($ifh, CHUNK_SIZE);
        $is_final = eof($ifh);

        my $nonce = $class->_make_nonce($counter, $is_final);
        my $ae = Crypt::AuthEnc::ChaCha20Poly1305->new($payload_key, $nonce);

        my $ciphertext = $ae->encrypt_add($chunk);
        my $tag = $ae->encrypt_done;

        print {$ofh} $ciphertext, $tag;

        $counter++;
    }

    return;
}


sub decrypt_payload {
    my ($class, $payload_key, $ciphertext) = @_;

    open my $ifh, '<:raw', \$ciphertext or croak "Cannot open input string: $!";

    my $output = '';
    open my $ofh, '>:raw', \$output or croak "Cannot open output string: $!";

    $class->decrypt_payload_fh($payload_key, $ifh, $ofh);

    close $ofh or croak "Cannot close output string: $!";
    close $ifh  or croak "Cannot close input string: $!";

    return $output;
}


sub decrypt_payload_fh {
    my ($class, $payload_key, $ifh, $ofh) = @_;

    my $max_encrypted_chunk = CHUNK_SIZE + TAG_SIZE;
    my $counter = 0;
    while (1) {
        # Each encrypted chunk is plaintext + 16 byte tag
        my $ct = $class->paranoid_read($ifh, $max_encrypted_chunk);

        # paranoid_read only comes back short at end of file, so a short read
        # is how this loop learns the file ends here. A *full* read says
        # nothing either way: more chunks may follow, or this may be the final
        # chunk sitting flush against the end of the file.
        my $short_read = length($ct) < $max_encrypted_chunk;

        if ($short_read) {
            # Spec: "Streaming decryption MUST signal an error if the end of
            # file is reached without successfully decrypting a final chunk."
            croak 'Payload authentication failed at chunk '.$counter
                . ': end of file reached without a final chunk'
                if length($ct) == 0;
            croak 'Payload authentication failed at chunk '.$counter
                . ': chunk is shorter than its authentication tag'
                if length($ct) < TAG_SIZE;
            # Spec: "The final chunk MAY be shorter than 64 KiB but MUST NOT
            # be empty unless the whole payload is empty."
            croak 'Payload authentication failed at chunk '.$counter
                . ': final chunk is empty and is not the only chunk'
                if length($ct) == TAG_SIZE && $counter > 0;
        }

        my $tag = substr($ct, -TAG_SIZE, TAG_SIZE, '');

        # The final-chunk flag lives in the nonce, so the only way to learn
        # which nonce the writer used is to authenticate under it -- the
        # file's length cannot answer it. A short chunk can only be the final
        # one. A full chunk is tried as non-final first and, failing that, as
        # a full-length final chunk. No ciphertext can authenticate under both
        # nonces, so the second attempt cannot accept a chunk the writer did
        # not mark that way: it is a second verification, not a second chance.
        my $is_final = $short_read ? 1 : 0;
        my $plaintext = $class->_open_chunk($payload_key, $counter, $is_final, $ct, $tag);
        if (! defined($plaintext) && ! $is_final) {
            $is_final = 1;
            $plaintext = $class->_open_chunk($payload_key, $counter, $is_final, $ct, $tag);
        }
        croak "Payload authentication failed at chunk $counter" unless defined $plaintext;

        print {$ofh} $plaintext;

        if ($is_final) {
            # A final chunk ends the payload, so anything still in the file
            # invalidates it -- trailing garbage as much as another
            # well-formed chunk.
            croak 'Payload authentication failed at chunk '.$counter
                . ': trailing data after the final chunk'
                if length($class->paranoid_read($ifh, 1));
            return;
        }

        $counter++;
    }
}


sub _open_chunk {
    my ($class, $payload_key, $counter, $is_final, $ciphertext, $tag) = @_;

    my $nonce = $class->_make_nonce($counter, $is_final);
    my $ae = Crypt::AuthEnc::ChaCha20Poly1305->new($payload_key, $nonce);

    # decrypt_add hands back unauthenticated plaintext, so it is only returned
    # to the caller once decrypt_done has verified the tag over it.
    my $plaintext = $ae->decrypt_add($ciphertext);
    return unless $ae->decrypt_done($tag);

    return $plaintext;
}

sub _make_nonce {
    my ($class, $counter, $is_final) = @_;

    # 11 bytes counter (big-endian) + 1 byte final flag
    my $nonce = "\x00" x 3;  # First 3 bytes zero
    $nonce .= pack('N', ($counter >> 32) & 0xFFFFFFFF);  # Next 4 bytes
    $nonce .= pack('N', $counter & 0xFFFFFFFF);          # Next 4 bytes
    $nonce .= pack('C', $is_final ? 1 : 0);              # Last byte: final flag

    return $nonce;
}

sub paranoid_read {
    my ($class, $fh, $length) = @_;
    my $retval = '';
    my $attempts = READ_ATTEMPTS;
    while ($length > 0 && $attempts > 0) {
        my $buffer = '';
        my $n_read = read($fh, $buffer, $length);
        croak "read(): $!" if ! defined($n_read);
        if ($n_read == 0) {
            last if eof($fh); # no more data, we're good
            --$attempts;
            next;
        }

        # reset attempts after successful read of *some* data
        $attempts = READ_ATTEMPTS;
        $retval .= $buffer;
        $length -= $n_read;
    }
    return $retval if $attempts > 0;
    croak "could not get requested data up to the end";
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Age::Primitives - Low-level cryptographic primitives for age encryption

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use Crypt::Age::Primitives;

    # Generate random file key
    my $file_key = Crypt::Age::Primitives->generate_file_key();

    # X25519 key exchange
    my ($pub, $priv) = Crypt::Age::Primitives->x25519_generate_keypair();
    my $secret = Crypt::Age::Primitives->x25519_shared_secret($our_priv, $their_pub);

    # Key derivation and wrapping
    my $wrap_key = Crypt::Age::Primitives->derive_wrap_key($secret, $eph_pub, $rec_pub);
    my $wrapped = Crypt::Age::Primitives->wrap_file_key($wrap_key, $file_key);
    my $unwrapped = Crypt::Age::Primitives->unwrap_file_key($wrap_key, $wrapped);

    # Payload encryption
    my $payload_key = Crypt::Age::Primitives->derive_payload_key($file_key);
    my $encrypted = Crypt::Age::Primitives->encrypt_payload($payload_key, $plaintext);
    my $decrypted = Crypt::Age::Primitives->decrypt_payload($payload_key, $encrypted);

    # Header MAC
    my $mac = Crypt::Age::Primitives->compute_header_mac($file_key, $header_bytes);

=head1 DESCRIPTION

This module provides low-level cryptographic primitives for age encryption.
It wraps functions from L<CryptX> and implements the age-specific key
derivation and payload encryption schemes.

This is an internal module used by L<Crypt::Age>. Most users should use the
high-level interface provided by L<Crypt::Age> instead.

=head2 Cryptographic Primitives Used

=over 4

=item * X25519 - Key exchange (Curve25519 Diffie-Hellman)

=item * ChaCha20-Poly1305 - AEAD encryption

=item * HKDF-SHA256 - Key derivation

=item * HMAC-SHA256 - Header MAC

=back

=head2 generate_file_key

    my $file_key = Crypt::Age::Primitives->generate_file_key();

Generates a random 16-byte file key using a cryptographically secure PRNG.

The file key is used to encrypt the payload and is itself encrypted for each
recipient.

=head2 x25519_generate_keypair

    my ($public_bytes, $private_bytes) = Crypt::Age::Primitives->x25519_generate_keypair();

Generates a new X25519 keypair. Returns raw 32-byte public and private keys.

Note: For generating age-encoded keypairs, use L<Crypt::Age::Keys/generate_keypair>
instead.

=head2 x25519_shared_secret

    my $shared_secret = Crypt::Age::Primitives->x25519_shared_secret($our_private, $their_public);

Performs X25519 key exchange to compute a shared secret.

Parameters are raw 32-byte keys. Returns a 32-byte shared secret.

Dies if the shared secret is all C<0x00> bytes, which the age specification
requires ("If the shared secret is all 0x00 bytes, the identity implementation
MUST abort"). Such a secret means the peer key is a low-order point: on the
decrypt path an attacker-supplied ephemeral share, on the encrypt path a
recipient key that would yield a wrapping key known to everyone. The error
message carries no key or secret material.

Note that this is a backstop: a sufficiently recent L<CryptX> refuses the same
peer keys one layer down and dies with its own message before this check is
reached.

=head2 derive_wrap_key

    my $wrap_key = Crypt::Age::Primitives->derive_wrap_key(
        $shared_secret,
        $ephemeral_public,
        $recipient_public
    );

Derives a wrapping key from an X25519 shared secret using HKDF-SHA256.

The salt is C<ephemeral_public || recipient_public> (concatenated).
The info string is C<"age-encryption.org/v1/X25519">.

Returns a 32-byte key suitable for wrapping the file key.

=head2 wrap_file_key

    my $wrapped_key = Crypt::Age::Primitives->wrap_file_key($wrap_key, $file_key);

Wraps a 16-byte file key using ChaCha20-Poly1305 with a zero nonce.

Returns a 32-byte value: 16 bytes ciphertext + 16 bytes authentication tag.

=head2 unwrap_file_key

    my $file_key = Crypt::Age::Primitives->unwrap_file_key($wrap_key, $wrapped_key);

Unwraps a wrapped file key using ChaCha20-Poly1305.

Dies if authentication fails. Returns the 16-byte file key on success.

=head2 derive_payload_key

    my $payload_key = Crypt::Age::Primitives->derive_payload_key($file_key, $nonce);

Derives a 32-byte payload encryption key from the file key and nonce using HKDF-SHA256.

The nonce (16 bytes) is used as the salt, and C<"payload"> is the info string.

=head2 generate_payload_nonce

    my $nonce = Crypt::Age::Primitives->generate_payload_nonce();

Generates a random 16-byte nonce for payload encryption.

=head2 compute_header_mac

    my $mac = Crypt::Age::Primitives->compute_header_mac($file_key, $header_bytes);

Computes HMAC-SHA256 MAC over the header bytes.

First derives a MAC key from the file key using HKDF with info string C<"header">,
then computes HMAC-SHA256 of the header. Returns 32 bytes.

=head2 encrypt_payload

    my $ciphertext = Crypt::Age::Primitives->encrypt_payload($payload_key, $plaintext);

Encrypts the payload using ChaCha20-Poly1305 in chunked mode.

The plaintext is split into 64 KiB chunks. Each chunk is encrypted with a unique
nonce derived from a counter and a final-chunk flag. Returns the concatenated
encrypted chunks.

=head2 encrypt_payload_fh

    my $ciphertext = Crypt::Age::Primitives->encrypt_payload_fh($payload_key, $ifh, $ofh);

Encrypts the payload using ChaCha20-Poly1305 in chunked mode, using filehandles
for both input and output.

The plaintext is split into 64 KiB chunks. Each chunk is encrypted with a unique
nonce derived from a counter and a final-chunk flag. Returns the concatenated
encrypted chunks.

=head2 decrypt_payload

    my $plaintext = Crypt::Age::Primitives->decrypt_payload($payload_key, $ciphertext);

Decrypts a chunked payload encrypted with C<encrypt_payload>.

Returns the decrypted plaintext. Dies on everything L</decrypt_payload_fh>
dies on -- a chunk that fails authentication, input ending without a final
chunk, an empty final chunk that is not the whole payload, or data after the
final chunk.

Unlike L</decrypt_payload_fh> this method releases nothing on failure: the
partial plaintext is written to an internal buffer that is discarded when the
call dies, so a caller only ever sees plaintext from a payload that was
decrypted to its final chunk. Callers that need the streaming behaviour, and
can handle the partial release that comes with it, want the filehandle form.

=head2 decrypt_payload_fh

    Crypt::Age::Primitives->decrypt_payload_fh($payload_key, $ifh, $ofh);

Decrypts a chunked payload encrypted with C<encrypt_payload>, reading the
ciphertext from C<$ifh> and writing the plaintext to C<$ofh> one chunk at a
time. Returns nothing.

A chunk is final because it authenticates under the final-flag nonce, never
because it happens to end the file. Dies if a chunk fails authentication under
either nonce, if the input ends without a final chunk, if a final chunk other
than the whole payload is empty, or if any byte follows the final chunk.

B<On failure, plaintext already written to C<$ofh> stays there.> Decryption is
streaming, so every chunk that authenticated before the error was released to
the output handle: a truncated file yields its intact prefix and then dies. Each
released chunk is individually authenticated, but the message as a whole is not
-- its completeness is exactly what the error says was never established. A
caller must therefore discard whatever reached C<$ofh> when this method dies,
and must not treat it as an authenticated message merely because the individual
bytes were authentic.

=head1 SEE ALSO

=over 4

=item * L<Crypt::Age> - Main age encryption module

=item * L<CryptX> - Provides all cryptographic primitives

=item * L<Crypt::PK::X25519> - X25519 key exchange

=item * L<Crypt::AuthEnc::ChaCha20Poly1305> - AEAD encryption

=item * L<Crypt::KeyDerivation> - HKDF implementation

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-crypt-age/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
