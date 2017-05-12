package Catalyst::Controller::HTML::FormFu::Action::MultiFormConfig;

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
            && $self->attributes->{ActionClass}[0] eq
            $config->{multiform_config_action};

    my $multi = $controller->_multiform;
    my @files = grep {length} split /\s+/, $self->{_attr_params}->[0] || '';

    if ( !@files ) {
        push @files, $self->reverse;
    }

    my $ext_regex = $config->{_file_ext_regex};

    for my $file (@files) {

        $c->log->debug( __PACKAGE__ . " searching for file '$file'" )
            if $c->debug;

        if ( $file =~ m/ \. $ext_regex \z /x ) {
            $multi->load_config_file($file);
        }
        else {
            $multi->load_config_filestem($file);
        }
    }

    $multi->process;

    $c->stash->{ $config->{multiform_stash} } = $multi;
    $c->stash->{ $config->{form_stash} }      = $multi->current_form;

    $self->next::method(@_);
}

1;
