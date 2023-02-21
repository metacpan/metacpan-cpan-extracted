package App::VTide::Command::Refresh;

# Created on: 2016-03-22 15:42:06
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moo;
use warnings;
use version;
use Carp;
use English qw/ -no_match_vars /;
use YAML::Syck;

extends 'App::VTide::Command::Run';

our $VERSION = version->new('0.1.20');
our $NAME    = 'refresh';
our $OPTIONS = [
    'force|f',
    'verbose|v+',
];
sub details_sub { return ( $NAME, $OPTIONS )};

sub run {
    my ($self) = @_;

    # re-read sub-comand configs
    $self->vtide->_generate_sub_command;

    # check that all the sessions still exist
    $self->clean_sessions();

    return;
}

sub clean_sessions {
    my ( $self) = @_;

    my $file     = $self->history;
    my $sessions = eval { LoadFile( $file ) } || {};

    for my $session (keys %{ $sessions->{sessions} }) {
        my $dir = ref $sessions->{sessions}{$session}
            ? $sessions->{sessions}{$session}{dir}
            : $sessions->{sessions}{$session};

        if ( ! -d $dir || ! -f "$dir/.vtide.yml" ) {
            warn "$session ($dir) is missing\n";
            $self->hooks->run('refresh_session_missing', $session, $dir);
            delete $sessions->{sessions}{$session} if $self->defaults->{force};
        }
    }

    DumpFile( $file, $sessions );

    return;
}

sub auto_complete {
    my ($self) = @_;
}

1;

__END__

=head1 NAME

App::VTide::Command::Refresh - Refresh App::VTide configurations

=head1 VERSION

This documentation refers to App::VTide::Command::Refresh version 0.1.20

=head1 SYNOPSIS

    vtide refresh [-f|--force]

    OPTIONS
     -f --force     When sessions are mising this will force the removal of the reference
     -v --verbose   Show environment as well as config
        --help      Show this help
        --man       Show the full man page

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head3 C<run ()>

Run the command

=head2 C<clean_sessions ()>

Clean up sessions which no longer exist.

=head2 C<auto_complete ()>

Auto completes sub-commands that can have help shown

=head2 C<details_sub ()>

Returns the commands details

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
