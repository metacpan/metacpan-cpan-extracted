package Datahub::Factory;

use Datahub::Factory::Sane;

our $VERSION = '1.71';

use Datahub::Factory::Env;
use Datahub::Factory::Config;
use Datahub::Factory::Pipeline;
use Sub::Exporter::Util qw(curry_method);
use Sub::Exporter -setup => {
    exports => [
        log              => curry_method,
        cfg              => curry_method,
        importer         => curry_method,
        fixer            => curry_method,
        store            => curry_method,
        exporter         => curry_method,
        pipeline         => curry_method,
        module           => curry_method,
    ],
    collectors => {'-load' => \'_import_load', ':load' => \'_import_load'},
};
use namespace::clean;

sub _import_load {
    my ($self, $value, $data) = @_;

    if (is_array_ref $value) {
      self->load(@$value);
    }
    else {
      $self->load;
    }

    1;
}

sub load {
    my $class = shift;
    my $env   = Datahub::Factory::Env->new();
    $class->_env($env);
    $class;
}

sub _env {
    my ($class, $env) = @_;
    state $loaded_env;
    $loaded_env = $env if defined $env;
    $loaded_env
        ||= Datahub::Factory::Env->new();
}

sub importer {
    my $class = shift;
    $class->_env->importer(@_);
}

sub fixer {
    my $class = shift;
    $class->_env->fixer(@_);
}

sub exporter {
    my $class = shift;
    $class->_env->exporter(@_);
}

sub log {
	$_[0]->_env->log;
}

sub cfg {
    my $cfg = Datahub::Factory::Config->new();
    return $cfg->config;
}

sub pipeline {
    my $class = shift;
    return $class->_env->pipeline(@_);
}

sub module {
    my $class = shift;
    return $class->_env->module(@_);
}

1;
__END__

=head1 NAME

Datahub::Factory - A conveyor belt which transports data from a data source to a data sink.

=begin markdown

# STATUS

[![Build Status](https://travis-ci.org/thedatahub/Datahub-Factory.svg?branch=master)](https://travis-ci.org/thedatahub/Datahub-Factory)
[![CPANTS kwalitee](https://cpants.cpanauthors.org/dist/Datahub-Factory.png)](https://cpants.cpanauthors.org/dist/Datahub-Factory)

=end markdown

=head1 SYNOPSIS

dhconveyor \[ARGUMENTS\] \[OPTIONS\]

=head1 DESCRIPTION

Datahub::Factory is a command line conveyor belt which automates three tasks:

=over

=item Data is fetched automatically from a local or remote data source.

=item Data is converted to an exchange format.

=item The output is pushed to a data sink.

=back

Datahub::Factory fetches data from several sources as specified by the _Importer_ settings, executes a L<Catmandu::Fix> and sends it to
a data sink, set by _Exporter_. Several importer and exporter modules are supported.

Datahub::Factory contains Log4perl support to monitor conveyor belt operations.

Note: This toolset is not a generic tool. It has been tailored towards the functional requirements of the Flemish Art Collection use case.

=head1 CONFIGURATION

=head2 Command line options

All commands share the following switches:

=over

=item --log_level

Set the log_level. Takes a numeric parameter. Supported levels are: 1 (WARN), 2 (INFO), 3 (DEBUG). WARN (1) is the default.

=item --log_output

Selects an output for the log messages. By default, it will send them to STDERR (pass STDERR as parameter), but STDOUT (STDOUT) and a log file (logs/import_-date-.log) (STATISTICS) are also supported.

=item --verbose

Set verbosity. Invoking the command with the --verbose, -v flag will render verbose output to the terminal.

=back

=head1 COMMANDS

=head2 help COMMAND

Documentation about command line options.

It is possible to provide either all importer and/or exporter options on the command line, or to create a _pipeline configuration file_ that sets those options.

=head2 L<transport [OPTIONS]|https://metacpan.org/pod/Datahub::Factory::Command::transport>

Fetch data from a local or remote source, convert it to an exchange format and export the data.

=head1 PLUGINS

_Datahub::Factory_ uses a plugin-based architecture, making it easy to extend with new functionality.

New commands can be added by creating a Perl module that contains a `command_name.pm` file in the `lib/Datahub/Factory/Command` path. _Datahub::Factory_ uses the L<Datahub::Factory::Command> namespace and L<App::Cmd> internally.

New L<Datahub::Factory::Importer>, L<Datahub::Factory::Exporter> and L<Datahub::Factory::Fixer> plugins can be added in the same way, in the lib/Datahub/Factory/Importer, lib/Datahub/Factory/Exporter or lib/Datahub/Factory/Fixer path. All plugins use the L<Datahub::Factory::Importer> L<Datahub::Factoryy::Exporter> or L<Datahub::Factory::Fixer> namespace and the namespace package as a L<Moose::Role>.

=head1 AUTHORS

Matthias Vandermaesen <matthias.vandermaesen@vlaamsekunstcollectie.be>
Pieter De Praetere <pieter@packed.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by PACKED, vzw, Vlaamse Kunstcollectie, vzw.

This is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License, Version 3, June 2007.

=cut
