package Crypt::OpenSSL3::X509;
$Crypt::OpenSSL3::X509::VERSION = '0.002';
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

version 0.002

=head1 METHODS

=head2 dup

=head2 digest

=head2 get_issuer_name

=head2 get_subject_name

=head2 pubkey_digest

=head2 read_pem

=head2 set_issuer_name

=head2 set_subject_name

=head2 write_pem

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
