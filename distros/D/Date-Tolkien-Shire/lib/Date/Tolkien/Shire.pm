package Date::Tolkien::Shire;

use strict;
use warnings;

use Date::Tolkien::Shire::Data qw{
    __date_to_day_of_year
    __day_of_week
    __day_of_year_to_date
    __format
    __holiday_name
    __is_leap_year
    __month_name
    __on_date
    __rata_die_to_year_day
    __trad_weekday_name
    __weekday_name
    __year_day_to_rata_die
    GREGORIAN_RATA_DIE_TO_SHIRE
};
use Time::Local;

our $ERROR;
our $VERSION = '1.901';

sub new {
    my ( $class, $date, %arg ) = @_;
    my $self = {};
    $ERROR = '';
    bless($self, $class);
    $self->set_date($date) if defined($date);
    $self->set_accented( $arg{accented} );
    $self->set_traditional( $arg{traditional} );
    return $self;
}

sub error {
    return $ERROR;
}

sub today {
    my ( $class, %arg ) = @_;
    # TODO If I ever do time-of-day support, this will have to change.
    my $self = $class->new( time );
    $self->set_accented( $arg{accented} );
    $self->set_traditional( $arg{traditional} );
    return $self;
}

sub from_shire {
    my ( $class, %arg ) = @_;
    my $accented = delete $arg{accented};
    my $traditional = delete $arg{traditional};
    my $self = $class->new()->set_shire( %arg );
    $self->set_accented( $accented );
    $self->set_traditional( $traditional );
    return $self;
}

sub set_date {
    my ( $self, $date ) = @_;
    $ERROR = '';

    if ( ! defined $date ) {
	$ERROR = 'You must pass in a date to set me equal to';
	return $self;
    }

    my $ref = ref $date;

    if ( __PACKAGE__ eq $ref ) {

	# Shallow clone
	%{ $self } = %{ $date };

    } elsif ( ! $ref ) {

	# TODO this will throw warnings if the date is not a number.
	my ( $greg_year, $greg_day_of_year ) = ( localtime $date )[5,7];

	my $greg_rata_die = __year_day_to_rata_die(
	    $greg_year + 1900,
	    $greg_day_of_year + 1,
	);

	$self->set_rata_die( $greg_rata_die );

    } else {
	$ERROR .= 'The date you gave is invalid';
    }
    return $self;
}

sub set_rata_die {
    my ( $self, $greg_rata_die ) = @_;

    my $shire_rata_die = $greg_rata_die + GREGORIAN_RATA_DIE_TO_SHIRE;

    my ( $shire_year, $shire_day_of_year ) = __rata_die_to_year_day(
	$shire_rata_die );

    my ( $shire_month, $shire_day ) = __day_of_year_to_date(
	$shire_year,
	$shire_day_of_year,
    );

    $self->{year} = $shire_year;
    $self->{month} = $shire_month;
    if ( $shire_month ) {
	$self->{holiday} = 0;
	$self->{monthday} = $shire_day;
    } else {
	$self->{holiday} = $shire_day;
	$self->{monthday} = 0;
    }
    $self->{weekday} = __day_of_week( $shire_month, $shire_day );

    return $self;
}

{
    my %legal = map { $_ => 1 } qw{ year month day holiday };

    sub set_shire {
	my ( $self, %arg ) = @_;

	foreach my $key ( keys %arg ) {
	    $legal{$key}
		or return _error_out( $self,
		"No such argument as '$key'" );
	    $arg{$key} =~ m/ \A [0-9]+ \z /smx
		or return _error_out( $self,
		"Argument '$key' must be an unsigned integer" );
	}

	defined $arg{year}
	    or return _error_out( $self, 'Year must be specified' );

	if ( $arg{month} ) {
	    $arg{holiday}
		and return _error_out( $self,
		'Month and holiday must not both be specified' );
	    if ( $arg{month} ) {
		$arg{holiday} = 0;
		$arg{day} ||= 1;
	    } else {
		$arg{holiday} = $arg{day};
		$arg{day} = 0;
	    }
	} else {
	    $arg{holiday} ||= 1;
	    $arg{month} = $arg{day} = 0;
	}

	$ERROR = '';
	$arg{weekday} = __day_of_week( $arg{month}, $arg{day} ||
	    $arg{holiday} );
	$arg{monthday} = delete $arg{day};
	%{ $self } = %arg;
	return $self;
    }
}

sub set_accented {
    my ( $self, $value ) = @_;
    $self->{accented} = $value;
    return $self;
}

sub set_traditional {
    my ( $self, $value ) = @_;
    $self->{traditional} = $value;
    return $self;
}

sub time_in_seconds {
    my ( $self ) = @_;

    $self->_has_date()
	or return 0;

    my $shire_day_of_year = __date_to_day_of_year(
	$self->{year},
	$self->{month},
	$self->{monthday} || $self->{holiday},
    );

    my $shire_rata_die = __year_day_to_rata_die(
	$self->{year},
	$shire_day_of_year,
    );

    my $greg_rata_die = $shire_rata_die - GREGORIAN_RATA_DIE_TO_SHIRE;

    my ( $greg_year, $greg_day_of_year ) = __rata_die_to_year_day(
	$greg_rata_die );

    my @monthlen = ( 31, 28 + __is_leap_year( $greg_year ),
	31, 30, 31, 30, 31, 31, 30, 31, 30, 31 );

    my $greg_day = $greg_day_of_year;
    for ( my $greg_month = 0; $greg_month < @monthlen; $greg_month++ ) {
	$greg_day <= $monthlen[$greg_month]
	    and return timelocal(
	    0, 0, 0, $greg_day, $greg_month, $greg_year );
	$greg_day -= $monthlen[$greg_month];
    }

    $ERROR = "Programming error: computed day $greg_day_of_year in Gregorian year $greg_year";
    return 0;
}

# TODO if I do time of day, epoch() will return it, whereas
# time_in_seconds will not.
*epoch = \&time_in_seconds;	# sub epoch;

sub weekday {
    my ( $self ) = @_;

    $self->_has_date()
	or return 0;

    return __weekday_name( $self->{weekday} );
}

sub weekday_number {
    my ( $self ) = @_;

    $self->_has_date()
	or return 0;

    return $self->{weekday};
}

sub trad_weekday {
    my ( $self ) = @_;

    $self->_has_date()
	or return 0;

    return __trad_weekday_name( $self->{weekday} );
}

sub month {
    my ( $self ) = @_;

    $self->_has_date()
	or return 0;

    return __month_name( $self->{month} );
}

sub day {
    my ( $self ) = @_;

    $self->_has_date()
	or return 0;

    return $self->{monthday};
}

sub holiday {
    my ( $self ) = @_;

    $self->_has_date()
	or return 0;

    return __holiday_name( $self->{holiday} );
}

sub year {
    my ( $self ) = @_;

    $self->_has_date()
	or return 0;

    return $self->{year};
}

use overload
    '<=>' => \&_space_ship,
    'cmp' => \&_space_ship,
    '""'  => \&as_string,
    ;

#All the other operators come automatically once this one is defined

sub _space_ship {
    my ($date1, $date2) = @_;
    my $time1 = $date1->time_in_seconds();
    $ERROR .= " on left operand" if $ERROR;
    my $time2 = $date2->time_in_seconds();
    $ERROR .= " on right operand" if $ERROR;
    return $time1 <=> $time2;
} #end sub _space_ship

sub accented { return $_[0]->{accented} }

sub as_string {
    # I can not just assign to $_[1] because it is an alias for the
    # argument, thus the possibility of spooky action at a distance.
    splice @_, 1, $#_, '%Ex';
    goto &strftime;
}

sub on_date {
    # I can not just assign to $_[1] because it is an alias for the
    # argument, thus the possibility of spooky action at a distance.
    splice @_, 1, $#_, '%Ex%n%En%Ed';
    goto &strftime;
}

sub strftime {
    my ( $self, @fmt ) = @_;

    $self->_has_date()
	or return 0;

    return wantarray ?
	( map { __format( $self, $_ ) } @fmt ) :
	__format( $self, $fmt[0] );
}

sub traditional { return $_[0]->{traditional} }

# Date::Tolkien::Shire::Data::__format() date object interface

*__fmt_shire_year = \&year;	# sub __fmt_shire_year;

sub __fmt_shire_month {
    my ( $self ) = @_;

    $self->_has_date()
	or return 0;

    return $self->{month};
}

sub __fmt_shire_day {
    my ( $self ) = @_;

    $self->_has_date()
	or return 0;

    return $self->{monthday} || $self->{holiday};
}

sub __fmt_shire_day_of_week {
    my ( $self ) = @_;

    $self->_has_date()
	or return 0;

    return $self->{weekday};
}

# sub __fmt_shire_hour; sub __fmt_shire_minute; sub __fmt_shire_second;
# sub __fmt_shire_nanosecond;
*__fmt_shire_hour = *__fmt_shire_minute = *__fmt_shire_second =
    *__fmt_shire_nanosecond = sub { 0 };

# The interface definition requires this to return undef, since the zone
# is undefined. See Date::Tolkien::Shire::Data.
sub __fmt_shire_zone_offset { return undef }	## no critic (ProhibitExplicitReturnUndef)
sub __fmt_shire_zone_name { return '' }

*__fmt_shire_epoch = \&epoch;			# sub __fmt_shire_epoch;
*__fmt_shire_accented = \&accented;	# sub __fmt_shire_accented;
*__fmt_shire_traditional = \&traditional;	# sub __fmt_shire_traditional;

sub _error_out {
    my ( $return, @msg ) = @_;
    $ERROR = join ' ', @msg;
    return $return;
}

sub _has_date {
    my ( $self ) = @_;
    if ( grep { ! defined $self->{$_} }
	qw{ holiday month monthday weekday year } ) {
	$ERROR = 'You must set a date first';
	return 0;
    } else {
	$ERROR = '';
	return 1;
    }
}

1;

__END__

=head1 NAME

Date::Tolkien::Shire - Convert dates into the Shire Calendar.

=head1 SYNOPSIS

 use Date::Tolkien::Shire;

 my $dts = Date::Tolkien::Shire->new( time );
 print $dts->on_date();

=head1 DESCRIPTION

This is an object-oriented module to convert dates into the Shire
Calendar as presented in the Lord of the Rings by J. R. R. Tolkien.  It
includes converting epoch time to the Shire Calendar (you can also get
epoch time back), comparison operators, and a method to print a
formatted string that does something to the effect of I<on this
date in history> -- pulling events from the Lord of the Rings.

The biggest use I can see in this thing is in a startup script or
possibly to keep yourself entertained in an otherwise boring app that
includes a date.  If you have any other ideas/suggestions/uses, etc.,
please let me know.  I am curious to see how this gets used (if it gets
used that is).

=head1 METHODS

Note:  I have tried to make these as friendly as possible when an error
occurs.  As a consequence, none of them die, croak, etc.  All of these
return 0 on error, but as 0 can be a valid output in a couple cases (the
day of the month for a holiday, for example), the error method should
always be checked to see if an error has occurred.  As long as you set a
date before you try to use it, you should be ok.

=head2 new

    $shiredate = Date::Tolkien::Shire->new;
    $shiredate = Date::Tolkien::Shire->new(time);
    $shiredate = Date::Tolkien::Shire->new($another_shiredate);

The constructor C<new()> can take zero or one parameter. Either a new object
can be created without setting a specific date (the zero-parameter
version), or an object can be created and the date set to either a
current shire date, or an epoch time such as is returned by the time
function. For specifics on setting dates, see the 'set_date' function.

This constructor also takes optional arguments as name/value pairs. The
optional arguments are:

=over

=item accented

If this value is true (in the Perl sense), L<on_date()|/on_date> will
produce accented output, as will L<strftime()|/strftime> if given a
template that includes the events on the date represented by the object.

=item traditional

If this value is true (in the Perl sense), L<on_date()|/on_date> and
L<strftime()|/strftime> will produce traditional rather than common
weekday names. This option does not affect the output of
L<weekday()|/weekday> or L<trad_weekday()|/trad_weekday>.

=back

=head2 error

    $the_error = $shiredate->error;
    $the_error = Date::Tolkien::Shire->error;

This returns a null string if everything in the previous method call was
as it should be, and a string contain a description of what happened if
an error occurred.

=head2 today

    $shiredate = Date::Tolkien::Shire->today();

This convenience constructor returns an object set to midnight the
morning of the current local day.

The optional arguments for L<new()|/new> may also be used here.

=head2 from_shire

    $shiredate = Date::Tolkien::Shire->from_shire(
        year    => 1419,
        month   => 3,
        day     => 25,
    );
    $shiredate = Date::Tolkien::Shire->from_shire(
        year    => 1419,
        holiday => 3,
    );

This convenience constructor just wraps a call to C<new()> followed by a
call to C<set_shire()>.

The optional arguments for L<new()|/new> may also be used here.

=head2 set_date

This method takes either the seconds from the start of the epoch (like
what C<time()> returns) or another shire date object, and sets the date
of the object in question equal to that date.  If the object previously
contained a date, it will be overwritten.  Local time, rather than UTC,
is used in converting from epoch date.

Please see the note below on calculating the year if you're curious how
I arrived by that.

=head2 set_rata_die

    $shiredate->set_rata_die( $datetime->utc_rd_values() );

This method takes a date in days since December 31 of Gregorian year 0,
and sets the date of the invocant to that date. Only the first argument
is used, but others, if provided, should be consistent with the output
of the L<DateTime|DateTime> C<utc_rd_values()>, to save trouble in the
(probably unlikely) event that I add time-of-day functionality to this
package.

=head2 set_shire

    $shiredate->set_shire(
        year    => 1418,
        month	=> 3,
        day     => 25,
    );
    $shiredate->set_shire(
        year    => 1419,
        holiday => 3,
    );

This method sets the object's date to the given date in the Shire
calendar. The named arguments are C<year>, C<month>, C<day>, and
C<holiday>, and all are numeric. The C<year> argument is required; all
others are optional. You may not specify both C<month> and C<holiday>.
If C<month> is specified, C<day> defaults to C<1>; otherwise C<holiday>
defaults to C<1>.

This method returns the invocant. Errors are indicated by setting the
C<$ERROR> variable.

=head2 set_accented

This method takes a Boolean value which determines whether
L<on_date()|/on_date> should produce accented output. It returns the
invocant.

=head2 set_traditional

This method takes a Boolean value which determines whether
L<on_date()|/on_date> should use traditional rather than common names
for the days of the week. It returns the invocant.

=head2 time_in_seconds

    $epoch_time = $shire_date->time_in_seconds

Returns the epoch time (with 0 for hours, minutes, and seconds) of
a given shire date. This relies on the library Time::Local, so the
caveats and error handling with that module apply to this method as
well.

=head2 epoch

This is currently a synonym for L<time_in_seconds()|/time_in_seconds>.
But if I ever implement time-of-day functionality (far from certain)
this method will include that, whereas
L<time_in_seconds()|/time_in_seconds> will remain as of midnight.

=head2 weekday

    $day_of_week_name = $shiredate->weekday;

This method returns the day of the week using the more modern names in
use during the War of the Ring and given in the Lord of the Rings
Appendix D.  If the day in question is not part of any week (Midyear's
day and the Overlithe), then an empty string is returned.

=head2 weekday_number

    $day_of_week_number = $shiredate->weekday_number;

This method returns the number of the day of the week of the date in
question, or C<0> if the day is not part of any week (i.e.
C<Midyear's day> or the C<Overlithe>). Note that C<0> is also returned
on an error (date not set), so the careful programmer who uses this
method will check C<$ERROR> if C<0> is returned.

=head2 trad_weekday

    $day_of_week = $shiredate->trad_weekday

This method returns the day of the week using the archaic forms, the
oldest forms found in the Yellowskin of Tuckborough (also given in
Appendix D).  If the day in question is not part of any week (Midyear's
day and the Overlithe), then an empty string is returned.

=head2 month

    $month_name = $shiredate->month;

This method returns the month name of the date in question, or an empty
string if the day is a holiday, since holidays are not part of any
month.

=head2 day

    $day_of_month = $self->day;

This method returns the day of the month of the day in question, or C<0> in
the case of a holiday, since they are not part of any month. Since C<0>
is also returned on an error (date not set), the careful programmer will
check C<$ERROR> if C<0> is returned.

=head2 holiday

    $holiday_name = $shiredate->holiday;

If the day in question is a holiday, returns the holiday name: C<"1
Yule">, C<"2 Yule"> (first day of the new year), C<"1 Lithe">,
C<"Midyear's day">, C<"Overlithe">, or C<"2 Lithe">.  If the day is not
a holiday, an empty string is returned.

=head2 year

    $shire_year = $shiredate->year;

Returns the year of the shire date in question.  See the note on year
calculation below if you want to see how I figured this.

=head2 accented

This method returns a true value if L<on_date()|/on_date> is to produce
accented output.

=head2 traditional

This method returns a true value if L<on_date()|/on_date> is to use
traditional rather than current weekday names.

=head2 Overloaded Operators

The following comparison operators are available:

    $shiredate1 <  $shiredate2
    $shiredate1 lt $shiredate2
    $shiredate1 <= $shiredate2
    $shiredate1 le $shiredate2
    $shiredate1 >  $shiredate2
    $shiredate1 gt $shiredate2
    $shiredate1 >= $shiredate2
    $shiredate1 ge $shiredate2
    $shiredate1 == $shiredate2
    $shiredate1 eq $shiredate2
    $shiredate1 != $shiredate2
    $shiredate1 ne $shiredate2
    $shiredate1 <=> $shiredate2
    $shiredate1 cmp $shiredate2

You can only compare on shire date to another (no apples to oranges
here).  In this context both the numeric and string operators perform
the exact same function.  Like the standard operators, all but <=> and
cmp return 1 if the condition is true and the null string if it is
false.  <=> and cmp return -1 if the left operand is less than the right
one, 0 if the two operands are equal, and 1 if the left operand is
greater than the right one.

Additionally, you can view a shire date as a string:

    # prints something like 'Monday 28 Rethe 7465'
    print $shiredate;

=head2 as_string

    $shire_date_as_string = $shire_date->as_string;

Returns the given shire date as a string, similar in theory to
C<scalar localtime>. This is the method used to implement
the stringification overload.

=head2 on_date

    $historic_events = $shire_date->on_date

or you may want to try something like

    my $shiredate = Date::Tolkien::Shire->new( time );
    print "Today is " . $shiredate->on_date . "\n";

This method returns a string containing important events that happened
on this day and month in history, as well as the day itself.  It does
not give much more usefulness as far as using dates go, but it should be
fun to run during a startup script or something.  At present the events
are limited to the crucial years at the end of the third age when the
final war of the ring took place and Sauron was permanently defeated.
More dates will be added as I find them (if I find them maybe I should
say).  All the ones below come from Appendix B of the Lord of the Rings.
At this point, these are only available in English.

Note here that the string is formatted. This is to keep things simple
when using it as in the example above.  Note that in this example you
are actually ending with a double newline, as the first newline is part
of the return value.

If you don't like how this is formatted, complain at me and if I like
you I'll consider changing it :-)

If L<accented()|/accented> is true, this method returns accented output.
If L<traditional()|/traditional> is true, this method uses traditional
rather than common weekday names.

=head2 strftime

This is a re-implementation imported from
L<Date::Tolkien::Shire::Data|Date::Tolkien::Shire::Data>. It is intended
to be reasonably compatible with the same-named L<DateTime|DateTime>
method, but has some additions to deal with the peculiarities of the
Shire calendar.

See L<__format()|Date::Tolkien::Shire::Data/__format> in
L<Date::Tolkien::Shire::Data|Date::Tolkien::Shire::Data> for the
documentation, since that is the code that does the heavy lifting for
us.

If L<accented()|/accented> is true, this method returns accented output.
If L<traditional()|/traditional> is true, this method uses traditional
rather than common weekday names.

=head1 NOTE: YEAR CALCULATION

L<http://www.glyphweb.com/arda/f/fourthage.html> references a letter sent by
Tolkien in 1958 in which he estimates approximately 6000 years have passed
since the War of the Ring and the end of the Third Age.  (Thanks to Danny
O'Brien from sending me this link).  I took this approximate as an exact
and calculated back 6000 years from 1958 and set this as the start of the
4th age (1422).  Thus the fourth age begins in our B.C 4042.

According to Appendix D of the Lord of the Rings, leap years in the
hobbits'
calendar are every 4 years unless it is the turn of the century, in which
case it is not a leap year.  Our calendar uses every 4 years unless it
is
100 years unless it is 400 years.  So, if no changes had been made to
the hobbits' calendar since the end of the third age, their calendar would
be about 15 days further behind ours now then when the War of the Ring took
place.  Implementing this seemed to me to go against Tolkien's general habit
of converting dates in the novel to our equivalents to give us a better
sense of time.  My thoughts, at least right now, is that it is truer to the
spirit of things for March 25 today to be about the same as March 25 was back
then.  So instead, I have modified Tolkien's description of the hobbits'
calendar so that leap years occur once every 4 years unless it is 100
years unless it is 400 years, so that it matches our calendar in that
regard.  These 100 and 400 year intervals occur at different times in
the two calendars, however.  Thus the last day of our year is sometimes
7 Afteryule, sometimes 8, and sometimes 9.

=head1 BIBLIOGRAPHY

Tolkien, J. R. R. I<Return of the King>.  New York: Houghton Mifflin Press,
1955.

L<http://www.glyphweb.com/arda/f/fourthage.html>

=head1 BUGS

Epoch time.  Since epoch time was used as the base for this module, and the
only way to currently set a date is from epoch time, it borks on values that
epoch time doesn't support (currently values before 1902 or after 2037).  The
module should automatically expand in available dates directly with epoch time
support on your system.

=head1 AUTHOR

Tom Braun <tbraun@pobox.com>

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2001-2003, 2006 Tom Braun. All rights reserved.

Copyright (C) 2017 Thomas R. Wyant, III

The calendar implemented on this module was created by J.R.R. Tolkien,
and the copyright is still held by his estate.  The license and
copyright given herein applies only to this code and not to the
calendar itself.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
