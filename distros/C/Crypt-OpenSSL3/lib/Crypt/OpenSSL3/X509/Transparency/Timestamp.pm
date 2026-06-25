package Crypt::OpenSSL3::X509::Transparency::Timestamp;
$Crypt::OpenSSL3::X509::Transparency::Timestamp::VERSION = '0.009';
use strict;
use warnings;

use Crypt::OpenSSL3;

1;

# ABSTRACT: An X509 certificate transparency signed timestamp

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::OpenSSL3::X509::Transparency::Timestamp - An X509 certificate transparency signed timestamp

=head1 VERSION

version 0.009

=head1 METHODS

=head2 new

=head2 new_from_base64

=head2 get_extensions

=head2 get_log_entry_type

=head2 get_log_id

=head2 get_signature

=head2 get_signature_nid

=head2 get_source

=head2 get_timestamp

=head2 get_validation_status

=head2 get_version

=head2 set_extensions

=head2 set_log_entry_type

=head2 set_log_id

=head2 set_signature

=head2 set_signature_nid

=head2 set_source

=head2 set_timestamp

=head2 set_version

=head2 validate

=head1 CONSTANTS

=over 4

=item ENTRY_TYPE_NOT_SET

=item ENTRY_TYPE_PRECERT

=item ENTRY_TYPE_X509

=item SOURCE_OCSP_STAPLED_RESPONSE

=item SOURCE_TLS_EXTENSION

=item SOURCE_UNKNOWN

=item SOURCE_X509V3_EXTENSION

=item VALIDATION_STATUS_INVALID

=item VALIDATION_STATUS_NOT_SET

=item VALIDATION_STATUS_UNKNOWN_LOG

=item VALIDATION_STATUS_UNKNOWN_VERSION

=item VALIDATION_STATUS_UNVERIFIED

=item VALIDATION_STATUS_VALID

=item VERSION_NOT_SET

=item VERSION_V1

=back

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
