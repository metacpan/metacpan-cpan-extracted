package DBIx::ObjectMapper::Metadata::Table::Column::Type::Bit;
use strict;
use warnings;
use Carp::Clan qw/^DBIx::ObjectMapper/;
use Try::Tiny;
use base qw(DBIx::ObjectMapper::Metadata::Table::Column::Type);

my $enable_bit_vector = 1;
try{
    require Bit::Vector;
} catch {
    #warn "Bit::Vector not installed.";
    $enable_bit_vector = 0;
};

## copied from Rose::DB

sub to_storage {
    my ( $self, $val ) = @_;

    return $val
        unless $enable_bit_vector
            and ref $val
            and ref $val eq 'Bit::Vector';

    if( $self->size ) {
        $val = Bit::Vector->new_Bin($self->size, $val->to_Bin);
        return sprintf('%0*b', $self->size, hex($val->to_Hex));
    }
    else {
        return sprintf('%b', hex($val->to_Hex));
    }
}

sub from_storage {
    my ( $self, $val ) = @_;

    return $val unless $enable_bit_vector and length($val) > 0;

    my $size = $self->size;
    if ( $val =~ /^[10]+$/ ) {
        return Bit::Vector->new_Bin( $size || length $val, $val );
    }
    elsif ( $val =~ /^\d*[2-9]\d*$/ ) {
        return Bit::Vector->new_Dec( $size || ( length($val) * 4 ), $val );
    }
    elsif ($val =~ s/^0x//
        || $val =~ s/^X'(.*)'$/$1/
        || $val =~ /^[0-9a-f]+$/i )
    {
        return Bit::Vector->new_Hex( $size || ( length($val) * 4 ), $val );
    }
    elsif ( $val =~ s/^B'([10]+)'$/$1/i ) {
        return Bit::Vector->new_Bin( $size || length $val, $val );
    }
    else {
        #warn "Could not parse bitfield value '$val'";
        #return $val;
        return Bit::Vector->new_Bin($size || length($val), unpack("B*", $val) );
    }
}


1;
