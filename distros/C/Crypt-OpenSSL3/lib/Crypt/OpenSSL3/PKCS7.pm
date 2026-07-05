package Crypt::OpenSSL3::PKCS7;
$Crypt::OpenSSL3::PKCS7::VERSION = '0.010';
use strict;
use warnings;

use Crypt::OpenSSL3;

1;

# ABSTRACT: A PKCS7 envelope

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::OpenSSL3::PKCS7 - A PKCS7 envelope

=head1 VERSION

version 0.010

=head1 METHODS

=head2 add_certificate

=head2 decode_der

=head2 decrypt

=head2 encode_der

=head2 encrypt

=head2 get_signers

=head2 get_octet_string

=head2 new

=head2 read_der

=head2 read_pem

=head2 sign

=head2 type_is_data

=head2 type_is_digest

=head2 type_is_encrypted

=head2 type_is_enveloped

=head2 type_is_other

=head2 type_is_signed

=head2 type_is_signedAndEnveloped

=head2 verify

=head2 write_der

=head2 write_pem

=head1 CONSTANTS

=over 4

=item * BINARY

=item * DETACHED

=item * NOATTR

=item * NOCERTS

=item * NOCHAIN

=item * NOCRL

=item * NOINTERN

=item * NOSIGS

=item * NOSMIMECAP

=item * NOVERIFY

=item * STREAM

=item * TEXT

=back

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Leon Timmermans.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
