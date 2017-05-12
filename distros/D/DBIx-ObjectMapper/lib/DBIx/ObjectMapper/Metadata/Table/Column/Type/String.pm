package DBIx::ObjectMapper::Metadata::Table::Column::Type::String;
use strict;
use warnings;
use base qw(DBIx::ObjectMapper::Metadata::Table::Column::Type);
use Encode;
use Scalar::Util qw(looks_like_number);

sub _init {
    my $self = shift;
    my ( $size, @opt ) = @_;
    $self->{size} = $size if $size and looks_like_number( $size );
    $self->{utf8} = 1 if grep { $_ eq 'utf8' } @opt;
}

sub from_storage {
    my ( $self, $val ) = @_;

    if( $val and $self->utf8 and !Encode::is_utf8($val) ) {
        $val = Encode::decode( 'utf8', $val )
    }

    return $val;
}

sub to_storage {
    my ( $self, $val ) = @_;

    if( defined $val and $self->utf8 and Encode::is_utf8($val) ) {
        $val = Encode::encode( 'utf8', $val )
    }

    return $val;
}

1;
