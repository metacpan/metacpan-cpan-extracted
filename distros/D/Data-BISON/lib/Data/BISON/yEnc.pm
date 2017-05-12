package Data::BISON::yEnc;

use strict;
use warnings;
use Carp;

use base qw(Exporter);

our @EXPORT_OK = qw( encode_yEnc decode_yEnc );

sub encode_yEnc {
    croak "encode_yEnc needs one argument" unless @_ == 1;

    my $data = shift;
    my @data = map { ord $_ } split //, $data;
    my @out  = ();
    while ( defined( my $byte = shift @data ) ) {
        my $rep = ( $byte + 42 ) & 0xFF;
        if (   $rep == 0x00
            || $rep == 0x0A
            || $rep == 0x0D
            || $rep == 0x3D ) {
            push @out, 0x3D;
            $rep = ( $rep + 64 ) & 0xFF;
        }
        push @out, $rep;
    }

    return join '', map { chr $_ } @out;
}

sub decode_yEnc {
    croak "decode_yEnc needs one argument" unless @_ == 1;

    my $data = shift;
    my @data = map { ord $_ } split //, $data;
    my @out  = ();
    while ( defined( my $byte = shift @data ) ) {
        next
          if $byte == 0x00
          || $byte == 0x0A
          || $byte == 0x0D;
        if ( $byte == 0x3D ) {
            my $next = shift @data;
            croak "Escape character at end of data"
              unless defined $next;
            $byte = ( $next - 64 ) & 0xFF;
        }
        push @out, ( $byte - 42 ) & 0xFF;
    }

    return join '', map { chr $_ } @out;
}

1;

=head1 NAME

Data::BISON::yEnc - Implements yEnc encode, decode for Data::BISON

=head1 VERSION

This document describes Data::BISON::yEnc version 0.0.3

=head1 SYNOPSIS

    use Data::BISON::yEnc qw(encode_yEnc decode_yEnc);

    my $encoded = encode_yEnc( 'Some text or maybe binary data' );
    print decode_yEnc( $encoded );
  
=head1 DESCRIPTION

yEnc is an encoding that allows arbitrary binary data to be encoded as
8 bit ASCII. The encoded data will not include the characters 0x00,
0x09, 0x0A or 0x0D so it can be safely reformatted without losing its
original meaning.

The full yEnc specification describes an envelope scheme that allows
multiple binary files to be encoded a la MIME multipart or uuencode.
This implementation only performs encoding and decoding of binary data
into yEnc. See L<Convert::yEnc> for a more complete implementation.

For more about yEnc see L<http://www.yenc.org/>.

=head1 INTERFACE 

=over

=item C<< encode_yEnc >>

Encode arbitrary binary data using the yEnc encoding scheme.

    my $safe = encode_yEnc( $binary_data );

=item C<< decode_yEnc >>

Decode data that has been encoded using yEnc.

    my $data = decode_yEnc( $yenc );

=back

=head1 DIAGNOSTICS

=over

=item C<< encode_yEnc needs one argument >>

encode_yEnc takes a single argument - a string containing the binary
data to be encoded.

=item C<< decode_yEnc needs one argument >>

decode_yEnc takes a single argument - a string containing the yEnc
encoded data to be decoded.

=item C<< Escape character at end of data >>

The yEnc escape character (0x3D) was found as the last character in the
data to be decoded. The escape character should always be followed by
the character it escapes.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Data::BISON::yEnc requires no configuration files or environment variables.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-data-bison@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Andy Armstrong C<< <andy@hexten.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
