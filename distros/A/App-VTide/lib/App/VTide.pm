package App::VTide;

# Created on: 2016-01-28 09:58:07
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moo;
use warnings;
use version;
use Carp;
use English qw/ -no_match_vars /;
use Getopt::Alt;
use App::VTide::Config;
use App::VTide::Hooks;
use Path::Tiny;
use File::Touch;
use YAML::Syck qw/ LoadFile DumpFile /;

our $VERSION = version->new('0.1.17');

has config => (
    is      => 'rw',
    lazy    => 1,
    default => sub { return App::VTide::Config->new() },
);
has hooks => (
    is      => 'rw',
    lazy    => 1,
    default => sub { return App::VTide::Hooks->new( vtide => $_[0] ) },
);
has sub_commands => (
    is      => 'rw',
    lazy    => 1,
    builder => '_sub_commands',
);

sub run {
    my ($self) = @_;
    $self->config->history(@ARGV);
    my @sub_commands = keys %{ $self->sub_commands };

    my ( $options, $cmd, $opt ) = get_options(
        {   name          => 'vtide',
            conf_prefix   => '.',
            helper        => 1,
            default       => { test => 0, },
            auto_complete => sub {
                my ( $option, $auto, $errors ) = @_;
                my $sub_command = $option->files->[0] || '';
                if ( $sub_command eq '--' ) {
                    print join ' ', sort @sub_commands;
                    return;
                }
                elsif ( grep {/^$sub_command./} @sub_commands ) {
                    print join ' ', sort grep {/^$sub_command/} @sub_commands;
                    return;
                }
                elsif ( !$self->sub_commands->{$sub_command} ) {
                    unshift @{ $option->files }, $sub_command;
                    $sub_command = $ENV{VTIDE_DIR} ? 'edit' : 'start';
                }
                eval {
                    $self->load_subcommand( $sub_command, $option )
                        ->auto_complete($auto);
                    1;
                } or do {
                    print join ' ',
                        grep {/$sub_command/xms} sort @sub_commands;
                }
            },
            auto_complete_shortener => sub {
                my ( $getopt, @args ) = @_;
                my $sub_command = shift @args || '';

                if ( grep {/^$sub_command./} @sub_commands ) {
                    $getopt->cmd($sub_command);
                }
                elsif ( !$self->sub_commands->{$sub_command} ) {
                    $getopt->cmd( $ENV{VTIDE_DIR} ? 'edit' : 'start' );
                    unshift @args, $sub_command;
                }
                else {
                    $getopt->cmd($sub_command) if !$getopt->cmd;
                }

                return @args;
            },
            sub_command   => $self->sub_commands,
            help_package  => __PACKAGE__,
            help_packages => {
                map { $_ => __PACKAGE__ . '::Command::' . ucfirst $_ }
                    @sub_commands,
            },
        },
        [   'name|n=s',
            'test|T!',
            'verbose|v+',
        ],
    );

    if ( !$self->sub_commands->{ $opt->cmd } ) {
        unshift @ARGV, $opt->cmd;
        $opt->cmd( $ENV{VTIDE_DIR} ? 'edit' : 'start' );
        $opt->files( \@ARGV );
    }

    my $subcommand = eval { $self->load_subcommand( $opt->cmd, $opt ) };
    if ( !$subcommand ) {
        $subcommand
            = $self->load_subcommand( $ENV{VTIDE_DIR} ? 'edit' : 'start',
            $opt );
        my ( undef, $dir ) = $subcommand->session_dir( $opt->cmd );
        if ( !$dir ) {
            my $error = $@;
            warn $@ if $opt->opt->verbose;
            warn "Unknown command '$cmd'!\n",
                "Valid commands - ", ( join ', ', sort @sub_commands ),
                "\n";
            require Pod::Usage;
            Pod::Usage::pod2usage(
                -verbose => 1,
                -input   => __FILE__,
            );
        }
        unshift @{ $opt->files }, $opt->cmd;
    }

    return $subcommand->run;
}

sub load_subcommand {
    my ( $self, $cmd, $opt ) = @_;

    my $file   = 'App/VTide/Command/' . ucfirst $cmd . '.pm';
    my $module = 'App::VTide::Command::' . ucfirst $cmd;

    require $file;

    return $module->new(
        defaults => $opt->opt,
        options  => $opt,
        vtide    => $self,
    );
}

sub _sub_commands {
    my ($self)   = @_;
    my $sub_file = path $ENV{HOME}, '.vtide', 'sub-commands.yml';

    mkdir $sub_file->parent if !-d $sub_file->parent;

    if ( -f $sub_file && path($0)->stat->mtime ne $sub_file->stat->mtime ) {
        unlink $sub_file;
    }

    return LoadFile("$sub_file") if -f $sub_file;

    return $self->_generate_sub_command();
}

sub _generate_sub_command {
    my ($self)   = @_;
    my $sub_file = path $ENV{HOME}, '.vtide', 'sub-commands.yml';

    require Module::Pluggable;
    Module::Pluggable->import(
        require     => 1,
        search_path => ['App::VTide::Command']
    );
    my @commands = __PACKAGE__->plugins;

    my $sub_commands = {};
    for my $command ( reverse sort @commands ) {
        my ( $name, $conf ) = $command->details_sub;
        $sub_commands->{$name} = $conf;
    }

    DumpFile( $sub_file, $sub_commands );
    File::Touch->new( reference => $0 )->touch($sub_file);

    return $sub_commands;
}

1;

__END__

=head1 NAME

App::VTide - A vim/tmux based IDE for the terminal

=head1 VERSION

This documentation refers to App::VTide version 0.1.17

=head1 SYNOPSIS

    vtide [start] [project]
    vtide (init|start|edit|run|conf|grep|recent|split|refresh|save|help) [options]

  COMMANDS:
    conf    Show editor config settings
    edit    Run vim for a group of files
    grep    Run grep against configured globs
    help    Show help for vtide sub commands
    init    Initialise a new project
    recent  List recently run vtide sessions
    refresh Refreshes the autocomplete cache
    run     Run a projects terminal command
    save    Make/Save changes to a projects config file
    split   Simply split up a tmux widow (using the same syntax as the config)
    start   Open a project in Tmux

  Examples:
    # start a new project, name taken from the directory name
    vtide init
    # start a new project specifying the project name
    vtide init --name my-project
    # start the project in the current directory
    vtide start
    # start the "my-project" project previously initialised
    vtide start my-project
    # Shortcuts
    #  When not in a tmux session starting a new session
    vtide my-project
    #  When in a tmux session you can run edit with out specifying it
    vtide my-glob

=head1 DESCRIPTION

VTide provides a way to manage L<tmux> sessions. It allows for an easy way
to configure a session window and run programs or open files for editing
in them. The aim is to allow for easy project setup and management for
projects managed on the command line. L<App::VTide> also includes helpers
for loading files into editors (such as vim) in separate tmux terminals.
This can help to open pre-defined groups of files.

=head2 Philosophy

One piece of work == one project == one terminal tab. In one terminal
tmux is run with tmux windows for editing different files, running commands
and version control work.

=head1 SUBROUTINES/METHODS

=head2 C<run ()>

Run the vtide commands

=head2 C<load_subcommand ( $cmd, $opt )>

Loads the sub-command module and creates a new instance of it to return
to the caller.

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

A full description of the configuration files can be found in
L<App::VTide::Configuration>.

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2016 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
