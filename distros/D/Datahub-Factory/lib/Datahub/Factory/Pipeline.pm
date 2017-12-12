package Datahub::Factory::Pipeline;

use Datahub::Factory::Sane;

our $VERSION = '1.73';

use Moose::Role;
use Config::Simple;
use namespace::clean;

has file_name    => (is => 'ro', required => 1);
has config       => (is => 'lazy');

requires 'parse';

sub _build_config {
    my $self = shift;
    return new Config::Simple($self->file_name);
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



