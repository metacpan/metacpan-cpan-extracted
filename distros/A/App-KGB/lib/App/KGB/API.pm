# vim: ts=4:sw=4:et:ai:sts=4
#
# KGB - an IRC bot helping collaboration
# Copyright © 2012 Damyan Ivanov
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

package App::KGB::API;

use strict;
use warnings;

our $VERSION = 4;

1;

__END__

=head1 NAME

App::KGB::API -- KGB bot API documentation

=head1 VERSION 4 (JSON)

=head2 General, authentication

Version 4 uses JSON-RPC as described in
L<http://http://json-rpc.org/wiki/specification> with one extension. Since all
requests are authenticated, two HTTP headers need to be included:

=over

=item X-KGB-Project: project-name

=item X-KGB-Auth: hash

=back

The project name is the string identifying the project on the server side, and
the hash is the hexadecimal representation of the SHA-1 hash calculated over
the following data:

=over

=item Project password

This is the shared password known to the client and the server.

=item project-name

=item request-text

This is the JSON-encoded request text. The same that is sent in the HTTP body.

=back

=head2 Commit notification

Request is a JSON-RPC call to a method called B<commit_v4> with a single
argument, which is a map with the following possible keys:

=over

=item repo_id I<project-name>

=item rev_prefix I<revision-prefix>

Usually C<r> for Subversion commits

=item commit_id I<commit id>

Subversion revision, Git hash or just empty (for CVS).

=item changes I<changes list>

A list of changes, encoded as strings. It is simple file name prepended with
C<(A)> for added, C<(M)> (or nothing) for modified and C<(D)> for deleted. See
L<App::KGB::Change>.

=item commit_log I<log message>

=item author I<user/name>

=item branch I<branch name>

=item module I<module name>

=item extra I<additional information>

A map with extra information. Currently C<web_link> is the only member that the
server recognises.

=back

=head2 Plain message relay

The message relay calls are to the B<relay_message> method, with the only
argument the message to be relayed.

=head1 SEE ALSO

L<kgb-client(1)>, L<kgb-bot(1)>

=head1 AUTHOR

=over

=item Damyan Ivanov L<dmn@debian.org>

=back

=head1 COPYRIGHT & LICENSE

Copyright (C) 2012 Damyan Ivanov

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
