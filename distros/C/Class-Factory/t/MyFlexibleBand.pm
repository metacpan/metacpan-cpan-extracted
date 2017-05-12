package MyFlexibleBand;

# $Id: MyFlexibleBand.pm 28 2002-02-10 17:41:10Z cwinters $

use strict;
use base qw( Class::Factory );

my %TYPES = ();
sub get_factory_type { return $TYPES{ $_[1] } }
sub set_factory_type { return $TYPES{ $_[1] } = $_[2] }

my %REGISTER = ();
sub get_register_type { return $REGISTER{ $_[1] } }
sub set_register_type { return $REGISTER{ $_[1] } = $_[2] }

sub init {
    my ( $self, $params ) = @_;
    $self->band_name( $params->{band_name} );
    return $self;
}


sub band_name {
    my ( $self, $name ) = @_;
    $self->{band_name} = $name if ( $name );
    return $self->{band_name};
}

sub genre {
    my ( $self, $genre ) = @_;
    $self->{genre} = $genre if ( $genre );
    return $self->{genre};
}

MyFlexibleBand->add_factory_type( rock    => 'MyRockBand' );
MyFlexibleBand->register_factory_type( country => 'MyCountryBand' );

1;

