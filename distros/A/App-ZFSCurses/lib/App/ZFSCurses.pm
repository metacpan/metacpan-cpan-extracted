package App::ZFSCurses;

use 5.006;
use strict;
use warnings;

=head1 NAME

App::ZFSCurses - L<zfscurses> backend.

=head1 VERSION

Version 1.212.

=cut

our $VERSION = '1.212';

=head1 MODULES

The App::ZFSCurses namespace is composed of 5 modules, namely:

=over 5

=item L<App::ZFSCurses::UI::Datasets>

Draw UI components showing a list of ZFS datasets.

=item L<App::ZFSCurses::UI::Snapshots>

Draw UI components showing a list of ZFS snapshots.

=item L<App::ZFSCurses::Text>

Return texts for various UI components.

=item L<App::ZFSCurses::Backend>

Perform backend operations i.e. run commands, capture results and return those
results to the UI.

=item L<App::ZFSCurses::WidgetFactory>

Draw a certain kind of widget depending on the context.

=back

=head1 AUTHOR

Patrice Clement <monsieurp at cpan.org>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2020 by Patrice Clement.

This is free software, licensed under the (three-clause) BSD License.

See the LICENSE file.

=cut

1;
