#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use Crypt::Age;
use Crypt::Age::Header;

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

# Filehandle operations
{
    my ($public, $secret) = Crypt::Age->generate_keypair;
    my $plaintext = "File content test\nWith newlines\n";

    my ($in_fh, $in_file) = tempfile(UNLINK => 1);
    print $in_fh $plaintext;
    close $in_fh;

    my $enc_data = '';
    {
        open my $in_fh, '<', $in_file or die "open($in_file): $!";
        open my $out_fh, '>', \$enc_data or die "open() string for output: $!";
        Crypt::Age->encrypt_filehandle(
            input      => $in_fh,
            output     => $out_fh,
            recipients => [$public],
        );
    }
    ok length($enc_data), 'encrypted data generated';

    my $decrypted;
    {
        my ($enc_fh, $enc_file) = tempfile(UNLINK => 1);
        print $enc_fh $enc_data;
        close $enc_fh;
        $enc_fh = undef;
        open $enc_fh, '<', $enc_file or die "open($enc_file): $!";

        my ($out_fh, $out_file) = tempfile(UNLINK => 1);
        Crypt::Age->decrypt_filehandle(
            input      => $enc_fh,
            output     => $out_fh,
            identities => [$secret],
        );
        close $out_fh;
        close $enc_fh;

        open my $fh, '<:raw', $out_file;
        $decrypted = do { local $/; <$fh> };
        close $fh;

    }
    is($decrypted, $plaintext, 'file roundtrip successful');

}

# Truncated files. On main (commit a830d60, before PR #3) a payload-less
# file -- a valid header and nonce followed by zero payload bytes -- decrypted
# silently to the empty string (karr #6): decrypt_payload's substr-arithmetic
# loop never ran for zero remaining bytes. The spec requires signaling an
# error when EOF is reached without a final chunk. PR #3's read()/eof()-based
# payload path croaks instead, incidentally via AEAD tag verification on an
# empty/short tag. The other two cases (short nonce, payload shorter than the
# tag) are adjacent truncation shapes for the same read/eof path; both already
# raised an error before PR #3 too, so they are safety-net coverage rather
# than a red/green regression, but are cheap to pin down alongside karr #6.
{
    my ($public, $secret) = Crypt::Age->generate_keypair;
    my $plaintext = "x" x 128;

    my $full = Crypt::Age->encrypt(plaintext => $plaintext, recipients => [$public]);

    my $offset = 0;
    Crypt::Age::Header->parse(\$full, \$offset);   # locate the header/payload boundary
    my $header = substr($full, 0, $offset);
    my $nonce  = substr($full, $offset, 16);
    is(length($nonce), 16, 'fixture: full nonce is 16 bytes');

    # (a) header + full nonce, zero payload bytes at all (karr #6).
    {
        my $ct = $header . $nonce;
        my $got = eval { Crypt::Age->decrypt(ciphertext => $ct, identities => [$secret]) };
        ok(!defined $got, 'payload-less file does not silently decrypt');
        ok($@, 'payload-less file raises an error');
    }

    # (b) nonce truncated to 8 bytes, nothing following.
    {
        my $ct = $header . substr($nonce, 0, 8);
        my $got = eval { Crypt::Age->decrypt(ciphertext => $ct, identities => [$secret]) };
        ok(!defined $got, 'truncated 8-byte nonce does not decrypt');
        ok($@, 'truncated nonce raises an error');
    }

    # (c) payload present but shorter than the 16-byte AEAD tag.
    {
        my $ct = $header . $nonce . substr($full, $offset + 16, 5);
        my $got = eval { Crypt::Age->decrypt(ciphertext => $ct, identities => [$secret]) };
        ok(!defined $got, 'payload shorter than the tag size does not decrypt');
        ok($@, 'short payload raises an error');
    }
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
