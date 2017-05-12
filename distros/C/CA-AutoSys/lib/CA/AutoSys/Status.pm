#
# $Id: Status.pm 57 2007-10-26 15:10:55Z sini $
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

package CA::AutoSys::Status;

use strict;
use warnings;

use Exporter;
use vars qw(@ISA @EXPORT $VERSION);
@ISA = qw(Exporter);
@EXPORT = qw(&new &format_status &format_time);

$VERSION = '1.03';

our %status_names = (
	0 => '  ',	# *empty*
	1 => 'RU',	# running
	2 => ' 2',	# *not defined*
	3 => 'ST',	# starting
	4 => 'SU',	# success
	5 => 'FA',	# failure
	6 => 'TE',	# terminated
	7 => 'OI',	# on ice
	8 => 'IN',	# inactive
	9 => 'AC',	# activated
	10 => 'RE',	# restart
	11 => 'OH',	# on hold
	12 => 'QW',	# queue wait
	13 => '13',	# *not defined*
	14 => 'RD',	# refresh dependencies
	15 => 'RF',	# refresh filewatcher
);

use constant {
	NONE		=> 0,
	RUNNING		=> 1,
	UNDEF_2		=> 2,
	STARTING	=> 3,
	SUCCESS		=> 4,
	FAILURE		=> 5,
	TERMINATED	=> 6,
	ON_ICE		=> 7,
	INACTIVE	=> 8,
	ACTIVATED	=> 9,
	RESTART		=> 10,
	ON_HOLD		=> 11,
	QUEUE_WAIT	=> 12,
	UNDEF_13	=> 13,
	REFRESH_DEP	=> 14,
	REFRESH_FW	=> 15
};

our %long_status = (
	0		=> "NONE",
	1		=> "RUNNING",
	2		=> "UNDEF_2",
	3		=> "STARTING",
	4		=> "SUCCESS",
	5		=> "FAILURE",
	6		=> "TERMINATED",
	7		=> "ON_ICE",
	8		=> "INACTIVE",
	9		=> "ACTIVATED",
	10		=> "RESTART",
	11		=> "ON_HOLD",
	12		=> "QUEUE_WAIT",
	13		=> "UNDEF_13",
	14		=> "REFRESH_DEP",
	15		=> "REFRESH_FW"
);

sub new {
	my $self = {};
	my $class = shift();

	if (@_) {
		my %args = @_;
		$self->{last_start} = $args{last_start} ? $args{last_start} : undef;
		$self->{last_end} = $args{last_end} ? $args{last_end} : undef;
		$self->{status} = $args{status} ? $args{status} : undef;
		$self->{status_time} = $args{status_time} ? $args{status_time} : undef;
		$self->{name} = $long_status{$self->{status}};
		$self->{run_num} = $args{run_num} ? $args{run_num} : undef;
		$self->{ntry} = $args{ntry} ? $args{ntry} : undef;
		$self->{exit_code} = $args{exit_code} ? $args{exit_code} : undef;
	}

	bless($self);
	return $self;
}	# new()

sub format_status {
	my $status = shift();
	return $status_names{$status};
}	# format_status()

sub format_time {
	my $time = shift();
	if (!defined($time) || $time == 999999999) {
		return "-----";
	}
	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday) = localtime($time);
	$mon++;
	$year += 1900;
	return sprintf("%02d/%02d/%04d  %02d:%02d:%02d", $mon, $mday, $year, $hour, $min, $sec);
	# return sprintf("%02d/%02d/%04d  %02d:%02d:%02d (%d)", $mon, $mday, $year, $hour, $min, $sec, $time);
}	# format_time()

1;

__END__

=head1 NAME

CA::AutoSys::Status - Object representing an AutoSys job status.

=head1 CLASS METHODS

=head2 B<format_status() >

    my $status_string = $status->format_status($status->{status}) ;

Returns a two character string that represents the status like the AutoSys 'autorep' tool.

=head2 B<format_time() >

    my $time_string = $status->format_time($status->{last_start}) ;

Returns a time string that looks like the one from AutoSys' 'autorep' tool.

=head1 INSTANCE VARIABLES

=head2 B<last_start>

    print "last_start: ".$status->{last_start}."\n";

Contains the time when the job was last started or 999999999 (CA's equivalent for never).
Time is measured in non leap seconds since the epoch, i.e. like the return value of perl's time() function.

=head2 B<last_end>

    print "last_end: ".$status->{last_end}."\n";

Contains the time when the job last ended or 999999999 (CA's equivalent for never).
Time is measured in non leap seconds since the epoch, i.e. like the return value of perl's time() function.

=head2 B<status>

    print "status: ".$status->{status}."\n";

Contains an integer value that represents the status of the job.
The various integer values are mapped to these constants:

    NONE        = 0
    RUNNING     = 1
    UNDEF_2     = 2
    STARTING    = 3
    SUCCESS     = 4
    FAILURE     = 5
    TERMINATED  = 6
    ON_ICE      = 7
    INACTIVE    = 8
    ACTIVATED   = 9
    RESTART     = 10
    ON_HOLD     = 11
    QUEUE_WAIT  = 12
    UNDEF_13    = 13
    REFRESH_DEP = 14
    REFRESH_FW  = 15

=head2 B<status_time>

    print "status_time: ".$status->{status_time}."\n";

Contains the time of the last status change or 999999999 (CA's equivalent for never).
Time is measured in non leap seconds since the epoch, i.e. like the return value of perl's time() function.

=head2 B<name>

    print "status name: ".$status->{name}."\n";

Contains the long name of the appropriate integer value that represents the status of the job.
Can be used instead of the more cryptic output of the L<format_status() > method.
The various integer values are mapped to these constants:

    "NONE"        = 0
    "RUNNING"     = 1
    "UNDEF_2"     = 2
    "STARTING"    = 3
    "SUCCESS"     = 4
    "FAILURE"     = 5
    "TERMINATED"  = 6
    "ON_ICE"      = 7
    "INACTIVE"    = 8
    "ACTIVATED"   = 9
    "RESTART"     = 10
    "ON_HOLD"     = 11
    "QUEUE_WAIT"  = 12
    "UNDEF_13"    = 13
    "REFRESH_DEP" = 14
    "REFRESH_FW"  = 15

=head2 B<run_num>

    print "run_num: ".$status->{run_num}."\n";

Contains an integer value that shows an AutoSys internal run number.
It is currently only used to be output-compatible with CA's 'autorep' tool.

=head2 B<ntry>

    print "ntry: ".$status->{ntry}."\n";

Contains an integer that shows how often the run of the job has been retried by AutoSys.

=head2 B<exit_code>

    print "exit_code: ".$status->{exit_code}."\n";

Contains the last exit code of the job.

=head1 SEE ALSO

L<CA::AutoSys::Job|CA::AutoSys::Job>, L<CA::AutoSys|CA::AutoSys>

=head1 AUTHOR

Sinisa Susnjar <sini@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007 Sinisa Susnjar. All rights reserved.

This program is free software; you can use and redistribute it under the terms of the L-GPL.
See the LICENSE file for details.
