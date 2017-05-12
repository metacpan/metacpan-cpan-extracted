package DBD::Sys::Plugin::Meta::AllTables;

use strict;
use warnings;

use vars qw($VERSION @colNames);
use base qw(DBD::Sys::Table);

use Params::Util qw(_ARRAY);

=pod

=head1 NAME

DBD::Sys::Plugin::Meta::AllTables - DBD::Sys Table Overview

=head1 SYNOPSIS

  $alltables = $dbh->selectall_hashref("select * from alltables", "table_name");

=head1 ISA

  DBD::Sys::Plugin::Meta::AllTables
  ISA DBD::Sys::Table

=cut

@colNames = qw(table_qualifier table_owner table_name table_type remarks);
$VERSION  = "0.102";

=head1 DESCRIPTION

Columns:

=over 8

=item table_qualifier

Unused, I<NULL>.

=item table_owner

Unused, I<NULL>

=item table_name

Name of the table

=item table_type

Class name of the table implementation

=item remarks

Unused, I<NULL>

=back

=head1 METHODS

=head2 get_col_names

Returns the column names of the table

=head2 get_priority

Returns 100 - the lowest priority used by DBD::Sys delivered tables.

=cut

sub get_col_names() { @colNames }
sub get_priority    { return 100; }

=head2 collect_data

Collects the data for the table using the plugin manager.
See L<DBD::Sys::PluginManager/get_table_details> for details.

=cut

sub collect_data()
{
    my @data;
    my %tables = $_[0]->{database}->{sys_pluginmgr}->get_table_details();

    while ( my ( $table, $class ) = each(%tables) )
    {
        push( @data,
              [ undef, undef, $table, 'TABLE', _ARRAY($class) ? join( ',', @$class ) : $class ] );
    }

    return \@data;
}

=head1 PREREQUISITES

The table C<alltables> provide information about the tables in DBD::Sys, so
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
