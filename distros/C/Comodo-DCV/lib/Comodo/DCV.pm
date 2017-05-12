package Comodo::DCV;

use strict;
use warnings;

use Digest::MD5 ();
use Digest::SHA ();

our $VERSION = 0.03;

=pod

=encoding utf-8

=head1 NAME

Comodo::DCV - DCV logic for COMODO SSL APIs

=head1 SYNOPSIS

  use Comodo::DCV;

  #The following acts on a DER-formatted (i.e., binary) CSR only.
  my ($filename, $contents) = Comodo::DCV::get_filename_and_contents( $csr_der );

=head1 DESCRIPTION

This module implements logic that is necessary for HTTP-based validation
according to COMODO’s APIs for SSL certificate issuance, as documented
at L<http://secure.comodo.net/api/pdf/latest/Domain%20Control%20Validation.pdf>.

You can verify this module’s output by comparing it to that from
L<https://secure.comodo.net/utilities/decodeCSR.html>.

B<NOTE>: This module works on DER-formatted (binary) CSRs. If you need to work with
PEM-formatted (text/Base64) CSRs, first convert them via C<Crypt::Format> or similar
logic.

=cut

sub get_filename_and_contents {
    my ($csr_der) = @_;

    die 'Call in list context!' if !wantarray;

    my $md5_hash = Digest::MD5::md5_hex($csr_der);
    $md5_hash =~ tr<a-f><A-F>;

    my $filename = "$md5_hash.txt";

    my $contents = join(
        $/,
        Digest::SHA::sha1_hex($csr_der),
        'comodoca.com',
    );

    return ( $filename, $contents );
}

=pod

=head1 BUGS

Please report to L<https://github.com/FGasper/p5-Comodo-DCV/issues>.
Thank you!

=head1 AUTHOR

    Felipe Gasper
    CPAN ID: FELIPE

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;
