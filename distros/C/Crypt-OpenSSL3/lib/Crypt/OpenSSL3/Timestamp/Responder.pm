package Crypt::OpenSSL3::Timestamp::Responder;
$Crypt::OpenSSL3::Timestamp::Responder::VERSION = '0.010';
use strict;
use warnings;

use Crypt::OpenSSL3;

1;

# ABSTRACT: A Timestamp Protocol responder

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::OpenSSL3::Timestamp::Responder - A Timestamp Protocol responder

=head1 VERSION

version 0.010

=head1 METHODS

=head2 new

=head2 add_failure_info

=head2 add_flags

=head2 add_md

=head2 add_policy

=head2 create_response

=head2 get_request

=head2 get_tst_info

=head2 set_accuracy

=head2 set_certs

=head2 set_clock_precision_digits

=head2 set_def_policy

=head2 set_ess_cert_id_digest

=head2 set_serial_cb

=head2 set_signer_cert

=head2 set_signer_digest

=head2 set_signer_key

=head2 set_status_info

=head2 set_status_info_cond

=head2 set_time_cb

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Leon Timmermans.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
