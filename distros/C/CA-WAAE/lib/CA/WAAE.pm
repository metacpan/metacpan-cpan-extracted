#
# CA::WAAE - Perl Interface to CA's AutoSys job control.
#
# Original CA::AutoSys code:
# Copyright (c) 2007 Sinisa Susnjar <sini@cpan.org>
# See LICENSE for terms of distribution.
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#

package CA::WAAE;

require CA::WAAE::Job;

use strict;
use warnings;
use DBI;

our $VERSION = '0.03';

sub new {
    my $self  = {};
    my $class = shift();

    my %args = @_;
    for my $attr (qw(dsn user password dbh db_type table_prefix schema)) {
        $self->{$attr} = $args{$attr};
    }

    if ( !$self->{dbh} ) {
        die "no dbh/dsn given in new()" if !$self->{dsn};
        $self->{dbh}
            = DBI->connect( $self->{dsn}, $self->{user}, $self->{password},
            { PrintError => 0, RaiseError => 1 } );
    }

    my $db_type = $self->{dbh}{Driver}{Name};
    if ( $db_type eq 'Oracle' ) {

        # Default and untaint schema/table_prefix
        $self->{schema} ||= 'aedbadmin';
        $self->{schema} =~ /(\w+)/;
        $self->{schema} = $1;

        $self->{table_prefix} ||= 'ujo_';
        $self->{table_prefix} =~ /([\w.]+)/;
        $self->{table_prefix} = $1;

        $self->{dbh}->do("alter session set current_schema=$self->{schema}");
    }

    bless $self, $class;
    return $self;
}    # new()

sub _query {
    my $self   = shift;
    my $prefix = $self->{table_prefix} || '';
    my $query  = <<SQL;
select  j.*, s.*, j2.job_name as box_name, m.name job_type_name
from    ${prefix}job j join ${prefix}job_status s
on      j.joid = s.joid
left outer join ${prefix}job j2
on      j.box_joid = j2.joid
left outer join ${prefix}meta_types m
on      j.job_type = m.type_id and m.sub_type = 'STRINGS'
SQL
    return $query;
}    # _query()

sub find_jobs {
    my $self     = shift();
    my $job_name = shift();

    $job_name =~ s/\*/%/g;
    my $op = ( $job_name =~ /[%?]/ ) ? 'like' : '=';

    my $query = $self->_query() . <<SQL;
where j.job_name $op ?
order by j.joid
SQL
    my $sth = $self->{dbh}->prepare($query);
    $sth->execute($job_name);

    return CA::WAAE::JobList->new(
        parent           => $self->{parent},
        database_handle  => $self->{dbh},
        statement_handle => $sth,
        table_prefix     => $self->{table_prefix},
    );

}    # find_jobs()

sub job_list {
    my $self = shift;
    my $h    = $self->find_jobs(@_);
    my @list;
    while ( my $job = $h->next_job() ) {
        push @list, $job;
    }
    return wantarray ? @list : \@list;
}

sub send_event {
    my $self = shift();
    my ( $job_name, $event, $status, $event_time );
    if (@_) {
        my %args = @_;
        $job_name   = $args{job_name}   ? $args{job_name}   : '';
        $event      = $args{event}      ? $args{event}      : '';
        $status     = $args{status}     ? $args{status}     : '';
        $event_time = $args{event_time} ? $args{event_time} : '';
    }

    my $dbh     = $self->{dbh};
    my $db_type = $self->{db_type};

    $_ = $dbh->quote($_) for $job_name, $event, $status, $event_time;
    my $prefix = $self->{table_prefix} || '';
    my $sql
        = ( $db_type eq 'Oracle' )
        ? "BEGIN :rtn := ${prefix}sendevent( $event, $job_name, $status, '', $event_time ); END;"
        : qq( exec sendevent $event, $job_name, $status, '', $event_time, '' );
    my $sth = $dbh->prepare($sql);

    my $rc;
    $sth->bind_param_inout( ':rtn', \$rc, 128 ) if $db_type eq 'Oracle';
    $sth->execute();
    ($rc) = $sth->fetchrow_array() if $db_type ne 'Oracle';

    return $rc;
}    # send_event()

1;
__END__

=head1 NAME

CA::WAAE - Interface to CA's Workflow Automation AE (AutoSys Edition) job control.

=head1 SYNOPSIS

    use CA::WAAE;

    my $hdl = CA::WAAE->new( [OPT] ) ;
    my $jobs = $hdl->find_jobs($jobname) ;
    while (my $job = $jobs->next_job()) {
        :
    }
    my $status = $job->status() ;
    my $children = $job->find_children() ;
    while (my $child = $children->next_child()) {
        :
    }

=head1 CLASS METHODS

=head2 B<new()>

    my $hdl = CA::WAAE->new( [OPT] ) ;

Creates a new CA::WAAE object.

Below is a list of valid options:

=over 5

=item B<dbh>

Pass in a database handle. If this is specified, then dsn, user, and password are not required.

=item B<dsn>

Specify the DSN of the AutoSys' database server to connect to. If nothing is specified, Sybase will be
assumed: dbi:Sybase:server=<your_server>
With this option you should be able to connect to databases other than Sybase.

=item B<user>

Specify the database user. With an out-of-the-box AutoSys installation, the default user should work.

=item B<password>

Specify the database password. With an out-of-the-box AutoSys installation, the default password should work.

=item B<schema>

For Oracle, the schema that your AutoSys tables are in. Defaults to 'aedbadmin' for an Oracle database.

=item B<table_prefix>

Specify a prefix to add to table names. E.g. 'ujo_' will make sql refer to table 'ujo_job' instead of 'job'.
'ujo_' is the default for an Oracle database.

=back

Example:

    my $hdl = CA::WAAE->new(server => "AUTOSYS_DEV");

=head1 INSTANCE METHODS

=head2 B<find_jobs()>

    my $jobs = $hdl->find_jobs($jobname) ;

Finds jobs with a given name. When you have the wildcard character '%' somewhere in the job name,
it will return all matching jobs, i.e.:

To find all jobs starting with the string 'MY_JOB':

    $jobs = $hdl->find_jobs('MY_JOB%');

To find all jobs that have the string 'JOB' somewhere in the name:

    $jobs = $hdl->find_jobs('%JOB%');

To find a job with an exact name:

    $jobs = $hdl->find_jobs('JOB_42');

See also L<CA::WAAE::Job|CA::WAAE::Job>

=head2 B<job_list()>

Same as find_jobs, but returns an array of L<CA::WAAE::Job|CA::WAAE::Job> objects.

=head2 B<send_event()>

    my $rc = $hdl->send_event( [OPT] ) ;

Sends an event to the given job. Returns 1 on success, 0 otherwise.
At least the event name should be given. Depending on the event, more options may be necessary (see below).
For details, consult your AutoSys' User Guide.

Below is a list of valid options:

=over 5

=item B<job_name>

The name of the job - no wildcards allowed.

=item B<event>

Event name. The following list contains all available event names in alphabetical order:

    ALARM                  CHANGE_PRIORITY        CHANGE_STATUS
    CHECK_HEARTBEAT        CHK_BOX_TERM           CHK_MAX_ALARM
    CHK_N_START            CHK_RUN_WINDOW         COMMENT
    DELETEJOB              EXTERNAL_DEPENDENCY    FORCE_STARTJOB
    HEARTBEAT              JOB_OFF_HOLD           JOB_OFF_ICE
    JOB_ON_HOLD            JOB_ON_ICE             KILLJOB
    QUE_RECOVERY           REFRESH_BROKER         RESEND_EXTERNAL_STATUS
    SEND_SIGNAL            SET_GLOBAL             STARTJOB

=item B<status>

The job status when the event is C<CHANGE_STATUS>. The following list contains all possible states for the C<CHANGE_STATUS> event in alphabetical order:

    ACTIVATED              FAILURE                INACTIVE
    ON_HOLD                ON_ICE                 QUE_WAIT
    REFRESH_DEPENDENCIES   REFRESH_FILEWATCHER    RESTART
    RUNNING                STARTING               SUCCESS
    TERMINATED

=item B<event_time>

Use this when you want to schedule an event at a given time.
The argument should have the format 'YYYY/MM/DD HH:MM:SS'.

=back

To force a job start at a given time:

    my $rc = $hdl->send_event(job_name => 'HAPPY_NEW_YEAR', event => 'FORCE_STARTJOB',
                              event_time => '2007/12/31 23:59:59');

To mark an job as inactive:

    my $rc = $hdl->send_event(job_name => 'JOB_42', event => 'CHANGE_STATUS', status => 'INACTIVE');

=head1 TODOs

Make the interface more "OO", e.g. allow the user to send an event directly from an C<CA::WAAE::Job> object
to the underlying job instead of having to use C<CA::WAAE-E<gt>send_event()>.

Due to changes in the underlying database, different attributes of different types of jobs are
stored in separate tables. We currently only get those attributes for command and sql job types.

There are lots of missing AutoSys features, e.g. "alarms".

=head1 SEE ALSO

L<CA::WAAE::Job|CA::WAAE::Job>

=head1 AUTHOR

Original L<CA::AutoSys|CA::AutoSys> code by Sinisa Susnjar <sini@cpan.org>

Updates by Douglas Wilson <dougw@cpan.org>

=head1 MODIFICATION HISTORY

See the CHANGES file.

=head1 COPYRIGHT AND LICENSE

Original L<CA::AutoSys|CA::AutoSys> code:
Copyright (c) 2007 Sinisa Susnjar. All rights reserved.

This program is free software; you can use and redistribute it under the terms of the L-GPL.
See the LICENSE file for details.
