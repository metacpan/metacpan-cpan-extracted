#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile tempdir);
use Crypt::Age;

# Check if age CLI is available
my $age_bin = `which age 2>/dev/null`;
chomp $age_bin;

my $rage_bin = `which rage 2>/dev/null`;
chomp $rage_bin;

my $cli_bin = $age_bin || $rage_bin;

if (!$cli_bin) {
    plan skip_all => 'age or rage CLI not found, skipping interop tests';
}

diag("Using CLI: $cli_bin");

my $tmpdir = tempdir(CLEANUP => 1);

# Test: Perl encrypts, CLI decrypts
{
    my ($public, $secret) = Crypt::Age->generate_keypair;
    my $plaintext = "Hello from Perl!";

    # Write secret key to file for CLI
    my $key_file = "$tmpdir/key.txt";
    open my $fh, '>', $key_file;
    print $fh "$secret\n";
    close $fh;

    # Encrypt with Perl
    my $encrypted = Crypt::Age->encrypt(
        plaintext  => $plaintext,
        recipients => [$public],
    );

    my $enc_file = "$tmpdir/perl_encrypted.age";
    open $fh, '>:raw', $enc_file;
    print $fh $encrypted;
    close $fh;

    # Decrypt with CLI
    my $decrypted = `$cli_bin -d -i "$key_file" "$enc_file" 2>&1`;
    my $exit_code = $? >> 8;

    is($exit_code, 0, 'CLI decryption succeeded');
    is($decrypted, $plaintext, 'CLI decrypted Perl-encrypted data correctly');
}

# Test: CLI encrypts, Perl decrypts
{
    my ($public, $secret) = Crypt::Age->generate_keypair;
    my $plaintext = "Hello from CLI!";

    # Write plaintext to file
    my $plain_file = "$tmpdir/plain.txt";
    open my $fh, '>', $plain_file;
    print $fh $plaintext;
    close $fh;

    # Encrypt with CLI
    my $enc_file = "$tmpdir/cli_encrypted.age";
    my $output = `$cli_bin -r "$public" -o "$enc_file" "$plain_file" 2>&1`;
    my $exit_code = $? >> 8;

    is($exit_code, 0, 'CLI encryption succeeded') or diag($output);

    # Decrypt with Perl
    open $fh, '<:raw', $enc_file;
    my $encrypted = do { local $/; <$fh> };
    close $fh;

    my $decrypted = Crypt::Age->decrypt(
        ciphertext => $encrypted,
        identities => [$secret],
    );

    is($decrypted, $plaintext, 'Perl decrypted CLI-encrypted data correctly');
}

# Test: Large file interop
{
    my ($public, $secret) = Crypt::Age->generate_keypair;
    my $plaintext = "x" x (64 * 1024 + 1);  # Just over one chunk

    my $key_file = "$tmpdir/key2.txt";
    open my $fh, '>', $key_file;
    print $fh "$secret\n";
    close $fh;

    # Perl encrypt, CLI decrypt
    my $encrypted = Crypt::Age->encrypt(
        plaintext  => $plaintext,
        recipients => [$public],
    );

    my $enc_file = "$tmpdir/large.age";
    open $fh, '>:raw', $enc_file;
    print $fh $encrypted;
    close $fh;

    my $decrypted = `$cli_bin -d -i "$key_file" "$enc_file" 2>&1`;
    my $exit_code = $? >> 8;

    is($exit_code, 0, 'CLI decrypted large file');
    is(length($decrypted), length($plaintext), 'large file length matches');
    is($decrypted, $plaintext, 'large file content matches');
}

# Test: Binary data interop
{
    my ($public, $secret) = Crypt::Age->generate_keypair;
    my $plaintext = join('', map { chr($_) } 0..255);

    my $key_file = "$tmpdir/key3.txt";
    open my $fh, '>', $key_file;
    print $fh "$secret\n";
    close $fh;

    my $encrypted = Crypt::Age->encrypt(
        plaintext  => $plaintext,
        recipients => [$public],
    );

    my $enc_file = "$tmpdir/binary.age";
    open $fh, '>:raw', $enc_file;
    print $fh $encrypted;
    close $fh;

    my $decrypted = `$cli_bin -d -i "$key_file" "$enc_file"`;
    my $exit_code = $? >> 8;

    is($exit_code, 0, 'CLI decrypted binary data');
    is($decrypted, $plaintext, 'binary data matches');
}

done_testing;
