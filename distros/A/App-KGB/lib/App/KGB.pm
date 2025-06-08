# vim: ts=4:sw=4:et:ai:sts=4
#
# KGB - an IRC bot helping collaboration
# Copyright © 2008 Martina Ferrari
# Copyright © 2009 Damyan Ivanov
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the Free Software Foundation, Inc., 51
# Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

package App::KGB;

use strict;
use warnings;

=encoding UTF-8

=head1 NAME

App::KGB - collaborative IRC helper

=cut

our $VERSION = '1.62';

=head1 DESCRIPTION

B<App::KGB> is a helper aimed at people working together using version control
systems and IRC. It has two parts:

=over

=item server, L<kgb-bot(1)>

A daemon listening for commit notifications that relays them to IRC.

=item client, L<kgb-client(1)>, L<App::KGB::Client>

Hooks into the version control system and sends commit notifications to the
daemon.

=back

=head2 SUPPORTED VERSION CONTROL SYSTEMS

=over

=item Git

=item Subversion

=back

=head1 SEE ALSO

=over

=item L<kgb-client(1)>

=item L<App::KGB::Client>

=item L<kgb-bot(1)>

=back

=head1 AUTHOR

=over

=item Martina Ferrari L<tina@debian.org>

=item Damyan Ivanov L<dmn@debian.org>

=back

=head1 LICENSE

Copyright (C) 2008 Martina Ferrari
Copyright (C) 2008-2009, 2025 Damyan Ivanov
Copyright (C) 2023 Antoine Beaupré

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 51
Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

=cut

1;
