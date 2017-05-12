# Copyright (c) 2005-2007 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: Business.pm,v 1.5 2007/06/18 06:11:56 martin Stab $

package Date::Gregorian::Business;

use strict;
use integer;
use Date::Gregorian;
use base qw(Date::Gregorian);
use vars qw($VERSION);

# ----- object definition -----

# ............. index ..............      # .......... value ..........
use constant F_OFFSET    => Date::Gregorian::NFIELDS;
use constant F_ALIGNMENT => F_OFFSET+0;  # 0 = morning, 1 = evening
use constant F_MAKE_CAL  => F_OFFSET+1;  # sub (date, year) => [calendar]
use constant F_YEAR      => F_OFFSET+2;  # currently initialized year
use constant F_CALENDAR  => F_OFFSET+3;  # list of: 1 = biz, 0 = holiday
use constant NFIELDS     => F_OFFSET+4;

# ----- predefined variables -----

$VERSION = 0.04;

# elements of default biz calendars
my $skip_weekend    = [ 0,  0,  0,  0,  0,  2,  1];  # Sat, Sun -> Mon
my $avoid_weekend   = [ 0,  0,  0,  0,  0, -1,  1];  # Sat -> Fri, Sun -> Mon
my $next_monday     = [ 0,  6,  5,  4,  3,  2,  1];  # set_weekday(Mon, ">=")
my $prev_monday     = [-7, -1, -2, -3, -4, -5, -6];  # set_weekday(Mon, "<")
my $next_wednesday  = [ 2,  1,  0,  6,  5,  4,  3];  # set_weekday(Wed, ">=")
my $next_thursday   = [ 3,  2,  1,  0,  6,  5,  4];  # set_weekday(Thu, ">=")
my $saturday_sunday = [ 5,  6];

# some biz calendars known by default
my %samples = (
    'us' => [
	$saturday_sunday,
	[
	    [ 1,  1, $skip_weekend],	# New Year's day
	    [ 1, 15, $next_monday],	# Martin Luther King
	    [ 2, 15, $next_monday],	# President's day
	    [ 6,  1, $prev_monday],	# Memorial day
	    [ 7,  4, $avoid_weekend],	# Independence day
	    [ 9,  1, $next_monday],	# Labor day
	    [10,  8, $next_monday],	# Columbus day
	    [11, 11, $avoid_weekend],	# Veteran's day
	    [11, 22, $next_thursday],	# Thanksgiving day
	    [12, 25, $skip_weekend],	# Christmas day
	],
    ],
    'de' => [
	$saturday_sunday,
	[
	    [ 1,  1],					# New Year's day
	    [ 0, -2],					# Good Friday
	    [ 0,  1],					# Easter Monday
	    [ 5,  1],					# Labour day
	    [ 0, 50],					# Pentecost Monday
	    [ 6, 17, undef,           [1954,  1989]],	# German Unity
	    [10,  3, undef,           [1990, undef]],	# German Unity
	    [11, 16, $next_wednesday, [undef, 1994]],	# Penitence day
	    [12, 25],					# Christmas day
	    [12, 26],					# 2nd day of Christmas
	],
    ],
);
$samples{'de_BW'} = [
    $saturday_sunday,
    [
	@{$samples{'de'}->[1]}, 
	[ 1,  6],					# Epiphany
	[ 0, 39],					# Ascension day
	[ 0, 60],					# Corpus Christi
	[11,  1],					# All Saints day
    ]
];
$samples{'de_BY'} = [
    $saturday_sunday,
    [
	@{$samples{'de_BW'}->[1]}, 
	[ 8, 15],					# Assumption day
    ]
];
$samples{'de_BW2'} = _more_xmas(@{$samples{'de_BW'}});
$samples{'de_BY2'} = _more_xmas(@{$samples{'de_BY'}});

my $default_configuration = 'us';

# ----- private functions and methods -----

# check whether a given year is in a range or general selection
sub _select_year {
    my ($self, $day, $year) = @_;
    my $selection = $day->[3];
    if (!ref $selection) {
	return $year == $selection;
    }
    if ('CODE' eq ref $selection) {
	return $selection->($self, $year, @{$day}[0, 1]);
    }
    return
	(!defined($selection->[0]) || $selection->[0] <= $year) &&
	(!defined($selection->[1]) || $year <= $selection->[1]);
}

# make_cal factory, generating a calendar generator enclosing a configuration
sub _make_make_cal {
    my ($weekly, $yearly) = @_;

    return sub {
	my ($date, $year) = @_;
	my $firstday = $date->new->set_yd($year, 1, 1);
	my $first_wd = $firstday->get_weekday;
	my $someday  = @$yearly && $firstday->new;
	my $easter   = undef;
	my $index;
	my $calendar = $firstday->get_empty_calendar($year, $weekly);
	foreach my $day (@$yearly) {
	    if (!defined($day->[3]) || _select_year($someday, $day, $year)) {
		if ($day->[0]) {
		    $index =
			$someday->set_ymd($year, @{$day}[0, 1])
			->get_days_since($firstday);
		    $index += $day->[2]->[$someday->get_weekday] if $day->[2];
		}
		else {
		    if (!defined $easter) {
			$easter =
			    $someday->set_easter($year)
			    ->get_days_since($firstday);
		    }
		    $index = $easter + $day->[1];
		    $index += $day->[2]->[(496 + $day->[1]) % 7] if $day->[2];
		}
		$calendar->[$index] = 0 if 0 <= $index && $index < @$calendar;
	    }
	}
	return $calendar;
    };
}

# experimental feature: half business days on Dec 24 and 31, if not weekend
sub _more_xmas {
    my $make_cal = _make_make_cal(@_);
    return sub {
	my $calendar = $make_cal->(@_);
	if (8 <= @$calendar && $calendar->[-1]) {
	    @{$calendar}[-8, -1] = (0.5, 0.5);
	}
	return $calendar;
    }
}

# fetch biz calendar for given year, initializing it if necessary
sub _calendar {
    my ($self, $year) = @_;

    if (!defined($self->[F_YEAR]) || $year != $self->[F_YEAR]) {
	$self->[F_YEAR] = $year;
	$self->[F_CALENDAR] = $self->[F_MAKE_CAL]->($self, $year);
    }
    return $self->[F_CALENDAR];
}

# ----- public methods -----

sub get_empty_calendar {
    my ($date, $year, $weekly_nonbiz) = @_;

    my $firstday = $date->new->set_yd($year, 1);
    my $days     = $firstday->get_days_in_year($year);
    my $first_wd = $firstday->get_weekday;

    my @week = (1) x 7;
    foreach my $day (@$weekly_nonbiz) {
	$week[$day] = 0;
    }
    @week = @week[$first_wd .. 6, 0 .. $first_wd-1] if $first_wd;

    my @calendar = ((@week) x ($days / 7), @week[0 .. ($days % 7)-1]);
    return \@calendar;
}

sub define_configuration {
    my ($class, $name, $configuration) = @_;
    my $type = defined($configuration)? ref($configuration): '!';

    if (!$type) {
	return undef if !exists $samples{$configuration};
	$configuration = $samples{$configuration};
    }
    elsif ('ARRAY' ne $type && 'CODE' ne $type) {
	return undef;
    }
    $samples{$name} = $configuration;
    return $class;
}

sub configure_business {
    my ($self, $configuration) = @_;
    my $type = defined($configuration)? ref($configuration): '!';

    if (!$type) {
	return undef if !exists $samples{$configuration};
	$configuration = $samples{$configuration};
	$type = ref $configuration;
    }
    if (ref $self) {
	# instance method: configure this object
	if ('CODE' eq $type) {
	    $self->[F_MAKE_CAL] = $configuration;
	}
	elsif ('ARRAY' eq $type) {
	    $self->[F_MAKE_CAL] = _make_make_cal(@$configuration);
	}
	else {
	    return undef;
	}
	$self->[F_YEAR] = $self->[F_CALENDAR] = undef;
    }
    else {
	# class method: configure default
	if ('ARRAY' ne $type && 'CODE' ne $type) {
	    return undef;
	}
	$default_configuration = $configuration;
    }

    return $self;
}

sub new {
    my ($class_or_object, $configuration) = @_;
    my $self = $class_or_object->SUPER::new;

    if (!ref $class_or_object) {
	$self->[F_ALIGNMENT] = 0;
    }
    if (defined $configuration) {
	return $self->configure_business($configuration);
    }
    elsif (!ref $class_or_object) {
	return $self->configure_business($default_configuration);
    }
    return $self;
}

sub align {
    my ($self, $alignment) = @_;
    $self->[F_ALIGNMENT] = $alignment? 1: 0;
    return $self;
}

sub get_alignment {
    my $self = $_[0];
    return $self->[F_ALIGNMENT];
}

# tweak super class to provide default alignment
sub Date::Gregorian::get_alignment {
    return 0;
}

sub is_businessday {
    my ($self) = @_;
    my ($year, $day) = $self->get_yd;

    return $self->_calendar($year)->[$day-1];
}

# count business days, proceeding into the future
# $days gives the interval measured in real days (positive)
# alignment tells where to start: 0 = at current day, 1 = the day after
# 0 <= result <= $days
sub _count_businessdays_up {
    my ($self, $days) = @_;
    my ($year, $day) = $self->get_yd;
    my $calendar = $self->_calendar($year);
    my $result = 0;

    --$day if !$self->[F_ALIGNMENT];
    while (0 < $days) {
	while (@$calendar <= $day) {
	    $calendar = $self->_calendar(++$year);
	    $day = 0;
	}
	do {
	    no integer;
	    $result += $calendar->[$day];
	};
	++$day;
	--$days;
    }
    return $result;
}

# count business days, proceeding into the past
# $days gives the interval measured in real days (positive)
# alignment tells where to start: 1 = at current day, 0 = the day before
# 0 <= result <= $days
sub _count_businessdays_down {
    my ($self, $days) = @_;
    my ($year, $day) = $self->get_yd;
    my $calendar = $self->_calendar($year);
    my $result = 0;

    --$day if !$self->[F_ALIGNMENT];
    while (0 < $days) {
	--$day;
	--$days;
	while ($day < 0) {
	    $calendar = $self->_calendar(--$year);
	    $day = $#$calendar;
	}
	do {
	    no integer;
	    $result += $calendar->[$day];
	};
    }
    return $result;
}

#   Alignments and results             Now:0   Now:1   Now:0   Now:1
#   b--(H)--b---b---b--(H)--b---b      Then:0  Then:1  Then:1  Then:0
#      Then            Now              3       3       3       3
#          Then        Now              3       2       2       3
#      Then                Now          3       4       3       4
#          Then            Now          3       3       2       4
#   b--(H)--b---b---b--(H)--b---b
#      Now             Then            -3      -3      -3      -3
#      Now                 Then        -3      -4      -4      -3
#          Now         Then            -3      -2      -3      -2
#          Now             Then        -3      -3      -4      -2
#   b--(H)--b---b---b--(H)--b---b

sub get_businessdays_since {
    my ($self, $then) = @_;
    my $delta =
	$self->get_days_since($then) +
	$self->[F_ALIGNMENT] - $then->get_alignment;
    if ($delta > 0) {
	return $self->_count_businessdays_down($delta);
    }
    if ($delta < 0) {
	return -$self->_count_businessdays_up(-$delta);
    }
    return 0;
}

sub get_businessdays_until {
    my ($self, $then) = @_;
    my $delta =
	$self->get_days_since($then) +
	$self->[F_ALIGNMENT] - $then->get_alignment;
    if ($delta > 0) {
	return -$self->_count_businessdays_down($delta);
    }
    if ($delta < 0) {
	return $self->_count_businessdays_up(-$delta);
    }
    return 0;
}

sub set_next_businessday {
    my ($self, $relation) = @_;
    my ($year, $day) = $self->get_yd;
    my $calendar = $self->_calendar($year);

    --$day;
    return $self if '<' ne $relation && '>' ne $relation && $calendar->[$day];
    if ('<' eq $relation || '<=' eq $relation) {
	do {
	    --$day;
	    while ($day < 0) {
		$calendar = $self->_calendar(--$year);
		$day = $#$calendar;
	    }
	}
	while (!$calendar->[$day]);
    }
    else {
	do {
	    ++$day;
	    while (@$calendar <= $day) {
		$calendar = $self->_calendar(++$year);
		$day = 0;
	    }
	}
	while (!$calendar->[$day]);
    }
    return $self->set_yd($year, $day+1);
}

sub iterate_businessdays_upto {
    my ($self, $limit, $rel) = @_;
    my $days = ($rel eq '<=') - $self->get_days_since($limit);
    my ($year, $day, $calendar);
    if (0 < $days) {
	($year, $day) = $self->get_yd;
	--$day;
	$calendar = $self->_calendar($year);
    }
    return sub {
	while (0 < $days) {
	    while (@$calendar <= $day) {
		$calendar = $self->_calendar(++$year);
		$day = 0;
	    }
	    --$days;
	    if ($calendar->[$day++]) {
		return $self->set_yd($year, $day);
	    }
	}
	return undef;
    };
}

sub iterate_businessdays_downto {
    my ($self, $limit, $rel) = @_;
    my $days = $self->get_days_since($limit) + ($rel ne '>');
    my ($year, $day, $calendar);
    if (0 < $days) {
	($year, $day) = $self->get_yd;
	--$day;
	$calendar = $self->_calendar($year);
    }
    return sub {
	while (0 < $days) {
	    while ($day < 0) {
		$calendar = $self->_calendar(--$year);
		$day = $#$calendar;
	    }
	    --$days;
	    if ($calendar->[$day--]) {
		return $self->set_yd($year, $day+2);
	    }
	}
	return undef;
    };
}

#   -b----H----b----b----H----b-
#     ^  ^ ^  ^               
#     0       0 1  1 2       2

sub add_businessdays {
    no integer;
    my ($self, $days, $new_alignment) = @_;
    my ($year, $day) = $self->get_yd;
    -- $day;
    my $calendar = $self->_calendar($year);
    my $alignment = $self->[F_ALIGNMENT];

    # handle alignment change
    if (defined($new_alignment) && ($alignment xor $new_alignment)) {
	if ($new_alignment) {
	    $alignment = $self->[F_ALIGNMENT] = 1;
	    $days -= $calendar->[$day];
	}
	else {
	    $alignment = $self->[F_ALIGNMENT] = 0;
	    $days += $calendar->[$day];
	}
    }

    if (0 < $days || !$days && !$alignment) {
	# move forward in time
	$days -= $calendar->[$day] if !$alignment;
	while (0 < $days || !$days && !$alignment) {
	    ++$day;
	    while (@$calendar <= $day) {
		$calendar = $self->_calendar(++$year);
		$day = 0;
	    }
	    $days -= $calendar->[$day];
	}
    }
    else {
	# move backwards in time
	$days += $calendar->[$day] if $alignment;
	while ($days < 0 || !$days && $alignment) {
	    --$day;
	    while ($day < 0) {
		$calendar = $self->_calendar(--$year);
		$day = $#$calendar;
	    }
	    $days += $calendar->[$day];
	}
    }

    return $self->set_yd($year, $day+1);
}

1;

__END__

=head1 NAME

Date::Gregorian::Business - business days extension for Date::Gregorian

=head1 SYNOPSIS

  use Date::Gregorian::Business;
  use Date::Gregorian qw(:weekdays);

  $date = Date::Gregorian::Business->new('us');

  if ($date->set_today->is_businessday) {
    print "Busy today.\n";
  }
  
  $date2 = $date->new->set_ymd(2005, 3, 14);

  $date2->align(0);                          # morning
  $date->align(1);                           # evening

  $delta = $date->get_businessdays_since($date2);
  $delta = -$date->get_businessdays_until($date2);

  $date->set_next_businessday('>=');
  $date->add_businessdays(25);
  $date->add_businessdays(-10, 0);
  $date->add_businessdays(-10, 1);

  $iterator = $date->iterate_businessdays_upto($date2, '<');
  $iterator = $date->iterate_businessdays_upto($date2, '<=');
  $iterator = $date->iterate_businessdays_downto($date2, '>');
  $iterator = $date->iterate_businessdays_downto($date2, '>=');
  while ($iterator->()) {
    printf "%d-%02d-%02d\n", $date->get_ymd;
  }

  $alignment = $date->get_alignment;

  # ----- configuration -----

  @my_holidays = (
      [6],                                   # Sundays
      [
	[11, 22, [3, 2, 1, 0, 6, 5, 4]],     # Thanksgiving
	[12, 25],                            # December 25
	[12, 26, undef, [2005, 2010]],       # December 26 in 2005-2010
	[12, 27, undef, sub { $_[1] & 1 }],  # December 27 in odd years
      ]
  );

  sub my_make_calendar {
    my ($date, $year) = @_;
    my $calendar = $date->get_empty_calendar($year, [SATURDAY, SUNDAY]);
    my $firstday = $date->new->set_yd($year, 1);

    # ... calculate holidays of given year, for example ...
    my $holiday = $date->new->set_ymd($year, 7, 4);
    my $index = $holiday->get_days_since($firstday);
    # Sunday -> next Monday, Saturday -> previous Friday
    if (!$calendar->[$index] && !$calendar->[++$index]) {
	$index -= 2;
    }
    $calendar->[$index] = 0;
    # ... and so on for all holidays of year $year.

    return $calendar;
  }

  Date::Gregorian::Business->define_configuration(
    'Acme Ltd.' => \@my_holidays
  );

  Date::Gregorian::Business->define_configuration(
    'Acme Ltd.' => \&my_make_calendar
  );

  # set default configuration and create object with defaults
  Date::Gregorian::Business->configure_business('Acme Ltd.') or die;
  $date = Date::Gregorian::Business->new;

  # create object with explicitly specified configuration
  $date = Date::Gregorian::Business->new('Acme Ltd.') or die;

  # create object and change configuration later
  $date = Date::Gregorian::Business->new;
  $date->configure_business('Acme Ltd.') or die;
  $date->configure_business(\@my_holidays) or die;
  $date->configure_business(\&my_make_calendar) or die;

  # some pre-defined configurations
  $date->configure_business('us');           # US banking
  $date->configure_business('de');           # German nation-wide

=head1 DESCRIPTION

I<Date::Gregorian::Business> is an extension of Date::Gregorian supporting
date calculations involving business days.

Objects of this class have a notion of whether or not a day is a
business day and provide methods to count business days between two
dates or find the other end of a date interval, given a start or
end date and a number of business days in between.  Other methods
allow to define business calendars for use with this module.

By default, a date interval includes the earlier date and does not
include the later date of its two end points, no matter in what order
they are given.  We call this "morning alignment".  However, individual
date objects can be either "morning" or "evening" aligned, meaning they
represent the situation at the beginning or end of the day in question.
Where a date object is the result of a calculation, its alignment can
be chosen through an optional method argument.

=head2 User methods

=over 4

=item new

I<new>, called as a class method, creates and returns a new date
object.  The optional parameter can be a configuration or (more
typically) the name of a configuration.  If omitted, the current
default configuration is used.  Business calendar configurations
are described in detail in an extra section below.  In case of bad
configurations B<undef> is returned.

I<new>, called as an object method, returns a clone of the object.
A different configuration for the new object can be specified.
Again, in case of bad configurations B<undef> is returned.

=item is_businessday

I<is_businessday> returns a nonzero number (typically 1) if the
date currently represented by the object is a business day, or zero
if it falls on a weekend or holiday.  Special business calendars
may have business days counting less than a whole day in calculations.
Objects configured that way may return 0.5 or even another numeric
value between 0 and 1 for some dates.  In any case I<is_businessday>
can be used in boolean context.

=item align

I<align> sets the alignment of a date.  An alignment of 0 means
morning alignment, 1 means evening alignment.  With morning alignment,
the current day is counted in durations extending into the future,
and not counted in durations extending from that date into the past.
Mnemonic is, in the morning, a day's business lies ahead, whereas
in the evening, it lies behind.  Night workers please pardon the
simplification.

=item get_businessdays_since get_businessdays_until

There are two methods to count the number of business days between
two dates.  Their only difference is the sign of the result:
I<get_businessdays_since> is positive if the parameter refers to
an earlier date than the object and business days lie between them,
zero if no business days are counted, and negative otherwise.  Note
the role of alignments described in the previous paragraph.
I<get_businessdays_until> is positive when I<get_businessdays_since>
is negative and vice versa.  The parameter may be an arbitrary
Date::Gregorian object.  If it is not a Date::Gregorian::Business
object its alignment is taken to be the default (morning).

=item set_next_businessday

I<set_next_businessday> moves an arbitrary date up or down to the
next business day.  Its parameter must be one of the four relation
operators ">=", ">", "<=" or "<" as a string.  ">=" means, the date
should not be changed if it is a business day, or changed to the
closest business day in the future otherwise.  ">" means the date
should be changed to the closest business day truly later than the
current date.  "<=" and "<" likewise work in the other direction.
Alignment does not matter and is not changed.

=item add_businessdays

I<add_businessdays> moves an arbitrary date forward or backwards
in time up to a given number of business days.  A positive number
of days means moving towards the future.  The result is always a
business day.  The alignment will not be changed if the second
parameter is omitted, or else set to the second parameter.  The
result will be rounded to the beginning or end of a business day
if necessary, as determined by its alignment.

Rounding: If you work with simple calendars and integer numbers,
all results will be precise.  However, with calendars containing
fractions of business days or with non-integer values of day
differences, a calculated date may end up somewhere in the middle
of a business day rather than at its beginning or end.  The final
result will stay at that date but move up or down to the desired
alignment.  In other words, fractional days will be rounded down
to morning alignment or up to evening alignment, whichever applies.

No ambiguities: Even if a calculated date lies next to a number of
non-business days in a way that more than one date would satisfy a
desired span of business days, results are always well-defined by
the fact that they must be business days.  Thus, morning alignment
will pull a result to the first business day after weekends and
holidays, while evening alignment will pull a result to the last
business day before any non-business days.  If you add zero business
days to some arbitrary date you get the unique date of the properly
aligned business day next to it.

=item iterate_businessdays_upto iterate_businessdays_downto

I<iterate_businessdays_upto> and I<iterate_businessdays_downto>
provide iterators over a range of business days.  They return a
reference to a subroutine that can be called without argument in a
while condition to set the given date iteratively to each one of a
sequence of dates, while skipping non-business days.  The business
day closest to the current date is always the first one to be
visited (unless the sequence is all empty).  The limit parameter
determines the end of the sequence, together with the relation
parameter:  '<' excludes the upper limit from the sequence, '<='
includes the upper limit, '>=' includes the lower limit and '>'
excludes the lower limit.

Each iterator maintains its own state; therefore it is legal to run
more than one iterator in parallel or even create new iterators
within iterations.  Undefining an iterator after use might help to
save memory.

=item get_alignment

I<get_alignment> retrieves the alignment (either 0 for morning or
1 for evening).

=back

=head2 Configuration

Version compatibility note: The configuration specifications described
here are expected to evolve with further development of this module.
In fact, they should ultimately be replaced by easier-to-use
configuration objects.  We will try to stay downward compatible for
some time, however.

The business calendar to use can be customized both on an
object-by-object basis and by way of general defaults.  Business
calendars can be stored under a name and later referenced by that
name.

A business calendar can be defined through a list of holiday
definitions or more generally through a code reference, as explained
below.  A number of such definitions of common interest will be
accessible in later editions of this module or some related component.

=over 4

=item define_configuration

I<define_configuration> names and defines a configuration.  It can
later be referenced by its name.  By convention, user-defined names
should start with an uppercase letter, while configuration names
provided as a part of the distribution will always start with a
lowercase letter.

=item configure_business

I<configure_business>, used as an object method, re-configures that
object.  It returns the object on success, B<undef> in case of a
bad configuration.

I<configure_business>, used as a class method, defines the default
configuration for new objects created with neither a configuration
parameter nor a reference object.  It returns the class name on
success, B<undef> in case of a bad configuration.

The configuration parameter for I<define_configuration>, I<new> and
I<configure_business> can be the name of a known configuration, an
array reference or a code reference.  A configuration name must be
known at the time it is used, for it is always immediately replaced
by the named configuration.

An array reference used as a configuration has to refer to a
two-element array like this:

  $configuration = [\@weekend_days, \@holidays];

Here, C<@weekend_days> is a list of the non-business days of every
week, given as numerical values as defined in I<Date::Gregorian>.
For example:

  use Date::Gregorian qw(:weekdays);
  @weekend_days = (SATURDAY, SUNDAY);

The list of weekend days may be empty, but must not contain all
seven days of the week, which would imply that the whole week has
no business days and thus be the reason for endless loops.

The second element of a configuration is a list of holiday definitions.
Each one of these defines a yearly recurring event like this:

  $holiday = [$month, $day, $weekday_shift, $valid_years];

Here, C<$month> and C<$day> with month ranging from 1 to 12 define
an anniversary by date.  Alternatively, month may be zero and day
a signed integer value defining a date relative to Easter Sunday.
For example, C<[0, -2]> would refer to Good Friday (two days before
Easter Sunday) while C<[0, 1]> would refer to Easter Monday.  The
distance from Easter Sunday must be in the range of (roughly)
C<-80..250> to make sure the actual date is a day of the same year.
Easter-related holidays ending up in different years are silently
ignored.

If C<$weekday_shift> is omitted or undefined, a holiday occurs on
a fixed month and day (or distance from easter), no matter what day
of the week it falls on.  In order to shift it dependent on the
weekday, C<$weekday_shift> must be a reference of a seven-element
array of days to add, ordered from Monday to Sunday.  Examples:

  [0, 0, 0, 0, 0, 2, 1] # Saturday and Sunday -> next Monday

  [0, 6, 5, 4, 3, 2, 1] # any day other than Monday -> next Monday

  [3, 2, 1, 0, 6, 5, 4] # any non-Thursday -> next Thursday

The last two examples above show how holidays can be defined that
always fall on the same day of the week.  To continue the example,
Thanksgiving Day could be defined like this:

  $thanksgiving = [11, 22, [3, 2, 1, 0, 6, 5, 4]];

The fourth element of a holiday definition is also optional and
limits the years the definition is valid for.  It may be either:

=over 4

=item *

a plain number, defining the single year the definition is valid,

=item *

a reference of a two-element array, defining the first and
the last year of a range of years, where B<undef> means
no limit,

=item *

a reference of a subroutine taking a date object and a year, month
and day, returning a boolean for whether the holiday is valid in
that year.  Month and day are taken directly from the holiday
definition (even where the month value is zero for dates relative
to easter).  The date object is a clone of the original object
(though not initialized to a particular date), just for safety.
It may be changed while the original object should not be.

=back

A more general way to specify a complete configuration is a code
reference.  It must refer to a subroutine that takes a date object
and a year (which you can also view as a method with a year parameter)
and returns an array reference.  The array must have exactly that
many elements as there are days in the given year.  Each element
must be defined and have a numerical value greater or equal to zero.
These values will be returned by I<is_businessday> and added together
in calculations.  The idea is that one call to the subroutine figures
out the calendar of a whole year in one go.

=item get_empty_calendar

I<get_empty_calendar> is a helper method mainly intended for use
in such a subroutine.  It takes two mandatory parameters, a year
and a reference to an array like C<@weekend_days> above, and returns
a reference of an array of zeroes and ones representing the weekends
and weekly business days of that year suitable to be further modified
and finally returned by said subroutine.

=back

=head1 AUTHOR

Martin Becker <hasch-cpan-dg@cozap.com>, May 2005.

=head1 SEE ALSO

L<Date::Gregorian>.

=cut

