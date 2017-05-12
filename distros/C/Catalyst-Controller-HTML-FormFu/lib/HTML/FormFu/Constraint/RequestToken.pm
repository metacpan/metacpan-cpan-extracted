package HTML::FormFu::Constraint::RequestToken;

use strict;

our $VERSION = '2.01'; # VERSION

use Moose;

extends 'HTML::FormFu::Constraint';

sub BUILD {
    my ( $self, $args ) = @_;

    $self->message($self->parent->message);

    return;
}

sub constrain_value {
    my ( $self, $value ) = @_;

    return $self->parent->verify_token( $value );
}

1;
