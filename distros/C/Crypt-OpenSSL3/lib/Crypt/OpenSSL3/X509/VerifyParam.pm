package Crypt::OpenSSL3::X509::VerifyParam;
$Crypt::OpenSSL3::X509::VerifyParam::VERSION = '0.008';
use strict;
use warnings;

use Crypt::OpenSSL3;

1;

# ABSTRACT: X509 Verification parameters

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::OpenSSL3::X509::VerifyParam - X509 Verification parameters

=head1 VERSION

version 0.008

=head1 METHODS

=head2 new

=head2 add_policy

=head2 add_host

=head2 clear_flags

=head2 get_auth_level

=head2 get_depth

=head2 get_email

=head2 get_flags

=head2 get_host

=head2 get_hostflags

=head2 get_inh_flags

=head2 get_ip_asc

=head2 get_peername

=head2 get_purpose

=head2 get_time

=head2 set_auth_level

=head2 set_depth

=head2 set_email

=head2 set_flags

=head2 set_host

=head2 set_hostflags

=head2 set_inh_flags

=head2 set_ip

=head2 set_ip_asc

=head2 set_purpose

=head2 set_time

=head2 set_trust

=head1 CONSTANTS

=over 4

=item PURPOSE_ANY

=item PURPOSE_CODE_SIGN

=item PURPOSE_CRL_SIGN

=item PURPOSE_NS_SSL_SERVER

=item PURPOSE_OCSP_HELPER

=item PURPOSE_SMIME_ENCRYPT

=item PURPOSE_SMIME_SIGN

=item PURPOSE_SSL_CLIENT

=item PURPOSE_SSL_SERVER

=item PURPOSE_TIMESTAMP_SIGN

=item V_FLAG_ALLOW_PROXY_CERTS

=item V_FLAG_CHECK_SS_SIGNATURE

=item V_FLAG_CRL_CHECK

=item V_FLAG_CRL_CHECK_ALL

=item V_FLAG_EXPLICIT_POLICY

=item V_FLAG_EXTENDED_CRL_SUPPORT

=item V_FLAG_IGNORE_CRITICAL

=item V_FLAG_INHIBIT_ANY

=item V_FLAG_INHIBIT_MAP

=item V_FLAG_NOTIFY_POLICY

=item V_FLAG_NO_ALT_CHAINS

=item V_FLAG_NO_CHECK_TIME

=item V_FLAG_OCSP_RESP_CHECK

=item V_FLAG_OCSP_RESP_CHECK_ALL

=item V_FLAG_PARTIAL_CHAIN

=item V_FLAG_POLICY_CHECK

=item V_FLAG_SUITEB_128_LOS

=item V_FLAG_SUITEB_128_LOS_ONLY

=item V_FLAG_SUITEB_192_LOS

=item V_FLAG_TRUSTED_FIRST

=item V_FLAG_USE_CHECK_TIME

=item V_FLAG_USE_DELTAS

=item V_FLAG_X509_STRICT

=back

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
