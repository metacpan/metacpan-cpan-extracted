package Date::PeriodParser;

use 5.010;
use strict;
use warnings;
use Time::Local;
use Lingua::EN::Words2Nums qw(words2nums);
use Date::Calc qw(
    Add_Delta_Days
    Add_Delta_YM
    Date_to_Time
    Day_of_Week
    Days_in_Month
    Decode_Month
);

use constant GIBBERISH => -1;
use constant AMBIGUOUS => -2;
use constant DEPENDENCY => -3;

# Boring administrative details
require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw( parse_period) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw( parse_period);
our $VERSION = '0.17';

$Date::PeriodParser::DEBUG = 0;

our $TestTime; # This is set by our tests so we don't have to 
               # dynamically figure out acceptable ranges for our test results

my $roughly = qr/((?:a?round(?: about)?|about|roughly|circa|sometime)\s*)+/;

# Emit debug messages if the package global $DEBUG is set.

sub _debug {
    print STDERR "# @_\n" if $Date::PeriodParser::DEBUG;
}

# The actual parsing routine. Detailed below in the pod.

sub parse_period {
    local $_ = lc (shift // ''); # Since we're doing lots of regexps on it.
    my $now = $TestTime || time;
    my ($s, $m, $h, $day, $mon, $year) = my @now = 
        (localtime $now)[0..5];

    # Tidy slightly.
    s/^\s+//;s/\s+$//;
    return (GIBBERISH, "You didn't supply an argument.") unless $_;

    # We're trying to find two things: from and to.
    # We also want to keep track of how vague the user's being, so we
    # provide a flexibility score - for instance "about two weeks ago"
    # means maybe three days either side, but "around last September"
    # means perhaps twelve days either side. 
    my ($from, $to, $leeway);
    my $vague = s/^$roughly\s*//;
    _debug("this is a vague time");
    
    # Stupid cases first.
    # "now": precisely now, or +/- 5 minutes if vague (e.g. "about now")
    return _apply_leeway($now, $now, 300 * $vague) 
        if /^now$/;

    if ($_ eq "" and $vague) { # Biggest range possible.
        $from = 0; $to = 2**31-1;
        return ($from, $to);
    }

    # "this week", "last week", "next week"
    if ( m/(this|last|next) week/ ) {
        my $modifier = $1;
        my @today = _today();
        if ( $modifier eq 'last' ) {
            @today = Add_Delta_Days( @today, -7 );
        }
        elsif ( $modifier eq 'next' ) {
            @today = Add_Delta_Days( @today, +7 );
        }
        my $today = Day_of_Week(@today);
        my $monday = 1;
        my $sunday = 7;

        # Monday at midnight and sunday just before midnight
        my @monday = ( Add_Delta_Days(@today, $monday - $today),  0,  0,  0 );
        my @sunday = ( Add_Delta_Days(@today, $sunday - $today), 23, 59, 59 );
        
        return ( _timelocal(@monday), _timelocal(@sunday) );
    }

    # "this month", "last month", "next month"
    if (m/(this|last|next) month/) {
        my $modifier = $1;
        my ( $year, $month, $day ) = _today();

        # find a day in the previous month
        if ( $modifier eq 'last' ) {
            ( $year, $month ) = Add_Delta_YM( $year, $month, $day, 0, -1 );
        }
        elsif ( $modifier eq 'next' ) {
            ( $year, $month ) = Add_Delta_YM( $year, $month, $day, 0, 1 );
        }

        my @first = ( $year, $month, 1, 0, 0, 0 );    # first day at midnight
        my $last_day_of_month = Days_in_Month( $year, $month );
        my @last = ( $year, $month, $last_day_of_month , 23, 59, 59 );

        return ( _timelocal(@first), _timelocal(@last) );
    }

    # "january 2007", "dec 1991", etc
    if (m{\A (\w+) \s+ (\d{4}) \z}xms) {
        my $month = $1;
        my $year  = $2;

        if ( $month = Decode_Month($month) ) {
            my @first = ( $year, $month, 1, 0, 0, 0 );   # first day at midnight
            my $last_day_of_month = Days_in_Month( $year, $month );
            my @last = ( $year, $month, $last_day_of_month, 23, 59, 59 );
            return ( _timelocal(@first), _timelocal(@last) );
        }
    }

    # Recent times
    if (/(the day (before|after) )?(yesterday|today|tomorrow)/ ||
              /^this (morning|afternoon|evening|lunchtime)/   ||
            /^at lunchtime$/ ||
            /^(in the) (morning|afternoon|evening)/ ||
            /^(last |to)night/) {

        if (s/the day (before|after)//) {
            my $wind = $1 eq "before" ? -1 : 1;
            _debug("Modifying day by $wind");
            $day += $wind;
        }
        if (/yesterday/)   { $day--; _debug("Back 1 day") }
        elsif (/tomorrow/) { $day++; _debug("Forward 1 day") }

        # if it's later than the morning and the phrase is 
        # "in the morning", add a day.
        if ($h>12 and /in the morning$/) {$day++}

        # if it's later than the afternoon and the phrase is 
        # "in the afternoon", add a day.
        elsif ($h>18 and /in the afternoon$/) {$day++}

        # if it's nighttime, and the phrase is "in the evening", add a day.
        elsif (($h>21 or $h<6) and /in the evening$/) {$day++}

        $day-- if /last/;

        ($day, $mon, $year) = _zyprexa($day, $mon, $year);

        ($from, $to, $leeway) = _period_or_all_day($day, $mon, $year, $now);
        return _apply_leeway($from, $to, $leeway * $vague);

    }

    # "ago" and "from now" are both pretty limited: only an offset in
    # days is currently supported.
    s/a (week|month|day|year)/one $1/g;

    if (/^(.*) day(?:s)? ago$/ || /^in (.*) day(?:s)?(?: time)?$/ || 
        /^(.*) day(?:s)? (?:away)?\s*(?:from now)?$/) {
        my $days = $1;
        {
            local $_; 
            # words2nums() trashes $_.
            $days = Lingua::EN::Words2Nums::words2nums($days);
        }
        if (defined $days) { 
            $days *= -1 if /ago/;
            _debug("Modifying day by $days");
            $day += $days;
            ($day, $mon, $year) = _zyprexa($day, $mon, $year);
            ($from, $to, $leeway) = 
                _period_or_all_day($day, $mon, $year, $now);
            return _apply_leeway($from, $to, $leeway * $vague);
        }
     }

    if (/^(.*) week(?:s)? ago$/ || /^in (.*) week(?:s)?(?: time)?$/ || 
        /^(.*) week(?:s)? (?:away)?\s*(?:from now)?$/) {
        my $weeks = $1;
        my $days;
        {
            local $_; 
            # words2nums() trashes $_.
            $days = 7 * Lingua::EN::Words2Nums::words2nums($weeks);
        }
        if (defined $days) { 
            $days *= -1 if /ago/;
            _debug("Modifying day by $days");
            $day += $days;
            ($day, $mon, $year) = _zyprexa($day, $mon, $year);
            ($from, $to, $leeway) = 
                _period_or_all_day($day, $mon, $year, $now);
            return _apply_leeway($from, $to, $leeway * $vague);
        }
     }

    if (/^(.*) month(?:s)? ago$/ || /^in (.*) month(?:s)?(?: time)?$/ || 
        /^(.*) month(?:s)? (?:away)?\s*(?:from now)?$/) {
        my $months = $1;
        {
            local $_; 
            # words2nums() trashes $_.
            $months = Lingua::EN::Words2Nums::words2nums($months);
        }
        if (defined $months) { 
            $months *= -1 if /ago/;
            _debug("Modifying month by $months");
            $mon += $months;
            ($day, $mon, $year) = _zyprexa($day, $mon, $year);
            ($from, $to, $leeway) = 
                _period_or_all_day($day, $mon, $year, $now);
            return _apply_leeway($from, $to, $leeway * $vague);
        }
     }

    if (/^(.*) year(?:s)? ago$/ || /^in (.*) year(?:s)?(?: time)?$/ || 
        /^(.*) year(?:s)? (?:away)?\s*(?:from now)?$/) {
        my $years = $1;
        {
            local $_; 
            # words2nums() trashes $_.
            $years = Lingua::EN::Words2Nums::words2nums($years);
        }
        if (defined $years) { 
            $years *= -1 if /ago/;
            _debug("Modifying year by $years");
            $year += $years;
            ($day, $mon, $year) = _zyprexa($day, $mon, $year);
            ($from, $to, $leeway) = 
                _period_or_all_day($day, $mon, $year, $now);
            return _apply_leeway($from, $to, $leeway * $vague);
        }
     }

    # We got nothing. Warn the caller.
    if (!$from and !$to) {
        return (GIBBERISH, "I couldn't parse that at all.");
    }
}

# Define the basic ranges for a day. (earliest,latest) pairs.
my %points_of_day = (

    # Technically, after midnight is the morning of the next day.
    # Morning runs until noon.
    morning   => [
                    [0,   0,  0],
                    [12,  0,  0]
                 ],

    # Must be English rules for how long lunch is :) [JM]
    lunchtime => [
                    [12,  0,  0],
                    [13, 30,  0]
                 ],
    # Afternoon runs till 6 PM.
    afternoon => [
                    [13, 30,  0], # "It is not afternoon until a gentleman
                    [18,  0,  0]  # has had his luncheon."
                 ],
    # Evening runs up to but not including midnight.
    evening   => [
                    [18,  0,  0], # Regardless of what Mediterraneans think
                    [23, 59, 59]
                 ],
    # The entire day.
    day       => [
                    [0,   0,  0],
                    [23, 59, 59],
                 ]
);

# _apply_point_of_day takes the word specifying the portion of the 
# day and transforms it into a range of hours.

sub _apply_point_of_day {
    my ($d, $m, $y, $point) = @_;
    my ($from, $to); 
    if ($point eq "night") { # Special case
        # Nights are a special case because they run over the
        # day boundary. (9PM to 5:59:59AM the next day).
        $from = timelocal(0,0,21,$d,$m,$y);
        $to   = timelocal(59,59,5,$d+1,$m,$y);
    } else {
        # Look up the appropriate range and set the hours
        # in the specified day.
        my $spec = $points_of_day{$point};
        my @from = (reverse(@{$spec->[0]}),$d,$m,$y);
        my @to   = (reverse(@{$spec->[1]}),$d,$m,$y);
        $from = timelocal(@from);
        $to   = timelocal(@to);
    }
    return ($from, $to);
}

# _period_or_all_day determines the size of leeway to
# be applied to a date (closer dates get less, dates
# further in the future or past get more). It also
# applies the appropriate point-of-day.
sub _period_or_all_day {
    my $point;
    my ($day, $mon, $year, $now) = @_;
    my $leeway;

    if (/(morning|afternoon|evening|lunchtime|night)/) {
        $leeway = 60*60*2;
        $point = $1;
    } else {
        # To determine the leeway, consider how many days ago this was;
        # we want to be more specific about recent events than ancient
        # ones.
        my $was = timelocal(0,0,0, $day, $mon, $year);
        my $days_ago = int(($now-$was)/(60*60*24))+1;
        $leeway = 60*60*3*$days_ago;
        # Up to a maximum of five days
        $leeway > 24*60*60*5 and $leeway = 24*60*60*5;
        _debug("Wanted around $days_ago, allowing $leeway either side");
        $point = "day";
    }
    return (_apply_point_of_day($day, $mon, $year, $point), $leeway);
}

# _apply_leeway just applies the necessary leeway to the
# current date range.
sub _apply_leeway {
    my ($from, $to, $leeway) = @_;
    my $new_from = $from - $leeway;
    my $new_to   = $to   + $leeway;
    # watch for daylight savings crossovers!
    for my $pair ( [\$new_from, $from], [\$new_to, $to] ) {
        if ( _isnt_dst(${ $pair->[0] }) and _is_dst($pair->[1]) ) {
            ${ $pair->[0] } += 60 * 60; # forward an hour to match
        }
        if ( _is_dst(${ $pair->[0] }) and _isnt_dst($pair->[1]) ) {
            ${ $pair->[0] } -= 60 * 60; # back an hour to match
        }
    }
    return ($new_from, $new_to);
}

sub _is_dst {
    my ($given_time) = shift;
    return (localtime $given_time)[-1];
}

sub _isnt_dst {
    return not _is_dst(@_);
}

# similar to Time::Local::timelocal but accepts the offsets returned by
# Date::Calc::Today_and_Now()
sub _timelocal {
    my ( $year, $mon, $day, $hour, $min, $sec ) = @_;

    # make offsets as expected by timelocal
    $year -= 1900;
    $mon--;

    return timelocal( $sec, $min, $hour, $day, $mon, $year );
}

# same as Date::Calc::Today but respect $TestTime so that
# we can test periods based on today's date
sub _today {
    my $now = $TestTime || time;
    my ( $day, $month, $year ) = ( localtime $now )[ 3 .. 5 ];
    $year += 1900;
    $month++;
    return ($year, $month, $day);
}

# Our date math can lead to days or months out of range, so we need to get 
# them back to something sane before we pass them to any of the date functions.
# (Zyprexa is an anti-psychotic.)
sub _zyprexa {
    my( $day, $month, $year) = @_;

    $day++;
    $month++;
    $year += 1900;

    while ($month > 12) {
        $year++;
        $month -= 12;
    }

    while ($month < 1) {
        $year--;
        $month += 12;
    }

    while ($day > Days_in_Month($year, $month)) {
        $day -= Days_in_Month ($year, $month);
        $month++;
        if ($month > 12) {
            $month = 1;
            $year++;
        }
    }

    while ($day < 0) {
        $month--;
        if ($month < 1) {
            $month = 12;
            $year--;
        }
        $day += Days_in_Month($year, $month);
    }

    $day--;
    $month--;
    $year -= 1900;

    return ($day, $month, $year);
}

1;
__END__

=head1 NAME

Date::PeriodParser - Turns English descriptions into time periods

=head1 SYNOPSIS

  use Date::PeriodParser;
  my ($midnight, $midday) = parse_period("this morning");
  my ($monday_am, $sunday_pm) = parse_period("this week");
  ... parse_period("sometime this afternoon");
  ... parse_period("around two weeks ago");


=head1 DESCRIPTION

C<Date::PeriodParser> provides a means of interpreting vague descriptions
of dates as actual, meaningful date values by taking a shot at 
interpreting the meaning of the supplied descriptive phrase, 
generating a best-guess before-and-after estimate of the time period described.

=head1 ROUTINES

=head2 parse_period

The subroutine C<parse_period> attempts to turn an English description
of a time period into a pair of Unix epoch times. As a famous man once
said, "Of course, this is a heuristic, which is a fancy way of saying
that it doesn't work".

=head1 WHAT'S CURRENTLY SUPPORTED

=over 4

=item * sometime

Returns full range of dates from the epoch to the latest-possible date
(currently "Mon Jan 18 19:14:07 2038").

=item * now

Returns the current date and time.

=item * today, tomorrow, yesterday

Supported, with "the day before" and "the day after" accepted as modifiers.
This means you can say relatively meaningless things like "the day after
yesterday" and "the day before tomorrow", but they work.

=item * day, morning, lunchtime, afternoon, evening, night

These are all supported with "this" and "in the" as modifiers;
relative times specified with "in the" (for morning, afternoon, and evening)
disambiguate relative to the current time. For instance, if it's afternoon
and "in the morning" is specified, this implies "tomorrow morning".

=item * this week, last week, this month, last month

"This" means the week or month which includes the current day.  Weeks begin on
Monday and end of Sunday.  "Last" means the week or month preceeding "this
week/month".

=item * january 2007, dec 2005, jul 1982

A month name followed by a four-digit year.

=item * "ago" and "from now"

Offsets in days, weeks, months, and years are accepted.

=item * "in I<xxx> (unit)(s)" and "in I<xxx> (units) time"

Offsets in days, weeks, months, and years are supported.

=back

If you enter something it can't parse, it'll return an error code and an
explanation instead of two epoch time values. Error code -1 means "You
entered gibberish", error code -2 means "you entered something
ambiguous", and the explanation will tell you how to disambiguate it.

=head1 DEPENDENCIES

=over 

=item * Lingua::EN::Words2Nums

Any of the phrases that use an English word for a number require that
L<Lingua::EN::Words2Nums> be installed.  If those phrases are not used,
the module is optional.

=item * Date::Calc

Used to do all that messy date math.

=back

=head1 BUGS

=over 

=item * Parsing is limited. Some relatively complicated things work fine, but some simple things do not.

=item * The time-of-day words ("morning", "afternoon", "evening", "night", and 
"lunchtime") should accept relative modifiers (e.g., "lunchtime tomorrow", 
"yesterday evening"), but don't.

=item * The API is much too C-like. We should probably throw a structured exception instead of returning a failure code.

=back

=head1 AUTHOR

Simon Cozens, C<simon@cpan.org>
Joe McMahon, C<mcmahon@cpan.org>
Major contributions by Michael Hendrix (mndrix@cpan.org) (Thanks!)

=head1 LEGAL

Copyright (C) 2002 by Simon Cozens; Copyright (c) 2005-2013 by Joe McMahon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
