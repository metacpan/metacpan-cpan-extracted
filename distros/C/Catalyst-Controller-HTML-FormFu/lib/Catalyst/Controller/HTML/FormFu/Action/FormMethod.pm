package Catalyst::Controller::HTML::FormFu::Action::FormMethod;

use strict;

our $VERSION = '2.01'; # VERSION

use Moose;
use Carp qw( croak );
use namespace::autoclean;

extends 'Catalyst::Controller::HTML::FormFu::ActionBase::Form';

sub execute {
    my $self = shift;
    my ( $controller, $c ) = @_;

    if ( $self->reverse =~ $self->_form_action_regex ) {
        # don't load form again
        return $self->next::method(@_);
    }

    my $config = $controller->_html_formfu_config;

    return $self->next::method(@_)
        unless exists $self->attributes->{ActionClass}
            && $self->attributes->{ActionClass}[0] eq $config->{method_action};

    my $form = $controller->_form;

    for ( @{ $self->{_attr_params} } ) {
        for my $method (split) {
            $c->log->debug($method) if $c->debug;

            my $args = $controller->$method($c) || {};

            $form->populate($args);
        }
    }

    $form->process;

    $c->stash->{ $config->{form_stash} } = $form;

    $self->next::method(@_);
}

1;
