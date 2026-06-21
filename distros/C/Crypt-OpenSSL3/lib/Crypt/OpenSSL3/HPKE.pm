package Crypt::OpenSSL3::HPKE;
$Crypt::OpenSSL3::HPKE::VERSION = '0.008';
use strict;
use warnings;

use Crypt::OpenSSL3;

1;

# ABSTRACT: Hybrid Public Key Encryption (RFC 9180) suite

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::OpenSSL3::HPKE - Hybrid Public Key Encryption (RFC 9180) suite

=head1 VERSION

version 0.008

=head1 DESCRIPTION

=head1 METHODS

=head2 new

=head2 from_string

=head2 aead_id

=head2 check

=head2 default

=head2 get_ciphertext_size

=head2 get_grease_value

=head2 get_public_encap_size

=head2 get_recommended_ikmelen

=head2 kdf_id

=head2 kem_id

=head2 keygen

=head2 suite

=head1 CONSTANTS

=head2 KEMs

=over 4

=item *  KEM_ID_P256

=item *  KEM_ID_P384

=item *  KEM_ID_P521

=item *  KEM_ID_X25519

=item *  KEM_ID_X448

=back

=head2 KDFs

=over 4

=item *  KDF_ID_HKDF_SHA256

=item *  KDF_ID_HKDF_SHA384

=item *  KDF_ID_HKDF_SHA512

=back

=head2 AEADs

=over 4

=item *  AEAD_ID_AES_GCM_128

=item *  AEAD_ID_AES_GCM_256

=item *  AEAD_ID_CHACHA_POLY1305

=item *  AEAD_ID_EXPORTONLY

=back

=head2 Modes

=over 4

=item *  MODE_AUTH

=item *  MODE_BASE

=item *  MODE_PSK

=item *  MODE_PSKAUTH

=back

=head2 Roles

=over 4

=item *  ROLE_RECEIVER

=item *  ROLE_SENDER

=back

=head2 Lengths

=over 4

=item *  MAX_INFOLEN

=item *  MAX_PARMLEN

=item *  MIN_PSKLEN

=back

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
