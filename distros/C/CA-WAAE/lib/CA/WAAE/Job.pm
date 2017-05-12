#
# CA::WAAE - Perl Interface to CA's Workflow Automation AutoSys Edition job control.
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

package CA::WAAE::JobList;

use strict;
use warnings;

our $VERSION = '0.03';

my $debug = 0;

sub new {
    my $self  = {};
    my $class = shift();

    if (@_) {
        my %args = @_;
        $self->{parent} = $args{parent} ? $args{parent} : undef;
        $self->{dbh}
            = $args{database_handle} ? $args{database_handle} : undef;
        $self->{sth}
            = $args{statement_handle} ? $args{statement_handle} : undef;
        $self->{parent_job} = $args{parent_job} ? $args{parent_job} : undef;
        $self->{table_prefix}
            = $args{table_prefix} ? $args{table_prefix} : undef;
    }

    if ($debug) { printf( "DEBUG: Job(%s) created.\n", $self ); }

    bless($self);
    return $self;
}    # new()

sub _fetch_next {
    my $self = shift;
    if ($debug) { printf( "DEBUG: Job(%s): _fetch_next()\n", $self ); }
    if ( my $h = $self->{sth}->fetchrow_hashref('NAME_lc') ) {
        return CA::WAAE::Job->new( %$self, %$h );
    }
    else {
        $self->{sth}->finish();
        delete $self->{sth};
        return undef;
    }
}    # _fetch_next()

sub next_job {
    my $self = shift();
    if ($debug) { printf( "DEBUG: Job(%s): next_job()\n", $self ); }
    return $self->_fetch_next();
}    # next_job()

sub next_child {
    my $self = shift();
    if ($debug) { printf( "DEBUG: Job(%s): next_child()\n", $self ); }
    return $self->_fetch_next();
}    # next_child()

package CA::WAAE::Job;

use Time::Piece qw(localtime);

our %status_names = (
    0  => '  ',    # *empty*
    1  => 'RU',    # running
    2  => ' 2',    # *not defined*
    3  => 'ST',    # starting
    4  => 'SU',    # success
    5  => 'FA',    # failure
    6  => 'TE',    # terminated
    7  => 'OI',    # on ice
    8  => 'IN',    # inactive
    9  => 'AC',    # activated
    10 => 'RE',    # restart
    11 => 'OH',    # on hold
    12 => 'QW',    # queue wait
    13 => '13',    # *not defined*
    14 => 'RD',    # refresh dependencies
    15 => 'RF',    # refresh filewatcher
);

use constant {
    NONE        => 0,
    RUNNING     => 1,
    UNDEF_2     => 2,
    STARTING    => 3,
    SUCCESS     => 4,
    FAILURE     => 5,
    TERMINATED  => 6,
    ON_ICE      => 7,
    INACTIVE    => 8,
    ACTIVATED   => 9,
    RESTART     => 10,
    ON_HOLD     => 11,
    QUEUE_WAIT  => 12,
    UNDEF_13    => 13,
    REFRESH_DEP => 14,
    REFRESH_FW  => 15
};

our %long_status = (
    0  => "NONE",
    1  => "RUNNING",
    2  => "UNDEF_2",
    3  => "STARTING",
    4  => "SUCCESS",
    5  => "FAILURE",
    6  => "TERMINATED",
    7  => "ON_ICE",
    8  => "INACTIVE",
    9  => "ACTIVATED",
    10 => "RESTART",
    11 => "ON_HOLD",
    12 => "QUEUE_WAIT",
    13 => "UNDEF_13",
    14 => "REFRESH_DEP",
    15 => "REFRESH_FW"
);

sub new {
    my $class = shift;
    my %args  = @_;
    my $self  = bless {%args}, $class;
    return $self;
}

my @command_attr = qw(
    chk_files
    command
    envvars
    heartbeat_interval
    interactive
    is_script
    over_num
    shell
    std_err_file
    std_in_file
    std_out_file
    ulimit
    userid
    elevated
    criteria
    dbtype
    dburl
    dbuserid
    dbuserrole
    monitor_condition
    monitor_type
    obj_name
    params
    params_num
    rtn_type
    trig_condition
    trig_type
);

for my $attr (@command_attr) {
    no strict 'refs';
    *$attr = sub {
        my $self = shift;
        my $data = $self->get_data() or return;
        $data->{$attr};
    };
}

sub job_type { $_[0]->{job_type_name} }

my %job_table = (
    CMD => 'command_job',
    SQL => 'sql_job',
);

sub get_data {
    my $self     = shift;
    my $job_type = $self->job_type();
    my $table    = $job_table{$job_type} or return;
    return $self->{JOB} if $self->{JOB};

    my $job_id = $self->{joid} or return;
    return unless defined $job_id;
    my $prefix = $self->{table_prefix} || '';
    my $sql = <<SQL;
select *
from ${prefix}$table
where joid = ?
SQL
    my $sth = $self->{dbh}->prepare($sql);
    $sth->execute($job_id);
    my $command_data = $sth->fetchrow_hashref('NAME_lc') or return;
    $sth->finish;
    $self->{JOB} = $command_data;
}

sub find_children {
    my $self = shift();
    if ($debug) { printf( "DEBUG: Job(%s): find_children()\n", $self ); }
    my $query = $self->{parent}->_query() . <<SQL;
where j.box_joid = $self->{joid}
order by j.joid
SQL
    my $sth = $self->{dbh}->prepare($query);
    if ($debug) {
        printf( "DEBUG: Job(%s): selecting children for joid %d\n",
            $self, $self->{joid} );
    }
    $sth->execute();
    return CA::WAAE::JobList->new(
        parent           => $self->{parent},
        database_handle  => $self->{dbh},
        statement_handle => $sth,
        parent_job       => $self
    );
}

sub children {
    my $self = shift;
    my $h    = $self->find_children();
    my @list;
    while ( my $job = $h->next_job() ) {
        push @list, $job;
    }
    return wantarray ? @list : \@list;
}

sub status {
    my $self = shift;
    my $status = shift || $self->{status};
    return $status_names{$status};
}

sub long_status {
    my $self = shift;
    my $status = shift || $self->{status};
    return $long_status{$status};
}

sub time {
    my $self = shift;
    my $tm   = shift;
    $tm = $self->{$tm} if defined($tm) and $tm =~ /\D/;
    return if !defined($tm) || $tm == 999999999;
    localtime($tm);
}

sub strftime {
    my $self = shift;
    my $time = shift;
    my $fmt  = shift || "%Y-%m-%d %H:%M:%S";
    my $tm   = $self->time($time) or return;
    return $tm->strftime($fmt);
}

1;

__END__

=head1 NAME

CA::WAAE::Job - Object representing an AutoSys job.

=head1 INSTANCE METHODS

=head2 B<next_job()>

    my $job = $jobs->next_job() ;

Returns the next job from a list of jobs previously acquired by a call to L<find_jobs()|CA::WAAE/find_jobs()>.

=head2 B<find_children()>

    my $children = $job->find_children() ;

Returns child jobs for a given job object. The child jobs can be traversed like this:

    my $children = $job->find_children() ;
    while (my $child = $children->next_child()) {
        # do something
        :
    }

=head2 B<children>

Same as find_children(), but returns an array of L<CA::WAAE::Job|CA::WAAE::Job> objects.

=head2 B<next_child()>

    my $child = $children->next_child() ;

Returns the next child from a list of child jobs previously acquired by a call to L<find_children()>.

=head2 B<status>

    print "status: ".$job->status."\n";

Contains the status of the last run of the job.
The hash entry $job->{status} contains the status_id.

=head1 INSTANCE VARIABLES

=head2 B<job_name>

    print "job_name: ".$job->{job_name}."\n";

Contains the name of the AutoSys job.

=head2 B<job_type>

    print "job_type: ".$job->job_type."\n";

Contains the job type name, e.g. 'CMD', 'BOX'.
The hash entry $job->{job_type} contains the job_type_id.

=head2 B<time>

    print "last_start: ".$job->time('last_start')."\n";

Returns a L<Time::Piece|Time::Piece> object for the given
datetime entry for the job.
The hash entries, e.g., $job->{last_start}, contain the epoch time.

=head2 B<strftime>

    print "last_start: ".$job->strftime('last_start', $fmt)."\n";

Formatted time for any datetime entry for the job.
The default format is "%Y-%m-%d %H:%M:%S".
The hash entries, e.g., $job->{last_start}, contain the epoch time.

=head2 B<joid>

    print "joid: ".$job->{joid}."\n";

Contains the internal job id in the AutoSys database.

=head1 SEE ALSO

L<CA::WAAE|CA::WAAE> L<CA::AutoSys|CA::AutoSys>

=head1 AUTHOR

Original L<CA::AutoSys|CA::AutoSys> code by Sinisa Susnjar <sini@cpan.org>

Updates by Douglas Wilson <dougw@cpan.org>

=head1 COPYRIGHT AND LICENSE

Original L<CA::AutoSys|CA::AutoSys> code:
Copyright (c) 2007 Sinisa Susnjar. All rights reserved.

This program is free software; you can use and redistribute it under the terms of the L-GPL.
See the LICENSE file for details.
