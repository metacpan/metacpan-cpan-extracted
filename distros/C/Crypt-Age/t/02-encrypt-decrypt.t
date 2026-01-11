#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use Crypt::Age;

# Basic roundtrip
{
    my ($public, $secret) = Crypt::Age->generate_keypair;
    my $plaintext = "Hello, World!";

    my $encrypted = Crypt::Age->encrypt(
        plaintext  => $plaintext,
        recipients => [$public],
    );

    ok(defined $encrypted, 'encryption succeeded');
    like($encrypted, qr/^age-encryption\.org\/v1\n/, 'encrypted data has age header');

    my $decrypted = Crypt::Age->decrypt(
        ciphertext => $encrypted,
        identities => [$secret],
    );

    is($decrypted, $plaintext, 'roundtrip successful');
}

# Empty plaintext
{
    my ($public, $secret) = Crypt::Age->generate_keypair;

    my $encrypted = Crypt::Age->encrypt(
        plaintext  => "",
        recipients => [$public],
    );

    my $decrypted = Crypt::Age->decrypt(
        ciphertext => $encrypted,
        identities => [$secret],
    );

    is($decrypted, "", 'empty plaintext roundtrip');
}

# Large plaintext (multiple chunks)
{
    my ($public, $secret) = Crypt::Age->generate_keypair;
    my $plaintext = "x" x (64 * 1024 * 3 + 1000);  # ~192KB + 1000 bytes

    my $encrypted = Crypt::Age->encrypt(
        plaintext  => $plaintext,
        recipients => [$public],
    );

    my $decrypted = Crypt::Age->decrypt(
        ciphertext => $encrypted,
        identities => [$secret],
    );

    is($decrypted, $plaintext, 'large plaintext roundtrip');
}

# Binary data
{
    my ($public, $secret) = Crypt::Age->generate_keypair;
    my $plaintext = join('', map { chr($_) } 0..255) x 10;

    my $encrypted = Crypt::Age->encrypt(
        plaintext  => $plaintext,
        recipients => [$public],
    );

    my $decrypted = Crypt::Age->decrypt(
        ciphertext => $encrypted,
        identities => [$secret],
    );

    is($decrypted, $plaintext, 'binary data roundtrip');
}

# Multiple recipients
{
    my ($public1, $secret1) = Crypt::Age->generate_keypair;
    my ($public2, $secret2) = Crypt::Age->generate_keypair;
    my $plaintext = "For multiple recipients";

    my $encrypted = Crypt::Age->encrypt(
        plaintext  => $plaintext,
        recipients => [$public1, $public2],
    );

    # Decrypt with first identity
    my $decrypted1 = Crypt::Age->decrypt(
        ciphertext => $encrypted,
        identities => [$secret1],
    );
    is($decrypted1, $plaintext, 'decrypt with first recipient');

    # Decrypt with second identity
    my $decrypted2 = Crypt::Age->decrypt(
        ciphertext => $encrypted,
        identities => [$secret2],
    );
    is($decrypted2, $plaintext, 'decrypt with second recipient');
}

# Wrong identity should fail
{
    my ($public1, $secret1) = Crypt::Age->generate_keypair;
    my ($public2, $secret2) = Crypt::Age->generate_keypair;

    my $encrypted = Crypt::Age->encrypt(
        plaintext  => "Secret",
        recipients => [$public1],
    );

    eval {
        Crypt::Age->decrypt(
            ciphertext => $encrypted,
            identities => [$secret2],
        );
    };
    like($@, qr/No matching identity/, 'wrong identity fails');
}

# File operations
{
    my ($public, $secret) = Crypt::Age->generate_keypair;
    my $plaintext = "File content test\nWith newlines\n";

    my ($in_fh, $in_file) = tempfile(UNLINK => 1);
    print $in_fh $plaintext;
    close $in_fh;

    my (undef, $enc_file) = tempfile(UNLINK => 1);
    my (undef, $out_file) = tempfile(UNLINK => 1);

    Crypt::Age->encrypt_file(
        input      => $in_file,
        output     => $enc_file,
        recipients => [$public],
    );

    ok(-s $enc_file > 0, 'encrypted file created');

    Crypt::Age->decrypt_file(
        input      => $enc_file,
        output     => $out_file,
        identities => [$secret],
    );

    open my $fh, '<:raw', $out_file;
    my $decrypted = do { local $/; <$fh> };
    close $fh;

    is($decrypted, $plaintext, 'file roundtrip successful');
}

# Error handling
{
    eval { Crypt::Age->encrypt(recipients => ['age1abc']) };
    like($@, qr/plaintext required/, 'encrypt requires plaintext');

    eval { Crypt::Age->encrypt(plaintext => 'x') };
    like($@, qr/recipients required/, 'encrypt requires recipients');

    eval { Crypt::Age->encrypt(plaintext => 'x', recipients => []) };
    like($@, qr/at least one recipient/, 'encrypt requires non-empty recipients');

    eval { Crypt::Age->decrypt(identities => ['AGE-SECRET-KEY-1ABC']) };
    like($@, qr/ciphertext required/, 'decrypt requires ciphertext');
}

done_testing;
