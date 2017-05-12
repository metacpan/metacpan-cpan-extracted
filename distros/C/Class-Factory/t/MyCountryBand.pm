package MyCountryBand;

use strict;

# Note: @ISA is modified during the test

sub init {
    my ( $self, $params ) = @_;
    $self->SUPER::init( $params );
    $self->genre( 'COUNTRY' );
    return $self;
}

1;
