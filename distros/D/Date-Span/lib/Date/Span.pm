use strict;
use warnings;

package Date::Span 1.128;
# ABSTRACT: deal with date/time ranges than span multiple dates

use Exporter;
BEGIN { our @ISA = 'Exporter' }

our @EXPORT = qw(range_expand range_durations range_from_unit); ## no critic

#pod =head1 SYNOPSIS
#pod
#pod  use Date::Span;
#pod
#pod  @spanned = range_expand($start, $end);
#pod
#pod  print "from $_->[0] to $_->[1]\n" for (@spanned);
#pod
#pod =head1 DESCRIPTION
#pod
#pod This module provides code for dealing with datetime ranges that span multiple
#pod calendar days.  This is useful for computing, for example, the amount of
#pod seconds spent performing a task on each day.  Given the following table:
#pod
#pod   event   | begun            | ended
#pod  ---------+------------------+------------------
#pod   loading | 2004-01-01 00:00 | 2004-01-01 12:45
#pod   venting | 2004-01-01 12:45 | 2004-01-02 21:15
#pod   running | 2004-01-02 21:15 | 2004-01-03 00:00
#pod
#pod We may want to gather the following data:
#pod
#pod   date       | event   | time spent
#pod  ------------+---------+----------------
#pod   2004-01-01 | loading | 12.75 hours
#pod   2004-01-01 | venting | 11.25 hours
#pod   2004-01-02 | venting | 21.25 hours
#pod   2004-01-02 | running |  2.75 hours
#pod
#pod Date::Span takes a data like the first and produces data more like the second.
#pod (Details on exact interface are below.)
#pod
#pod =func range_durations
#pod
#pod   my @durations = range_durations($start, $end)
#pod
#pod Given C<$start> and C<$end> as timestamps (in epoch seconds),
#pod C<range_durations> returns a list of arrayrefs.  Each arrayref is a date
#pod (expressed as epoch seconds at midnight) and the number of seconds for which
#pod the given range intersects with the date.
#pod
#pod =cut

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

#pod =func range_expand
#pod
#pod   my @endpoint_pairs = range_expand($start, $end);
#pod
#pod Given C<$start> and C<$end> as timestamps (in epoch seconds),
#pod C<range_durations> returns a list of arrayrefs.  Each arrayref is a start and
#pod end timestamp.  No pair of start and end times will cross a date boundary, and
#pod the set of ranges as a whole will be identical to the passed start and end.
#pod
#pod =cut

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

#pod =func range_from_unit
#pod
#pod   my ($start, $end) = range_from_unit(@date_unit)
#pod
#pod C<@date_unit> is a specification of a unit of time, in the form:
#pod
#pod  @date_unit = ($year, $month, $day, $hour, $minute);
#pod
#pod Only C<$year> is mandatory; other arguments may be added, in order.  Month is
#pod given in the range (0 .. 11).  This function will return the first and last
#pod second of the given unit.
#pod
#pod A code reference may be passed as the last object.  It will be used to convert
#pod the date specification to a starting time.  If no coderef is passed, a simple
#pod one using Time::Local (and C<timegm>) will be used.
#pod
#pod =cut

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

#pod =head1 TODO
#pod
#pod This code was just yanked out of a general purpose set of utility functions
#pod I've compiled over the years.  It should be refactored (internally) and
#pod further tested.  The interface should stay pretty stable, though.
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Date::Span - deal with date/time ranges than span multiple dates

=head1 VERSION

version 1.128

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

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

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

Ricardo SIGNES <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
