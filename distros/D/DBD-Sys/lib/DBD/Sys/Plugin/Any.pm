package DBD::Sys::Plugin::Any;

use strict;
use warnings;

use vars qw($VERSION);

use base qw(DBD::Sys::Plugin);

$VERSION = "0.102";

#################### main pod documentation start ###################

=head1 NAME

DBD::Sys::Plugin::Any - provides tables available for any known operating system
using filesystems.

=head1 ISA

  DBD::Sys::Plugin::Any
  ISA DBD::Sys::Plugin

=head1 DESCRIPTION

This plugin manages the tables for any operating system. The tables provided
from here are expected to work everywhere (beside bugs).

=head2 TABLES

This plugin provides access to following tables:

=head3 filesystems

Table containing information about the filesystem, e.g. mountpoint, label,
etc. See L<DBD::Sys::Plugin::Any::FileSys> for details.

=head3 filesysdf

Table containing group informations. See L<DBD::Sys::Plugin::Any::FileSysDf>
for details.

=head3 procs

Table containing process information. See L<DBD::Sys::Plugin::Any::Procs>
for details.

=head3 netint

Table containing network interface information. See
L<DBD::Sys::Plugin::Any::NetInterface> for details.

=head1 METHODS

=head2 get_priority

Delivers the default priority for the tables for any operating system,
which is 100.

=cut

sub get_priority() { return 100; }

=head1 BUGS & LIMITATIONS

No known bugs at this moment.

The implementation of L<Proc::ProcessTable> is very limited for several
platforms and should improved. L<Net::Interface> lacks MSWin32 support
and needs help porting from autoconf to hints framework.

=head1 AUTHOR

    Jens Rehsack			Alexander Breibach
    CPAN ID: REHSACK
    rehsack@cpan.org			alexander.breibach@googlemail.com
    http://www.rehsack.de/

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SUPPORT

Free support can be requested via regular CPAN bug-tracking system. There is
no guaranteed reaction time or solution time, but it's always tried to give
accept or reject a reported ticket within a week. It depends on business load.
That doesn't mean that ticket via rt aren't handles as soon as possible,
that means that soon depends on how much I have to do.

Business and commercial support should be acquired from the authors via
preferred freelancer agencies.

=cut

1;    # every module must end like this
