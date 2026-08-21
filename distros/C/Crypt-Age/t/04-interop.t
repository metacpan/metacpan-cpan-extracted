#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile tempdir);
use Crypt::Age;
use Crypt::Age::Header;
use Crypt::Age::Primitives;
use Crypt::Age::Stanza;
use Crypt::Age::Stanza::X25519;

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

# A hand-built header that is valid per the ABNF but that our own writer
# cannot reproduce byte-for-byte: a real X25519 stanza plus an extra,
# unknown-type stanza whose body is exactly 64 base64 characters (48 raw
# bytes) and therefore requires an empty final line per
# "final-line = *63base64char LF". Stanza::to_string omits that empty line
# (known gap, karr #3), so re-serializing this header comes out one byte
# short and a MAC computed over the re-serialization would not match.
#
# t/03-header.t already pins the underlying mechanism (_bytes reflects the
# literal input, not a re-serialization) without any binary. This test is
# the product-level consequence: the CLI must accept the crafted file
# outright -- proving it really is spec-valid, not just something our own
# parser happens to tolerate -- and Crypt::Age->decrypt must accept it too.
{
    my ($public, $secret) = Crypt::Age->generate_keypair;
    my $plaintext = "grease-test payload, valid per spec, not reproducible by our writer.\n";

    my $file_key = Crypt::Age::Primitives->generate_file_key;
    my $stanza   = Crypt::Age::Stanza::X25519->wrap($file_key, $public);

    my $grease_body = join '', map { chr($_ % 251) } 1 .. 48;
    my $grease_body_b64 = Crypt::Age::Stanza::encode_base64_no_padding($grease_body);
    is(length($grease_body_b64), 64, 'fixture: grease body is exactly 64 base64 chars');

    my $head_no_mac = join("\n",
        'age-encryption.org/v1',
        $stanza->to_string,
        '-> grease-test',
        $grease_body_b64,
        '',      # required empty final line for a 64-char-multiple body
        '---',
    );
    my $mac = Crypt::Age::Primitives->compute_header_mac($file_key, $head_no_mac);
    my $header_text = $head_no_mac . ' ' . Crypt::Age::Stanza::encode_base64_no_padding($mac) . "\n";

    my $nonce       = Crypt::Age::Primitives->generate_payload_nonce;
    my $payload_key = Crypt::Age::Primitives->derive_payload_key($file_key, $nonce);
    my $payload     = Crypt::Age::Primitives->encrypt_payload($payload_key, $plaintext);

    my $crafted = "$header_text$nonce$payload";

    my $key_file = "$tmpdir/grease_key.txt";
    open my $fh, '>', $key_file or die $!;
    print $fh "$secret\n";
    close $fh;

    my $crafted_file = "$tmpdir/grease.age";
    open $fh, '>:raw', $crafted_file or die $!;
    print $fh $crafted;
    close $fh;

    my $out_file = "$tmpdir/grease_out.bin";
    unlink $out_file;
    my $rc = system(qq{$cli_bin -d -i "$key_file" -o "$out_file" "$crafted_file" 2>"$tmpdir/grease_err"});
    is($rc, 0, 'CLI accepts the crafted spec-valid header')
        or diag(do { open my $e, '<', "$tmpdir/grease_err"; local $/; <$e> });

    open $fh, '<:raw', $out_file or die $!;
    my $cli_plain = do { local $/; <$fh> };
    close $fh;
    is($cli_plain, $plaintext, 'CLI decrypts the crafted file to the expected plaintext');

    my $got = eval { Crypt::Age->decrypt(ciphertext => $crafted, identities => [$secret]) };
    is($@, '', 'Crypt::Age->decrypt does not die on the crafted header');
    is($got, $plaintext, 'Crypt::Age->decrypt returns the correct plaintext from the crafted header');
}

# encrypt_filehandle / decrypt_filehandle against the CLI, both directions.
# t/02-encrypt-decrypt.t only round-trips these through Crypt::Age itself,
# which cannot show whether the wire format the filehandle path produces (or
# accepts) is one the reference implementation agrees with.
{
    my ($public, $secret) = Crypt::Age->generate_keypair;
    my $plaintext = "Filehandle interop payload.\n" x 100;

    my $key_file = "$tmpdir/fh_key.txt";
    open my $fh, '>', $key_file or die $!;
    print $fh "$secret\n";
    close $fh;

    my $in_file  = "$tmpdir/fh_plain.txt";
    open my $ifh, '>:raw', $in_file or die $!;
    print $ifh $plaintext;
    close $ifh;

    # Perl encrypt_filehandle -> CLI decrypt
    my $enc_file = "$tmpdir/fh_perl.age";
    open $ifh, '<:raw', $in_file or die $!;
    open my $ofh, '>:raw', $enc_file or die $!;
    Crypt::Age->encrypt_filehandle(input => $ifh, output => $ofh, recipients => [$public]);
    close $ofh;
    close $ifh;

    my $out_file = "$tmpdir/fh_perl_out.bin";
    unlink $out_file;
    my $rc = system(qq{$cli_bin -d -i "$key_file" -o "$out_file" "$enc_file" 2>"$tmpdir/fh_err1"});
    is($rc, 0, 'CLI decrypts encrypt_filehandle output')
        or diag(do { open my $e, '<', "$tmpdir/fh_err1"; local $/; <$e> });

    open my $rfh, '<:raw', $out_file or die $!;
    my $cli_plain = do { local $/; <$rfh> };
    close $rfh;
    is($cli_plain, $plaintext, 'encrypt_filehandle output matches after CLI decrypt');

    # CLI encrypt -> Perl decrypt_filehandle
    my $cli_enc_file = "$tmpdir/fh_cli.age";
    $rc = system(qq{$cli_bin -r "$public" -o "$cli_enc_file" "$in_file" 2>"$tmpdir/fh_err2"});
    is($rc, 0, 'CLI encrypts plaintext for decrypt_filehandle test')
        or diag(do { open my $e, '<', "$tmpdir/fh_err2"; local $/; <$e> });

    my $dec_file = "$tmpdir/fh_dec_out.bin";
    open my $cifh, '<:raw', $cli_enc_file or die $!;
    open my $cofh, '>:raw', $dec_file or die $!;
    Crypt::Age->decrypt_filehandle(input => $cifh, output => $cofh, identities => [$secret]);
    close $cofh;
    close $cifh;

    open my $dfh, '<:raw', $dec_file or die $!;
    my $decrypted = do { local $/; <$dfh> };
    close $dfh;
    is($decrypted, $plaintext, 'decrypt_filehandle output matches CLI-encrypted plaintext');
}

# STREAM chunk boundaries against the CLI, both directions. The payload path
# moved from substr arithmetic to read()/eof(); is_final is now decided by
# eof(), so these sizes exercise exactly-one-chunk (65536), one byte short of
# and past that boundary (65535, 65537), an empty payload (0), a
# single-byte payload (1), and exactly two chunks (131072).
for my $size (0, 1, 65535, 65536, 65537, 131072) {
    my ($public, $secret) = Crypt::Age->generate_keypair;

    my $data = '';
    $data .= chr(($_ * 37 + 11) & 0xFF) for 1 .. $size;
    is(length($data), $size, "fixture: chunk-boundary plaintext is $size bytes");

    my $key_file = "$tmpdir/cb_key_$size.txt";
    open my $fh, '>', $key_file or die $!;
    print $fh "$secret\n";
    close $fh;

    my $plain_file = "$tmpdir/cb_plain_$size.bin";
    open $fh, '>:raw', $plain_file or die $!;
    print $fh $data;
    close $fh;

    # Perl encrypt, CLI decrypt
    my $encrypted = Crypt::Age->encrypt(plaintext => $data, recipients => [$public]);
    my $enc_file = "$tmpdir/cb_perl_$size.age";
    open $fh, '>:raw', $enc_file or die $!;
    print $fh $encrypted;
    close $fh;

    my $out_file = "$tmpdir/cb_out_$size.bin";
    unlink $out_file;
    my $rc = system(qq{$cli_bin -d -i "$key_file" -o "$out_file" "$enc_file" 2>"$tmpdir/cb_err1_$size"});
    is($rc, 0, "CLI decrypts Perl output at size $size")
        or diag(do { open my $e, '<', "$tmpdir/cb_err1_$size"; local $/; <$e> });

    # age(1) creates its -o file lazily; a 0-byte plaintext leaves no file at all.
    my $cli_plain = '';
    if (-e $out_file) {
        open my $rfh, '<:raw', $out_file or die $!;
        $cli_plain = do { local $/; <$rfh> };
        close $rfh;
    }
    is(length($cli_plain), $size, "CLI-decrypted length matches at size $size");
    is($cli_plain, $data, "CLI-decrypted content matches at size $size");

    # CLI encrypt, Perl decrypt
    my $cli_enc_file = "$tmpdir/cb_cli_$size.age";
    $rc = system(qq{$cli_bin -r "$public" -o "$cli_enc_file" "$plain_file" 2>"$tmpdir/cb_err2_$size"});
    is($rc, 0, "CLI encrypts at size $size")
        or diag(do { open my $e, '<', "$tmpdir/cb_err2_$size"; local $/; <$e> });

    open $fh, '<:raw', $cli_enc_file or die $!;
    my $cli_encrypted = do { local $/; <$fh> };
    close $fh;

    my $decrypted = Crypt::Age->decrypt(ciphertext => $cli_encrypted, identities => [$secret]);
    is(length($decrypted), $size, "Perl-decrypted length matches CLI output at size $size");
    is($decrypted, $data, "Perl-decrypted content matches CLI output at size $size");
}

done_testing;
