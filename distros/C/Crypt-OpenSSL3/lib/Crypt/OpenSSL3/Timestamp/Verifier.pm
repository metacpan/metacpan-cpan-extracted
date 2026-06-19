package Crypt::OpenSSL3::Timestamp::Verifier;
$Crypt::OpenSSL3::Timestamp::Verifier::VERSION = '0.007';
use strict;
use warnings;

use Crypt::OpenSSL3;

1;

# ABSTRACT: A Timestamp Protocol verifier

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::OpenSSL3::Timestamp::Verifier - A Timestamp Protocol verifier

=head1 VERSION

version 0.007

=head1 METHODS

=head2 new

=head2 add_flags

=head2 init_from_request

=head2 set_certs

=head2 set_data

=head2 set_flags

=head2 set_imprint

=head2 set_store

=head2 verify_response

=head2 CONSTANTS

=over 4

=item * VFY_DATA

=item * VFY_IMPRINT

=item * VFY_NONCE

=item * VFY_POLICY

=item * VFY_SIGNATURE

=item * VFY_SIGNER

=item * VFY_TSA_NAME

=item * VFY_VERSION

=item * VFY_ALL_DATA

=item * VFY_ALL_IMPRINT

=back

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
