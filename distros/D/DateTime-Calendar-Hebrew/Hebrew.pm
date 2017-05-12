package DateTime::Calendar::Hebrew;
use DateTime;
use Params::Validate qw/validate SCALAR OBJECT CODEREF/;

use vars qw($VERSION);
$VERSION = '0.05';
use 5.010_000;

use strict;
no strict 'refs';

use constant HEBREW_EPOCH => -1373429;

use overload
	fallback => 1,
	'<=>' => '_compare_overload',
	'cmp' => '_compare_overload',
	'+'   => '_add_overload',
	'-'   => '_subtract_overload';

sub new {
    my $class = shift;
    my %p = validate( @_,
                      { year       => { type => SCALAR },
                        month      => { type => SCALAR, default => 1,
									    callbacks => {
											'is between 1 and 13' =>
											sub { $_[0] >= 1 && $_[0] <= 13 }
									    }
									  },
                        day        => { type => SCALAR, default => 1,
									    callbacks => {
											'is between 1 and 30' =>
											sub { $_[0] >= 1 && $_[0] <= 30 }
									    }
									  },
						hour       => { type => SCALAR, default => 0,
									    callbacks => {
											'is between 0 and 23' =>
											sub { $_[0] >= 0 && $_[0] <= 23 }
									    }
									  },
						minute     => { type => SCALAR, default => 0,
									    callbacks => {
											'is between 0 and 59' =>
											sub { $_[0] >= 0 && $_[0] <= 59 }
									    }
									  },
						second     => { type => SCALAR, default => 0,
									    callbacks => {
											'is between 0 and 59' =>
											sub { $_[0] >= 0 && $_[0] <= 59 }
									    }
									  },
						nanosecond =>	{ type => SCALAR, default => 0,
									    callbacks => {
											'is between 0 and 999999999' =>
											sub { $_[0] >= 0 && $_[0] <= 999999999 }
									    }
									  },
						sunset     =>	{ type => OBJECT, optional => 1 },
						time_zone  =>	{ type => SCALAR, optional => 1 },
                      } );

    my $self = bless \%p, $class;

	$self->{rd_days} = &_to_rd(@p{ qw(year month day) });
	$self->{rd_secs} = $p{hour} * 60 * 60 + $p{minute} * 60 + $p{second};
	if($self->{nanosecond}) { $self->{rd_nanosecs} = delete $self->{nanosecond}; }

	if($self->{sunset} and $self->{time_zone}) {
		my $DT_Event_Sunrise = $self->{sunset};
		my $time_zone = $self->{time_zone};
		my $DT = DateTime->from_object(object => $self);

		my $sunset = $DT_Event_Sunrise->next($DT->clone->truncate(to => 'day'));
		$sunset->set_time_zone($time_zone);

		if($DT > $sunset) {
			$self->{after_sunset} = 1;
			@{$self}{qw/year month day/} = &_from_rd($self->{rd_days} + 1);
		}
	}

    return $self;
}

sub from_object {
    my ( $class ) = shift;
    my %p = validate( @_, {
            object => {
                type => OBJECT,
                can => 'utc_rd_values',
            },
	});

    my $object = $p{object}->clone();
    $object->set_time_zone('floating') if $object->can( 'set_time_zone' );

    my ($rd_days, $rd_secs, $rd_nanosecs) = $object->utc_rd_values();
	$rd_nanosecs ||= 0;

	my %args;
	@args{ qw( year month day ) } = &_from_rd($rd_days);

    my($h, $m, $s);
    $s = $rd_secs % 60;
    $m = int($rd_secs / 60);
    $h = int($m / 60);
    $m %= 60;
	@args{ qw(hour minute second) } = ($h, $m, $s);

	$args{nanosecond} = $rd_nanosecs || 0;

	my $new_object = $class->new(%args);

	return $new_object;
}

sub set {
    my $self = shift;
    my %p = validate( @_,
                      { year     => { type => SCALAR, optional => 1 },
                        month    => { type => SCALAR, optional => 1,
									  callbacks => {
										'is between 1 and 13' =>
										sub { $_[0] >= 1 && $_[0] <= 13 }
									  }
									},
                        day      => { type => SCALAR, optional => 1,
									  callbacks => {
										'is between 1 and 30' =>
										sub { $_[0] >= 1 && $_[0] <= 30 }
									  }
									},
						hour     => { type => SCALAR, optional => 1,
									  callbacks => {
										'is between 0 and 23' =>
										sub { $_[0] >= 0 && $_[0] <= 23 }
									  }
									},
						minute   => { type => SCALAR, optional => 1,
									  callbacks => {
										'is between 0 and 59' =>
										sub { $_[0] >= 0 && $_[0] <= 59 }
									  }
									},
						second   => { type => SCALAR, optional => 1,
									  callbacks => {
										'is between 0 and 59' =>
										sub { $_[0] >= 0 && $_[0] <= 59 }
									  }
									},
						nanosecond =>	{ type => SCALAR, optional => 1,
									      callbacks => {
											'is between 0 and 999999999' =>
											sub { $_[0] >= 0 && $_[0] <= 999999999 }
										}
									},
						sunset =>		{ type => OBJECT, optional => 1 },
						time_zone =>	{ type => SCALAR, optional => 1 },
                      } );

    $self->{$_} = $p{$_} for keys %p;

	$self->{rd_days} = &_to_rd($self->{year}, $self->{month}, $self->{day});
    $self->{rd_secs} = $self->{hour} * 60 * 60 + $self->{minute} * 60 + $self->{second};
	if($self->{nanosecond}) { $self->{rd_nanosecs} = delete $self->{nanosecond}; }

	if($self->{sunset} and $self->{time_zone}) {
		my $DT_Event_Sunrise = $self->{sunset};
		my $time_zone = $self->{time_zone};
		my $DT = DateTime->from_object(object => $self);

		my $sunset = $DT_Event_Sunrise->next($DT->clone->truncate(to => 'day'));
		$sunset->set_time_zone($time_zone);

		if($DT > $sunset) {
			$self->{after_sunset} = 1;
			@{$self}{qw/year month day/} = &_from_rd($self->{rd_days} + 1);
		}
	}

    return $self;
}

sub utc_rd_values {
	my $self = shift;
	my @res = @{$self}{ qw/rd_days rd_secs rd_nanosecs/ };
	# Protect against undef
	$res[2] ||= 0;
	return @res;
}

sub utc_rd_as_seconds {
    my $self = shift;
    my ($rd_days, $rd_secs, $rd_nanosecs) = $self->utc_rd_values;

	return $rd_days*24*60*60 + $rd_secs;
}

sub clone {
    my $self = shift;
	my $clone = {%$self};
    bless $clone, ref $self;
	return $clone;
}

sub _compare_overload {
    return $_[2] ? - $_[0]->_compare($_[1]) : $_[0]->_compare($_[1]);
}

sub _compare {
	my($a, $b) = @_;

	return undef unless defined $b;

	unless($a->can('utc_rd_values') and $b->can('utc_rd_values')) {
		die "Cannot compare a datetime to a regular scalar";
	}

    my @a = $a->utc_rd_values;
    my @b = $b->utc_rd_values;

    foreach my $i (0..2) {
		return ($a[$i] <=> $b[$i]) if($a[$i] != $b[$i]);
    }

    return 0;
}

sub _add_overload {
    my($dt, $dur, $reversed) = @_;
    ($dur,$dt) = ($dt,$dur) if $reversed;
	return $dt->clone->add_duration($dur);
}

sub _subtract_overload {
    my($dt, $dur, $reversed) = @_;
    ($dur,$dt) = ($dt,$dur) if $reversed;
	return $dt->clone->subtract_duration($dur);
}

sub add_duration {
    my ($self, $dur) = @_;
	my %deltas = $dur->deltas;

	if($deltas{days})    { $self->{rd_days} += $deltas{days}; }
    if($deltas{hours})   { $self->{rd_secs} += $deltas{hours} * 60 * 60; }
    if($deltas{minutes}) { $self->{rd_secs} += $deltas{minutes} * 60; }
    if($deltas{seconds}) { $self->{rd_secs} += $deltas{seconds}; }
    if($deltas{nanoseconds}) { $self->{rd_nanosecs} += $deltas{nanoseconds}; }

	while($self->{rd_secs} < 0) {
		$self->{rd_days}--;
		$self->{rd_secs} += (24 * 60 * 60);
	}

    return $self->_normalize;
}

sub subtract_duration {
	my ($self, $dur) = @_;
	return $self->add_duration($dur->inverse);
}

sub _normalize {
	my($self) = shift; 

	my($h, $m, $s, $d);
	$s = $self->{rd_secs} % 60;
	$m = int($self->{rd_secs} / 60);
	$h = int($m / 60);
	$m %= 60;
	$d = int($h / 24);
	$h %= 24;

	$self->{rd_days} += $d;
	$self->{rd_secs} = ($h * 60 * 60) + ($m * 60) + $s;

	@{$self}{qw/year month day/} = &_from_rd($self->{rd_days});
	@{$self}{qw/hour minute second/} = ($h, $m, $s);
	
	return $self;
}

sub now {
    my $class = shift;
    $class = ref($class) || $class;

    my $dt = DateTime->now;
    my $ht = $class->from_object(object => $dt);
    return($ht);
}

sub today {
    my $class = shift;
    $class = ref($class) || $class;

    my $dt = DateTime->today;
    my $ht = $class->from_object(object => $dt);
    return($ht);
}

sub _from_rd {
    my $rd = shift;

    my ($year, $month, $day);
    $year = int(($rd - HEBREW_EPOCH) / 366);
    while ($rd >= &_to_rd($year + 1, 7, 1)) { $year++; }
    if ($rd < &_to_rd($year, 1, 1)) { $month = 7; }
    else { $month = 1; }
    while ($rd > &_to_rd($year, $month, (&_LastDayOfMonth($year, $month)))) { $month++; }
    $day = $rd - &_to_rd($year, $month, 1) + 1;

	return $year, $month, $day;
}

sub _to_rd {
    my ($year, $month, $day) = @_;
	if(scalar @_) { 
		($year, $month, $day) = @_;
	}

    my($m, $DayInYear);

    $DayInYear = $day;
    if ($month < 7) {
		$m = 7;
		while ($m <= (&_LastMonthOfYear($year))) {
			$DayInYear += &_LastDayOfMonth($year, $m++);
		}
		$m = 1;
		while ($m < $month) {
			$DayInYear += &_LastDayOfMonth($year, $m);
			$m++;
		}
    }
    else {
		$m = 7;
		while ($m < $month) {
			$DayInYear += &_LastDayOfMonth($year, $m);
			$m++;
		}
    }

    return($DayInYear + (&_CalendarElapsedDays($year) + HEBREW_EPOCH));
}

sub _leap_year {
    my $year = shift;

	if ((((7 * $year) + 1) % 19) < 7) { return 1; }
    else { return 0; }
}

sub _LastMonthOfYear {
    my $year = shift;

    if (&_leap_year($year)) { return 13; }
    else { return 12; }
}

sub _CalendarElapsedDays {
	my $year = shift;

    my($MonthsElapsed, $PartsElapsed, $HoursElapsed, $ConjunctionDay, $ConjunctionParts);
    my($AlternativeDay);

    $MonthsElapsed = (235 * int(($year - 1) / 19)) + (12 * (($year - 1) % 19)) + int((7 * (($year - 1) % 19) + 1) / 19);
    $PartsElapsed = 204 + 793 * ($MonthsElapsed % 1080);
    $HoursElapsed = 5 + 12 * $MonthsElapsed + 793 * int($MonthsElapsed / 1080) + int($PartsElapsed / 1080);
    $ConjunctionDay = 1 + 29 * $MonthsElapsed + int($HoursElapsed / 24);
    $ConjunctionParts = 1080 * ($HoursElapsed % 24) + $PartsElapsed % 1080;

    $AlternativeDay = 0;
    if (($ConjunctionParts >= 19440) ||
	((($ConjunctionDay % 7) == 2)
	 && ($ConjunctionParts >= 9924)
	 && (!&_leap_year($year))) ||
	((($ConjunctionDay % 7) == 1)
	 && ($ConjunctionParts >= 16789)
	 && (&_leap_year($year - 1))))
    { $AlternativeDay = $ConjunctionDay + 1; }
    else    { $AlternativeDay = $ConjunctionDay; }

    if ((($AlternativeDay % 7) == 0) ||
	(($AlternativeDay % 7) == 3) ||
	(($AlternativeDay % 7) == 5))
    { return (1 + $AlternativeDay); }
    else    { return $AlternativeDay; }
}

sub _DaysInYear {
	my $year = shift;
    return ((&_CalendarElapsedDays($year + 1)) - (&_CalendarElapsedDays($year)));
}

sub _LongCheshvan {
	my $year = shift;
    if ((&_DaysInYear($year) % 10) == 5) { return 1; }
    else { return 0; }
}       

sub _ShortKislev {
	my $year = shift;
    if ((&_DaysInYear($year) % 10) == 3) { return 1; }
    else { return 0; }
}

sub _LastDayOfMonth {
    my ($year, $month) = @_;

    if (($month == 2) ||
	($month == 4) ||
	($month == 6) ||
	(($month == 8) && (! &_LongCheshvan($year))) ||
	(($month == 9) && &_ShortKislev($year)) ||
	($month == 10) ||
	(($month == 12) && (!&_leap_year($year))) ||
	($month == 13)) { return 29; }
    else { return 30; }
}

sub month_name {
	my $self = shift;
	my $month = $self->month;
	if(@_) { $month = shift; }

    return (qw/Nissan Iyar Sivan Tamuz Av Elul Tishrei Cheshvan Kislev Tevet Shevat AdarI AdarII/)[$month-1];
}

sub day_name {
	my $self = shift;
	my $day = $self->day_of_week;
	if(@_) { $day = shift; }

    return (qw/Sunday Monday Tuesday Wednesday Thursday Friday Shabbos/)[$day - 1];
}

use DateTime::TimeZone::Floating qw( );
sub time_zone { DateTime::TimeZone::Floating->new() } 


sub year    { $_[0]->{year} }

sub month   { $_[0]->{month} }
*mon = \&month;

sub month_0   { $_[0]->month - 1 }
*mon_0 = \&month_0;

sub day_of_month { $_[0]->{day} }
*day  = \&day_of_month;
*mday = \&day_of_month;

sub day_of_month_0 { $_[0]->day - 1 }
*day_0  = \&day_of_month_0;
*mday_0 = \&day_of_month_0;

sub day_of_week {
	my $rd_days = $_[0]->{rd_days};
	if($_[0]->{after_sunset}) { $rd_days++; }
	return $rd_days % 7 + 1;
}
*wday = \&day_of_week;
*dow  = \&day_of_week;

sub day_of_week_0 {
	my $rd_days = $_[0]->{rd_days};
	if($_[0]->{after_sunset}) { $rd_days++; }
	return $rd_days % 7;
}
*wday_0 = \&day_of_week_0;
*dow_0  = \&day_of_week_0;

sub hour    { $_[0]->{hour} }
*hr = \&hour;

sub minute    { $_[0]->{minute} }
*min = \&minute;

sub second    { $_[0]->{second} }
*sec = \&second;

sub day_of_year {
	my $self = shift;
    my ($year, $month, $day) = @{$self}{qw/year month day/};

	my $m = 1;
	while ($m < $month) {
		$day += &_LastDayOfMonth($year, $m);
		$m++;
	}
	return $day;
}
*doy = \&day_of_year;

sub week_number {
    my $self = shift;

	my $day_of_year = $self->day_of_year;
	my $start_of_year = &_to_rd($self->year, 1, 1);
	my $first_week_started_on = $start_of_year % 7 + 1;

	return (($day_of_year + (7 - $first_week_started_on)) / 7) + 1;
}

sub day_of_year_0 { $_[0]->day_of_year - 1; }
*doy_0 = \&day_of_year_0;

sub hms {
    my ($self, $sep) = @_;
    $sep = ':' unless defined $sep;

    return sprintf( "%02d%s%02d%s%02d",
                    $self->hour, $sep,
                    $self->minute, $sep,
                    $self->second );
}
*time = \&hms;

sub hm {
    my ($self, $sep) = @_;
    $sep = ':' unless defined $sep;

    return sprintf( "%02d%s%02d",
                    $self->hour, $sep,
                    $self->minute );
}

sub ymd {
    my ($self, $sep) = @_;
    $sep = '-' unless defined $sep;

    return sprintf( "%04d%s%02d%s%02d",
                    $self->year, $sep,
                    $self->month, $sep,
                    $self->day );
}
*date = \&ymd;

sub mdy {
    my ($self, $sep) = @_;
    $sep = '-' unless defined $sep;

    return sprintf( "%02d%s%02d%s%04d",
                    $self->month, $sep,
                    $self->day, $sep,
                    $self->year );
}

sub dmy {
    my ($self, $sep) = @_;
    $sep = '-' unless defined $sep;

    return sprintf( "%02d%s%02d%s%04d",
                    $self->day, $sep,
                    $self->month, $sep,
                    $self->year );
}

sub datetime {
	my $self = shift;
	return ($self->ymd('-') . "T" . $self->hms);
}

my %formats = (
      'A' => sub { $_[0]->day_name },
      'a' => sub { my $a = $_[0]->day_of_week_0; (qw/Sun Mon Tue Wed Thu Fri Shabbat/)[$a] },
      'B' => sub { $_[0]->month_name },
      'd' => sub { sprintf( '%02d', $_[0]->day) },
      'D' => sub { $_[0]->strftime( '%m/%d/%Y') },
      'e' => sub { sprintf( '%2d', $_[0]->day) },
      'F' => sub { $_[0]->ymd('-') },
      'j' => sub { sprintf('%03d', $_[0]->day_of_year) },
      'H' => sub { sprintf('%02d', $_[0]->hour) },
	  'I' => sub { ($_[0]->hour == 12) ? '12' : sprintf('%02d', ($_[0]->hour % 12)) },
      'k' => sub { sprintf('%2d', $_[0]->hour) },
	  'l' => sub { ($_[0]->hour == 12) ? '12' : sprintf('%2d', ($_[0]->hour % 12)) },
      'M' => sub { sprintf('%02d', $_[0]->minute) },
      'm' => sub { sprintf('%02d', $_[0]->month) },
      'n' => sub { "\n" },
	  'P' => sub { ($_[0]->hour >= 12) ? "PM" : "AM" },
	  'p' => sub { ($_[0]->hour >= 12) ? "pm" : "am" },
      'r' => sub { $_[0]->strftime( '%I:%M:%S %p') },
      'R' => sub { $_[0]->strftime( '%H:%M') },
      'S' => sub { sprintf('%02d', $_[0]->second) },
      'T' => sub { $_[0]->strftime( '%H:%M:%S') },
      't' => sub { "\t" },
	  'u' => sub { my $u = $_[0]->day_of_week_0; $u == 0 ? 7 : $u },
	  'U' => sub { my $w = $_[0]->week_number; defined $w ? sprintf('%02d', $w) : '  ' },
	  'w' => sub { $_[0]->day_of_week_0 },
	  'W' => sub { sprintf('%02d', $_[0]->week_number) },
      'y' => sub { sprintf('%02d', substr($_[0]->year, -2)) },
      'Y' => sub { return $_[0]->year },
      '%' => sub { '%' },
    );
$formats{W} = $formats{V} = $formats{U};

sub strftime {
    my ($self, @r) = @_;

    foreach (@r) {
        s/%([%*A-Za-z])/ $formats{$1} ? $formats{$1}->($self) : $1 /ge;
        return $_ unless wantarray;
    }
    return @r;
}



1;
__END__

=head1 NAME

DateTime::Calendar::Hebrew - Dates in the Hebrew calendar

=head1 SYNOPSIS

  use DateTime::Calendar::Hebrew;

  $dt = DateTime::Calendar::Hebrew->new( year  => 5782,
                                         month => 10,
                                         day   => 4 );

=head1 DESCRIPTION

C<DateTime::Calendar::Hebrew> is the implementation of the Hebrew calendar.
Read on for more details on the Hebrew calendar.

=head1 THE HEBREW (JEWISH) CALENDAR

The Hebrew/Jewish calendar is a Luni-Solar calendar. Torah Law mandates that months are Lunar. The first day of a month coincides with the new moon in Jerusalem. (In ancient times, this was determined by witnesses. Read the books in the bibliography for more info). The Torah also mandates that certain holidays must occur in certain seasons. Seasons are solar, so a calendar that can work with lunar & solar events is needed.

The Hebrew Calendar uses a leap-month to regulate itself to the solar seasons. There are 12 months in a regular year. Months can be 29 or 30 days long. 2 of the months (Cheshvan & Kislev) change between having 29 & 30 days, depending on the year. In a Jewish Leap Year, an extra month number 13 is added.

Now a quick note about the numbering of the months. Most people expect a new year to start with month #1. However, the Hebrew calendar has more than one new year. The year number changes in the (Northern Hemisphere) Autumn with Tishrei (month #7), but the months are numbered beginning with Nissan (month #1) in the Spring.

Tishrei is the month in which you find the High-Holy-Days - 'Rosh HaShana' & 'Yom Kippur'.

Nissan, the Spring-new-year, commemorates the Exodus of the Ancient Israelites from Egypt. The Torah refers to months only by number, beginning with Nissan, e.g. giving the date of Yom Kippur in 'the seventh month'.

This system works for well for us, because of the leap month. If the new year is in the spring, the leap month is month 13. Otherwise, we'd have to re-number the months after a leap-month. 

Every month has a set number, using this module. Here's a list:

=over 4

=item 1. Nissan

=item 2. Iyar

=item 3. Sivan

=item 4. Tammuz

=item 5. Av or Menachem-Av

=item 6. Elul

=item 7. Tishrei

=item 8. Cheshvan or Mar-Cheshvan

=item 9. Kislev

=item 10. Teves

=item 11. Shevat

=item 12. AdarI

=item 13. AdarII (only in leap years)

=back

I<** A NOTE ABOUT SPELLING **>
If you speak Hebrew, you may take issue with my spelling of Hebrew words. I'm sorry, I used the spelling closest to the way I pronounce it. You could call it "Brooklyn-Ashkenaz-Pronunciation", if you like.

Back to the calendar. A cycle of Hebrew years takes 19 years and is called a Machzor. In that cycle, years 3, 6, 8, 11, 14, 17 & 19 are leap years.

Days (and holidays) begin at sunset, see below for more info.

The calculations for the start and length of the year are based on a number of factors, including rules about what holidays can't be on what days of the week, and things like that. For more detailed information about the Hebrew Calendar and Hebrew-Calendar-Algorithms, pick up one of the books listed above. I'm just not willing to plagiarize it all here. Of course a Google search on "Jewish Calendar" will probably offer you a wealth of materials.

=head1 SOURCES

Here are some absolutely essential books in understanding the Hebrew(Jewish) Calendar. Be forwarned - a working knowledge of Hebrew terms will help greatly:

B<The Comprehensive Hebrew Calendar by Arthur Spier. Third, Revised edition. Feldheim Publishers. ISBN 0-87306-398-8>

This book is great. Besides for a complete Jewish Calendar from 1900 to 2100, it contains a 22 page discourse on the Jewish Calendar - history, calculation method, religious observances - the works.

B<Understanding the Jewish Calendar by Rabbi Nathan Bushwick. Moznaim Publishing Corporation. ISBN 0-94011-817-3>

Another excellent book. Explains the calendar, lunation cycles, torah portions and more. This has more Astronomy than any of the others.

B<Calendrical Calculations by Edward Reingold & Nachum Dershowitz. Cambridge University Press. ISBN 0-521-77167-6 or 0-521-77752-6>

This book focuses on the math of calendar conversions. I use the first edition, which is full of examples in LISP. The second edition is supposed to include examples in other languages. It covers many different calendars - not just Hebrew.  See their page @ L<http://emr.cs.iit.edu/home/reingold/calendar-book/second-edition/>

There are other books, but those are the ones I used most extensively in my Perl coding.

=head1 METHODS

=over 4

=item * new(...)

	$dt = new Date::Calendar::Hebrew(
		year => 5782,
		month => 10,
		day => 5,
	);

This class method accepts parameters for each date and time component:
"year", "month", "day", "hour", "minute", "second" and "nanosecond".
"year" is required, all the rest are optional. time fields default to
'0', month/day fields to '1'. All fields except year are tested for validity:

	month : 1 to 13
	day   : 1 to 30
	hour  : 0 to 23
	minute/second : 0 to 59
	nanosecond : 0 to 999,999,999

C<Date::Calendar::Hebrew> doesn't support timezones. It uses the floating timezone.

The days on the Hebrew calendar begin at sunset. If you want to know the Hebrew
date, accurate with regard to local sunset, see the SUNSET section below.

=item * from_object(object => $object)

This class method can be used to construct a new object from
any object that implements the C<utc_rd_values()> method.  All
C<DateTime::Calendar> modules must implement this method in order to
provide cross-calendar compatibility.

=item * set(...)

	$dt->set(
		year  => 5782,
		month => 1,
		day   => 1,
	);

This method allows you to modify the values of the object. valid
fields are "year", "month", "day", "hour", "minute", "second",
and "nanosecond" . Returns the object being modified.
Values are checked for validity just as they are in C<new()>.

=item * utc_rd_values

Returns the current UTC Rata Die days and seconds as a three element
list.  This exists primarily to allow other calendar modules to create
objects based on the values provided by this object. We don't support
timezones, so this is actually the local RD.

=item * utc_rd_as_seconds

Returns the current UTC Rata Die days and seconds purely as seconds.
This is useful when you need a single number to represent a date. We
don't support timezones, so this is actually the local RD as seconds.

=item * clone

Returns a working copy of the object. 

=item * now

This class method returns a C<Date::Calendar::Hebrew> object created from C<DateTime->now()>.

=item * today

This class method returns a C<Date::Calendar::Hebrew> object created from C<DateTime->today()>.

=item * year

Returns the year.

=item * month

Returns the month of the year, from 1..13.

=item * day_of_month, day, mday

Returns the day of the month, from 1..30.

=item * day_of_month_0, day_0, mday_0

Returns the day of the month, from 0..29.

=item * hour   

=item * minute   

=item * second   

Each method returns the parameter named in the method.

=item * month_name($month);

Returns the name of the given month.  Called on an object ($dt->month_name), it returns the month name for the current month.

The Hebrew months are Nissan, Iyar, Sivan, Tammuz, (Menachem)Av, Elul, Tishrei, (Mar)Cheshvan, Kislev, Teves, Shevat & Adar. Leap years have "Adar II" or Second-Adar. If you feel that the order of the months is wrong, see the README.

=item * day_of_week, wday, dow

Returns the day of the week as a number, from 1..7, with 1 being
Sunday and 7 being Saturday.

=item * day_of_week_0, wday_0, dow_0

Returns the day of the week as a number, from 0..6, with 0 being
Sunday and 6 being Saturday.

=item * day_name

Returns the name of the current day of the week.

=item * day_of_year, doy

Returns the day of the year.

=item * day_of_year_0, doy_0

Returns the day of the year, starting with 0.

=item * ymd($optional_separator);

=item * mdy($optional_separator);

=item * dmy($optional_separator);

Each method returns the year, month, and day, in the order indicated
by the method name.  Years are zero-padded to four digits.  Months and
days are 0-padded to two digits.

By default, the values are separated by a dash (-), but this can be
overridden by passing a value to the method.

=item * hms($optional_separator);

Returns the time, in the format of I<HH:MM:SS>.

By default, the values are separated by a colon (:), but this can be
overridden by passing a value to the method.

=item * hm($optional_separator);

Returns the time, in the format of I<HH:MM>.

By default, the values are separated by a colon (:), but this can be
overridden by passing a value to the method.

=item * timezone

Returns 'floating'

=item * datetime

Returns the date & time in the format of I<YYYY/MM/DDB<T>HH:MM:SS>

=item * strftime($format, ...)

This method implements functionality similar to the C<strftime()>
method in C.  However, if given multiple format strings, then it will
return multiple elements, one for each format string.

See L<DateTime> for a list of all possible format specifiers.
I implemented as many of them as I could.

=back

=head2 INTERNAL FUNCTIONS

=over 4

=item * _from_rd($RD);

Calculates the Hebrew year, month and day from the RD.

=item * _to_rd($year, $month, $day);

Calulates the RD from the  Hebrew year, month and day.

=item * _leap_year($year);

Returns true if the given year is a Hebrew leap-year.

=item * _LastMonthOfYear($year);

Returns the number of the last month in the given Hebrew year. Leap-years have 13 months, Regular-years have 12.

=item * _CalendarElapsedDays($year);

Returns the number of days that have passed from the Epoch of the Hebrew Calendar to the first day ofthe given year.

=item * _DaysInYear($year);

Returns the number of days in the given year.

=item * _LongCheshvan($year);

Returns true if the given year has an extended month of Cheshvan. Cheshvan can have 29 or 30 days. Normally it has 29.

=item * _ShortKislev($year);

Returns true if the given year has a shortened month of Kislev. Kislev can have 29 or 30 days. Normally it has 30.

=item * _LastDayOfMonth($year, $month);

Returns the length of the month in question, for the year in question.

=back

=head2 OPERATOR OVERLOADING AND OBJECT MATH

C<DateTime::Calendar::Hebrew> objects can be compares with the '>', '<', '<=>' and 'cmp' operators. You can also call
$DT->compare($OTHER_DT).

Simple math can be done on C<DateTime::Calendar::Hebrew> objects, using a C<DateTime::Duration>. The only supported fields are:
I<days, hours, minutes, seconds & nanoseconds>. You can also call $DT->add_duration($DURATION) and $DT->subtract_duration($DURATION).

=over 4

=item * _compare_overload

=item * _compare

=item * _add_overload

=item * _subtract_overload

=item * add_duration

=item * subtract_duration

=item * _normalize

=back

=head1 SUNSET AND THE HEBREW DATE

Days in the Hebrew Calendar start at sunset. This is only relevant
for religious purposes or pedantic programmers. There are some serious
(religious) issues involved, in areas that don't have a clearly defined,
daily sunset or sunrise. In the Arctic Circle, there are summer days where
the sun doesn't set, and winter days where the sun doesn't rise. Other
areas (e.g. Anchorage, Alaska Stockholm, Sweden, Oslo, Norway) where
the days are very short and twilight is exceptionally long. (I've never
experienced this, I'm copying it from a webpage.)

First off, I'd like to say, that if you are Jewish and have questions related to sunrise/sunset and religious observances - consult your local Rabbi. I'm no expert.

If you're not Jewish, and you want to know about Hebrew dates in these areas (or even if you are Jewish but you don't live there) - make friends with someone Jewish who lives there and ask them to ask their Rabbi. :)

Now that my awkward disclaimer is finished, on to the code issues.

If you wish the Hebrew date to be accurate with regard to sunset, you
need to provide 2 things: A DateTime::Event::Sunrise object, initialized
with a longitude and latitude for your location AND a time-zone for your
location. Without a timezone, I can't calculate sunset properly. These
items can be passed in via the constructor, or the set method. You
could configure the C<DateTime::Event::Sunrise> object for altitude &
interpolation if you wish.

=head2 NOTES ABOUT SUNSET

This feature was only tested for time-zones with a sunset for the day
in question.  THE RD_DAYS VALUE IS NOT MODIFIED. The internal local-
year/month/day fields are modified. The change in date only shows
when using the accessor methods for the object. RD_DAYS only changes
at midnight.  DateTime::Calendar::Hebrew doesn't support timezones! It
still uses a 'floating' time zone. Using $obj->set_time_zone(...) isn't
implemented, and won't help with sunset calculations. It needs to be
a field.

As has been pointed out to me, there is a feature/bug that causes some
confusion in the conversions. I prioritized the calculations, so that
the conversion from DateTime to DateTime::Calendar::Hebrew would always
look right. If you provide an english date, with a time after sunset
but before midnight, you will get a Hebrew time for the next day. The RD
will stay the same, but the Hebrew date changes. Conversly, if you want
to say the night of a certain Hebrew date, you need to use the date of
the previous day. The sunset 'belongs' to the English date e.g. If you
say "Nissan 14 5764, after sunset" (The time to search for leavening on
Passover eve), the code converts it to the RD equivalent to "Monday,
April 5th , 2004". After sunset of April 5th, is "Nissan 15th"! So if
you wanted an object to represent the time to search for leavening,
you need to create an object for "Nissan 13 5764, after sunset", which
will print out as "Nissan 14 5764, after sunset".

=head2 SAMPLE CODE

See C<eg/sunset.pl>, included in this distribution.

=head1 SUPPORT

Support for this module is provided via the datetime@perl.org email
list. See http://lists.perl.org/ for more details.

=head1 CREDITS

- Thanks to my good friend Richie Sevrinsky who helped me make sense of the calculations in the first place.

- Thanks to all the DateTime developers and the authors of the other Calendar modules, who gave me code to steal from ... I mean emulate.

- Thanks to Arthur Spier, Rabbi Bushwick and Messrs. Dershowitz and Reingold for writing excellent books on the subject.

=head1 AUTHOR

Steven J. Weinberger <perl@psycomp.com>
Raphael Mankin <RAPMANKIN@cpan.org> (co-maintainer)

=head1 COPYRIGHT

Copyright (c) 2003 Steven J. Weinberger.  All rights reserved.  This
program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<DateTime>

L<DateTime::Event::Sunrise>

L<DateTime::Duration>

L<DateTime::Event::Jewish>

datetime@perl.org mailing list

=cut
