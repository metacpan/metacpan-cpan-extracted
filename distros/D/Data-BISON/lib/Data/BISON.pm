package Data::BISON;

use warnings;
use strict;
use Carp;
use Data::BISON::Encoder;
use Data::BISON::Decoder;
use base qw(Exporter);

use version; our $VERSION = qv( '0.0.3' );

our @EXPORT_OK = qw( encode_bison decode_bison );

sub encode_bison {
    my $obj = shift;
    my $args = shift || {};

    my $enc = Data::BISON::Encoder->new( $args );
    return $enc->encode( $obj );
}

sub decode_bison {
    my $data = shift;
    my $args = shift || {};

    my $dec = Data::BISON::Decoder->new( $args );
    return $dec->decode( $data );
}

1;
__END__

=head1 NAME

Data::BISON - Encode or decode a BISON stream

=head1 VERSION

This document describes Data::BISON version 0.0.3

=head1 SYNOPSIS

    use Data::BISON;

    my $obj = {
        this => [ 1, 2, 3 ],
        that => { oops => 'frogs' },
    };

    my $bison = encode_bison( $obj );
    my $obj2 = decode_bison( $bison );

=head1 DESCRIPTION

BISON is a binary format for language independent serialisation of data.
You can find Kai Jäger's original description of it here:

L<http://www.kaijaeger.com/articles/introducing-bison-binary-interchange-standard.html>

Data::BISON is a thin procedural interface around the
L<Data::BISON::Encoder> and L<Data::BISON::Decoder> classes. See their
documentaion for more information.

=head1 INTERFACE

=over

=item C<< decode_bison( $data [, $options ] ) >>

Decode BISON encoded data.

    my $struct = decode_bison( $some_data );

If present the second argument is a reference to a hash of options that
is passed to the L<Data::BISON::Decoder> constructor.

=item C<< encode_bison( $data [, $options ] ) >>

Encode a data structure into BISON.

    my $data = encode_bison( $some_structure );

If present the second argument is a reference to a hash of options that
is passed to the L<Data::BISON::Encoder> constructor.

    my $struct = {
        pi => 3.1415
    };

    # Encode using doubles instead of floats
    my $data = encode_bison( $struct, { double => 1 } );

=back

=head1 DIAGNOSTICS

=over

=item C<< Illegal option(s): %s >>

You passed an illegal option to encode_bison or decode_bison. Check the
documentation for L<Data::BISON::Encoder> or L<Data::BISON::Decoder>
respectively for valid options and their meaning.

=item C<< Unrecognised BISON data (no signature found) >>

You attempted to decode data that didn't start with the BISON signature 'FMB'.

=item C<< Version must be 0.0.3 >>

Although you can specify a version to the encoder the only version
that's currently supported is 0.0.3. The version mechanism will allow
compatibility with future versions of the BISON spec.

=item C<< Maximum array / hash size is 65535 >>

Currently the number of elements in an array or hash is limited to 65535
by the encoding format used. It is hoped that a future BISON version
will raise this limit.

=item C<< Can't serialize objects yet >>

The current BISON spec does not allow for the serialization of objects.

=item C<< Unrecognised object type %s at offset %s in data stream >>

The BISON parser found a syntax error at the specified offset in the data.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Data::BISON requires no configuration files or environment variables.

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

Kai Jäger (L<< http://www.kaijaeger.com >>) designed BISON and wrote
the Javascript and PHP implementations.

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
