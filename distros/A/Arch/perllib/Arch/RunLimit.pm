# Arch Perl library, Copyright (C) 2004 Mikhael Goikhman
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

use 5.005;
use strict;

package Arch::RunLimit;

sub new ($%) {
	my $class = shift;
	my %init = @_;

	my $self = {
		limit => exists $init{limit}? $init{limit}: 5,
		timeout => exists $init{timeout}? $init{timeout}: 30 * 60,
		file => $init{file} || "/please/specify/run-limit-file",
		exceeded => undef,
		added => 0,
	};
	$self->{exceeded} = 0 if $self->{limit} <= 0 || $self->{timeout} <= 0;

	bless $self, $class;
	return $self;
}

sub exceeded ($) {
	my $self = shift;
	return $self->{exceeded} if defined $self->{exceeded};

	my ($hostname, $aliases, $addrtype, $length, $addr) = gethostent();
	my $hostip = join('.', unpack("C$length", $addr)) if $length && $addr;
	$hostname ||= "unknown-host";
	$hostip ||= "127.0.0.1";
	die "Internal: Unexpected hostname ($hostname)\n" if $hostname =~ /\s/;
	die "Internal: Unexpected hostip ($hostip)\n" if $hostip =~ /\s/;
	$self->{host_id} = "$hostname=$hostip";

	$self->{proc_able} = -d "/proc" && -d "/proc/$$",
	$self->{run_id} = "$^T $$ $self->{host_id}\n";
	$self->_update_run_limit_file(1);
	return $self->{exceeded};
}

sub _update_run_limit_file ($$) {
	my $self = shift;
	my $add_self = shift;

	return if $self->{exceeded};

	my $file = $self->{file};
	unless (-f $file) {
		open FH, ">$file" or die "Can't create run-limit file ($file)\n";
		close FH;
	}

	open FH, "+<$file" or die "Can't open $file for updating: $!\n";
	flock FH, 2;         # wait for exclusive lock
	seek FH, 0, 0;       # rewind to beginning
	my @content = <FH>;  # get current content

	print STDERR map { "run limit old: $_" } @content
		if $ENV{DEBUG} && ("$ENV{DEBUG}" & "\2") ne "\0";

	@content = grep {
		/^(\d+) (\d+) ([^\s]+)\n/ && (
			$3 ne $self->{host_id} || time() - $1 < $self->{timeout} &&
			(!$self->{proc_able} || -d "/proc/$2")
		);
	} @content;

	if ($add_self) {
		if (@content >= $self->{limit}) {
			$self->{exceeded} = 1;
		} else {
			$self->{exceeded} = 0;
			$self->{added} = 1;
			push @content, $self->{run_id};
		}
	} else {
		@content = grep { $_ ne $self->{run_id} } @content;
	}

	print STDERR map { "run limit new: $_" } @content
		if $ENV{DEBUG} && ("$ENV{DEBUG}" & "\2") ne "\0";

	seek FH, 0, 0;       # rewind again
	truncate FH, 0;      # empty the file
	print FH @content;   # print the new content
	close FH;            # release file
}

sub DESTROY ($) {
	my $self = shift;
	return unless $self->{added} && defined $self->{exceeded};
	$self->_update_run_limit_file(0);
}

1;

__END__

=head1 NAME

Arch::RunLimit - class to enforce a limit on the number of running
processes

=head1 SYNOPSIS 

    use Arch::RunLimit

    my $limit = Arch::RunLimit->new(file => $limit_file);

    die "run-limit exceeded" if $limit->exceeded;

=head1 DESCRIPTION

Arch::RunLimit provides an easy way to enforce a limit on the number
of concurrently running processes.

=head1 METHODS

The following methods are available:

B<new>,
B<exceeded>.

=over 4

=item B<new> I<%opts>

Create a new Arch::RunLimit object with the specified options:

=over 4

=item B<file> (mandatory)

The file used to keep track of the number of processes.

=item B<limit>

The maximum number of concurrently running processes. Defaults to C<5>.

=item B<timeout>

The timeout after which a process is assumed to be terminated in
seconds. Defaults to C<1800> (30 minutes).

=back

=item B<exceeded>

Return C<1> if the number of concurrently running processes has been
exceeded, C<0> otherwise.

=back

=head1 BUGS

Awaiting your reports.

=head1 AUTHORS

Mikhael Goikhman (migo@homemail.com--Perl-GPL/arch-perl--devel).

Enno Cramer (uebergeek@web.de--2003/arch-perl--devel).

=cut
