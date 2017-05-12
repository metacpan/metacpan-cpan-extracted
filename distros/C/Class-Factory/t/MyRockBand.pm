package MyRockBand;

use strict;

# Note: @ISA is modified during the test

sub init {
    my ( $self, $params ) = @_;
    $self->SUPER::init( $params );
    $self->genre( 'ROCK' );
    return $self;
}

1;
