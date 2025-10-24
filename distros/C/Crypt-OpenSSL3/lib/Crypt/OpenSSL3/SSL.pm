package Crypt::OpenSSL3::SSL;
$Crypt::OpenSSL3::SSL::VERSION = '0.002';
use strict;
use warnings;

use Crypt::OpenSSL3;

1;

# ABSTRACT: An SSL connection

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::OpenSSL3::SSL - An SSL connection

=head1 VERSION

version 0.002

=head1 SYNOPSIS

 my $ctx = Crypt::OpenSSL3::SSL::Context->new;
 $ctx->set_default_verify_paths;

 my $ssl = Crypt::OpenSSL3::SSL->new($ctx);
 $ssl->set_verify(Crypt::OpenSSL3::SSL::VERIFY_PEER);
 $ssl->set_fd(fileno $socket);
 $ssl->set_tlsext_host_name($hostname);
 $ssl->set_host($hostname);

 my $ret = $ssl->connect;
 die 'Could not connect: ' . $ssl->get_error($ret) if $ret <= 0;

 my $w_count = $ssl->write("GET / HTTP/1.1\r\nHost: www.google.com\r\n\r\n");
 die 'Could not write: ' . $ssl->get_error($w_count) if $w_count <= 0;
 my $r_count = $ssl->read(my $buffer, 2048);
 die 'Could not write: ' . $ssl->get_error($r_count) if $r_count <= 0;

=head1 DESCRIPTION

This is the main SSL/TLS class which is created by a server or client per established connection. This actually is the core class in the SSL API. At run-time the application usually deals with this class which has links to mostly all other classes.

Methods in this class generally match functions the C<SSL_*> namespace in C<libssl>.

=head1 METHODS

=head2 new

=head2 accept

=head2 accept_connection

=head2 accept_stream

=head2 add_client_CA

=head2 check_private_key

=head2 clear

=head2 clear_mode

=head2 clear_options

=head2 client_version

=head2 connect

=head2 copy_session_id

=head2 do_handshake

=head2 get_accept_connection_queue_len

=head2 get_accept_stream_queue_len

=head2 get_alpn_selected

=head2 get_blocking_mode

=head2 get_certificate

=head2 get_cipher_list

=head2 get_connection

=head2 get_context

=head2 get_current_cipher

=head2 get_domain

=head2 get_domain_flags

=head2 get_finished

=head2 get_peer_certificate

=head2 get_pending_cipher

=head2 get_error

=head2 get_event_timeout

=head2 get_fd

=head2 get_listener

=head2 get_mode

=head2 get_num_tickets

=head2 get_options

=head2 get_peer_finished

=head2 get_privatekey

=head2 get_read_ahead

=head2 get_rbio

=head2 get_rfd

=head2 get_rpoll_descriptor

=head2 get_security_level

=head2 get_session

=head2 get_servername

=head2 get_servername_type

=head2 get_ssl_method

=head2 get_stream_id

=head2 get_stream_type

=head2 get_verify_result

=head2 get_version

=head2 get_wbio

=head2 get_wfd

=head2 get_wpoll_descriptor

=head2 handle_events

=head2 has_pending

=head2 in_accept_init

=head2 in_before

=head2 in_connect_init

=head2 in_init

=head2 is_connection

=head2 is_domain

=head2 is_dtls

=head2 is_init_finished

=head2 is_listener

=head2 is_server

=head2 is_stream_local

=head2 is_tls

=head2 is_quic

=head2 listen

=head2 net_read_desired

=head2 net_write_desired

=head2 new_domain

=head2 new_from_listener

=head2 new_listener

=head2 new_listener_from

=head2 new_session_ticket

=head2 new_stream

=head2 peek

=head2 pending

=head2 read

=head2 rstate_string

=head2 rstate_string_long

=head2 sendfile

=head2 session_reused

=head2 set_accept_state

=head2 set_alpn_protos

=head2 set_blocking_mode

=head2 set_cipher_list

=head2 set_ciphersuites

=head2 set_connect_state

=head2 set_default_stream_mode

=head2 set_fd

=head2 set_host

=head2 set_incoming_stream_policy

=head2 set_initial_peer_addr

=head2 set_max_proto_version

=head2 set_min_proto_version

=head2 set_mode

=head2 set_num_tickets

=head2 set_options

=head2 set_post_handshake_auth

=head2 set_read_ahead

=head2 set_rbio

=head2 set_rfd

=head2 set_security_level

=head2 set_session

=head2 set_session_id_context

=head2 set_tlsext_host_name

=head2 set_verify

=head2 set_verify_depth

=head2 set_wbio

=head2 set_wfd

=head2 shutdown

=head2 state_string

=head2 state_string_long

=head2 stream_conclude

=head2 stream_reset

=head2 use_PrivateKey

=head2 use_PrivateKey_ASN1

=head2 use_PrivateKey_file

=head2 use_certificate

=head2 use_certificate_ASN1

=head2 use_certificate_chain_file

=head2 use_certificate_file

=head2 verify_client_post_handshake

=head2 version

=head2 write

=head1 CONSTANTS

=over 4

=item ERROR_NONE

=item ERROR_SSL

=item ERROR_SYSCALL

=item ERROR_WANT_ACCEPT

=item ERROR_WANT_ASYNC

=item ERROR_WANT_ASYNC_JOB

=item ERROR_WANT_CONNECT

=item ERROR_WANT_READ

=item ERROR_WANT_WRITE

=item ERROR_WANT_X509_LOOKUP

=item ERROR_ZERO_RETURN

=back

=over 4

=item VERIFY_NONE

=item VERIFY_PEER

=item VERIFY_CLIENT_ONCE

=item VERIFY_FAIL_IF_NO_PEER_CERT

=item VERIFY_POST_HANDSHAKE

=back

=over 4

=item TLS1_VERSION

=item TLS1_1_VERSION

=item TLS1_2_VERSION

=item TLS1_3_VERSION

=item DTLS1_VERSION

=item DTLS1_2_VERSION

=item QUIC1_VERSION

=back

=over 4

=item FILETYPE_ASN1

=item FILETYPE_PEM

=back

=over 4

=item MODE_ACCEPT_MOVING_WRITE_BUFFER

=item MODE_ASYNC

=item MODE_AUTO_RETRY

=item MODE_ENABLE_PARTIAL_WRITE

=item MODE_RELEASE_BUFFERS

=item MODE_SEND_FALLBACK_SCSV

=back

=over 4

=item ACCEPT_CONNECTION_NO_BLOCK

=item ACCEPT_STREAM_NO_BLOCK

=item DOMAIN_FLAG_BLOCKING

=item DOMAIN_FLAG_LEGACY_BLOCKING

=item DOMAIN_FLAG_MULTI_THREAD

=item DOMAIN_FLAG_SINGLE_THREAD

=item DOMAIN_FLAG_THREAD_ASSISTED

=item INCOMING_STREAM_POLICY_ACCEPT

=item INCOMING_STREAM_POLICY_AUTO

=item INCOMING_STREAM_POLICY_REJECT

=item STREAM_FLAG_ADVANCE

=item STREAM_FLAG_NO_BLOCK

=item STREAM_FLAG_UNI

=item STREAM_TYPE_BIDI

=item STREAM_TYPE_NONE

=item STREAM_TYPE_READ

=item STREAM_TYPE_WRITE

=back

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
