package Date::WeekNumber;
# ABSTRACT: calculate week of the year (ISO 8601 weeks, or 'CPAN weeks')
$Date::WeekNumber::VERSION = '0.06';
use 5.006;
use strict;
use warnings;
use parent 'Exporter';
use Carp;
use Scalar::Util qw/ reftype /;

our @EXPORT_OK = qw(iso_week_number cpan_week_number);

sub iso_week_number
{
    my $date = _dwim_date(@_);

    require Date::Calc;

    my ($week, $year) = Date::Calc::Week_of_Year($date->{year}, $date->{month}, $date->{day});

    return sprintf('%.4d-W%.2d', $year, $week);
}

# If %U returns a week number of 0, it means the day
# is actually in the final week of the year before.
# And by definition that's the same week number as 31st December
sub cpan_week_number
{
    my $date = _dwim_date(@_);

    require POSIX;
    my $week_number = POSIX::strftime('%U', 0, 0, 12,
                               $date->{day},
                               $date->{month}-1,
                               $date->{year}-1900);
    if ($week_number == 0) {
        $date->{year}--;
        $week_number = POSIX::strftime('%U', 0, 0, 12, 31, 11, $date->{year}-1900);
    }
    return sprintf('%.4d-W%.2d', $date->{year}, $week_number);
}

sub _dwim_date
{
    if (@_ == 1) {
        my $param = shift;

        if (reftype($param) && reftype($param) eq 'HASH') {
            return $param if exists($param->{year})
                          && exists($param->{month})
                          && exists($param->{day});
            croak "you must specify year, month and day\n";
        }
        elsif (reftype($param)) {
            croak "you can't pass a reference of type ".reftype($param);
        }
        elsif ($param =~ /^([0-9][0-9][0-9][0-9])-([0-9][0-9])-([0-9][0-9])$/) {
            return { year => $1, month => $2, day => $3 };
        }

        my @tm = gmtime($param);
        return { year => $tm[5] + 1900, month => $tm[4]+1, day => $tm[3] };

    }
    elsif (@_ == 3) {
        my ($year, $month, $day) = @_;
        return { year => $year, month => $month, day => $day };
    }
    elsif (@_ == 6) {
        my $hashref = { @_ };

        return $hashref if exists($hashref->{year})
                        && exists($hashref->{month})
                        && exists($hashref->{day});
        croak "you must specify year, month and day\n";
    }
    else {
        croak "invalid arguments\n";
    }
}

1;

=head1 NAME

Date::WeekNumber - calculate week of the year (ISO 8601 weeks, or 'CPAN weeks')

=head1 SYNOPSIS

 use Date::WeekNumber qw/ cpan_week_number /;
 
 $week = cpan_week_number('2013-12-31'); # '2014-W01'
 $week = cpan_week_number(time());
 $week = cpan_week_number({ year => 2012, month => 12, day => 31});

Or to get weeks according to ISO 8601:

 use Date::WeekNumber qw/ iso_week_number /;
 
 # pass parameters as for cpan_week_number() above

=head1 DESCRIPTION

The two functions provided by this module
can be used to generate the week number
in the year of a given date. For example:

 print "Today is in week ", iso_week_number(time()), "\n";

Which at the time I'm writing this will print:

 Today is in week 2014-W09

There are two functions provided: C<iso_week_number()> returns the week number
according to ISO 8601, where the weeks run from Monday through Sunday,
and C<cpan_week_number()>, where the weeks run from Sunday through Saturday.
A more complete definition of the week naming schemes is given below.

The CPAN week number is the definition used by Chris Madsen's
L<CPAN once a week, every week|http://onceaweek.cjmweb.net> contest,
and my L<CPAN new dist per month|http://neilb.org/neocpanisms/> contest.

There are a number of modules that can be used to calculate the week
number, but I wanted a minimalist interface that returned a string format,
rather than the year and week number separately. Plus I sometimes have
an epoch and sometimes a date string, so I decided to experiment with
a DWIMish interface (Do What I Mean), where you could pass the date
in whatever format you have it available, and it'll be handled.

=head1 Week numbering scheme

=head2 iso_week_number

The C<iso_week_number()> function returns a string with the week number
according to ISO 8601.

ISO 8601 defines week 01 as being the week with the first Thursday in it.
The first day of the week is Monday. Consider the transition from 2013 to 2014:

    December 2013            January 2014
 Su Mo Tu We Th Fr Sa    Su Mo Tu We Th Fr Sa
  1  2  3  4  5  6  7              1  2  3  4
  8  9 10 11 12 13 14     5  6  7  8  9 10 11
 15 16 17 18 19 20 21    12 13 14 15 16 17 18
 22 23 24 25 26 27 28    19 20 21 22 23 24 25
 29 30 31                26 27 28 29 30 31

So 2014-W01 runs from 30th December 2013 to 5th January 2014.

Similarly, consider the transition from 2009 to 2010:

    December 2009        January 2010
 Su Mo Tu We Th Fr Sa    Su Mo Tu We Th Fr Sa
        1  2  3  4  5                    1  2
  6  7  8  9 10 11 12     3  4  5  6  7  8  9
 13 14 15 16 17 18 19    10 11 12 13 14 15 16
 20 21 22 23 24 25 26    17 18 19 20 21 22 23
 27 28 29 30 31          24 25 26 27 28 29 30
                         31

In this case 2009-W52 runs runs 28th December 2009 through 3rd January 2010,
and 2010-W01 starts on Monday 4th January 2010.

=head2 cpan_week_number

The C<cpan_week_number()> function returns a string with the week number
according to 'CPAN Weeks'.

CPAN Weeks run from Sunday to Saturday, with week 01 of the year being
the week containing the first Sunday in January. Consider the transition
from 2011 to 2012:

    December 2011            January 2012
 Su Mo Tu We Th Fr Sa    Su Mo Tu We Th Fr Sa
              1  2  3     1  2  3  4  5  6  7
  4  5  6  7  8  9 10     8  9 10 11 12 13 14
 11 12 13 14 15 16 17    15 16 17 18 19 20 21
 18 19 20 21 22 23 24    22 23 24 25 26 27 28
 25 26 27 28 29 30 31    29 30 31

Week 2014-W01 runs from Sunday 1st January to Saturday 7th January.

Now look at the transition from 2006 to 2007:

    December 2006            January 2007
 Su Mo Tu We Th Fr Sa    Su Mo Tu We Th Fr Sa
                 1  2        1  2  3  4  5  6
  3  4  5  6  7  8  9     7  8  9 10 11 12 13
 10 11 12 13 14 15 16    14 15 16 17 18 19 20
 17 18 19 20 21 22 23    21 22 23 24 25 26 27
 24 25 26 27 28 29 30    28 29 30 31
 31

Week 2006-W53 runs from Sunday 31st December 2006 to Saturday 6th January 2007,
and 2007-W01 runs from Sunday 7th January to Saturday 13th January.

=head1 SEE ALSO

L<Date::WeekOfYear> provides a C<WeekOfYear()> function,
which returns the week number and associated year.
As of version 1.05 this return the ISO 8601 week number,
prior to that it returned something slightly different;
you can still request the old week numbering scheme.
Version 1.06 provided a mode for giving the output in the same
format as this module.

L<POSIX> contains the C<strftime()> function,
which is used by Date::WeekNumber.

L<DateTime> provides a C<week()> method, which returns
the ISO week number and associated year for a DateTime instance.
It also provides C<strftime()>.

L<Date::Calc> provides C<Week_of_Year()>, which returns
the ISO week number and associated year.

L<Date::ISO8601> provides a number of functions for converting
dates according to ISO 8601.

L<Date::ISO> can be used to produce an ISO week number,
using the C<iso_year()> and C<iso_week()> methods.

=head1 REPOSITORY

L<https://github.com/neilb/Date-WeekNumber>

=head1 AUTHOR

Neil Bowers E<lt>neilb@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2014 by Neil Bowers <neilb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

