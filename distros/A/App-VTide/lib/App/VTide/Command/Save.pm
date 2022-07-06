package App::VTide::Command::Save;

# Created on: 2016-01-30 20:38:50
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moo;
use warnings;
use version;
use Carp;
use List::MoreUtils qw/uniq/;
use English qw/ -no_match_vars /;
use YAML::Syck;
use Path::Tiny;

extends 'App::VTide::Command::Run';

our $VERSION = version->new('0.1.17');
our $NAME    = 'save';
our $OPTIONS = [
    'name|n=s',
    'record_env|record-env|r',
    'diff_env|diff-env|d',
    'save_env|save-env|s',
    'test|T!',
    'verbose|v+',
];
sub details_sub { return ( $NAME, $OPTIONS )};

has env_store => (
    is      => 'ro',
    default => '.vtide/.current-env',
);

sub run {
    my ($self) = @_;

    if ( $self->defaults->{record_env} ) {
        $self->record_env();
        $self->hooks->run('save_record_env');
    }
    elsif ( $self->defaults->{diff_env} ) {
        $self->defaults->{verbose} = 1;
        $self->diff_env();
    }
    elsif ( $self->defaults->{save_env} ) {
        $self->save_env( $self->diff_env() );
        $self->hooks->run( 'save_save_env', $self->diff_env() );
    }
    else {
        # default name is the project name
        $self->save( $self->defaults->{name}, @ARGV );
    }

    return;
}

sub save {
    my ($self, $name, @files) = @_;

    my $file   = $ENV{VTIDE_CONFIG} || '.vtide.yml';
    my $config = LoadFile($file);

    $config->{editor}{files}{$name} = [ @files ];

    DumpFile($file, $config);

    return;
}

sub record_env {
    my ($self) = @_;

    path($self->env_store)->parent->mkpath;

    DumpFile($self->env_store, \%ENV);

    return;
}

sub diff_env {
    my ($self) = @_;

    my $old_env = LoadFile($self->env_store);
    my @keys = uniq sort keys %ENV, keys %$old_env;
    my %diff;

    for my $key (@keys) {
        next if ($ENV{$key} || '') eq ($old_env->{$key} || '');
        if ( $self->defaults->{verbose} ) {
            printf "%-15s %-45.45s %-45.45s\n", $key, $ENV{$key} || q{''}, $old_env->{$key} || q{''};
        }
        $diff{$key} = $ENV{$key};
    }

    return %diff;
}

sub save_env {
    my ($self, %env) = @_;

    my $file   = $ENV{VTIDE_CONFIG} || '.vtide.yml';
    my $config = LoadFile($file);

    if ( $self->defaults->{terminal} ) {
        my $term = $self->defaults->{terminal};
        $config->{terminals}{$term}{env} = {
            %{ $config->{terminals}{$term}{env} || {} },
            %env,
        };
    }
    else {
        $config->{default}{env} = {
            %{ $config->{default}{env} || {} },
            %env,
        };
    }

    DumpFile($file, $config);

    return;
}

1;

__END__

=head1 NAME

App::VTide::Command::Save - Save configuration changes

=head1 VERSION

This documentation refers to App::VTide::Command::Save version 0.1.17

=head1 SYNOPSIS

    vtide save [(--name|-n) files-name] file-or-glob (file-or-glob...)
    vtide save --record-env
    vtide save --diff-env
    vtide save --save-env
    vtide save [--help|--man]

  OPTIONS:
   -n --name[=]str  Save the listed files or globs to the editor files list
                    under this name (Default is the project name)
   -r --record-env  Record the current environment (use before running commands
                    like nvm, rvm and perlbrew)
   -d --diff-env    Show the diff of the current environment and recorded
                    environment
   -s --save-env    Save the environment differences to .vtide.yml
   -v --verbose     Show more verbose output.
       --help       Show this help
       --man        Show full documentation

=head1 DESCRIPTION

This L<App::VTide> command saves extra information to the C<.vtide.yml> config
file. There are two forms:

=over 4

=item files

Saving files or globs to the editor/files list makes it easier to add new
groups of files. The name of the groups is specified by the C<--name>
parameter.

=item environment

Saving environment variable changes so specific groups of environment variables
can be set up each time a session is started. This is a multi step process
where the current environment before changes are saved via C<--record=env> then
the changes are made (e.g. running L<perlbrew>, C<nvm>, C<rvm> etc) and those
changes can be viewed via C<--dif-env> and recorded to the C<.vtide.yml> file
via C<--save-env>. This creates a temporary file C<.current-env> to store the
environment variables when C<--record-env> is run.

=back

=head1 SUBROUTINES/METHODS

=head2 C<run ()>

Need to implement

=head2 C<save ($name, @files)>

Saves new file group C<$name> with the file or glob patters from C<@files>
into the local C<.vtide.yml> config file.

=head2 C<record_env ()>

Save the current environment variables to a temporary file

=head2 C<diff_env ()>

Find the environment keys that differ in the current environment vs that stored
in the temporary file

=head2 C<save_env ()>

Save environment differences to the projects C<.vtide.yml> file

=head2 C<details_sub ()>

Returns the commands details.

=head1 ATTRIBUTES

=head2 C<env_store>

The name of the temporary file for storing the environment variables

=head1 HOOKS

=head2 C<save_record_env ()>

=head2 C<save_save_env ( $diff_env )>

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
