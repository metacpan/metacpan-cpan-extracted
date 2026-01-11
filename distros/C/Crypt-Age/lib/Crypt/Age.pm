package Crypt::Age;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Perl implementation of age encryption (age-encryption.org)

use Moo;
use Carp qw(croak);
use Crypt::Age::Keys;
use Crypt::Age::Primitives;
use Crypt::Age::Header;
use namespace::clean;


our $VERSION = '0.001';

sub generate_keypair {
    my ($class) = @_;
    return Crypt::Age::Keys->generate_keypair;
}


sub encrypt {
    my ($class, %args) = @_;
    my $plaintext  = $args{plaintext}  // croak "plaintext required";
    my $recipients = $args{recipients} // croak "recipients required";

    croak "recipients must be an array ref" unless ref($recipients) eq 'ARRAY';
    croak "at least one recipient required" unless @$recipients;

    # Generate random file key
    my $file_key = Crypt::Age::Primitives->generate_file_key;

    # Create header with wrapped file key for each recipient
    my $header = Crypt::Age::Header->create($file_key, $recipients);

    # Generate payload nonce and derive payload key
    my $nonce = Crypt::Age::Primitives->generate_payload_nonce;
    my $payload_key = Crypt::Age::Primitives->derive_payload_key($file_key, $nonce);
    my $encrypted_payload = Crypt::Age::Primitives->encrypt_payload($payload_key, $plaintext);

    # Output: header + nonce + encrypted_payload
    return $header->to_string . $nonce . $encrypted_payload;
}


sub decrypt {
    my ($class, %args) = @_;
    my $ciphertext = $args{ciphertext} // croak "ciphertext required";
    my $identities = $args{identities} // croak "identities required";

    croak "identities must be an array ref" unless ref($identities) eq 'ARRAY';
    croak "at least one identity required" unless @$identities;

    # Parse header
    my $offset = 0;
    my $header = Crypt::Age::Header->parse(\$ciphertext, \$offset);

    # Unwrap file key using identities
    my $file_key = $header->unwrap_file_key($identities);

    # Extract nonce (first 16 bytes after header) and encrypted payload
    my $nonce = substr($ciphertext, $offset, 16);
    my $encrypted_payload = substr($ciphertext, $offset + 16);

    # Derive payload key using nonce
    my $payload_key = Crypt::Age::Primitives->derive_payload_key($file_key, $nonce);

    return Crypt::Age::Primitives->decrypt_payload($payload_key, $encrypted_payload);
}


sub encrypt_file {
    my ($class, %args) = @_;
    my $input      = $args{input}      // croak "input required";
    my $output     = $args{output}     // croak "output required";
    my $recipients = $args{recipients} // croak "recipients required";

    open my $in_fh, '<:raw', $input
        or croak "Cannot open input file '$input': $!";
    my $plaintext = do { local $/; <$in_fh> };
    close $in_fh;

    my $ciphertext = $class->encrypt(
        plaintext  => $plaintext,
        recipients => $recipients,
    );

    open my $out_fh, '>:raw', $output
        or croak "Cannot open output file '$output': $!";
    print $out_fh $ciphertext;
    close $out_fh;

    return 1;
}


sub decrypt_file {
    my ($class, %args) = @_;
    my $input      = $args{input}      // croak "input required";
    my $output     = $args{output}     // croak "output required";
    my $identities = $args{identities} // croak "identities required";

    open my $in_fh, '<:raw', $input
        or croak "Cannot open input file '$input': $!";
    my $ciphertext = do { local $/; <$in_fh> };
    close $in_fh;

    my $plaintext = $class->decrypt(
        ciphertext => $ciphertext,
        identities => $identities,
    );

    open my $out_fh, '>:raw', $output
        or croak "Cannot open output file '$output': $!";
    print $out_fh $plaintext;
    close $out_fh;

    return 1;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Age - Perl implementation of age encryption (age-encryption.org)

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use Crypt::Age;

    # Generate keypair
    my ($public, $secret) = Crypt::Age->generate_keypair();
    # $public  = "age1ql3z7hjy..."
    # $secret  = "AGE-SECRET-KEY-1..."

    # Encrypt data
    my $encrypted = Crypt::Age->encrypt(
        plaintext  => "Hello, World!",
        recipients => [$public],
    );

    # Decrypt data
    my $decrypted = Crypt::Age->decrypt(
        ciphertext => $encrypted,
        identities => [$secret],
    );

    # Encrypt file
    Crypt::Age->encrypt_file(
        input      => 'secret.txt',
        output     => 'secret.txt.age',
        recipients => [$public],
    );

    # Decrypt file
    Crypt::Age->decrypt_file(
        input      => 'secret.txt.age',
        output     => 'secret.txt',
        identities => [$secret],
    );

=head1 DESCRIPTION

Crypt::Age is a pure Perl implementation of the age encryption format,
compatible with the reference Go implementation (L<https://github.com/FiloSottile/age>)
and the Rust implementation (L<https://github.com/str4d/rage>).

age is a simple, modern and secure file encryption tool with small explicit
keys, no config options, and UNIX-style composability. The format specification
is available at L<https://github.com/C2SP/C2SP/blob/main/age.md>.

This implementation uses X25519 for key exchange, ChaCha20-Poly1305 for
authenticated encryption, and HKDF-SHA256 for key derivation. All cryptographic
primitives are provided by L<CryptX>.

Files encrypted with Crypt::Age can be decrypted with the C<age> and C<rage>
command-line tools, and vice versa.

=head2 generate_keypair

    my ($public_key, $secret_key) = Crypt::Age->generate_keypair();

Generates a new X25519 keypair for age encryption.

Returns a list of two elements:

=over 4

=item * C<$public_key> - Bech32-encoded public key starting with C<age1>

=item * C<$secret_key> - Bech32-encoded secret key starting with C<AGE-SECRET-KEY-1>

=back

The public key can be shared with others to encrypt files for you. The secret
key must be kept private and is used to decrypt files encrypted to your public key.

=head2 encrypt

    my $ciphertext = Crypt::Age->encrypt(
        plaintext  => $data,
        recipients => \@public_keys,
    );

Encrypts plaintext data for one or more recipients.

Parameters:

=over 4

=item * C<plaintext> - The data to encrypt (required)

=item * C<recipients> - ArrayRef of Bech32-encoded public keys (required)

=back

Returns the encrypted data in age format, which includes a text header followed
by the encrypted payload. The file key is wrapped separately for each recipient,
allowing any of them to decrypt the data.

The returned data can be written to a file or transmitted directly.

=head2 decrypt

    my $plaintext = Crypt::Age->decrypt(
        ciphertext => $encrypted,
        identities => \@secret_keys,
    );

Decrypts age-encrypted data using one or more identities.

Parameters:

=over 4

=item * C<ciphertext> - The age-encrypted data (required)

=item * C<identities> - ArrayRef of Bech32-encoded secret keys (required)

=back

Returns the decrypted plaintext.

The method tries each identity against each recipient stanza in the header until
one successfully unwraps the file key. Dies if no matching identity is found or
if the MAC verification fails.

=head2 encrypt_file

    Crypt::Age->encrypt_file(
        input      => 'plaintext.txt',
        output     => 'encrypted.age',
        recipients => \@public_keys,
    );

Encrypts a file for one or more recipients.

Parameters:

=over 4

=item * C<input> - Path to input file (required)

=item * C<output> - Path to output file (required)

=item * C<recipients> - ArrayRef of Bech32-encoded public keys (required)

=back

The output file will be in age format and can be decrypted with the C<age> or
C<rage> command-line tools.

Returns C<1> on success. Dies on error (file not found, permission denied, etc).

=head2 decrypt_file

    Crypt::Age->decrypt_file(
        input      => 'encrypted.age',
        output     => 'plaintext.txt',
        identities => \@secret_keys,
    );

Decrypts an age-encrypted file using one or more identities.

Parameters:

=over 4

=item * C<input> - Path to encrypted input file (required)

=item * C<output> - Path to decrypted output file (required)

=item * C<identities> - ArrayRef of Bech32-encoded secret keys (required)

=back

Returns C<1> on success. Dies if no matching identity is found, if the MAC
verification fails, or on file I/O errors.

=head1 KEY FORMAT

=head2 Public Keys

Public keys are Bech32-encoded X25519 public keys with the human-readable
part C<age>:

    age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p

=head2 Secret Keys

Secret keys are uppercase Bech32-encoded X25519 secret keys with the
human-readable part C<AGE-SECRET-KEY->:

    AGE-SECRET-KEY-1QQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQ3290DG

=head1 INTEROPERABILITY

This module is designed to be compatible with:

=over 4

=item * L<https://github.com/FiloSottile/age> - Reference Go implementation

=item * L<https://github.com/str4d/rage> - Rust implementation

=back

Files encrypted with Crypt::Age can be decrypted with these tools and vice versa.

=head1 SECURITY

age uses modern cryptographic primitives:

=over 4

=item * X25519 for key agreement (Curve25519 Diffie-Hellman)

=item * ChaCha20-Poly1305 for authenticated encryption

=item * HKDF-SHA256 for key derivation

=back

The file key is randomly generated for each encryption operation. The payload
is encrypted in 64 KiB chunks with unique nonces derived from a counter and
final-chunk flag.

=head1 SEE ALSO

=over 4

=item * L<https://age-encryption.org> - age encryption homepage

=item * L<https://github.com/C2SP/C2SP/blob/main/age.md> - age format specification

=item * L<CryptX> - Cryptographic toolkit providing all primitives

=item * L<Crypt::Age::Keys> - Key generation and encoding

=item * L<Crypt::Age::Primitives> - Low-level cryptographic operations

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-crypt-age/issues>.

=head2 IRC

You can reach Getty on C<irc.perl.org> for questions and support.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
