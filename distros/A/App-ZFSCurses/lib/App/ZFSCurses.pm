package App::ZFSCurses;

use 5.006;
use strict;
use warnings;

=head1 NAME

App::ZFSCurses - a curses UI to query and modify a ZFS dataset properties.

=head1 VERSION

Version 1.100.

=cut

our $VERSION = '1.100';

=head1 SYNOPSIS

App::ZFSCurses is a curses UI to query and modify a ZFS dataset properties.

=cut

=head1 MODULES

App::ZFSCurses is composed of 4 modules, namely:

=over 4

=item L<App::ZFSCurses::UI>

Draw the UI components.

=item L<App::ZFSCurses::Text>

Return the text messages for various UI components.

=item L<App::ZFSCurses::Backend>

Perform so-called backend operations i.e. running commands.

=item L<App::ZFSCurses::WidgetFactory>

Draw a certain kind of widget depending on the context.

=back

=head1 AUTHOR

Patrice Clement <monsieurp at cpan.org>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2020 by Patrice Clement.

This is free software, licensed under the (three-clause) clause BSD License.

See the LICENSE file.

=cut

1;
