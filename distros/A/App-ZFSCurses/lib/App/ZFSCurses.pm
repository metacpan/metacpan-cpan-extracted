package App::ZFSCurses;

use 5.006;
use strict;
use warnings;

use App::ZFSCurses::UI;

=head1 NAME

App::ZFSCurses - a curses UI to query and modify a ZFS dataset properties.

The App::ZFSCurses module is the entry point of the program.

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.01';

=head1 SYNOPSIS

App::ZFSCurses is a curses UI to query and modify a ZFS dataset properties.

=cut

=head1 METHODS

=head2 new

Create an instance of App::ZFSCurses.

=cut

sub new {
    my $class = shift;
    return bless {}, $class;
}

=head2 run

Create an instance of App::ZFSCurses::UI, draw the UI and run it.

=cut

sub run {
    App::ZFSCurses::UI->new->draw_and_run();
}

=head1 AUTHOR

Patrice Clement <monsieurp at cpan.org>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2020 by Patrice Clement.

This is free software, licensed under the (three-clause) clause BSD License.

See the LICENSE file.

=cut

1;
