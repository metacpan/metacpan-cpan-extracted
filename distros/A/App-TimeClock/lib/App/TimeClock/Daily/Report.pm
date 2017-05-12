package App::TimeClock::Daily::Report;

use strict;
use warnings;

use POSIX qw(difftime strftime);
use Time::Local;

my $EOL_RE = qr/[\r\n]+\z/;

=head1 NAME

App::TimeClock::Daily::Report

=head1 DESCRIPTION

Can parse the timelog and generate a report using an instance of a
L<App::TimeClock::Daily::PrinterInterface>.

=head2 METHODS

=over

=item new($timelog, $printer)

Initializes a new L<App::TimeClock::Daily::Report> object.

Two parameters are required:

=over

=item B<$timelog>

Must point to a timelog file. Will die if not.

=item B<$printer>

An object derived from L<App::TimeClock::Daily::PrinterInterface>. Will die if not.

=back

=cut
sub new {
    die "must supply (timelog, printer) arguments to constructor" if $#_ != 2;
    my $class = shift;
    my $self = {
        timelog => shift,
        printer => shift
    };
    die "timelog ($self->{timelog}) does not exist" unless -f $self->{timelog} and -r $self->{timelog};
    die "printer is not a PrinterInterface" unless ref $self->{printer} and
	  UNIVERSAL::can($self->{printer},'isa') and $self->{printer}->isa("App::TimeClock::Daily::PrinterInterface");
    bless $self, $class;
};


=item _timelocal() 

Returns a time (seconds since epoch) from a date and time.

=cut
sub _timelocal {
    my ($self, $date, $time) = @_;
    my ($year, $mon, $mday) = split(/\//, $date);
    my ($hours, $min, $sec ) = split(/:/, $time);

    return timelocal($sec, $min, $hours, $mday, $mon-1, $year);
};


=item _get_report_time()

Returns the time when the report was executed.

=cut
sub _get_report_time { $_[0]->{_report_time} || time }


=item _set_report_time()

Sets the time when the report is executed.

Two parameters are required:

=over

=item B<$date>

The date as a string in the following format YYYY/MM/DD

=item B<$time>

The time as a string in the following format HH:MM:SS

=back

=cut
sub _set_report_time { $_[0]->{_report_time} = $_[0]->_timelocal($_[1], $_[2]) }


=item _read_lines()

Reads a set of check in and check out lines.

If end of file is reached after reading the check in line, then
reading of the check out line is skipped.

=cut
sub _read_lines {

    my ($self, $file) = (@_);
    my ($iline, $oline) = (undef, undef);

    die "Prematurely end of file." if eof($file);

    do {
        ($iline = <$file>) =~ s/$EOL_RE//g;
    } while ($iline =~ /^[bh] /); # Just skip unsupported codes (#13)

    die "Expected check in in line $." unless $iline =~ /^i /;

    if (not eof($file)) {
        ($oline = <$file>) =~ s/$EOL_RE//g;
        die "Excepted check out in line $." unless $oline =~ /^[oO] /; # Note: O is treated as o
    }

    return ($iline, $oline);
}


=item _parse_lines()

Parses a set of check in and check out lines.

The lines are split on space and should contain the following four
fields:

=over

=item state 

is either 'i' - check in or 'o' - check out.

=cut

=item date 

is formatted as YYYY/MM//DD

=cut

=item time

is formatted as HH:MM:SS

=cut

=item project

is then name of the project/task and is only required when checking in.

=cut

=back

=cut
sub _parse_lines {
    my ($self, $file) = (@_);
    my ($iline, $oline) = $self->_read_lines($file);

    my ($idate, $itime, $iproject) = (split(/ /, $iline, 4))[1..3];
    my ($odate, $otime, $oproject) = (defined $oline) ? (split(/ /, $oline, 4))[1..3] :
      (strftime("%Y/%m/%d", localtime($self->_get_report_time)),
       strftime("%H:%M:%S", localtime($self->_get_report_time)), "DANGLING");
       
    return ($idate, $itime, $iproject, $odate, $otime, $oproject);
}


=item execute()

Opens the timelog file starts parsing it, looping over each day and
calling print_day() for each.

=cut
sub execute {
    my $self = shift;

    open (my $file, "<:encoding(UTF-8)", $self->{timelog}) or die "$!\n";

    my %projects;
    my ($current_project, $current_date, $work, $day_hours);
    my ($day_start, $day_end);
    my ($work_year_to_date, $day_count) = (0,0);

    $day_hours = 0;

    $self->{printer}->print_header;

    while (not eof($file)) {
        my ($idate, $itime, $iproject, $odate, $otime, $oproject) = $self->_parse_lines($file);

        if (not defined $current_date) {
            # First check in, set the current date and start time
            $current_date = $idate;
            $day_start = $itime;
        } elsif ($current_date ne $idate) {
            # It's a new day, print the current day, update totals and reset variables
            $self->{printer}->print_day($current_date, $day_start, $day_end, $day_hours, %projects);

            $work_year_to_date += $day_hours;
            $day_count++;

            $day_hours = 0;
            $current_date = $idate;
            $day_start = $itime;
            %projects = ();
            $day_end = "";
        }

        $current_project = $iproject;
        $work = difftime($self->_timelocal($odate, $otime), $self->_timelocal($idate, $itime)) / 60 / 60;
        $day_hours += $work;
        $day_end = $otime;
        $projects{$current_project} += $work;

        if (defined $oproject && $oproject eq "DANGLING") {
            $projects{"$current_project (NOT checked out)"} = $projects{$current_project};
            delete $projects{$current_project};
        }
    }

    # Print the last day (in the loop we're only printing when date changes)
    if (defined $current_date) {
	$self->{printer}->print_day($current_date, $day_start, $day_end, $day_hours, %projects);
	$work_year_to_date += $day_hours;
	$day_count++;
    }

    $self->{printer}->print_footer($work_year_to_date, $day_count);
};
1;

=back

=for text
=encoding utf-8
=end

=head1 AUTHOR

Søren Lund, C<< <soren at lund.org> >>

=head1 SEE ALSO

L<timeclock.pl>

=head1 COPYRIGHT

Copyright (C) 2012-2015 Søren Lund

This file is part of App::TimeClock.

App::TimeClock is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

App::TimeClock is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with App::TimeClock.  If not, see <http://www.gnu.org/licenses/>.
