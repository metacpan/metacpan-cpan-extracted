package DBD::Sys::Plugin::Unix;

use strict;
use warnings;

use vars qw($VERSION);

use base qw(DBD::Sys::Plugin);

$VERSION = "0.102";

=head1 NAME

DBD::Sys::Plugin::Unix - provides tables B<available on Unix and alike environments only>.

=head1 ISA

  DBD::Sys::Plugin::Unix
  ISA DBD::Sys::Plugin

=head1 DESCRIPTION

This plugin manages the tables for any UNIX and unixoide operating
environment.  The tables provided from here are expected to work on any
UNIX compatible operating system (beside bugs).

=head2 TABLES

=head3 pwent

Table containing user information. See L<DBD::Sys::Plugin::Unix::Users>
for details.

=head3 grent

Table containing group information. See L<DBD::Sys::Plugin::Unix::Groups>
for details.

=head1 METHODS

=head2 get_priority

Returns the default priority for unix tables, 500.

=cut

sub get_priority() { return 500; }

=head1 PREREQUISITES

This plugin only works on Unix or unixoide environments.

=head1 BUGS & LIMITATIONS

No known bugs at this moment.

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
