package DBD::Sys::Plugin::Meta;

use strict;
use warnings;

use vars qw($VERSION);
use base qw(DBD::Sys::Plugin);

$VERSION = 0.100;

=head1 NAME

DBD::Sys::Plugin::Meta - provides tables with meta information about DBD::Sys.

=head1 ISA

  DBD::Sys::Plugin::Meta
  ISA DBD::Sys::Plugin

=head1 DESCRIPTION

This plugin is created to manage the tables containing DBD::Sys meta data.

=head2 TABLES

Provided tables:

=head3 alltables

Table containing the list of available tables. See
L<DBD::Sys::Plugin::Meta::AllTables> for details.

=head1 METHODS

=cut

require DBD::Sys::Plugin::Meta::AllTables;

my %supportedTables = ( alltables => 'DBD::Sys::Plugin::Meta::AllTables', );

=head2 get_supported_tables

Delivers the supported meta tables.

=cut

sub get_supported_tables() { %supportedTables }

=head2 get_priority

Delivers the default priority for the meta tables, which is 100.

=cut

sub get_priority { return 100; }

=head1 PREREQUISITES

The meta tables provide information about the tables in DBD::Sys, so
their only requirement is DBD::Sys.

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

1;
