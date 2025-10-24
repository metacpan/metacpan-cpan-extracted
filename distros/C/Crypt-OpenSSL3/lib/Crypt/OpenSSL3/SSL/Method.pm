package Crypt::OpenSSL3::SSL::Method;
$Crypt::OpenSSL3::SSL::Method::VERSION = '0.002';
use strict;
use warnings;

use Crypt::OpenSSL3;

1;

#ABSTRACT: Connection funcs for SSL connections

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::OpenSSL3::SSL::Method - Connection funcs for SSL connections

=head1 VERSION

version 0.002

=head1 DESCRIPTION

This is a dispatch structure describing the internal ssl library methods/functions which implement the various protocol versions (SSLv3 TLSv1, ...). It's needed to create a L<context|Crypt::OpenSSL3::SSL::Context>.

=head1 FUNCTIONS

=head2 TLS

=head2 TLS_client

=head2 TLS_server

=head2 DTLS

=head2 DTLS_client

=head2 DTLS_server

=head2 QUIC_client

=head2 QUIC_client_thread

=head2 QUIC_server

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
