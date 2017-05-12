#
# $Id: AutoSys.pm 68 2008-02-11 10:50:27Z sini $
#
# CA::AutoSys - Perl Interface to CA's AutoSys job control.
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

package CA::AutoSys;

require CA::AutoSys::Job;
require CA::AutoSys::Status;

use strict;
use warnings;
use DBI;

use vars qw($VERSION);

$VERSION = '1.05';

use Exporter;
use vars qw(@ISA @EXPORT);
@ISA = qw(Exporter);
@EXPORT = qw(&new);

our $errstr;

sub new {
	my $self = {};
	my $class = shift();

	$errstr = '';

	if (@_) {
		my %args = @_;
		$self->{dsn} = $args{dsn} ? $args{dsn} : undef;
		$self->{server} = $args{server} ? $args{server} : undef;
		$self->{user} = $args{user} ? $args{user} : undef;
		$self->{password} = $args{password} ? $args{password} : undef;
	}

	if (!defined($self->{dsn})) {
		if (!defined($self->{server})) {
			$errstr = "no dsn given in new()";
			return undef;
		}
		# Default to Sybase when no dsn was given...
		$self->{dsn} = "dbi:Sybase:server=$self->{server}";
	}
	$self->{dbh} = DBI->connect($self->{dsn}, $self->{user}, $self->{password});
	if (!$self->{dbh}) {
		$errstr = "can't connect to dsn ".$self->{dsn}.": ".$DBI::errstr;
		return undef;
	}

	bless($self);
	return $self;
}	# new()

sub find_jobs {
	my $self = shift();
	my $job_name = shift();
	my $job = CA::AutoSys::Job->new(parent => $self, database_handle => $self->{dbh});
	return $job->find_jobs($job_name);
}	# find_jobs()

sub send_event {
	my $self = shift();
	my ($job_name, $event, $status, $event_time);
	if (@_) {
		my %args = @_;
		$job_name = $args{job_name} ? $args{job_name} : '';
		$event = $args{event} ? $args{event} : '';
		$status = $args{status} ? $args{status} : '';
		$event_time = $args{event_time} ? $args{event_time} : '';
	}

	my $sth = $self->{dbh}->prepare(qq{
	exec sendevent '$event', '$job_name', '$status', '', '$event_time', ''
	});

	$sth->execute();

	my ($rc) = $sth->fetchrow_array();
	return $rc;
}	# send_event()

1;
__END__

=head1 NAME

CA::AutoSys - Interface to CA's AutoSys job control.

This module was born out of the need to control some AutoSys jobs via a Perl/CGI script.
It is sort of a quick hack, but it works for me... should you have some wishes / requirements
that are not mentioned in L</TODOs>, please let me know.

=head1 SYNOPSIS

    use CA::AutoSys;

    my $hdl = CA::AutoSys->new( [OPT] ) ;
    my $jobs = $hdl->find_jobs($jobname) ;
    while (my $job = $jobs->next_job()) {
        :
    }
    my $status = $job->get_status() ;
    my $children = $job->find_children() ;
    while (my $child = $children->next_child()) {
        :
    }

=head1 CLASS METHODS

=head2 B<new() >

    my $hdl = CA::AutoSys->new( [OPT] ) ;

Creates a new CA::AutoSys object.

Below is a list of valid options:

=over 5

=item B<dsn>

Specify the DSN of the AutoSys' database server to connect to. If nothing is specified, Sybase will be
assumed: dbi:Sybase:server=<your_server>
With this option you should be able to connect to databases other than Sybase.

=item B<server>

This option is deprecated - rather use the dsn option.
Specify the AutoSys' database server to connect to. Either this option or the dsn option above must be given.
Please note, that when specifying this server option, a Sybase database backend is assumed.

=item B<user>

Specify the database user. With an out-of-the-box AutoSys installation, the default user should work.

=item B<password>

Specify the database password. With an out-of-the-box AutoSys installation, the default password should work.

=back

Example:

    my $hdl = CA::AutoSys->new(server => "AUTOSYS_DEV");

=head1 INSTANCE METHODS

=head2 B<find_jobs() >

    my $jobs = $hdl->find_jobs($jobname) ;

Finds jobs with a given name. When you have the wildcard character '%' somewhere in the job name,
it will return all matching jobs, i.e.:

To find all jobs starting with the string 'MY_JOB':

    $jobs = $hdl->find_jobs('MY_JOB%');

To find all jobs that have the string 'JOB' somewhere in the name:

    $jobs = $hdl->find_jobs('%JOB%');

To find a job with an exact name:

    $jobs = $hdl->find_jobs('JOB_42');

See also L<CA::AutoSys::Job|CA::AutoSys::Job>

=head2 B<send_event() >

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

Make the interface more "perlish", e.g. return an array of jobs instead of forcing the user
to call C<next_job()> / C<next_child()>.

Make the interface more "OO", e.g. allow the user to send an event directly from an C<CA::AutoSys::Job> object
to the underlying job instead of having to use C<CA::AutoSys-E<gt>send_event()>.

There are lots of missing AutoSys features, e.g. "alarms".

=head1 SEE ALSO

L<CA::AutoSys::Job|CA::AutoSys::Job>, L<CA::AutoSys::Status|CA::AutoSys::Status>

=head1 AUTHOR

Sinisa Susnjar <sini@cpan.org>

=head1 MODIFICATION HISTORY

See the CHANGES file.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007 Sinisa Susnjar. All rights reserved.

This program is free software; you can use and redistribute it under the terms of the L-GPL.
See the LICENSE file for details.
