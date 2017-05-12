package Data::BISON::Decoder;

use warnings;
use strict;
use Carp;
use Data::BISON::Constants;
use Data::BISON::yEnc qw(decode_yEnc);
use Encode qw();
use Config;

use version; our $VERSION = qv( '0.0.3' );

our @ISA = qw(Data::BISON::Base);
use Data::BISON::Base {};

sub _make_object {
    my ( $self, $obj ) = @_;
    if ( $self->{backref} ) {
        push @{ $self->{objects} }, $obj;
    }
    return $obj;
}

sub _decode_int {
    my ( $self, $type, $data ) = @_;

    # TODO: Speed this up using unpack where we can
    my $len = $type - ( INT8 - 1 );
    my @rep  = splice @$data, 0, $len;
    my $byte = pop @rep;
    my $flip = ( $byte & 0x80 ) ? 0xFF : 0x00;
    my $val  = $byte ^ $flip;

    for ( 2 .. $len ) {
        $val = $val * 256 + pop @rep ^ $flip;
    }

    if ( $flip ) {

        # Restore 2s complement
        $val = -$val - 1;
    }

    return $val;
}

sub _decode_float {
    my ( $self, $type, $data ) = @_;
    my ( $len, $format ) = ( $type == FLOAT ) ? ( 4, 'f' ) : ( 8, 'd' );
    my @rep = splice @$data, 0, $len;

    if ( $Config{byteorder} eq '4321' ) {
        @rep = reverse @rep;
    }

    return unpack( $format, join '', map { chr $_ } @rep );
}

sub _decode_string {
    my ( $self, $type, $data ) = @_;

    my @str  = ();
    my $byte = shift @$data;
    while ( $byte ) {
        $byte = shift @$data if $byte == 0x5C;
        push @str, $byte;
        $byte = shift @$data;
    }

    return Encode::decode( UTF8, join '', map { chr $_ } @str );
}

sub _decode_size {
    my ( $self, $data ) = @_;
    my ( $lo, $hi ) = splice @$data, 0, 2;
    my $size = $lo + 256 * $hi;
    if ( $self->{version} > 1 && $size & 0x8000 ) {
        $size &= 0x7FFF;
        my ( $lo, $hi ) = splice @$data, 0, 2;
        $size += ( $lo + 256 * $hi ) << 15;
    }
    return $size;
}

sub _decode_version {
    my ( $self, $data ) = @_;
    my ( $tag, $lo, $hi ) = splice @$data, 0, 3;
    my $version = $lo + 256 * $hi;

    $self->{version} = $version & 0x7FFF;
    $self->{backref} = $version & 0x8000;
}

sub _decode_array {
    my ( $self, $type, $data ) = @_;
    my $size = $self->_decode_size( $data );
    my $ar = $self->_make_object( [] );
    for ( 1 .. $size ) {
        push @$ar, $self->_decode( $data );
    }

    return $ar;
}

sub _read_hash {
    my ( $self, $data, $size ) = @_;
    my $obj = $self->_make_object( {} );
    for ( 1 .. $size ) {
        my $key = $self->_decode_string( STRING, $data );
        $obj->{$key} = $self->_decode( $data );
    }
    return $obj;
}

sub _decode_hash {
    my ( $self, $type, $data ) = @_;
    my $size = $self->_decode_size( $data );
    return $self->_read_hash( $data, $size );
}

sub _decode_object {
    my ( $self, $type, $data ) = @_;
    my $size = $self->_decode_size( $data );
    my $class = $self->_decode_string( STRING, $data );

    # TODO: Map classname here

    # Validate it. We don't want to eval just /anything/
    die "Bad class name '$class'\n"
      unless $class =~ /^ \w+ (?: :: \w+ ) * $/x;

    # TODO: Find out whether the class exists before we attempt to use
    # it - it may have been defined in some other package.
    # Try to load the class
    eval "use $class";
    if ( $@ ) {
        chomp $@;
        die "Failed to load class ($@)\n";
    }

    my $obj = $self->_read_hash( $data, $size );

    return bless $obj, $class;
}

sub _decode_backref {
    my ( $self, $type, $data ) = @_;

    die "Unexpected backref\n"
      unless $self->{backref};

    my $ref = $self->_decode_size( $data );

    die "Backref out of range\n"
      if $ref < 0 || $ref >= @{ $self->{objects} };

    return $self->{objects}->[$ref];
}

sub _decode_stream {
    my ( $self, $type, $data ) = @_;
    my $size = $self->_decode_size( $data );
    my @rep = splice @$data, 0, $size;
    return join '', map { chr $_ } @rep;
}

my @TYPE_MAP = (
    undef,
    sub { return undef },
    sub { return undef },
    sub { return 1 },
    sub { return 0 },
    sub { my $self = shift; return $self->_decode_int( @_ ) },
    sub { my $self = shift; return $self->_decode_int( @_ ) },
    sub { my $self = shift; return $self->_decode_int( @_ ) },
    sub { my $self = shift; return $self->_decode_int( @_ ) },
    sub { my $self = shift; return $self->_decode_int( @_ ) },
    sub { my $self = shift; return $self->_decode_int( @_ ) },
    sub { my $self = shift; return $self->_decode_int( @_ ) },
    sub { my $self = shift; return $self->_decode_int( @_ ) },
    sub { my $self = shift; return $self->_decode_float( @_ ) },
    sub { my $self = shift; return $self->_decode_float( @_ ) },
    sub { my $self = shift; return $self->_decode_string( @_ ) },
    sub { my $self = shift; return $self->_decode_array( @_ ) },
    sub { my $self = shift; return $self->_decode_hash( @_ ) },
    sub { my $self = shift; return $self->_decode_stream( @_ ) },
    sub { my $self = shift; return $self->_decode_object( @_ ) },
    sub { my $self = shift; return $self->_decode_backref( @_ ) },
);

sub _decode {
    my $self = shift;
    my $data = shift;

    my $type = shift @$data;
    die "Unexpected end of data\n"
      unless defined $type;

    if ( my $handler = $TYPE_MAP[$type] ) {
        my $obj = $handler->( $self, $type, $data );

        # We only push scalars here to save doing it in the individual
        # handlers. HASHes, ARRAYs and OBJECTs must push themselves
        # early in case they contain a reference to themself.

        if ( $type < ARRAY && $self->{backref} ) {
            push @{ $self->{objects} }, $obj;
        }
        return $obj;
    }
    else {
        die sprintf( "Unrecognised object type 0x%02x\n", $type );
    }
}

sub decode {
    my $self = shift;

    $self->{version} = 1;
    $self->{backref} = 0;
    $self->{objects} = [];

    croak __PACKAGE__ . "->decode takes a single argument"
      unless @_ == 1;

    my $data = shift;

    if ( substr( $data, 0, 3 ) eq PWL ) {
        $data = decode_yEnc( $data );
    }

    croak "Unrecognised BISON data (no signature found)"
      unless substr( $data, 0, 3 ) eq FMB;

    my @data = map { ord $_ } split //, $data;
    my $len = @data;
    splice @data, 0, 3;

    if ( @data && $data[0] == VERSION ) {
        $self->_decode_version( \@data );
    }

    my $obj = eval { $self->_decode( \@data ) };

    if ( $@ ) {
        my $pos = $len - @data - 1;
        chomp $@;
        croak
          sprintf( "%s at offset %d (0x%x) in data stream", $@, $pos, $pos );
    }

    return $obj;
}

1;
__END__

=head1 NAME

Data::BISON::Decoder - Decode a BISON encoded data structure.

=head1 VERSION

This document describes Data::BISON::Decoder version 0.0.3

=head1 SYNOPSIS

    use Data::BISON::Decoder;

    my $dec = Data::BISON::Decoder->new;

    my $struct = $dec->decode( $bison_encoded_data );
  
=head1 DESCRIPTION

BISON is a binary format for language independent serialisation of data.
You can find Kai Jäger's original description of it here:

L<http://www.kaijaeger.com/articles/introducing-bison-binary-interchange-standard.html>

=head1 INTERFACE 

=over

=item C<< new >>

Create a new Data::BISON::Encoder.

=item C<< decode >>

Decode BISON serialized data. The data to be decoded may optionally have
been yEnc encoded; C<decode> will detect this and perform the
appropriate decoding.

The returned value is a scalar, hash reference or array reference.

=back

=head1 DIAGNOSTICS

=over

=item C<< Unrecognised BISON data (no signature found) >>

You attempted to decode data that didn't start with the BISON signature 'FMB'.

=item C<< Unrecognised object type %s at offset %s in data stream >>

The BISON parser found a syntax error at the specified offset in the data.

=back

=head1 CONFIGURATION AND ENVIRONMENT
  
Data::BISON::Decoder requires no configuration files or environment variables.

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
