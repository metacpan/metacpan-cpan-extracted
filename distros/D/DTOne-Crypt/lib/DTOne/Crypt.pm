package DTOne::Crypt;

use strict;
use 5.008_005;
our $VERSION = '0.05';

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(encrypt_aes256gcm decrypt_aes256gcm);

use Crypt::AuthEnc::GCM qw(gcm_encrypt_authenticate gcm_decrypt_verify);
use Crypt::ScryptKDF qw(scrypt_raw);
use Bytes::Random::Secure qw(random_bytes);
use MIME::Base64;
use Carp;

use constant SCRYPT_ITERATIONS      => 32768;   # 2**15
use constant SCRYPT_BLOCK_SIZE      => 8;
use constant SCRYPT_PARALLELISM     => 1;
use constant SCRYPT_DERIVED_KEY_LEN => 32;

sub encrypt_aes256gcm {
    my $plaintext  = shift;
    my $master_key = shift or croak "master key required";

    unless (defined $plaintext) {
        croak "plaintext data required";
    }

    $master_key = decode_base64($master_key);
    unless (length($master_key) == 32) {
        croak "invalid master key length";
    }

    my $iv   = random_bytes(12);
    my $salt = random_bytes(16);
    my $key  = scrypt_raw(
        $master_key,
        $salt,
        SCRYPT_ITERATIONS,
        SCRYPT_BLOCK_SIZE,
        SCRYPT_PARALLELISM,
        SCRYPT_DERIVED_KEY_LEN
    );

    my ($ciphertext, $tag) = gcm_encrypt_authenticate(
        'AES',
        $key,
        $iv,
        undef,
        $plaintext
    );

    return encode_base64(join('', $salt, $iv, $tag, $ciphertext), '');
}

sub decrypt_aes256gcm {
    my $encrypted  = shift or croak "encrypted data required";
    my $master_key = shift or croak "master key required";

    $master_key = decode_base64($master_key);
    unless (length($master_key) == 32) {
        croak "invalid master key length";
    }

    $encrypted = decode_base64($encrypted);
    my ($salt, $iv, $tag, $ciphertext) = unpack('a16 a12 a16 a*', $encrypted);
    my $key = scrypt_raw(
        $master_key,
        $salt,
        SCRYPT_ITERATIONS,
        SCRYPT_BLOCK_SIZE,
        SCRYPT_PARALLELISM,
        SCRYPT_DERIVED_KEY_LEN
    );

    return gcm_decrypt_verify(
        'AES',
        $key,
        $iv,
        undef,
        $ciphertext,
        $tag
    );
}

1;
__END__

=encoding utf-8

=head1 NAME

DTOne::Crypt - Cryptographic Toolkit

=head1 SYNOPSIS

  use DTOne::Crypt qw(encrypt_aes256gcm decrypt_aes256gcm);

  my $encrypted = encrypt_aes256gcm($plaintext, $master_key);
  my $decrypted = decrypt_aes256gcm($encrypted, $master_key);

=head1 DESCRIPTION

L<DTOne::Crypt> provides a cryptographic toolkit intended to abstract
complexities in data interchange.

=head1 FUNCTIONS

L<DTone::Crypt> implements the following functions, which can be imported
individually:

=head2 encrypt_aes256gcm

  my $encrypted = encrypt_aes256gcm($plaintext, $master_key);

Encrypt plaintext value using AES-256 GCM to a base64 encoded string containing
the salt, initialization vector (IV), ciphertext, and tag.

=head2 decrypt_aes256gcm

  my $decrypted = decrypt_aes256gcm($encrypted, $master_key);

Decrypt a composite base64 encoded string containing the salt, IV, ciphertext,
and tag back to its original plaintext value.

=head1 CAVEATS

=head2 Key Length

Master key is expected to be exactly 256 bits in length, encoded in base64.

=head2 Performance

Random byte generation on Linux might run slow over time unless L<haveged(8)>
is running. In this scenario, the streaming facility of aes-gcm will be more
memory efficient.

=head1 AUTHOR

Arnold Tan Casis E<lt>atancasis@cpan.orgE<gt>

=head1 ACKNOWLEDGMENTS

L<Pierre Gaulon|https://github.com/pgaulon> and L<Jose Nidhin|https://github.com/josnidhin>
for their valued inputs in interpreting numerous security recommendations and in
designing the data interchange protocol used in this module.

L<Sherwin Daganato|https://metacpan.org/author/SHERWIN> for the note on random
byte generation and caveats to performance on Linux systems.

L<Pierre Vigier|https://metacpan.org/author/PVIGIER> for the note on cross-language
compatibility with libraries in Go and Java.

=head1 COPYRIGHT

Copyright 2020- Arnold Tan Casis

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

See L<CryptX> for an excellent generic cryptographic toolkit.

=cut
