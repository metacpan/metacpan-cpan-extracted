use strict;
use warnings;

package Date::Span;
{
  $Date::Span::VERSION = '1.127';
}
# ABSTRACT: deal with date/time ranges than span multiple dates

use Exporter;
BEGIN { our @ISA = 'Exporter' }

our @EXPORT = qw(range_expand range_durations range_from_unit); ## no critic


sub _date_time {
  my $date = $_[0] - (my $time = $_[0] % 86400);
  ($date, $time)
}

sub range_durations {
	my ($start, $end) = @_;
	return if $end < $start;

	my ($start_date, $start_time) = _date_time($start);
	my ($end_date,   $end_time)   = _date_time($end);

	push my @results, [
		$start_date,
		(( $end_date != $start_date ) ? ( 86400 - $start_time ) : ($end - $start))
	];

	push @results,
		map { [ $start_date + 86400 * $_, 86400 ] }
		(1 .. ($end_date - $start_date - 86400) / 86400)
		if ($end_date - $start_date > 86400);

	push @results, [ $end_date, $end_time ] if $start_date != $end_date;

	return @results;
}


sub range_expand {
	my ($start, $end) = @_;
	return if $end < $start;

	my ($start_date, $start_time) = _date_time($start);
	my ($end_date,   $end_time)   = _date_time($end);

	push my @results, [
		$start, ( ( $end_date != $start_date ) ? ( $start_date + 86399 ) : $end )
	];

	push @results,
		map { [ $start_date + 86400 * $_, $start_date + 86400 * $_ + 86399 ] }
		(1 .. ($end_date - $start_date - 86400) / 86400)
		if ($end_date - $start_date > 86400);

	push @results, [ $end_date, $end ] if $start_date != $end_date;

	return @results;
}


my @monthdays = ( 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 );

sub _is_leap {
	not($_[0] % 4) and (($_[0] % 100) or not($_[0] % 400)) and $_[0] > 0
}

sub _leap_secs {
  _is_leap($_[0]) && $_[1] == 1 ? 86400 : 0
}

sub _begin_secs {
	require Time::Local;
	Time::Local::timegm(
    0,        # $sec
    $_[4]||0, # $min
    $_[3]||0, # $hour
    $_[2]||1, # $mday
    $_[1]||0, # $mon
    $_[0]     # $year
  );
}

sub range_from_unit {
	my $code = (ref($_[-1])||'' eq 'CODE') ? pop : \&_begin_secs;
	return unless @_;
	my ($year,$month,$day,$hour,$min) = @_;
	my $begin_secs = $code->(@_);
	my $length = defined $min   ? 60
             : defined $hour  ? 3600
             : defined $day   ? 86400
             : defined $month ? 86400 * $monthdays[$month+0]
                              + _leap_secs($year, $month)
             :                  86400 * (_is_leap($year) ? 366 : 365);

	return ($begin_secs, $begin_secs + $length - 1);
}


1;

__END__

=pod

=head1 NAME

Date::Span - deal with date/time ranges than span multiple dates

=head1 VERSION

version 1.127

=head1 SYNOPSIS

 use Date::Span;

 @spanned = range_expand($start, $end);

 print "from $_->[0] to $_->[1]\n" for (@spanned);

=head1 DESCRIPTION

This module provides code for dealing with datetime ranges that span multiple
calendar days.  This is useful for computing, for example, the amount of
seconds spent performing a task on each day.  Given the following table:

  event   | begun            | ended
 ---------+------------------+------------------
  loading | 2004-01-01 00:00 | 2004-01-01 12:45
  venting | 2004-01-01 12:45 | 2004-01-02 21:15
  running | 2004-01-02 21:15 | 2004-01-03 00:00

We may want to gather the following data:

  date       | event   | time spent
 ------------+---------+----------------
  2004-01-01 | loading | 12.75 hours
  2004-01-01 | venting | 11.25 hours
  2004-01-02 | venting | 21.25 hours
  2004-01-02 | running |  2.75 hours

Date::Span takes a data like the first and produces data more like the second.
(Details on exact interface are below.)

=head1 FUNCTIONS

=head2 range_durations

  my @durations = range_durations($start, $end)

Given C<$start> and C<$end> as timestamps (in epoch seconds),
C<range_durations> returns a list of arrayrefs.  Each arrayref is a date
(expressed as epoch seconds at midnight) and the number of seconds for which
the given range intersects with the date.

=head2 range_expand

  my @endpoint_pairs = range_expand($start, $end);

Given C<$start> and C<$end> as timestamps (in epoch seconds),
C<range_durations> returns a list of arrayrefs.  Each arrayref is a start and
end timestamp.  No pair of start and end times will cross a date boundary, and
the set of ranges as a whole will be identical to the passed start and end.

=head2 range_from_unit

  my ($start, $end) = range_from_unit(@date_unit)

C<@date_unit> is a specification of a unit of time, in the form:

 @date_unit = ($year, $month, $day, $hour, $minute);

Only C<$year> is mandatory; other arguments may be added, in order.  Month is
given in the range (0 .. 11).  This function will return the first and last
second of the given unit.

A code reference may be passed as the last object.  It will be used to convert
the date specification to a starting time.  If no coderef is passed, a simple
one using Time::Local (and C<timegm>) will be used.

=head1 TODO

This code was just yanked out of a general purpose set of utility functions
I've compiled over the years.  It should be refactored (internally) and
further tested.  The interface should stay pretty stable, though.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
