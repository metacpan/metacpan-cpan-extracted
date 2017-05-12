# Arch Perl library, Copyright (C) 2004 Mikhael Goikhman
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

use 5.005;
use strict;

package Arch;

use vars qw($VERSION);

$VERSION = '0.5.2';
$VERSION = eval $VERSION;

1;

__END__

=head1 NAME

Arch - GNU Arch Perl library

=head1 SYNOPSIS 

    use Arch 0.5.2;

    # perldoc Arch
    # axp man Arch

    # example: produce ChangeLog for the current project
    use Arch::Tree;

    foreach my $log (Arch::Tree->new->get_logs) {
        print "-" x 80, "\n";
        print $log->standard_date, "\n";
        print $log->summary, "\n\n";
        print $log->body;
    }


=head1 DESCRIPTION

The Arch-Perl library allows Perl developers to create GNU Arch front-ends
in an object oriented fashion. GNU Arch is a decentralized, changeset-oriented
revision control system.

Currently, a pragmatic high-level interface is built around tla or baz.
This functionality was initially developed for ArchZoom project,
and was highly enhanced to serve AXP and ArchWay projects as well.

=head1 AUTHORS

Mikhael Goikhman (migo@homemail.com--Perl-GPL/arch-perl--devel).

Enno Cramer (uebergeek@web.de--2003/arch-perl--devel).

=head1 SEE ALSO

For more information, see L<tla>,
L<Arch::Backend>,
L<Arch::Changes>,
L<Arch::Changeset>,
L<Arch::DiffParser>,
L<Arch::FileHighlighter>,
L<Arch::Inventory>,
L<Arch::Library>,
L<Arch::LiteWeb>,
L<Arch::Log>,
L<Arch::Name>,
L<Arch::Registry>,
L<Arch::RevisionBunches>,
L<Arch::Run>,
L<Arch::RunLimit>,
L<Arch::Session>,
L<Arch::SharedCache>,
L<Arch::SharedIndex>,
L<Arch::Storage>,
L<Arch::Tarball>,
L<Arch::TempFiles>,
L<Arch::Test::Archive>,
L<Arch::Test::Cases>,
L<Arch::Test::Framework>,
L<Arch::Test::Tree>.
L<Arch::Tree>,
L<Arch::Util>.

=cut
