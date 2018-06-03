package Date::Easy::Date;

use strict;
use warnings;
use autodie;

our $VERSION = '0.05'; # VERSION

use Exporter;
use parent 'Exporter';
our @EXPORT_OK = qw< date today >;
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

use parent 'Date::Easy::Datetime';

use Carp;
use Time::Local;
use Scalar::Util 'blessed';


##############################
# FUNCTIONS (*NOT* METHODS!) #
##############################


sub date
{
	my $date = shift;
	if ( $date =~ /^-?\d+$/ )
	{
		if ($date < 29000000 and $date >= 10000000)
		{
			my @time = $date =~ /^(\d{4})(\d{2})(\d{2})$/;
			return Date::Easy::Date->new(@time);
		}
		return Date::Easy::Date->new($date);
	}
	elsif ( $date !~ /\d/ )
	{
		my $time = _parsedate($date);
		croak("Illegal date: $date") unless defined $time;
		return Date::Easy::Date->new($time);
	}
	else
	{
		my ($d, $m, $y) = _strptime($date);
		if (defined $y)													# they're either all defined, or it's bogus
		{
			return Date::Easy::Date->new($y, $m, $d);
		}
		else
		{
			my $time = _parsedate($date);
			croak("Illegal date: $date") unless defined $time;
			return Date::Easy::Date->new($time);
		}
	}
	die("reached unreachable code");
}

sub today () { Date::Easy::Date->new }


sub _strptime
{
	require Date::Parse;
	# Most of this code is stolen from Date::Parse, by Graham Barr.
	#
	# In an ideal world, I would just use the code from there and not repeat it here.  However, the
	# problem is that str2time() calls strptime() to generate the pieces of a datetime, then does
	# some validation, then returns epoch seconds by calling timegm (from Time::Local) on it.  I
	# don't _want_ to call str2time because I'm just going to take the epoch seconds and turn them
	# back into pieces, so it's inefficicent.  But more importantly I _can't_ call str2time because
	# it converts to UTC, and I want the pieces as they are relative to whatever timezone the
	# parsed date has.
	#
	# On the other hand, the problem with calling strptime directly is that str2time is doing two
	# things there: the conversion to epoch seconds, which I don't want or need, and the validation,
	# which, it turns out, I *do* want, and need.  For instance, strptime will happily return a
	# month of -1 if it hits a parsing hiccough.  Which then strftime will turn into undef, as you
	# would expect.  But, if you're just calling strptime, that doesn't help you much. :-(
	#
	# Thus, I'm left with 3 possibilities, none of them very palatable:
	# 	#	call strptime, then call str2time as well
	#	#	repeat at least some of the code from str2time here
	#	#	do Something Devious, like wrap/monkey-patch strptime
	# #1 doesn't seem practical, because it means that every string that has to be parsed this way
	# has to be parsed twice, meaning it will take twice as long.  #3 seems too complex--since the
	# call to strptime is out of my control, I can't add arguments to it, or get any extra data out
	# of it, which means I have to store things in global variables, which means it wouldn't be
	# reentrant ... it would be a big mess.  So #2, unpalatable as it is, is what we're going with.
	#
	# Of course, this gives me the opportunity to tweak a few things.  For instance, we can tweak
	# the year value to fix RT/105031 (noted below).  Also, since this is only used by our ::Date
	# class, we don't give a crap about times or timezones, so we can totally ignore those parts.
	# (Well, *almost* totally: we still want to verify that we're getting valid values for them.)
	# Which makes this code actually much smaller than its Date::Parse equivalent.
	#
	# On top of that, this is a tiny bit more efficient.

	my ($str) = @_;

	# don't really care about seconds, minutes, or hours, but need to verify them
	# don't care about timezone at all
	my ($ss,$mm,$hh, $day, $month, $year, undef) = Date::Parse::strptime($str);
	my $num_defined = defined($day) + defined($month) + defined($year);
	return undef if $num_defined == 0;
	if ($num_defined < 3)
	{
		my @lt  = localtime(time);

		$month = $lt[4] unless defined $month;
		$day  = $lt[3] unless defined $day;
		$year = ($month > $lt[4]) ? ($lt[5] - 1) : $lt[5] unless defined $year;
	}
	$year += 1900; ++$month;											# undo timelocal's funkiness
																		# (this also corrects RT/105031)

	return undef unless $month >= 1 and $month <= 12 and $day >= 1 and $day <= 31;
	# we don't actually care about the hours/mins/secs, but if they're illegal, we should still fail
	return undef unless ($hh || 0) <= 23 and ($mm || 0) <= 59 and ($ss || 0) <= 59;
	return ($day, $month, $year);
}


sub _parsedate
{
	require Time::ParseDate;
	my $string = shift;

	# Remove any timezone specifier so we get the date as it was in that timezone.
	# I've gathered up all timezone matching code from Time::ParseDate as of v2015.103.
																		# matching code from Time/ParseDate.pm:
	my $break = qr{(?:\s+|\Z|\b(?![-:.,/]\d))};												# line 67
	$string =~ s/
			(?:
					[+-] \d\d:?\d\d \s+ \( "? (?: [A-Z]{1,4}[TCW56] | IDLE ) \)				# lines 424-435
				|	GMT \s* [-+]\d{1,2}														# line 441
				|	(?: GMT \s* )? [+-] \d\d:?\d\d											# line 452
				|	"? (?: [A-Z]{1,4}[TCW56] | IDLE )										# line 457 (and 695-700)
			) $break //x;

	# We *must* force scalar context.  Remember, parsedate called in list context also returns the
	# "remainder" of the parsed string (which is often undef, which could wreak havoc with a call
	# that incorporates our return value, particularly one to _mktime).
	return scalar Time::ParseDate::parsedate($string, DATE_REQUIRED => 1);
}


#######################
# REGULAR CLASS STUFF #
#######################


sub new
{
	my $class = shift;
	my ($y, $m, $d);
	if (@_ == 3)
	{
		($y, $m, $d) = @_;
		--$m;										# timegm will expect month as 0..11
	}
	else
	{
		my ($time) = @_;
		$time = time unless defined $time;
		if (my $conv_class = blessed $time)
		{
			if ( $time->isa('Time::Piece') )
			{
				($d, $m, $y) = ($time->mday, $time->_mon, $time->year);
			}
			else
			{
				croak("Don't know how to convert $conv_class to $class");
			}
		}
		else
		{
			($d, $m, $y) = (localtime $time)[3..5];	# `Date`s are parsed relative to local time ...
			$y += 1900;								# (timelocal/timegm does odd things w/ 2-digit dates)
		}
	}

	my $truncated_date =
			eval { timegm( 0,0,0, $d,$m,$y ) };		# ... but stored as UTC
	croak("Illegal date: $y/" . ($m + 1) . "/$d") unless defined $truncated_date;
	return $class->_mkdate($truncated_date);
}

sub _mkdate
{
	my ($invocant, $epoch) = @_;
	my $class = ref $invocant || $invocant;
	return bless Date::Easy::Datetime->new(UTC => $epoch), $class;		# always UTC
}


############################
# OVERRIDDEN FROM DATETIME #
############################


sub split
{
	my $impl = shift->{impl};
	( $impl->year, $impl->mon, $impl->mday )
}


# override addition and subtraction
# numbers added to a ::Date are days

sub _add_integer		{ $_[0]->add_days($_[1])      }
sub _subtract_integer	{ $_[0]->subtract_days($_[1]) }


# These are illegal to call.
sub add_seconds { die("cannot call add_seconds on a Date value") }
sub add_minutes { die("cannot call add_minutes on a Date value") }
sub add_hours { die("cannot call add_hours on a Date value") }
sub subtract_seconds { die("cannot call subtract_seconds on a Date value") }
sub subtract_minutes { die("cannot call subtract_minutes on a Date value") }
sub subtract_hours { die("cannot call subtract_hours on a Date value") }



1;



# ABSTRACT: easy date class
# COPYRIGHT

__END__

=pod

=head1 NAME

Date::Easy::Date - easy date class

=head1 VERSION

This document describes version 0.05 of Date::Easy::Date.

=head1 SYNOPSIS

    use Date::Easy::Date ':all';

    # guaranteed to have a time of midnight
    my $d = date("3-Sep-1940");

    # addition and subtraction work in increments of days
    my $tomorrow = today + 1;
    my $last_week = today - 7;
    say "$d was ", today - $d, " days ago";

    my $yr = $d->year;
    my $mo = $d->month;
    my $da = $d->day;
    my $ep = $d->epoch;
    my $qr = $d->quarter;
    my $dw = $d->day_of_week;

    say $d->strftime("%d/%m/%Y");

    my $tp = $d->as('Time::Piece');

=head1 DESCRIPTION

A Date::Easy::Date object is really just a L<Date::Easy::Datetime> object whose time portion is
always guaranteed to be midnight.  In typical usage, you will either use the C<date> constructor to
convert a human-readable string to a date, or the C<today> function to return today's date.  Both
are exported with the C<:all> tag; nothing is exported by default.

Arithmetic operators (plus and minus) either add or subtract days to or from the date object.  All
methods are inherited from Date::Easy::Datetime.

Like their underlying datetime objects, date objects are immutable.

See L<Date::Easy> for more general usage notes.

=head1 USAGE

=head2 Constructors

=head3 Date::Easy::Date->new

Returns the same as L</today>.

=head3 Date::Easy::Date->new($e)

Takes the given epoch seconds, turns it into a datetime (in the local timezone), then throws away
the time portion and constructs a date object with the remainder.

=head3 Date::Easy::Date->new($y, $m, $d)

Takes the given year, month, and day, and turns it into a date object.  Month and day are
human-centric (i.e., 1-based, not 0-based).  Year should probably be a 4-digit year; if you pass in
a 2-digit year, you get whatever century C<timegm> thinks you should get, which may or may not be
what you expected.

=head3 Date::Easy::Date->new($obj)

If the sole argument to C<new> is a blessed object, attempts to convert that object to a date.
Currently the only type of object that can be successfully converted is a L<Time::Piece>.

=head3 today

Returns the current date (in the local timezone).

=head3 date($string)

Takes the human-readable string and converts it to a date using the following heuristics:

=over 4

=item *

If the string consists of exactly 8 digits, and the first two digits are between "10" and "28"
(inclusive), treats it as a compact datestring in the form YYYYMMDD.  Splits it up and passes year,
month, and day to C<new>.

=item *

Otherwise, if the string consists of nothing but digits (including an optional leading negative
sign), treats it as a number of epoch seconds and passes it to C<new>.

=item *

Otherwise, if the string contains no digits at all, removes any timezone specifier, then passes it
to L<Time::ParseDate>'s C<parsedate> function.  If the result is defined, passes the resulting epoch
seconds to C<new>.

=item *

Otherwise if the string contains some digits, passes it to L<Date::Parse>'s C<strptime> function.
If the resulting six values are defined and in the proper ranges, passes the year, month, and day to
C<new>.

=item *

Otherwise if the results of calling C<strptime> are unsatisfactory, removes any timezone specifier,
then passes it to L<Time::ParseDate>'s C<parsedate> function.  If the result is defined, passes the
resulting epoch seconds to C<new>.

=item *

If C<parsedate> returns C<undef> (in either position), throws an "Illegal date" exception.

=back

Though this sounds complicated, most of the time it just does what you meant and you don't need to
think about it.

=head2 Accessors

All accessors are inherited from L<Date::Easy::Datetime>, so refer to those docs.  Note that
C<hour>, C<minute>, and C<second> will always return 0 for a date object, and C<time_zone> will
always return 'UTC'.  Likewise, C<is_local> always returns false and C<is_utc> (and its alias
C<is_gmt>) always return true.

=head2 Overridden Methods

A few methods inherited from L<Date::Easy::Datetime> return different results in
C<Date::Easy::Date>.

=head3 split

Returns a list consisting of the year, month, and day, in that order, in the same ranges as returned
by the L<Date::Easy::Datetime/Accessors>.  This differs from datetime's C<split> in that the final
three elements (hours, minutes, and seconds) are omitted, since they're always zero.  Doesn't return
anything useful in scalar context, so don't do that.  Calling C<split> in scalar context may
eventually be changed to throw a warning or fatal error.

=head3 add_seconds

=head3 add_minutes

=head3 add_hours

=head3 subtract_seconds

=head3 subtract_minutes

=head3 subtract_hours

These methods throw exceptions if you call them for a date value, because they would adjust the time
portion, and the time portion of a date value must always be midnight.

=head2 Other Methods

All other methods are also inherited from L<Date::Easy::Datetime>, so refer to those docs.

=head2 Overloaded Operators

=head3 Addition

You can add an integer value to a date object.  It adds that number of days and returns a new date
object.  The original date is not modified.

=head3 Subtraction

You can subtract an integer value from a date object.  It subtracts that number of days and returns
a new date object.  The original date is not modified.

You can subtract one date from another; the result is the number of days you would have to add to
the right-hand operand to get the left-hand operand (therefore, the result is positive when the
left-hand side is a later date, and negative when the left-hand side is earlier).  Currently the
result of attempting to subtract a datetime from a date is undefined.

=head1 BUGS, CAVEATS and NOTES

Because a number like "20090120" can be either a compact datestring (20-Jan-2009) or  a valid number
of epoch seconds (21-Aug-1970 12:35:20), there is a range of epoch seconds that you cannot pass in
via C<date>.  That range is 26-Apr-1970 17:46:40 to 2-Dec-1970 15:33:19.

Any timezone portion specified in a string passed to C<date> is completely ignored.

Because dates I<don't> have the same bug with 4-digit years that are 50+ years old that datetimes
do, they have a different bug instead.  If you pass a 2-digit year to `date` and it gets handled by
L<Date::Parse>, it will always come back in the 20th century:

    say date("2/1/17"); # Thu Feb  1 00:00:00 1917

Avoiding this is simple: always use 4-digit dates (which is a good habit to get into anyway).  Given
the choice between the two bugs, this was considered the lesser of two weevils.

See also L<Date::Easy/"Limitations">.

=head1 AUTHOR

Buddy Burden <barefootcoder@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Buddy Burden.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
