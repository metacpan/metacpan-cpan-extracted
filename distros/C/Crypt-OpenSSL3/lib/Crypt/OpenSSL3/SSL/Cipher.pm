package Crypt::OpenSSL3::SSL::Cipher;
$Crypt::OpenSSL3::SSL::Cipher::VERSION = '0.002';
use strict;
use warnings;

use Crypt::OpenSSL3;

1;

# ABSTRACT: An SSL Cipher

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::OpenSSL3::SSL::Cipher - An SSL Cipher

=head1 VERSION

version 0.002

=head1 DESCRIPTION

This class holds the algorithm information for a particular cipher which are a core part of the SSL/TLS protocol. The available ciphers are configured on a L<context|Crypt::OpenSSL3::SSL::Context> basis and the actual ones used are then part of the L<session|Crypt::OpenSSL3::SSL::Session>.

=head1 METHODS

=head2 description

=head2 get_auth_nid

=head2 get_bits

=head2 get_cipher_nid

=head2 get_digest_nid

=head2 get_handshake_digest

=head2 get_id

=head2 get_kx_nid

=head2 get_name

=head2 get_protocol_id

=head2 get_version

=head2 is_aead

=head2 standard_name

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
