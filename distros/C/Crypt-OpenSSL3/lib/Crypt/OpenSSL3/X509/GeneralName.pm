package Crypt::OpenSSL3::X509::GeneralName;
$Crypt::OpenSSL3::X509::GeneralName::VERSION = '0.009';
use strict;
use warnings;

use Crypt::OpenSSL3;

1;

# ABSTRACT: An X509 generalized name

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::OpenSSL3::X509::GeneralName - An X509 generalized name

=head1 VERSION

version 0.009

=head1 METHODS

=head2 new

=head2 new_from_x509_name

=head2 dup

=head2 to_string

=head2 to_value

=head2 type

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
