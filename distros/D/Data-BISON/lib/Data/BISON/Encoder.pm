package Data::BISON::Encoder;

use warnings;
use strict;
use Carp;
use Data::BISON::Constants;
use Data::BISON::yEnc qw(encode_yEnc);
use Scalar::Util qw(blessed);
use Scalar::Util::Numeric qw(isnum isint isfloat);
use Encode qw();
use Config;

use version; our $VERSION = qv( '0.0.3' );

our @ISA = qw(Data::BISON::Base);
use Data::BISON::Base {
    yenc    => { default => 0 },
    double  => { default => 0 },
    version => {
        default => MIN_VER,
        set     => sub {
            my ( $self, $attr, $ver ) = @_;
            if ( $ver < MIN_VER || $ver > CUR_VER ) {
                my $desc = ( MIN_VER == CUR_VER )
                  ? MIN_VER
                  : 'between ' . MIN_VER . ' and ' . CUR_VER;
                croak "Version must be $desc";
            }
            $self->{$attr} = $ver;
        },
    },
    sort => { default => 0 },
};

my @INT_LEN = ( NULL, INT8, INT16, INT24, INT32 );

sub _encode_size {
    my $self = shift;
    my $size = shift;

    if ( $size > 0xFFFF ) {
        croak "Maximum array / hash size is 65535";
    }

    return pack( 'v', $size );
}

sub _encode_string {
    my $self = shift;
    my $str  = shift;

    my $octets = Encode::encode( UTF8, $str );
    $octets =~ s{(\\|\0)}{\\$1}g;

    return $octets . "\0";
}

sub _encode_hash {
    my $self = shift;
    my $hash = shift;

    my @enc = ();

    my @keys = keys %$hash;
    @keys = sort @keys if $self->sort;

    push @enc, $self->_encode_size( scalar @keys );

    for my $key ( @keys ) {
        push @enc, $self->_encode_string( $key );
        push @enc, $self->_encode_obj( $hash->{$key} );
    }

    return join( '', @enc );
}

sub _encode_array {
    my $self  = shift;
    my $array = shift;

    my @enc = ();
    push @enc, $self->_encode_size( scalar @$array );
    push @enc, map { $self->_encode_obj( $_ ) } @$array;

    return join( '', @enc );
}

# Unlike the above these return a serialized value /with/ the type byte
# prepended.

sub _encode_int {
    my $self = shift;
    my $int  = shift;

    my @rep = map { ord } split( //, pack( 'V', $int ) );

    # Trim extra bytes
    if ( $int < 0 ) {
        push @rep, 0xFF;
        pop @rep while @rep > 1 && $rep[-1] == 0xFF && $rep[-2] >= 0x80;
    }
    else {
        push @rep, 0x00;
        pop @rep while @rep > 1 && $rep[-1] == 0x00 && $rep[-2] < 0x80;
    }

    return chr( $INT_LEN[@rep] ) . pack( 'C*', @rep );
}

sub _encode_float {
    my $self  = shift;
    my $float = shift;

    my $rep = pack( $self->double ? 'd' : 'f', $float );

    if ( $Config{byteorder} eq '4321' ) {
        $rep = join( '', reverse split( //, $rep ) );
    }

    return chr( $self->double ? DOUBLE: FLOAT ) . $rep;
}

sub _encode_obj {
    my $self = shift;
    my $obj  = shift;

    if ( !defined $obj ) {
        return chr( UNDEF );
    }
    elsif ( my $type = ref $obj ) {
        if ( $type eq 'HASH' ) {
            return chr( HASH ) . $self->_encode_hash( $obj );
        }
        elsif ( $type eq 'ARRAY' ) {
            return chr( ARRAY ) . $self->_encode_array( $obj );
        }
        elsif ( blessed $obj ) {
            croak "Can't serialize objects yet";
        }
    }
    elsif ( isnum $obj) {
        if ( isint $obj ) {
            return $self->_encode_int( $obj );
        }
        else {
            return $self->_encode_float( $obj );
        }
    }
    else {
        return chr( STRING ) . $self->_encode_string( $obj );
    }
}

sub _encode {
    my $self = shift;

    return FMB . $self->_encode_obj( shift );
}

sub encode {
    my $self = shift;

    croak __PACKAGE__ . "->encode takes a single argument"
      unless @_ == 1;

    my $obj = shift;

    my $enc_data = $self->_encode( $obj );

    if ( $self->yenc ) {
        return encode_yEnc( $enc_data );
    }

    return $enc_data;
}

1;
__END__

=head1 NAME

Data::BISON::Encoder - Encode a BISON encoded data structure.

=head1 VERSION

This document describes Data::BISON::Encoder version 0.0.3

=head1 SYNOPSIS

    use Data::BISON::Encoder;

    my $enc = Data::BISON::Encoder->new;

    my $struct = {
        counter => [ 1, 2, 'three' ],
        names => {
            'Andy' => 'Armstrong',
            'Kai'  => 'Jäger',
        },
    };

    my $data = $enc->encode( $struct );

=head1 DESCRIPTION

BISON is a binary format for language independent serialisation of data.
You can find Kai Jäger's original description of it here:

L<http://www.kaijaeger.com/articles/introducing-bison-binary-interchange-standard.html>

=head1 INTERFACE

=over

=item C<< new( [ $args ] ) >>

Create a new Data::BISON::Encoder. Any options must be passed as a hash reference like this:

    my $enc = Data::BISON::Encoder->new( {
        double => 1,
        yenc => 1
    } );

These options are supported:

=over

=item * double

Normally floating point values will be encoded using 4 byte 'float'
format. Set this option to have them encoded as 8 byte doubles instead.

=item * yenc

Set this option to a true value to have the resulting data encoded using
the yEnc encoding scheme which makes it 8 bit ASCII safe.
Data::BISON::Decoder automatically detects and handles yEnc encoding.

=item * version

Set the version of the BISON specification to use for encoding.
Currently only version 1 is supported.

=back

=item C<< encode >>

Serialize a data structure using BISON encoding. The argument must be a
scalar, hash reference or array reference. Serialization of objects is
not handled by the current version of BISON.

The returned value is a binary string containing the BISON
representation of the data.

    my $encoder = Data::BISON::Encoder->new;

    my $d1 = $encoder->encode( 'A simple scalar' );
    my $d2 = $encoder->encode( 1.23456 );
    my $d3 = $encoder->encode( [ 4, 5, 6 ] );

As of BISON version 0.0.3 the maximum number of elements for an encoded
array or hash is 65535, just like in the olden days. It seems likely
that this limit will be removed in a future version of BISON. Note that
this limitation is part of the BISON specification rather than of this
implementation of it.

=item C<< version >>

Get or set the version of the BISON format to be used by the encoder.
Currently only version 0.0.3 is supported.

    my $v = $enc->version;

    $enc->version('0.0.3');

=item C<< yenc >>

Get or set the yEnc encoding flag. If true output from the encoder is
passed through encode_yEnc.

=item C<< double >>

Get or set the double flag. If true floating point values will be
encoded as 8 byte doubles. If false (the default) they are encoded as
four byte floats.

=back

=head1 DIAGNOSTICS

=over

=item C<< Illegal option(s): %s >>

You passed an illegal option to new. The supported options are C<yenc>,
C<double> and C<version>.

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

=back

=head1 CONFIGURATION AND ENVIRONMENT

Data::BISON::Encoder requires no configuration files or environment variables.

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
