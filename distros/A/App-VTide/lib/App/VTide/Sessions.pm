package App::VTide::Sessions;

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
use Path::Tiny;
use YAML::Syck qw/ LoadFile DumpFile /;

our $VERSION = version->new('0.1.20');

has sessions_file => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        if ( $ENV{VTIDE_DIR} && -d $ENV{VTIDE_DIR} ) {
            mkdir path $ENV{VTIDE_DIR}, '.vtide'
              if !-d path $ENV{VTIDE_DIR}, '.vtide';
            return path $ENV{VTIDE_DIR}, '.vtide/sessions.yml';
        }

        mkdir path $ENV{HOME}, '.vtide' if !-d path $ENV{HOME}, '.vtide';
        return path $ENV{HOME}, '.vtide/sessions.yml';
    },
);

has sessions => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my ($self) = @_;
        my $file = $self->sessions_file;
        if ( -f $file ) {
            return LoadFile($file);
        }

        return {};
    }
);

sub add_session {
    my ( $self, @session ) = @_;
    my $sessions = $self->sessions;
    $sessions->{current} ||= [];
    push @{ $sessions->{current} }, \@session;
    $self->write_session();
}

sub write_session {
    my ($self) = @_;
    my $file = $self->sessions_file;
    DumpFile $file, $self->sessions;
}

1;

__END__

=head1 NAME

App::VTide::Sessions - Manage start and edit session

=head1 VERSION

This documentation refers to App::VTide::Sessions version 0.1.20

=head1 SYNOPSIS

   use App::VTide::Sessions;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.

=head1 DESCRIPTION

This module provides the basis from running user defined hooks. Those hooks
are located in the C<~/.vtide/hooks.pl> and C<$PROJECT/.vtide/hooks.pl> files.
They are perl files that are expected to return a hash where the keys are the
hook names and the values are subs to be run. Details about individual hooks
can be found in the various sub-command modules.

=head1 SUBROUTINES/METHODS

=head2 C<run ( $hook, @args )>

The the hook C<$hook> with the supplied arguments.

=head1 ATTRIBUTES

=head2 vtide

Reference to the vtide object

=head2 hook_cmds

Hash of configured hook subroutines

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
