package Crypt::OpenSSL3::X509;
$Crypt::OpenSSL3::X509::VERSION = '0.010';
use strict;
use warnings;

use Crypt::OpenSSL3;

1;

# ABSTRACT: An X509 certificate

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::OpenSSL3::X509 - An X509 certificate

=head1 VERSION

version 0.010

=head1 METHODS

=head2 new

=head2 dup

=head2 add_ext

=head2 check_ca

=head2 check_email

=head2 check_host

=head2 check_ip

=head2 check_ip_asc

=head2 check_issued

=head2 check_private_key

=head2 cmp

=head2 decode_der

=head2 delete_ext

=head2 digest

=head2 digest_sig

=head2 encode_der

=head2 encode_der_tbs

=head2 get_authority_issuer

=head2 get_authority_key_id

=head2 get_authority_serial

=head2 get_ct_precert_scts

=head2 get_default_cert_dir

=head2 get_default_cert_dir_env

=head2 get_default_cert_file

=head2 get_default_cert_file_env

=head2 get_distinguishing_id

=head2 get_ext

=head2 get_extensions

=head2 get_ext_by_NID

=head2 get_ext_by_OBJ

=head2 get_ext_by_critical

=head2 get_ext_count

=head2 get_extended_key_usage

=head2 get_extension_flags

=head2 get_issuer_alt_names

=head2 get_issuer_name

=head2 get_key_usage

=head2 get_notAfter

=head2 get_notBefore

=head2 get_pathlen

=head2 get_proxy_pathlen

=head2 get_pubkey

=head2 get_serialNumber

=head2 get_signature

=head2 get_signature_nid

=head2 get_subject_alt_names

=head2 get_subject_key_id

=head2 get_subject_name

=head2 get_tbs_sigalg

=head2 get_version

=head2 issuer_and_serial_cmp

=head2 issuer_name_cmp

=head2 issuer_name_hash

=head2 pubkey_digest

=head2 read_der

=head2 read_pem

=head2 self_signed

=head2 set_distinguishing_id

=head2 set_issuer_name

=head2 set_notAfter

=head2 set_notBefore

=head2 set_proxy_flag

=head2 set_proxy_pathlen

=head2 set_pubkey

=head2 set_serialNumber

=head2 set_subject_name

=head2 set_version

=head2 sign

=head2 sign_ctx

=head2 subject_name_cmp

=head2 subject_name_hash

=head2 verify

=head2 write_der

=head2 write_pem

=head1 CONSTANTS

=over 4

=item CHECK_FLAG_ALWAYS_CHECK_SUBJECT

=item CHECK_FLAG_MULTI_LABEL_WILDCARDS

=item CHECK_FLAG_NEVER_CHECK_SUBJECT

=item CHECK_FLAG_NO_PARTIAL_WILDCARDS

=item CHECK_FLAG_NO_WILDCARDS

=item CHECK_FLAG_SINGLE_LABEL_SUBDOMAINS

=back

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Leon Timmermans.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
