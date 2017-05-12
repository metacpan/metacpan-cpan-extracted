package MySimpleBand;

# $Id: MySimpleBand.pm 35 2004-10-13 02:00:44Z cwinters $

use strict;
use base qw( Class::Factory );

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

# Use these to hold logging/error messages we can inspect later

$MySimpleBand::log_msg   = '';
$MySimpleBand::error_msg = '';

sub factory_log {
    shift; $MySimpleBand::log_msg = join( '', @_ );
}

sub factory_error {
    shift; $MySimpleBand::error_msg = join( '', @_ );
}

__PACKAGE__->add_factory_type( rock => 'MyRockBand' );
__PACKAGE__->register_factory_type( country => 'MyCountryBand' );

1;

