package Crypt::OpenSSL3::ASN1::String;
$Crypt::OpenSSL3::ASN1::String::VERSION = '0.005';
use strict;
use warnings;

use Crypt::OpenSSL3;

1;

# ABSTRACT: An ASN1 string

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::OpenSSL3::ASN1::String - An ASN1 string

=head1 VERSION

version 0.005

=head1 METHODS

=head2 cmp

=head2 dup

=head2 get_data

=head2 length

=head2 set

=head2 print

=head2 print_ex

=head2 to_UTF8

=head2 type

=head1 CONSTANTS

=over 4

=item FLGS_DUMP_ALL

=item FLGS_DUMP_DER

=item FLGS_DUMP_UNKNOWN

=item FLGS_ESC_2253

=item FLGS_ESC_2254

=item FLGS_ESC_CTRL

=item FLGS_ESC_MSB

=item FLGS_IGNORE_TYPE

=item FLGS_RFC2253

=item FLGS_SHOW_TYPE

=item FLGS_UTF8_CONVERT

=back

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
