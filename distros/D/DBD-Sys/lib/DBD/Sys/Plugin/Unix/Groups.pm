package DBD::Sys::Plugin::Unix::Groups;

use strict;
use warnings;
use vars qw($VERSION @colNames);

use base qw(DBD::Sys::Table);

$VERSION  = "0.102";
@colNames = qw(groupname grpass gid members);

=pod

=head1 NAME

DBD::Sys::Plugin::Unix::Groups - provides a table containing operating system user groups

=head1 SYNOPSIS

  $groups = $dbh->selectall_hashref("select * from grent", "groupname");

=head1 ISA

  DBD::Sys::Plugin::Unix::Groups;
  ISA DBD::Sys::Table

=head1 DESCRIPTION

This module provides the table I<grent> filled the data from the group
database C<group(5)>.

=head2 COLUMNS

=head3 groupname

Name of the group

=head3 grpass

Encrypted password of the group

=head3 gid

Numerical group id of the users primary group

=head3 members

Numerical count of the members in this group

=head1 METHODS

=head2 get_table_name

Returns 'grent'.

=cut

sub get_table_name() { return 'grent'; }

=head2 get_col_names

Returns the column names of the table as named in L</Columns>

=cut

sub get_col_names() { @colNames }

my $havegrent = 0;
eval { endgrent(); my @grentry = getgrent(); endgrent(); $havegrent = 1; };

=head2 collect_data

Retrieves the data from the group database and put it into fetchable rows.

=cut

sub collect_data()
{
    my %data;

    if ($havegrent)
    {
        setgrent();    # rewind to ensure we're starting fresh ...
        while ( my ( $name, $grpass, $gid, $members ) = getgrent() )
        {
            if ( defined( $data{$name} ) )    # FBSD seems to have a bug with multiple entries
            {
                my $row = $data{$name};
                unless (     ( $row->[0] eq $name )
                         and ( $row->[1] eq $grpass )
                         and ( $row->[2] == $gid )
                         and ( $row->[3] eq $members ) )
                {
                    warn
                      "$name is delivered more than once and the group information differs from the first one";
                }
            }
            else
            {
                $data{$name} = [ $name, $grpass, $gid, $members ];
            }
        }
        setgrent();    # rewind
        endgrent();
    }

    my @data = values %data;
    return \@data;
}

=head1 PREREQUISITES

Perl support for the functions getgrent, setgrent, endgrent is required
to provide data for the table.

=head1 AUTHOR

    Jens Rehsack			Alexander Breibach
    CPAN ID: REHSACK
    rehsack@cpan.org			alexander.breibach@googlemail.com
    http://www.rehsack.de/

=head1 ACKNOWLEDGEMENTS

Some advisories how to implement the data collecting safer and more
portable was provided by Ashish SHUKLA <ashish@freebsd.org>.

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
