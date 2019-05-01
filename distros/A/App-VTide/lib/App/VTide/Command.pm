package App::VTide::Command;

# Created on: 2016-01-30 15:06:14
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moo;
use warnings;
use version;
use Carp;
use English qw/ -no_match_vars /;
use File::chdir;
use Path::Tiny;
use YAML::Syck;

our $VERSION = version->new('0.1.10');

has [qw/ defaults options /] => (
    is => 'rw',
);

has vtide => (
    is       => 'rw',
    required => 1,
    handles  => [qw/ config hooks /],
);

has history => (
    is      => 'rw',
    default => sub { return path $ENV{HOME}, '.vtide/history.yml' },
);

has glob_depth => (
    is      => 'rw',
    lazy    => 1,
    default => sub { return $_[0]->config->get->{default}{glob_depth} || 3 },
);

sub save_session {
    my ( $self, $name, $dir ) = @_;

    my $file     = $self->history;
    my $sessions = eval { LoadFile( $file ) } || {};

    $sessions->{sessions}{$name} = {
        time => scalar time,
        dir  => "$dir",
    };

    DumpFile( $file, $sessions );

    return;
}

sub session_dir {
    my ( $self, $name ) = @_;
    $name ||= '';

    # there are 3 ways of determining a session name:
    #  1. Passed in directly
    #  2. Set from the environment variable VTIDE_NAME
    #  3. Found in a config file in the current directory
    if ( ! $name ) {
        die "No session name found!\n" if !-f '.vtide.yml';
        my $config = LoadFile('.vtide.yml');
        $name = $config->{name};
    }

    my $file     = $self->history;
    my $sessions = eval { LoadFile( $file ) } || {};

    my $dir = ref $sessions->{sessions}{$name} ?
        $sessions->{sessions}{$name}{dir}
        : $sessions->{sessions}{$name}
            || $ENV{VTIDE_DIR} || path('.')->absolute;

    my $config = path $dir, '.vtide.yml';

    $self->config->local_config( $config );
    $self->env( $name, $dir, $config );

    return ( $name, $dir );
}

sub env {
    my ( $self, $name, $dir, $config ) = @_;

    $dir ||= path( $ENV{VTIDE_DIR} || '.' )->absolute;
    $dir = path($dir);

    $config ||= $ENV{VTIDE_CONFIG} || $dir->path( '.vtide.yml' );
    $name   ||= $ENV{VTIDE_NAME}
        || $self->defaults->{name}
        || $self->config->get->{name}
        || $dir->basename;

    $ENV{VTIDE_NAME}   = "$name";
    $ENV{VTIDE_DIR}    = "$dir";
    $ENV{VTIDE_CONFIG} = "$config";

    return ( $name, $dir, $config );
}

sub auto_complete {
    my ($self) = @_;

    warn lc ( ref $self =~ /.*::/ ), " has no --auto-complete support\n";
    return;
}

sub _dglob {
    my ($self, $glob) = @_;

    # if the "glob" is actually a single file then just return it
    return ($glob) if -f $glob;

    my @files;
    for my $deep_glob ( $self->_globable($glob) ) {
        push @files, glob $deep_glob;
    }

    return @files;
}

sub _globable {
    my ($self, $glob) = @_;

    my ($base, $rest) = $glob =~ m{^(.*?) [*][*] /? (.*)$}xms;

    return ($glob) if !$rest;

    my @globs;
    for ( 0 .. $self->glob_depth ) {
        push @globs, $self->_globable("$base$rest");
        $base .= '*/';
    }

    return @globs;
}

1;

__END__

=head1 NAME

App::VTide::Command - Base class for VTide sub commands

=head1 VERSION

This documentation refers to App::VTide::Command version 0.1.10

=head1 SYNOPSIS

    # in a package with the prefix App::VTide::Command::
    extends 'App::VTide::Command';

    # child class code

=head1 DESCRIPTION

C<App::VTide::Command> is the base class for the sub-commands of C<vtide>.
It provides helper methods and default attributes for those commands.

=head1 SUBROUTINES/METHODS

=head2 C<new ( %hash )>

See the attributes for the arguments to pass here.

=head2 C<session_dir ( $name )>

Get the session directory for C<$name>.

=head2 C<save_session ( $name, $dir )>

Save the session and directory in the history file if it is configured. If
its not, then the environment variable C<$VTIDE_DIR> is used and failing that
falls back to the current directory. The local C<.vtide.yml> is then loaded
into the config.

=head2 C<env ( $name, $dir, $config )>

Configure the environment variables based on C<$name>, C<$dir> and C<$config>

=head2 C<auto_complete ()>

Default auto-complete action for sub-commands

=head2 C<_dglob ( $glob )>

Gets the files globs from $glob

=head2 C<_globable ( $glob )>

Converts a deep blog (e.g. **/*.js) to a series of perl globs
(e.g. ['*.js', '*/*.js', '*/*/*.js', '*/*/*/*.js'])

=head1 ATTRIBUTES

=head2 C<defaults>

Values from command line arguments

=head2 C<options>

Command line configuration

=head2 C<vtide>

Reference to parent command with configuration object.

=head2 C<history>

History configuration file

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

Copyright (c) 2016 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
