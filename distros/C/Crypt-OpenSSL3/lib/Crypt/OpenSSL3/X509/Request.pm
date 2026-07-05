package Crypt::OpenSSL3::X509::Request;
$Crypt::OpenSSL3::X509::Request::VERSION = '0.010';
use strict;
use warnings;

1;

# ABSTRACT: A X509 / PKCS10 certificate signing request

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::OpenSSL3::X509::Request - A X509 / PKCS10 certificate signing request

=head1 VERSION

version 0.010

=head1 METHODS

=head2 new

=head2 add_attr

=head2 add_attr_by_NID

=head2 add_attr_by_OBJ

=head2 add_attr_by_txt

=head2 add_extensions

=head2 add_extensions_nid

=head2 check_private_key

=head2 decode_der

=head2 delete_attr

=head2 digest

=head2 dup

=head2 encode_der

=head2 encode_der_tbs

=head2 get_X509_pubkey

=head2 get_attr

=head2 get_attr_by_NID

=head2 get_attr_by_OBJ

=head2 get_attr_count

=head2 get_extensions

=head2 get_distinguishing_id

=head2 get_pubkey

=head2 get_signature

=head2 get_signature_nid

=head2 get_subject_name

=head2 get_version

=head2 read_der

=head2 read_pem

=head2 set_distinguishing_id

=head2 set_pubkey

=head2 set_signature

=head2 set_signature_algo

=head2 set_subject_name

=head2 set_version

=head2 sign

=head2 sign_ctx

=head2 verify

=head2 write_der

=head2 write_pem

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Leon Timmermans.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
