package Crypt::OpenSSL3::SSL::Session;
$Crypt::OpenSSL3::SSL::Session::VERSION = '0.002';
use strict;
use warnings;

use Crypt::OpenSSL3;

1;

# ABSTRACT: SSL Session state

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::OpenSSL3::SSL::Session - SSL Session state

=head1 VERSION

version 0.002

=head1 DESCRIPTION

This is a class containing the current TLS/SSL session details for a connection: L<cipher|Crypt::OpenSSL3::SSL::Cipher>, client and server certificates, keys, etc.

=head1 METHODS

=head2 new

=head2 dup

=head2 get_alpn_selected

=head2 get_cipher

=head2 get_compress_id

=head2 get_hostname

=head2 get_id

=head2 get_id_context

=head2 get_max_early_data

=head2 get_peer

=head2 get_protocol_version

=head2 get_ticket

=head2 get_ticket_lifetime_hint

=head2 get_time

=head2 get_timeout

=head2 has_ticket

=head2 is_resumable

=head2 print

=head2 print_keylog

=head2 set_alpn_selected

=head2 set_cipher

=head2 set_hostname

=head2 set_id

=head2 set_id_context

=head2 set_max_early_data

=head2 set_protocol_version

=head2 set_time

=head2 set_timeout

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
