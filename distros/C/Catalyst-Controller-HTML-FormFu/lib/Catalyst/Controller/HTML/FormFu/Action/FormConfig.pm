package Catalyst::Controller::HTML::FormFu::Action::FormConfig;

use strict;

our $VERSION = '2.01'; # VERSION

use Moose;
use Config::Any;
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
            && $self->attributes->{ActionClass}[0] eq $config->{config_action};

    my $form = $controller->_form;
    my @files = grep {length} split /\s+/, $self->{_attr_params}->[0] || '';

    if ( !@files ) {
        push @files, $self->reverse;
    }

    my $ext_regex = $config->{_file_ext_regex};

    for my $file (@files) {
        $c->log->debug( __PACKAGE__ . " loading config file '$file'" )
            if $c->debug;

        if ( $file =~ m/ \. $ext_regex \z /x ) {
            $form->load_config_file($file);
        }
        else {
            $form->load_config_filestem($file);
        }
    }

    $form->process;

    $c->stash->{ $config->{form_stash} } = $form;

    $self->next::method(@_);
}

1;
