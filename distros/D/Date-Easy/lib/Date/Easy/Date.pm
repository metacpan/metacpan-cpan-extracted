package Date::Easy::Date;

use strict;
use warnings;
use autodie;

our $VERSION = '0.08'; # VERSION

use Exporter;
use parent 'Exporter';
our @EXPORT_OK = qw< date today >;
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

use parent 'Date::Easy::Datetime';

use Carp;
use Scalar::Util 'blessed';
use Time::Local 1.26, qw< timegm_modern >;


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
		my (undef,undef,undef, $d, $m, $y)								# ignore first 3 values (time portion)
			= Date::Easy::Datetime::_strptime($date, 'local');			# remember: parse as local, store as UTC
		if (defined $y)													# they're either all defined, or it's bogus
		{
			# return value from _strptime for month is still in the funky 0 - 11 range
			return Date::Easy::Date->new($y, $m + 1, $d);
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
			($d, $m, $y) = (localtime $time)[3..5];						# `Date`s are parsed relative to local time ...
			$y += 1900;			# (no 2-digit dates allowed!)
		}
	}

	my $truncated_date =
			eval { timegm_modern( 0,0,0, $d,$m,$y ) };					# ... but stored as UTC
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

This document describes version 0.08 of Date::Easy::Date.

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
human-centric (i.e., 1-based, not 0-based).  Year should be a 4-digit year; if you pass in a 2-digit
year, you get a year bewteen 1900 and 1999, even if you use the last 2 digits of the current year.

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

If you pass a 2-digit year to `date`, it will always come back in the 20th century:

    say date("2/1/17"); # Thu Feb  1 00:00:00 1917

Avoiding this is simple: always use 4-digit dates (which is a good habit to get into anyway).  This
could be considered a bug, since Time::Local uses a 50-year sliding window, which I<might> be
considered to be more correct behavior.  However, by suffering this "bug," we avoid a bigger one
(see L<RT/53413|https://rt.cpan.org/Public/Bug/Display.html?id=53413> and
L<RT/105031|https://rt.cpan.org/Public/Bug/Display.html?id=105031>).

See also L<Date::Easy/"Limitations">.

=head1 AUTHOR

Buddy Burden <barefootcoder@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Buddy Burden.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
