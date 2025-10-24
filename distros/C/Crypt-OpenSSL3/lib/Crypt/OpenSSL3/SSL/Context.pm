package Crypt::OpenSSL3::SSL::Context;
$Crypt::OpenSSL3::SSL::Context::VERSION = '0.002';
use strict;
use warnings;

use Crypt::OpenSSL3;

1;

#ABSTRACT: A context for SSL connections

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::OpenSSL3::SSL::Context - A context for SSL connections

=head1 VERSION

version 0.002

=head1 SYNOPSIS

my $method = Crypt::OpenSSL3::SSL::Protocol->TLS_client;
my $ctx = Crypt::OpenSSL3::SSL::Context->new($method);
$ctx->set_verify(Crypt::OpenSSL3::SSL::VERIFY_PEER);
$ctx->set_default_verify_paths();

my $ssl = Crypt::OpenSSL3::SSL->new($ctx);
my $ssl2 = Crypt::OpenSSL3::SSL->new($ctx);
my $ssl3 = Crypt::OpenSSL3::SSL->new($ctx);

=head1 DESCRIPTION

This is the global context class which is created by a server or client once per program life-time and which holds mainly default values for the SSL classes which are later created for the connections; these will have exactly the same name as in L<Crypt::OpenSSL3::SSL|Crypt::OpenSSL3::SSL>. It also contains the certificate store that is used to validate certificates and a session cache that facilitates fast reconnection.

Methods in this class generally match the C<SSL_CTX_*> namespace in C<libssl>.

=head1 METHODS

=head2 new

=head2 add_client_CA

=head2 add_extra_chain_cert

=head2 add_session

=head2 check_private_key

=head2 clear_extra_chain_certs

=head2 clear_mode

=head2 clear_options

=head2 get_cert_store

=head2 get_domain_flags

=head2 get_max_proto_version

=head2 get_min_proto_version

=head2 get_mode

=head2 get_num_tickets

=head2 get_options

=head2 get_read_ahead

=head2 load_verify_dir

=head2 load_verify_file

=head2 load_verify_locations

=head2 load_verify_store

=head2 remove_session

=head2 sess_accept

=head2 sess_accept_good

=head2 sess_accept_renegotiate

=head2 sess_cache_full

=head2 sess_cb_hits

=head2 sess_connect

=head2 sess_connect_good

=head2 sess_connect_renegotiate

=head2 sess_get_cache_size

=head2 sess_hits

=head2 sess_misses

=head2 sess_number

=head2 sess_set_cache_size

=head2 sess_timeouts

=head2 set_alpn_protos

=head2 set_cert_store

=head2 set_cipher_list

=head2 set_ciphersuites

=head2 set_default_verify_dir

=head2 set_default_verify_file

=head2 set_default_verify_paths

=head2 set_domain_flags

=head2 set_max_proto_version

=head2 set_min_proto_version

=head2 set_mode

=head2 set_num_tickets

=head2 set_options

=head2 set_post_handshake_auth

=head2 set_read_ahead

=head2 set_session_id_context

=head2 set_verify

=head2 set_verify_depth

=head2 use_PrivateKey

=head2 use_PrivateKey_ASN1

=head2 use_PrivateKey_file

=head2 use_certificate

=head2 use_certificate_ASN1

=head2 use_certificate_chain_file

=head2 use_certificate_file

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
