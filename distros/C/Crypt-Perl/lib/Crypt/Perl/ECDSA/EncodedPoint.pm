package Crypt::Perl::ECDSA::EncodedPoint;

use strict;
use warnings;

use Try::Tiny;

use Crypt::Perl::ECDSA::Utils ();
use Crypt::Perl::X ();

#input can be a string or BigInt,
#in any of “hybrid”, “uncompressed”, or “compressed” formats
sub new {
    my ($class, $input) = @_;

    my $bin;

    my $input_is_obj;
    if ( try { $input->isa('Crypt::Perl::BigInt') } ) {
        $bin = $input->as_bytes();
        $input_is_obj = 1;
    }
    else {
        $input =~ s<\A\0+><>;
        $bin = $input;
    }

    my $first_octet = ord substr( $bin, 0, 1 );

    my $self = bless {}, $class;

    #Accommodate “hybrid” points
    if ($first_octet == 6 || $first_octet == 7) {
        $self->{'_bin'} = "\x04" . substr( $bin, 1 );
    }
    elsif ($first_octet == 4) {
        $self->{'_bin'} = $bin;
    }
    elsif ($first_octet == 2 || $first_octet == 3) {
        $self->{'_compressed_bin'} = $bin;
    }
    else {
        die Crypt::Perl::X::create('Generic', sprintf "Invalid leading octet in ECDSA point: %v02x", $bin);
    }

    return $self;
}

#returns a string
sub get_compressed {
    my ($self) = @_;

    return $self->{'_compressed_bin'} ||= do {
        Crypt::Perl::ECDSA::Utils::compress_point( $self->{'_bin'} );
    };
}

#returns a string
sub get_uncompressed {
    my ($self, $curve_hr) = @_;

    die "Need curve! (p, a, b)" if !$curve_hr;

    return $self->{'_bin'} ||= do {
        die "Need compressed bin!" if !$self->{'_compressed_bin'};

        Crypt::Perl::ECDSA::Utils::decompress_point(
            $self->{'_compressed_bin'},
            @{$curve_hr}{ qw( p a b ) },
        );
    };
}

#If there’s ever a demand for “hybrid”:
#0x06 and 0x07 take the place of the uncompressed leading 0x04,
#analogous to 0x02 and 0x03 in the compressed form.

1;
