package Crypt::ECDH_ES;
$Crypt::ECDH_ES::VERSION = '0.006';
use strict;
use warnings;

use Carp;
use Crypt::Curve25519;
use Crypt::SysRandom qw/random_bytes/;
use Crypt::Rijndael 1.16;
use Digest::SHA qw/sha256 hmac_sha256/;

use Exporter 5.57 'import';
our @EXPORT_OK = qw/ecdhes_encrypt ecdhes_decrypt ecdhes_encrypt_authenticated ecdhes_decrypt_authenticated ecdhes_generate_key/;
our %EXPORT_TAGS = (all => \@EXPORT_OK);

my $format_unauthenticated = 'C/a C/a n/a N/a';

sub ecdhes_encrypt {
	my ($public_key, $data) = @_;

	my $private = curve25519_secret_key(random_bytes(32));
	my $public  = curve25519_public_key($private);
	my $shared  = curve25519_shared_secret($private, $public_key);

	my ($encrypt_key, $sign_key) = unpack 'a16 a16', sha256($shared);
	my $iv     = substr sha256($public), 0, 16;
	my $cipher = Crypt::Rijndael->new($encrypt_key, Crypt::Rijndael::MODE_CBC);

	my $pad_length = 16 - length($data) % 16;
	my $padding = chr($pad_length) x $pad_length;

	my $ciphertext = $cipher->encrypt($data . $padding, $iv);
	my $mac = hmac_sha256($iv . $ciphertext, $sign_key);
	return pack $format_unauthenticated, '', $public, $mac, $ciphertext;
}

sub ecdhes_decrypt {
	my ($private_key, $packed_data) = @_;

	my ($options, $public, $mac, $ciphertext) = unpack $format_unauthenticated, $packed_data;
	croak 'Unknown options' if $options ne '';

	my $shared = curve25519_shared_secret($private_key, $public);
	my ($encrypt_key, $sign_key) = unpack 'a16 a16', sha256($shared);
	my $iv     = substr sha256($public), 0, 16;
	croak 'MAC is incorrect' if hmac_sha256($iv . $ciphertext, $sign_key) ne $mac;
	my $cipher = Crypt::Rijndael->new($encrypt_key, Crypt::Rijndael::MODE_CBC);

	my $plaintext = $cipher->decrypt($ciphertext, $iv);
	my $pad_length = ord substr $plaintext, -1;
	substr($plaintext, -$pad_length, $pad_length, '') eq chr($pad_length) x $pad_length or croak 'Incorrectly padded';
	return $plaintext;
}

my $format_authenticated = 'C/a C/a C/a C/a N/a';

sub ecdhes_encrypt_authenticated {
	my ($public_key_other, $private_key_self, $data) = @_;

	my $public_key_self = curve25519_public_key($private_key_self);
	my $private_ephemeral = curve25519_secret_key(random_bytes(32));
	my $ephemeral_public  = curve25519_public_key($private_ephemeral);
	my $primary_shared  = curve25519_shared_secret($private_ephemeral, $public_key_other);

	my ($primary_encrypt_key, $primary_iv) = unpack 'a16 a16', sha256($primary_shared);
	my $primary_cipher = Crypt::Rijndael->new($primary_encrypt_key, Crypt::Rijndael::MODE_CBC);
	my $encrypted_public_key = $primary_cipher->encrypt($public_key_self, $primary_iv);

	my $secondary_shared = $primary_shared . curve25519_shared_secret($private_key_self, $public_key_other);
	my ($secondary_encrypt_key, $sign_key) = unpack 'a16 a16', sha256($secondary_shared);
	my $cipher = Crypt::Rijndael->new($secondary_encrypt_key, Crypt::Rijndael::MODE_CBC);
	my $iv     = substr sha256($ephemeral_public), 0, 16;

	my $pad_length = 16 - length($data) % 16;
	my $padding = chr($pad_length) x $pad_length;

	my $ciphertext = $cipher->encrypt($data . $padding, $iv);
	my $mac = hmac_sha256($iv . $ciphertext, $sign_key);
	return pack $format_authenticated, "\x{1}", $ephemeral_public, $encrypted_public_key, $mac, $ciphertext;
}

sub ecdhes_decrypt_authenticated {
	my ($private_key, $packed_data) = @_;

	my ($options, $ephemeral_public, $encrypted_public_key, $mac, $ciphertext) = unpack $format_authenticated, $packed_data;
	croak 'Unknown options' if $options ne "\x{1}";

	my $primary_shared = curve25519_shared_secret($private_key, $ephemeral_public);
	my ($primary_encrypt_key, $primary_iv) = unpack 'a16 a16', sha256($primary_shared);
	my $primary_cipher = Crypt::Rijndael->new($primary_encrypt_key, Crypt::Rijndael::MODE_CBC);
	my $public_key = $primary_cipher->decrypt($encrypted_public_key, $primary_iv);

	my $secondary_shared = $primary_shared . curve25519_shared_secret($private_key, $public_key);
	my ($secondary_encrypt_key, $sign_key) = unpack 'a16 a16', sha256($secondary_shared);
	my $cipher = Crypt::Rijndael->new($secondary_encrypt_key, Crypt::Rijndael::MODE_CBC);
	my $iv     = substr sha256($ephemeral_public), 0, 16;

	croak 'MAC is incorrect' if hmac_sha256($iv . $ciphertext, $sign_key) ne $mac;

	my $plaintext = $cipher->decrypt($ciphertext, $iv);
	my $pad_length = ord substr $plaintext, -1;
	substr($plaintext, -$pad_length, $pad_length, '') eq chr($pad_length) x $pad_length or croak 'Incorrectly padded';
	return ($plaintext, $public_key);
}

sub ecdhes_generate_key {
	my $buf = random_bytes(32);
	my $secret = curve25519_secret_key($buf);
	my $public = curve25519_public_key($secret);
	return ($public, $secret);
}

1;

#ABSTRACT: A fast and small hybrid crypto system

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::ECDH_ES - A fast and small hybrid crypto system

=head1 VERSION

version 0.006

=head1 SYNOPSIS

 my $ciphertext = ecdhes_encrypt($public_key, $data);
 my $plaintext = ecdhes_decrypt($private_key, $ciphertext);

=head1 DESCRIPTION

This module uses elliptic curve cryptography in an ephemerical-static configuration combined with the AES cipher to achieve a hybrid cryptographical system. Both the public and the private key are simply 32 byte blobs.

=head2 Use-cases

You may want to use this module when storing sensive data in such a way that the encoding side can't read it afterwards, for example a website storing credit card data in a database that will be used by a separate back-end financial processor. When used in this way, a leak of the database and keys given to the website will not leak those credit card numbers.

=head2 Technical details

This modules uses Daniel J. Bernstein's curve25519 (also used by OpenSSH) to perform a Diffie-Hellman key agreement between an encoder and a decoder. The keys of the decoder should be known in advance (as this system works as a one-way communication mechanism), for the encoder a new keypair is generated for every encryption using the system's cryptographically secure pseudo-random number generator. The shared key resulting from the key agreement is hashed and used to encrypt the plaintext using AES in CBC mode (with the IV deterministically derived from the public key). It also adds a HMAC, with the key derived from the same shared secret as the encryption key.

All cryptographic components are believed to provide at least 128-bits of security.

=head2 Variants

There are two variants of this system; both will encrypt the payload, but only one will authenticate the sender.

=head1 FUNCTIONS

=head2 ecdhes_encrypt

 my $ciphertext = ecdhes_encrypt($public_key, $plaintext)

This will encrypt C<$plaintext> using C<$public_key>. This is a non-deterministic encryption: the result will be different for every invocation.

=head2 ecdhes_decrypt

 my $plaintext = ecdhes_decrypt($private_key, $ciphertext)

This will decrypt C<$ciphertext> (as encrypted using C<ecdhes_encrypt>) using C<$private_key> and return the plaintext.

=head2 ecdhes_encrypt_authenticated

 my $ciphertext = ecdhes_encrypt_authenticated($receiver_public_key, $sender_private_key, $plaintext)

This will encrypt C<$plaintext> using C<$receiver_public_key> and C<$sender_private_key>. This is a non-deterministic encryption: the result will be different for every invocation.

=head2 ecdhes_decrypt_authenticated

 my ($plaintext, $sender_public_key) = ecdhes_decrypt_authenticated($receiver_private_key, $ciphertext)

This will decrypt C<$ciphertext> (as encrypted using C<ecdhes_encrypt_authenticated>) using C<$receiver_private_key> and return the plaintext and the public key of the sender.

=head2 ecdhes_generate_key

 my ($public_key, $private_key) = ecdhes_generate_key()

This function generates a new random curve25519 keypair.

=head1 SEE ALSO

=over 4

=item * L<ecdh_es|https://github.com/tomk3003/ecdh_es>

A compatible decoder written in C.

=item * L<Crypt::OpenPGP|Crypt::OpenPGP>

This module can be used to achieve exactly the same effect in a more standardized way, but it requires much more infrastructure (such as a keychain), many more dependencies, larger messages and more thinking about various settings.

=item * L<Crypt::Ed25519|Crypt::Ed25519>

This is a public key signing/verification system based on an equivalent curve.

=back

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
