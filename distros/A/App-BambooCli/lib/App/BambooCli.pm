package App::BambooCli;

# Created on: 2019-05-15 09:09:16
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moo;
use warnings;
use version;
use Carp;
use Scalar::Util;
use List::Util;
#use List::MoreUtils;
use Getopt::Alt;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use Path::Tiny;
use YAML::Syck qw/ LoadFile DumpFile /;
use App::BambooCli::Config;

our $VERSION = version->new('0.0.1');

has config => (
    is      => 'rw',
);

has sub_commands => (
    is      => 'rw',
    lazy    => 1,
    builder => '_sub_commands',
);

sub start {
    my ($self) = @_;
    my @sub_commands = keys %{ $self->sub_commands };

    my ($options, $cmd, $opt) = get_options(
        {
            name        => 'bamboo',
            conf_prefix => '.',
            helper      => 1,
            default     => {
                config => {},
                test   => 0,
            },
            auto_complete => sub {
                my ($option, $auto, $errors) = @_;
                my $sub_command = $option->files->[0] || '';
                if ( $sub_command eq '--' ) {
                    print join ' ', sort @sub_commands;
                    return;
                }
                elsif ( grep {/^$sub_command./} @sub_commands ) {
                    print join ' ', sort grep {/^$sub_command/} @sub_commands;
                    return;
                }
                elsif ( ! $self->sub_commands->{$sub_command} ) {
                    unshift @{$option->files}, $sub_command;
                    $sub_command = $ENV{VTIDE_DIR} ? 'edit' : 'start';
                }
                eval {
                    $self->load_subcommand( $sub_command, $option )->auto_complete($auto);
                    1;
                } or do {
                    print join ' ', grep {/$sub_command/xms} sort @sub_commands;
                }
            },
            auto_complete_shortener => sub {
                my ($getopt, @args) = @_;
                my $sub_command = shift @args || '';

                if ( grep {/^$sub_command./} @sub_commands ) {
                    $getopt->cmd($sub_command);
                }
                elsif ( ! $self->sub_commands->{$sub_command} ) {
                    $getopt->cmd( $ENV{VTIDE_DIR} ? 'edit' : 'start' );
                    unshift @args, $sub_command;
                }
                else {
                    $getopt->cmd($sub_command) if ! $getopt->cmd;
                }

                return @args;
            },
            sub_command   => $self->sub_commands,
            help_package  => __PACKAGE__,
            help_packages => {
                map {$_ => __PACKAGE__ . '::Command::' . ucfirst $_}
                @sub_commands,
            },
        },
        [
            'config|c=s%',
            'test|T!',
            'verbose|v+',
        ],
    );

    $self->config( App::BambooCli::Config->new(%{ $options->config }) );

    #if ( ! $self->sub_commands->{ $opt->cmd } ) {
    #    unshift @ARGV, $opt->cmd;
    #    $opt->cmd( $ENV{VTIDE_DIR} ? 'edit' : 'start' );
    #    $opt->files(\@ARGV);
    #}

    my $subcommand = $self->load_subcommand( $opt->cmd, $opt );
    #if ( ! $subcommand ) {
    #    $subcommand = $self->load_subcommand( $ENV{VTIDE_DIR} ? 'edit' : 'start', $opt );
    #    my (undef, $dir) = $subcommand->session_dir($opt->cmd);
    #    if ( !$dir ) {
    #        my $error = $@;
    #        warn $@ if $opt->opt->verbose;
    #        warn "Unknown command '$cmd'!\n",
    #            "Valid commands - ", ( join ', ', sort @sub_commands ),
    #            "\n";
    #        require Pod::Usage;
    #        Pod::Usage::pod2usage(
    #            -verbose => 1,
    #            -input   => __FILE__,
    #        );
    #    }
    #    unshift @{ $opt->files }, $opt->cmd;
    #}

    return $subcommand->run;
}

sub load_subcommand {
    my ( $self, $cmd, $opt ) = @_;

    my $file   = 'App/BambooCli/Command/' . ucfirst $cmd . '.pm';
    my $module = 'App::BambooCli::Command::' . ucfirst $cmd;

    require $file;

    return $module->new(
        defaults => $opt->opt,
        options  => $opt,
        bamboo   => $self,
    )->get_sub_options;
}

sub _sub_commands {
    my ($self)   = @_;
    my $sub_file = path $ENV{HOME}, '.bamboo', 'sub-commands.yml';

    mkdir $sub_file->parent if ! -d $sub_file->parent;

    return LoadFile("$sub_file") if -f $sub_file;

    return $self->_generate_sub_command();
}

sub _generate_sub_command {
    my ($self)   = @_;
    my $sub_file = path $ENV{HOME}, '.bamboo', 'sub-commands.yml';

    require Module::Pluggable;
    Module::Pluggable->import( require => 1, search_path => ['App::BambooCli::Command'] );
    my @commands = __PACKAGE__->plugins;

    my $sub_commands = {};
    for my $command (reverse sort @commands) {
        my ($name, $conf) = $command->details_sub;
        $sub_commands->{$name} = $conf;
    }

    DumpFile($sub_file, $sub_commands);

    return $sub_commands;
}

1;

__END__

=head1 NAME

App::BambooCli - The brains behind the bamboo command

=head1 VERSION

This documentation refers to App::BambooCli version 0.0.1

=head1 SYNOPSIS

   use App::BambooCli;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 C<sub_commands>

=head2 C<config>

=head2 C<start>

=head2 C<load_subcommand>

=head2 C<_sub_commands>

=head2 C<_generate_sub_command>

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2019 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
