package Date::Easy::Datetime;

use strict;
use warnings;
use autodie;

our $VERSION = '0.08'; # VERSION

use Exporter;
use parent 'Exporter';
our @EXPORT_OK = qw< datetime now >;
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

use Carp;
use Time::Piece;
use Scalar::Util 'blessed';
use Time::Local 1.26, qw< timegm_modern timelocal_modern >;


# this can be modified (preferably using `local`) to use GMT/UTC as the default
# or you can pass a value to `import` via your `use` line
our $DEFAULT_ZONE = 'local';

my %ZONE_FLAG = ( local => 1, UTC => 0, GMT => 0 );


sub import
{
	my @args;
	exists $ZONE_FLAG{$_} ? $DEFAULT_ZONE = $_ : push @args, $_ foreach @_;
	@_ = @args;
	goto &Exporter::import;
}


##############################
# FUNCTIONS (*NOT* METHODS!) #
##############################

sub datetime
{
	my $zonespec = @_ % 2 == 0 ? shift : $DEFAULT_ZONE;
	my $datetime = shift;
	if ( $datetime =~ /^-?\d+$/ )
	{
		return Date::Easy::Datetime->new($zonespec, $datetime);
	}
	else
	{
		my $t = _str2time($datetime, $zonespec);
		$t = _parsedate($datetime, $zonespec) unless defined $t;
		croak("Illegal datetime: $datetime") unless defined $t;
		return Date::Easy::Datetime->new( $zonespec, $t );
	}
	die("reached unreachable code");
}

sub now () { Date::Easy::Datetime->new }


sub _strptime
{
	require Date::Parse;
	# Most of this code is stolen from Date::Parse, by Graham Barr.  It is used here (see _str2time,
	# below), but its true raison d'etre is for use by Date::Easy::Date.
	#
	# In an ideal world, I would just use the code from Date::Parse and not repeat it here.
	# However, the problem is that str2time() calls strptime() to generate the pieces of a datetime,
	# then does some validation, then returns epoch seconds by calling timegm (from Time::Local) on
	# it.  For dates, I don't _want_ to call str2time because I'm just going to take the epoch
	# seconds and turn them back into pieces, so it's inefficicent.  But more importantly I _can't_
	# call str2time because it converts to UTC, and I want the pieces as they are relative to
	# whatever timezone the parsed date has.
	#
	# On the other hand, the problem with calling strptime directly is that str2time is doing two
	# things there: the conversion to epoch seconds, which I don't want or need for dates, and the
	# validation, which, it turns out, I *do* want, and need, even for dates.  For instance,
	# strptime will happily return a month of -1 if it hits a parsing hiccough.  Which then str2time
	# will turn into undef, as you would expect.  But, if you're just calling strptime, that doesn't
	# help you much. :-(
	#
	# Thus, for dates in particular, I'm left with 3 possibilities, none of them very palatable:
	# 	#	call strptime, then call str2time as well
	#	#	repeat at least some of the code from str2time here
	#	#	do Something Devious, like wrap/monkey-patch strptime
	# #1 doesn't seem practical, because it means that every string that has to be parsed this way
	# has to be parsed twice, meaning it will take twice as long.  #3 seems too complex--since the
	# call to strptime is out of my control, I can't add arguments to it, or get any extra data out
	# of it, which means I have to store things in global variables, which means it wouldn't be
	# reentrant ... it would be a big mess.  So #2, unpalatable as it is, is what we're going with.
	#
	# Of course, this gives me the opportunity to tweak a few things.  Primarily, we can tweak our
	# code to fix RT/105031 et al (see comments below, in _str2time).  There's a few minor
	# efficiency gains we can get from not doing things the older code seemed to think was
	# necessary.  (Of course, maybe it really is, in which case I'll have to put it all back.)
	#
	# The code in _strptime is as much of Date::Parse::str2time as is necessary to handle all the
	# validation and still return separate time values.  This way it can be used by both dates and
	# datetimes.

	my ($str, $zonespec) = @_;

	my ($sec, $min, $hour, $day, $month, $year, $zone)
			= Date::Parse::strptime($str, $zonespec eq 'local' ? () : $zonespec);
	my $num_defined = defined($day) + defined($month) + defined($year);
	return () if $num_defined == 0;
	if ($num_defined < 3)
	{
		my @lt  = localtime(time);

		$month = $lt[4] unless defined $month;
		$day  = $lt[3] unless defined $day;
		$year = ($month > $lt[4]) ? ($lt[5] - 1) : $lt[5] unless defined $year;
	}
	$hour ||= 0; $min ||= 0; $sec ||= 0;			# default time components to zero
	my $subsec = $sec - int($sec); $sec = int($sec);# extract any fractional part (e.g. milliseconds)
	$year += 1900 if $year < 1000;					# undo timelocal funkiness and adjust for RT/53413 / RT/105031

	return () unless $month >= 0 and $month <= 11 and $day >= 1 and $day <= 31
						and $hour <= 23 and $min <= 59 and $sec <= 59;

	return ($sec, $min, $hour, $day, $month, $year, $zone, $subsec);
}

sub _str2time
{
	require Date::Parse;
	# Most of this code is also stolen from Date::Parse, by Graham Barr.  This is the remainder of
	# Date::Parse::str2time, which takes the separate values (from _strptime, above) and turns them
	# into an epoch seconds value.  See also the big comment block below.

	my ($time, $zonespec) = @_;
	my ($sec, $min, $hour, $day, $month, $year, $zone, $subsec) = _strptime($time, $zonespec);
	# doesn't really matter which one we check (other than $zone); either they're all defined, or none are
	return undef unless defined $year;

	# This block is changed from the original in Date::Parse in the following ways:
	#	*	We're using timegm_modern/timelocal_modern instead of timegm/timelocal.  This fixes all
	#		sorts of gnarly issues, but most especially the heinous RT/53413 / RT/105031 bug.  (Side
	#		note: perhaps Parse::Date could use these as well?  If so, that would close that raft of
	#		bugs and then we wouldn't need to reimplement the guts of `str2time` at all.)
	#	*	The original code set the __DIE__ sig handler to ignore in the `eval`s.  But I'm not
	#		comfortable doing that, and I'm not convinced it's necessary.
	#	*	The original code did a little dance to make sure that a -1 return from timegm/timelocal
	#		was a valid return and not an indication of an error.  But I can't see any indication
	#		that they ever actually return -1 on error, either in the current Time::Local code, or
	#		in its Changes file (e.g. for older versions).  And, since our version of `strptime`
	#		specifically adds 1900 to the year (sometimes) to avoid Time::Local's horrible
	#		"two-digit year" handling, it makes coming up with a value to compare -1 against more of
	#		a PITA.  Plus it's inefficient for what appears to be no real gain.
	my $result;
	if (defined $zone)
	{
		$result = eval { timegm_modern($sec, $min, $hour, $day, $month, $year) };
		return undef unless defined $result;
		$result -= $zone;
	}
	else
	{
		$result = eval { timelocal_modern($sec, $min, $hour, $day, $month, $year) };
		return undef unless defined $result;
	}

	return $result + $subsec;
}

sub _parsedate
{
	require Time::ParseDate;
	my ($time, $zonespec) = @_;
	return scalar Time::ParseDate::parsedate($time, $zonespec eq 'local' ? () : (GMT => 1));
}


#######################
# REGULAR CLASS STUFF #
#######################

sub new
{
	my $class = shift;
	my $zonespec = @_ == 2 || @_ == 7 ? shift : $DEFAULT_ZONE;
	croak("Unrecognized timezone specifier") unless exists $ZONE_FLAG{$zonespec};

	my $t;
	if (@_ == 0)
	{
		$t = time;
	}
	elsif (@_ == 6)
	{
		my ($y, $m, $d, $H, $M, $S) = @_;
		--$m;										# timelocal/timegm will expect month as 0..11
		# but we'll use timelocal_modern/timegm_modern so we don't need to twiddle the year number
		$t = eval {		$zonespec eq 'local'
							? timelocal_modern($S, $M, $H, $d, $m, $y)
							:    timegm_modern($S, $M, $H, $d, $m, $y)
		};
		croak("Illegal datetime: $y/" . ($m + 1) . "/$d $H:$M:$S") unless defined $t;
	}
	elsif (@_ == 1)
	{
		$t = shift;
		if ( my $conv_class = blessed $t )
		{
			if ( $t->isa('Time::Piece') )
			{
				# it's already what we were going to construct anyway;
				# just stick it in a hashref and call it a day
				return bless { impl => $t }, $class;
			}
			else
			{
				croak("Don't know how to convert $conv_class to $class");
			}
		}
	}
	else
	{
		croak("Illegal number of arguments to datetime()");
	}

	bless { impl => scalar Time::Piece->_mktime($t, $ZONE_FLAG{$zonespec}) }, $class;
}


sub is_local {  shift->{impl}->[Time::Piece::c_islocal] }
sub is_gmt   { !shift->{impl}->[Time::Piece::c_islocal] }
*is_utc = \&is_gmt;


sub as
{
	my ($self, $conv_spec) = @_;

	if ( $conv_spec =~ /^(\W)(\w+)$/ )
	{
		my $fmt = join($1, map { "%$_" } split('', $2));
		return $self->strftime($fmt);
	}
	if ( $conv_spec eq 'Time::Piece' )
	{
		return $self->{impl};
	}
	else
	{
		croak("Don't know how to convert " . ref( $self) . " to $conv_spec");
	}
}


# ACCESSORS

sub year		{ shift->{impl}->year }
sub month		{ shift->{impl}->mon }
sub day			{ shift->{impl}->mday }
sub hour		{ shift->{impl}->hour }
sub minute		{ shift->{impl}->min }
sub second		{ shift->{impl}->sec }
sub epoch		{ shift->{impl}->epoch }
sub time_zone	{ shift->{impl}->strftime('%Z') }
sub day_of_week	{ shift->{impl}->day_of_week || 7 }						# change Sunday from 0 to 7
sub day_of_year	{ shift->{impl}->yday + 1 }								# change from 0-based to 1-based
sub quarter		{ int(shift->{impl}->_mon / 3) + 1 }					# calc quarter from (zero-based) month

sub split
{
	my $impl = shift->{impl};
	( $impl->year, $impl->mon, $impl->mday, $impl->hour, $impl->min, $impl->sec )
}


# FORMATTERS

sub strftime	{ shift->{impl}->strftime(@_) }
sub iso8601		{ shift->{impl}->datetime }
*iso = \&iso8601;


########################
# OVERLOADED OPERATORS #
########################

sub _op_convert
{
	my $operand = shift;
	return $operand unless blessed $operand;
	return $operand->{impl} if $operand->isa('Date::Easy::Datetime');
	return $operand if $operand->isa('Time::Piece');
	croak ("don't know how to handle conversion of " . ref $operand);
}

sub _result_convert
{
	my $func = shift;
	return ref($_[0])->new( scalar $func->(_op_convert($_[0]), _op_convert($_[1]), $_[2]) );
}

sub _add_seconds		{ _result_convert( \&Time::Piece::add      => @_ ) }
sub _subtract_seconds	{ _result_convert( \&Time::Piece::subtract => @_ ) }
# subclasses can override these to change what units an integer represents
sub _add_integer		{ $_[0]->add_seconds($_[1])      }
sub _subtract_integer	{ $_[0]->subtract_seconds($_[1]) }

sub _dispatch_add
{
	if ( blessed $_[1] && $_[1]->isa('Date::Easy::Units') )
	{
		$_[1]->_add_to($_[0]);
	}
	else
	{
		# this should DTRT for whichever class we are
		$_[0]->_add_integer($_[1]);
	}
}

sub _dispatch_subtract
{
	if ( blessed $_[1] && $_[1]->isa('Date::Easy::Units') )
	{
		# this shouldn't be possible ...
		die("should have called overloaded - for ::Units") if $_[2];
		# as the name implies, this method assumes reversed operands
		$_[1]->_subtract_from($_[0]);
	}
	elsif ( blessed $_[1] && $_[1]->isa('Date::Easy::Datetime') )
	{
		my ($lhs, $rhs) = $_[2] ? @_[1,0] : @_[0,1];
		my $divisor = $lhs->isa('Date::Easy::Date') && $rhs->isa('Date::Easy::Date') ? 86_400 : 1;
		($lhs->epoch - $rhs->epoch) / $divisor;
	}
	else
	{
		# this should DTRT for whichever class we are
		$_[0]->_subtract_integer($_[1]);
	}
}

use overload
	'""'	=>	sub { Time::Piece::cdate      (_op_convert($_[0])                           ) },
	'<=>'	=>	sub { Time::Piece::compare    (_op_convert($_[0]), _op_convert($_[1]), $_[2]) },
	'cmp'	=>	sub { Time::Piece::str_compare(_op_convert($_[0]), _op_convert($_[1]), $_[2]) },

	'+'		=>	\&_dispatch_add,
	'-'		=>	\&_dispatch_subtract,
;


# MATH METHODS

sub add_seconds			{ shift->_add_seconds      (@_) }
sub add_minutes			{ shift->_add_seconds      ($_[0] * 60)            }
sub add_hours			{ shift->_add_seconds      ($_[0] * 60 * 60)       }
sub add_days			{ shift->_add_seconds      ($_[0] * 60 * 60 * 24)  }
sub add_weeks			{ shift->add_days          ($_[0] * 7)             }
sub add_months			{ ref($_[0])->new( shift->{impl}->add_months(@_) ) }
sub add_years			{ ref($_[0])->new( shift->{impl}->add_years (@_) ) }

sub subtract_seconds	{ shift->_subtract_seconds (@_) }
sub subtract_minutes	{ shift->_subtract_seconds ($_[0] * 60)            }
sub subtract_hours		{ shift->_subtract_seconds ($_[0] * 60 * 60)       }
sub subtract_days		{ shift->_subtract_seconds ($_[0] * 60 * 60 * 24)  }
sub subtract_weeks		{ shift->subtract_days     ($_[0] * 7)             }
sub subtract_months		{ shift->add_months($_[0] * -1)                    }
sub subtract_years		{ shift->add_years ($_[0] * -1)                    }



1;



# ABSTRACT: easy datetime class
# COPYRIGHT

__END__

=pod

=head1 NAME

Date::Easy::Datetime - easy datetime class

=head1 VERSION

This document describes version 0.08 of Date::Easy::Datetime.

=head1 SYNOPSIS

    use Date::Easy::Datetime ':all';

    # default timezone is your local zone
    my $dt = datetime("3/31/2012 7:38am");

    # addition and subtraction work in increments of seconds
    my $this_time_yesterday = now - 60*60*24;
    my $after_30_minutes = now + 30 * 60;
    say "$dt was ", now - $dt, " seconds ago";
    # or can add or subtract months
    my $next_month = now->add_months(1);
    my $last_month = now->add_months(-1);

    # if you prefer UTC
    my $utc = datetime(UTC => "2016-03-07 01:22:16PST-0800");

    # or UTC for all your objects
    use Date::Easy::Datetime 'UTC';
    say datetime("Jan 1 2000 midnight")->time_zone;
    # prints "UTC"

    my $yr = $dt->year;
    my $mo = $dt->month;
    my $da = $dt->day;
    my $hr = $dt->hour;
    my $mi = $dt->minute;
    my $sc = $dt->second;
    my $ep = $dt->epoch;
    my $zo = $dt->time_zone;
    my $qr = $dt->quarter;
    my $dw = $dt->day_of_week;

    say $dt->strftime("%Y-%m-%dT%H:%M:%S%z");
    say $dt->iso8601;
    say $dt->as("/Ymd");

    my $tp = $dt->as('Time::Piece');

=head1 DESCRIPTION

A Date::Easy::Datetime object contains a L<Time::Piece> object and provides a slightly different UI
to access it.  In typical usage, you will either use the C<datetime> constructor to convert a
human-readable string to a datetime, or the C<now> function to return the current datetime (i.e. the
datetime object corresponding to C<time()>).  Both are exported with the C<:all> tag; nothing is
exported by default.

Arithmetic operators (plus and minus) either add or subtract seconds to or from the datetime object.
Accessor methods use the naming conventions of L<DateTime> (rather than those of Time::Piece).

Datetime objects are immutable.

See L<Date::Easy> for more general usage notes.

=head1 USAGE

=head2 Zone Specifiers

There are three zone specifiers that Date::Easy::Datetime understands:

=head3 local

'local' means to use the local timezone, however that is determined (often this is via the C<$TZ>
environment variable, but your system may differ).  That is, under 'local' Date::Easy::Datetime will
use C<localtime> and C<timelocal> (technically, C<timelocal_modern>, from L<Time::Local>) to deal
with epoch seconds.

=head3 UTC

'UTC' means to use the UTC timzeone, which essentialy means to ignore timezone altogether.  That is,
under 'UTC' Date::Easy::Datetime will use C<gmtime> and C<timegm> (technically, C<timegm_local>,
from L<Time::Local>) to deal with epcoh seconds.

=head3 GMT

As far as Date::Easy::Datetime is concerned, 'GMT' is always exactly equivalent to 'UTC'.  It's just
an alias for people who prefer that term.

=head2 Import Parameters

After the C<use Date::Easy::Datetime> statement, you can add parameters.  These can be one of three
things, in any order.

=head3 Function names

These are passed on to L<Exporter> to export only certain function names.  The only names currently
recognized are C<now> and C<datetime>.

=head3 Exporter tags

These are also passed on to L<Exporter>.  The only tag currently recognized is C<:all>, which means
to import all the names above.

=head3 Zone specifier

These change the default zone specifier for all datetime objects.  If you specify more than one, the
last one wins (but don't do that).  There is only one default zone specifier, so don't do this in a
module.

Possible values are listed under L</"Zone Specifiers">.  'local' is the default, so it's redundant
to pass that in, but you may just wish to be explicit.  As always, 'UTC' and 'GMT' are equivalent.

=head2 Constructors

=head3 Date::Easy::Datetime->new

Returns the same as L</now>.

=head3 Date::Easy::Datetime->new($e)

Takes the given epoch seconds and turns it into a datetime using the default zone specifier.

=head3 Date::Easy::Datetime->new($zone_spec => $e)

Takes the given epoch seconds and turns it into a datetime using the given zone specifier.

=head3 Date::Easy::Datetime->new($y, $m, $d, $hr, $mi, $sc)

Takes the given year, month, day, hours, minutes, and seconds, and turns them into a datetime
object, using the default zone specifier.  Month and day are human-centric (i.e., 1-based, not
0-based).  Year should be a 4-digit year; if you pass in a 2-digit year, you get a year bewteen 1900
and 1999, even if you use the last 2 digits of the current year.

=head3 Date::Easy::Datetime->new($zone_spec => $y, $m, $d, $hr, $mi, $sc)

Takes the given year, month, day, hours, minutes, and seconds, and turns them into a datetime
object, using the given zone specifier.  Month and day are human-centric (i.e., 1-based, not
0-based).  Year should be a 4-digit year; if you pass in a 2-digit year, you get a year bewteen 1900
and 1999, even if you use the last 2 digits of the current year.

=head3 Date::Easy::Datetime->new($obj)

If the sole argument to C<new> is a blessed object, attempts to convert that object to a datetime.
Currently the only type of object that can be successfully converted is a L<Time::Piece>.

=head3 now

Returns the current datetime (using the default zone specifier).

=head3 datetime($string)

=head3 datetime($zone_spec => $string)

Takes the human-readable string and converts it to a datetime using the given zone specifier, if
passed (or the default zone specifier if not), using the following heuristics:

=over 4

=item *

If the string consists of nothing but digits (including an optional leading negative sign), treats
it as a number of epoch seconds and passes it to C<new>.

=item *

Otherwise passes it to L<Date::Parse>'s C<str2time> function.  If the zone specifier is 'GMT' or
'UTC', this is passed to C<str2time> as its second argument.  If the result is defined, pass it as
epoch seconds to C<new>.

=item *

Otherwise if the result of calling C<str2time> is undefined, passes it to L<Time::ParseDate>'s
C<parsedate> function.  If the result is defined, passes the resulting epoch seconds to C<new>.

=item *

If C<parsedate> returns C<undef>, throws an "Illegal date" exception.

=back

This is designed to be a DWIMmy method which will most of the time just do what you meant so you
don't need to think about it.

=head2 Accessors

Names of accessors match the L<DateTime> class.  Ranges generally match what DateTime uses as well.

=head3 is_local

Returns true if the datetime is in the current timezone.

=head3 is_utc

Returns true if the datetime is in UTC.

=head3 is_gmt

Alias for C<is_utc>.

=head3 year

Returns the year (4-digit).

=head3 month

Returns the month as a number (1 - 12).

=head3 day

Returns the day as a number (1 - 31).

=head3 hour

Returns the hour (0 - 23).

=head3 minute

Returns the minute (0 - 59).

=head3 second

Returns the second (0 - 59).

=head3 epoch

Returns the datetime as a number of epoch seconds.

=head2 Other Methods

=head3 time_zone

Same as C<strftime('%Z')>.

=head3 day_of_week

Returns the day of the week from 1 (Monday) to 7 (Sunday).

=head3 day_of_year

Returns the day of the year from 1 (January 1st) to either 365 (December 31st) for a non-leap year,
or 366 for a leap year.

=head3 quarter

Returns the quarter of the year, based on the month (1 - 4).

=head3 strftime($fmt)

Calls L<Time::Piece>'s C<strftime>.  See those docs for full details.

=head3 iso8601

Calls L<Time::Piece>'s C<datetime>, which produces an ISO 8601 formatted datetime.

=head3 iso

Alias for L</iso8601>, in case you can never remember the exact digits (like me).

=head3 split

Returns a list consisting of the year, month, day, hours, minutes, and seconds, in that order, in
the same ranges as returned by the L</Accessors>.  Doesn't return anything useful in scalar context,
so don't do that.  Calling C<split> in scalar context may eventually be changed to throw a warning
or fatal error.

=head3 as($conv_spec)

Tries to convert the datetime according to the supplied conversion specification.  There are two
possible formats for the spec:

=over

=item *

If the spec consists of a non-letter followed by one or more letters (and nothing else), C<as> will
convert this to a time format to be passed to L</strftime>.  For instance, the spec "-Ymd" is
converted to "%Y-%m-%d", and ":HMS" is converted to "%H:%M:%S".  This allows conversion to a string
using much more compact formats, such as "/mdy" or even S<" abdYZ">.

=item *

Otherwise, the spec is expected to be a classname, and C<as> tries to convert the datetime to the
given class.  Currently, the only acceptable classname is L<Time::Piece>.  (Since a
Date::Easy::Datetime is stored internally as a Time::Piece object, this is a trivial lookup.)

=back

=head2 Overloaded Operators

=head3 Addition

You can add an integer value to a datetime object.  It adds that number of seconds and returns a new
datetime object.  The original datetime is not modified.

=head3 Subtraction

You can subtract an integer value from a datetime object.  It subtracts that number of seconds and
returns a new datetime object.  The original datetime is not modified.

You can subtract one datetime from another; the result is the number of seconds you would have to
add to the right-hand operand to get the left-hand operand (therefore, the result is positive when
the left-hand side is a later datetime, and negative when the left-hand side is earlier).  Currently
the result of attempting to subtract a date from a datetime is undefined.

=head2 Math Methods

=head3 add_seconds($num)

Same as adding C<$num> directly to the datetime.

=head3 add_minutes($num)

Same as adding C<$num * 60> directly to the datetime.

=head3 add_hours($num)

Same as adding C<$num * 60 * 60> directly to the datetime.

=head3 add_days($num)

Same as adding C<$num * 60 * 60 * 24> directly to the datetime.

=head3 add_weeks($num)

Same as calling C<add_days($num * 7)> on the datetime.

=head3 add_months($num)

Calls L<Time::Piece>'s C<add_months> to add a given number of months and return a new datetime
object.  The original datetime is not modified.  See the L<Time::Piece> docs for full details,
especially as regards what happens when you try to add months to dates at the ends of months.

=head3 add_years($num)

Calls L<Time::Piece>'s C<add_years> to add a given number of years and return a new datetime object.
The original datetime is not modified.  See the L<Time::Piece> docs for full details.  (Though the
Time::Piece documentation isn't clear on this point, adding a year to Feb 29th of a leap years acts
correspondingly to adding a month to Jan 29th of a non-leap year.)

=head3 subtract_seconds($num)

=head3 subtract_minutes($num)

=head3 subtract_hours($num)

=head3 subtract_days($num)

=head3 subtract_weeks($num)

=head3 subtract_months($num)

=head3 subtract_years($num)

The same as calling the equivalent C<add_> method, but with C<-$num>.

=head1 BUGS, CAVEATS and NOTES

If you try to pass a zone specifier to C<new> along with a Time::Piece object, it is ignored.  That
means that this code:

	use Time::Piece;
	use Date::Easy::Datetime;

	my $tp = localtime;
	my $dt = Date::Easy::Datetime->new(UTC => $tp);

is not going to do what you thought it would do.  (Although, honestly, I'm not sure what you thought
it was going to do.)

There is a bug in L<Time::ParseDate> which causes epoch seconds to be one hour off in certain
specific circumstances.  Please note that you will I<not> hit this bug if the string you pass to
L</datetime> has I<any> of the following characteristicts:

=over 4

=item *

If you use one of the UTC L</"Zone Specifiers">.

=item *

If your string never makes it to Time::ParseDate, either because it's a number of epoch seconds, or
because it's parseable by L<Date::Parse>.

=item *

If your string contains a time zone, in any format.

=item *

If your string is a relative time, such as "next week" or "+3 minutes".

=item *

If your local timezone doesn't use DST (e.g. Ecuador, Kenya, Nepal, Saudi Arabia, etc).

=item *

If the DST flag (i.e. the condition of either being on daylight savings or not) of the time in your string matches the current DST flag, in your local timezone.

=back

Hopefully this means hitting this bug will be rare.  An upstream bug L<has been
filed|https://github.com/muir/Time-modules/issues/8>.

If your local timezone contains leap seconds, you will likely get funky results with UTC datetimes,
such as this being true:

    $dt->second != $dt->strftime("%S")

in all cases except, of course, datetimes from before the first leap second was added (i.e. prior to
30-Jun-1972 23:59:60).  Weirdly, this isn't a problem with local datetimes.  An upstream bug L<has
been filed|https://github.com/rjbs/Time-Piece/issues/23>, although there is still some ongoing
discussion about whether this is a bug or not, and whether it's fixable even if it is.

If you pass a 2-digit year to `datetime`, it will always come back in the 20th century:

    say datetime("2/1/17"); # Thu Feb  1 00:00:00 1917

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
