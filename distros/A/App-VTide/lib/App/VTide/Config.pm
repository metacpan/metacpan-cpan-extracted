package App::VTide::Config;

# Created on: 2016-01-28 10:29:47
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moo;
use warnings;
use version;
use Carp;
use English qw/ -no_match_vars /;
use Path::Tiny;
use YAML::Syck qw/ LoadFile /;
use Hash::Merge::Simple qw/ merge /;

our $VERSION = version->new('0.1.9');

has global_config => (
    is      => 'rw',
    default => sub {
        mkdir path $ENV{HOME}, '.vtide' if ! -d path $ENV{HOME}, '.vtide';
        return path $ENV{HOME}, '.vtide/defaults.yml';
    },
);

has history_file => (
    is      => 'rw',
    default => sub {
        mkdir path $ENV{HOME}, '.vtide' if ! -d path $ENV{HOME}, '.vtide';
        return path $ENV{HOME}, '.vtide/history.log';
    },
);

has local_config => (
    is      => 'rw',
    lazy    => 1,
    default => sub { return path $ENV{VTIDE_CONFIG} || '.vtide.yml' },
);

has [qw/ global_time local_time /] => (
    is      => 'rw',
    lazy    => 1,
    default => 0,
);

has data => (
    is  => 'rw',
);

sub get {
    my ($self) = @_;

    if ( $self->changed ) {
        my $global_time = ( stat $self->global_config )[9];
        my $local_time = ( stat $self->local_config )[9];

        $self->global_time( $global_time );
        $self->local_time( $local_time );

        my $global = eval { LoadFile( $self->global_config ); } || {};
        my $local  = eval { LoadFile( $self->local_config );  } || {};

        $self->data( merge $global, $local );
    }

    return $self->data;
}

sub changed {
    my ($self) = @_;
    my $global_orig = $self->global_time;
    my $local_orig  = $self->local_time ;

    my $global_time = ( stat $self->global_config )[9];
    my $local_time  = ( stat $self->local_config )[9];

    $self->global_time( $global_time );
    $self->local_time ( $local_time  );

    return ! $self->data
        || ( $global_time && $global_orig < $global_time )
        || ( $local_time  && $local_orig  < $local_time  );
}

sub history {
    my ($self, @command) = @_;
    my $fh = $self->history_file->opena;
    print {$fh} '[' . localtime .'] '. (join ' ', map {/[^\w-]/ ? "'$_'" : $_} @command), "\n";
    return;
}

1;

__END__

=head1 NAME

App::VTide::Config - Manage configuration for VTide

=head1 VERSION

This documentation refers to App::VTide::Config version 0.1.9

=head1 SYNOPSIS

   use App::VTide::Config;

   my $config = App::VTide::Config->new(
        global_config => "$ENV{HOME}/.vtide/defaults.yml",
        local_config  => './.vtide.yml',
   );

   $config->get();
   # returns the merged global and local configurations (will always be up
   # to date with files on disk i.e. files are checked for changes on each
   # call)

=head1 DESCRIPTION

This module gets the global L<App::VTide> configuration and the local
project configuration data and returns the merged configuration.

=head1 SUBROUTINES/METHODS

=head2 C<get ()>

Get the merged local and global configuration files. The files are scanned
for changes each call so the current values are always returned.

=head2 C<changed ()>

Returns true if either the C<global_config> or C<local_config> files have
changed since the last read.

=head2 C<history (@command)>

Store C<@command> in history

=head1 ATTRIBUTES

=head2 global_config

The name of the global configuration file (Defaults to ~/.vtide/defaults.yml)

=head2 local_config

The name of the current project's configuration file (Defaults to ./.vtide.yml)

=head2 global_time

Last modified time for the C<global_config> file (Defaults to 0)

=head2 history_file

File to store command history

=head2 local_time

Last modified time for the C<local_config> file (Defaults to 0)

=head2 data

Cached combined global/local data

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
