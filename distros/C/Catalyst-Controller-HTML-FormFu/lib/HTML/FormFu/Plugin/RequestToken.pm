package HTML::FormFu::Plugin::RequestToken;

use strict;

our $VERSION = '2.01'; # VERSION

use Moose;
use MooseX::Attribute::FormFuChained;
extends 'HTML::FormFu::Plugin';

has context         => ( is => 'rw', traits  => ['FormFuChained'] );
has field_name      => ( is => 'rw', traits  => ['FormFuChained'] );
has session_key     => ( is => 'rw', traits  => ['FormFuChained'] );
has expiration_time => ( is => 'rw', traits  => ['FormFuChained'] );

sub process {
    my ($self) = @_;

    return if $self->form->get_all_element( { name => $self->field_name } );

    my $c = $self->form->stash->{'context'};

    $self->form->elements( [ {
                type            => 'RequestToken',
                name            => $self->field_name,
                expiration_time => $self->expiration_time,
                context         => $self->context,
                session_key     => $self->session_key
            } ] );

    return;
}

1;
