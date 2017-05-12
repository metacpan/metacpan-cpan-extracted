package DBD::Sys::Plugin::Unix::Logins;

use strict;
use warnings;
use vars qw($VERSION @colNames);

use base qw(DBD::Sys::Table);

$VERSION  = "0.102";
@colNames = qw(username id line pid type host timestamp);

my $haveSysUtmp;

=pod

=head1 NAME

DBD::Sys::Plugin::Unix::Logins - provides a table containing logged on users

=head1 SYNOPSIS

  $logins = $dbh->selectall_hashref("select * from logins", "time");

=head1 ISA

  DBD::Sys::Plugin::Unix::Logins;
  ISA DBD::Sys::Table

=head1 DESCRIPTION

This module provides the table I<logins> filled with the data from the utmp
database C<utmp(5)>.

=head2 COLUMNS

=head3 username

Username if this is a record for a user process. Some systems may return
other information depending on the record type. If no user was set this
entry is skipped.

=head3 id

The identifier for this record - it might be the inittab tag or some other
system dependent value. If the system lacks support for this field, it's
a counted number.

=head3 line

For user process records this will be the name of the terminalor line that
the user is connected on.

=head3 pid

The process ID of the process that created this record.

=head3 type

The type of the record. See L<Sys::Utmp::Utent> for details.

=head3 host

On systems which support this the method will return the hostname of the
host for which the process that created the record was started - for
example for a telnet login.

=head3 timestamp

The time in epoch seconds which the record was created.

=head1 METHODS

=head2 get_table_name

Returns 'logins'.

=cut

sub get_table_name() { return 'logins'; }

=head2 get_col_names

Returns the column names of the table as named in L</Columns>

=cut

sub get_col_names() { @colNames }

=head2 get_attributes

Return the attributes supported by this module:

=head3 filename

Allows to specify an alternate filename to use. It's unused per default
and will use C<_PATH_UTMP>.

    $dbh->{sys_logins_filename} = q(/var/log/wtmp); # last logings

=cut

sub get_attributes() { return qw(filename) }

=head2 get_primary_key

Returns 'timestamp' - you must be very quick to login twice per second

=cut

sub get_primary_key() { return 'timestamp'; }

=head2 collect_data

Retrieves the data from the utmp database and put it into fetchable rows.

=cut

sub collect_data()
{
    my $self = $_[0];
    my @data;

    unless ( defined($haveSysUtmp) )
    {
        $haveSysUtmp = 0;
        eval {
            require Sys::Utmp;
            $haveSysUtmp = 1;
        };
    }

    if ($haveSysUtmp)
    {
        my %params;
        $self->{meta}->{filename} and $params{Filename} = $self->{attrs}->{filename};
        my $utmp = Sys::Utmp->new(%params);
        my $id   = 0;

        while ( my $utent = $utmp->getutent() )
        {
            next unless $utent->ut_user;
            push(
                  @data,
                  [
                     $utent->ut_user, $utent->ut_id eq "" ? $id++ : $utent->ut_id,
                     $utent->ut_line, $utent->ut_pid == -1 ? undef : $utent->ut_pid,
                     $utent->ut_type, $utent->ut_host eq "" ? undef : $utent->ut_host,
                     $utent->ut_time
                  ]
                );
        }

        $utmp->endutent;
    }

    return \@data;
}

=head1 PREREQUISITES

The module C<Sys::Utmp> is required to provide data for the table.

=head1 AUTHOR

    Jens Rehsack
    CPAN ID: REHSACK
    rehsack@cpan.org
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
