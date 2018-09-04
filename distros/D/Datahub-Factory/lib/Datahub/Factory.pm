package Datahub::Factory;

use Datahub::Factory::Sane;

our $VERSION = '1.74';

use Datahub::Factory::Env;
use Datahub::Factory::Config;
use Datahub::Factory::Pipeline;
use File::Spec;
use Sub::Exporter::Util qw(curry_method);
use Sub::Exporter -setup => {
    exports => [
        log              => curry_method,
        cfg              => curry_method,
        importer         => curry_method,
        fixer            => curry_method,
        store            => curry_method,
        exporter         => curry_method,
        indexer          => curry_method,
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
        ||= Datahub::Factory::Env->new(load_paths => $class->default_load_path);
}

sub default_load_path {    # TODO move to Catmandu::Env
    my ($class, $path) = @_;
    state $default_path;
    $default_path = $path if defined $path;
    $default_path //= do {
        my $script = File::Spec->rel2abs($0);
        my ($script_vol, $script_path, $script_name)
            = File::Spec->splitpath($script);
        my @dirs = grep length, File::Spec->splitdir($script_path);
        if ($dirs[-1] eq 'bin') {
            pop @dirs;
            File::Spec->catdir(File::Spec->rootdir, @dirs);
        }
        else {
            $script_path;
        }
    };
}

sub config {
    my ($class, $config) = @_;

    if ($config) {
        my $env = Datahub::Factory::Env->new(load_paths => $class->_env->load_paths);
        $env->_set_config($config);
        $class->_env($env);
    }

    $class->_env->config;
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

sub indexer {
    my $class = shift;
    $class->_env->indexer(@_);
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

=pod

=head1 NAME

Datahub::Factory - A conveyor belt which transports data from a data source to a data sink.

=head1 SYNOPSIS

dhconveyor command OPTIONS

=head1 DESCRIPTION

Datahub::Factory is a command line conveyor belt which automates three tasks:

=over

=item Data is fetched automatically from a local or remote data source.

=item Data is converted to an exchange format.

=item The output is pushed to a data sink.

=back

Datahub::Factory fetches data from several sources as specified by the Importer settings, 
executes a L<Catmandu::Fix> and sends it to a data sink, set via an Exporter. 
Several importer and exporter modules are provided, but developers can extend the functionality with their own modules.

Datahub::Factory contains Log4perl support.

=head1 CONFIGURATION

=head2 Command line options

All commands share the following switches:

=over

=item --log_level

Set the log_level. Takes a numeric parameter. Supported levels are: 1 (WARN), 
2 (INFO), 3 (DEBUG). WARN (1) is the default.

=item --log_output

Selects an output for the log messages. By default, it will send them to STDERR 
(pass STDERR as parameter), but STDOUT (STDOUT) and a log file.

=item --verbose

Set verbosity. Invoking the command with the --verbose, -v flag will render 
verbose output to the terminal.

=back

=head1 COMMANDS

=head2 help COMMAND

Documentation about command line options.

=head2 L<transport OPTIONS|https://metacpan.org/pod/Datahub::Factory::Command::transport>

Fetch data from a local or remote source, convert it to an exchange format and export the data.

=head2 L<transport OPTIONS|https://metacpan.org/pod/Datahub::Factory::Command::index>

Fetch data from a local source, and push it to an enterprise search engine via a bulk API.


=head1 API

Datahub::Factory uses a plugin-based architecture, making it easy to extend with new functionality.

New commands can be added by creating a Perl module that contains a `command_name.pm` file in the `lib/Datahub/Factory/Command` path. 
Datahub::Factory uses the L<Datahub::Factory::Command> namespace and leverages L<App::Cmd> internally.

New L<Datahub::Factory::Importer>, L<Datahub::Factory::Exporter> and L<Datahub::Factory::Fixer> plugins can be added in the same way. 

=head1 AUTHORS

Matthias Vandermaesen <matthias.vandermaesen@vlaamsekunstcollectie.be>
Pieter De Praetere <pieter@packed.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by PACKED, vzw, Vlaamse Kunstcollectie, vzw.

This is free software; you can redistribute it and/or modify it under the terms 
of the GNU General Public License, Version 3, June 2007.

=cut
