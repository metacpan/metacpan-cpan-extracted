package App::VTide::Command::Split;

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

extends 'App::VTide::Command::Start';

our $VERSION = version->new('0.1.17');
our $NAME    = 'split';
our $OPTIONS = [ 'test|t!', 'verbose|v+', ];
our $LOCAL   = 1;
sub details_sub { return ( $NAME, $OPTIONS, $LOCAL ) }

sub run {
    my ($self) = @_;

    my $split = shift @ARGV;
    my $v     = $self->defaults->{verbose} ? '--verbose' : '';
    my $term  = $ENV{VTIDE_TERM};
    my $cmd   = $term ? "vtide run $v" : 'bash';
    my $out   = $self->tmux_window( $term, $cmd, undef, $split );

    if ( $self->defaults->{test} ) {
        print "tmux $out\n";
        return 1;
    }

    system "tmux $out";

    return;
}

sub auto_complete {
    my ($self) = @_;
}

1;

__END__

=head1 NAME

App::VTide::Command::Split - Split tmux terminal helper

=head1 VERSION

This documentation refers to App::VTide::Command::Split version 0.1.17

=head1 SYNOPSIS

    vtide split [-t|--test] command

    OPTIONS
     command        Split command, the same format at the configuration file
     -t --test      Show the commands to slit the terminal
     -v --verbose   Show environment as well as config
        --help      Show this help
        --man       Show the full man page

    Examples
      # split the screen horizontally (keep cursor on initial screen)
      vtide split h
      # split the screen horizontally (move cursor to new screen)
      vtide split H

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head3 C<run ()>

Run the command

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
