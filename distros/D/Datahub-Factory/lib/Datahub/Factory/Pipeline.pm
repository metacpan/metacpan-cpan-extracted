package Datahub::Factory::Pipeline;

use Datahub::Factory::Sane;

use Moo;
use namespace::clean;
use Config::Simple;
use Data::Dumper;

has file_name    => (is => 'ro', required => 1);
has config       => (is => 'lazy');

sub _build_config {
    my $self = shift;
    return new Config::Simple($self->file_name);
}

sub parse {
    my $self = shift;
    my $options;

    # Set the id_path of the incoming item. Points to the identifier of an object.

    if (!defined($self->config->param('Importer.id_path'))) {
        Datahub::Factory::InvalidPipeline->throw(
            'message' => sprintf('Missing required property id_path in the [Importer] block.')
        );
    }
    $options->{'id_path'} = $self->config->param('Importer.id_path');

    # Importer

    my $importer = $self->config->param('Importer.plugin');
    if (!defined($importer)) {
        Datahub::Factory::InvalidPipeline->throw(
            'message' => sprintf('Undefined value for plugin at [Importer]')
        );
    }

    $options->{'importer'} = {
        'name'    => $importer,
        'options' => $self->plugin_options('importer', $importer)
    };

    # Exporter

    my $exporter = $self->config->param('Exporter.plugin');
    if (!defined($exporter)) {
        Datahub::Factory::InvalidPipeline->throw(
            'message' => sprintf('Undefined value for plugin at [Exporter]')
        );
    }

    $options->{'exporter'} = {
        'name'    => $exporter,
        'options' => $self->plugin_options('exporter', $exporter)
    };

    # Fixers

    # Default fixer

    my $fixer = $self->config->param('Fixer.plugin');
    if (!defined($fixer)) {
        die 'Undefined value for plugin at [Fixer]'; # Throw Error object instead
    }

    my $plugin_options = $self->plugin_options('fixer', $fixer);

    # Validate if both condition_path or fixers properties are present
    if (!defined($plugin_options->{'file_name'})) {
        if (!defined($plugin_options->{'condition_path'})) {
            Datahub::Factory::InvalidPipeline->throw(
                'message' => sprintf('The "condition_path" was not set correctly.')
            );
        }

        if (!defined($plugin_options->{'fixers'})) {
            Datahub::Factory::InvalidPipeline->throw(
                'message' => sprintf('The "fixers" was not set correctly.')
            );
        }
    }

    # If fixers exist, check if comma separated list, if not throw validation error

    $options->{'fixer'}->{'plugin'} = $fixer;

    $options->{'fixer'}->{$fixer} = {
        'name' => $fixer,
        'options' => $self->plugin_options('fixer', $fixer)
    };

    my $conditional_fixers = $options->{'fixer'}->{$fixer}->{'options'}->{'fixers'};
    foreach my $conditional_fixer (@{$conditional_fixers}) {
        $options->{'fixer'}->{'conditionals'}->{$conditional_fixer} = {
            'name' => $conditional_fixer,
            'options' => $self->block_options(sprintf('plugin_fixer_%s', $conditional_fixer))
        };
    }

    return $options;
}

sub plugin_options {
    my ($self, $plugin_type, $plugin_name) = @_;
    return $self->block_options(sprintf('plugin_%s_%s', $plugin_type, $plugin_name));
}

sub module_options {
    my ($self, $module_name) = @_;
    return $self->block_options(sprintf('module_%s', $module_name));
}

sub block_options {
    my ($self, $plugin_block_name) = @_;
    return $self->config->get_block($plugin_block_name);
}

1;

__END__

=encoding utf-8

=head1 NAME

Datahub::Factory::Pipeline - The Pipeline configuration handler class.

=head1 DESCRIPTION

This class reads, parses and validates a pipeline INI configuration file and
stores the resulting configuration in a hash. This hash is used in the transport
command.

A pipeline is a transport line between two systems. In the realm of Digital
Culture and GLAM (Galleries, Libraries, Archives & Museums) this will typically
be a connection between the API's of a registration or records management system
and an intermediary system (i.e. aggregator) or a consumer application (i.e.
website)

The structure of the hash looks like this:

    my $opts = {
        id_path => 'path_to_identifier',
        importer => {
            name => 'Name of the importer',
            options => { ... }
        },
        exporter => {
            name => 'Name of the exporter',
            options => { ... }
        },
        fixers => {
            'fixer_foo' => {
                name => 'Name of the fixer foo',
                options => { ... }
            },
            'fixer_bar' => {
                name => 'Name of the fixer bar',
                options => { ... }
            }
        }
    };

=head1 AUTHORS

Pieter De Praetere <pieter@packed.be>
Matthias Vandermaesen <matthias.vandermaesen@vlaamsekunstcollectie.be>

=head1 COPYRIGHT

Copyright 2016 - PACKED vzw, Vlaamse Kunstcollectie vzw

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the terms of the GPLv3.

=cut



