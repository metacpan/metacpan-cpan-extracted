# Copyright (c) 1999-2007 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: Gregorian.pm,v 1.15 2007/06/19 12:10:58 martin Stab $

package Date::Gregorian;

use strict;
use integer;
use vars qw($VERSION @ISA @EXPORT_OK %EXPORT_TAGS);
require Exporter;

@ISA = qw(Exporter);
%EXPORT_TAGS = (
    'weekdays' => [qw(
	    MONDAY TUESDAY WEDNESDAY THURSDAY FRIDAY SATURDAY SUNDAY
	)],
    'months' => [qw(
	    JANUARY FEBRUARY MARCH APRIL MAY JUNE JULY
	    AUGUST SEPTEMBER OCTOBER NOVEMBER DECEMBER
	)],
);
@EXPORT_OK = map @{$_}, values %EXPORT_TAGS;

$VERSION = '0.12';

# ----- object definition -----

# Date::Gregorian=ARRAY(...)

# .......... index ..........	# .......... value ..........
use constant F_DAYNO   => 0;	# continuos day number, "March ...th, 1 BC"
use constant F_TR_DATE => 1;	# first Gregorian date in dayno format
use constant F_TR_EYR  => 2;	# first Gregorian easter year
use constant F_YMD     => 3;	# [year, month, day] (on demand, memoized)
use constant F_YDYW    => 4;	# [yearday, year, week] (on demand, memoized)
use constant F_SEC_NS  => 5;	# [seconds, nanoseconds] (optional)
use constant NFIELDS   => 6;

# ----- other constants -----

use constant MONDAY    => 0;
use constant TUESDAY   => 1;
use constant WEDNESDAY => 2;
use constant THURSDAY  => 3;
use constant FRIDAY    => 4;
use constant SATURDAY  => 5;
use constant SUNDAY    => 6;

use constant JANUARY   =>  1;
use constant FEBRUARY  =>  2;
use constant MARCH     =>  3;
use constant APRIL     =>  4;
use constant MAY       =>  5;
use constant JUNE      =>  6;
use constant JULY      =>  7;
use constant AUGUST    =>  8;
use constant SEPTEMBER =>  9;
use constant OCTOBER   => 10;
use constant NOVEMBER  => 11;
use constant DECEMBER  => 12;

# ----- predefined private variables -----

my @m2d      = map +($_ * 153 + 2) / 5, (0..11);
my $epoch    = _ymd2dayno( 1970, 1, 1, 1, 1);
my @defaults = (
    $epoch,				# F_DAYNO
    _ymd2dayno(1582, 10, 15, 1, 1),	# F_TR_DATE
    1583,				# F_TR_EYR
    undef,				# F_YMD
    undef,				# F_YDYW
    undef,				# F_SEC_NS
);
my ($gmt_epoch, $gmt_correction) = _init_gmt();
my $datetime_epoch = 307;
my $default_sec_ns = [0, 0];
my %JG = ('J' => 0, 'G' => 1);
my $localtime_offset = 0;

# ----- private functions -----

# ($div, $mod) = _divmod($numerator, $denominator)
#
sub _divmod {
    no integer;				# use well defined percent operator
    my $mod = $_[0] % $_[1];
    return (($_[0] - $mod) / $_[1], $mod);
}

# $dayno = _ymd2dayno($year, $month, $day, $tr_date, $fixed)
# fixed == 1: tr_date == 0: force Julian, tr_date == 1: force Gregorian
# fixed == boolean false: normal operation
#
sub _ymd2dayno {
    my ($y, $m, $d, $s, $fixed) = @_;

    if    (15 <= $m) { $m -= 3;      $y += $m / 12; $m %= 12;          }
    elsif ( 3 <= $m) { $m -= 3;                                        }
    elsif (-9 <= $m) { $m += 9;      $y --;                            }
    else             { $m = 14 - $m; $y -= $m / 12; $m = 11 - $m % 12; }

    $d += $m2d[$m] + $y * 365 + ($y >> 2) - 1;
    if (!$fixed && $s <= $d || $fixed && $s) {
	$y = 0 <= $y? $y / 100: -((99 - $y) / 100);
	$d -= $y - ($y >> 2) - 2;
    }
    return $d;
}

# ($year, $month, $day) = _dayno2ymd($dayno, $tr_date)
#
sub _dayno2ymd {
    my ($n, $s) = @_;
    my ($d, $m, $y);
    my $c;
    if ($s <= $n) {
	($c, $n) = _divmod($n - 2, 146097);
	$c *= 400;
	$n += (($n << 2) + 3) / 146097;
    }
    else {
	($c, $n) = _divmod($n, 1461);
	$c <<= 2;
    }
    $y = (($n << 2) + 3) / 1461;
    $n = ($n - $y * 365 - ($y >> 2)) * 5 + 2;
    $m = $n / 153 + 3;
    $d = $n % 153 / 5 + 1;
    $y ++, $m -= 12 if 12 < $m;
    return ($c + $y, $m, $d);
}

# ($dayno, $ymd) = _easter($year, $tr_date, $tr_eyr)
#
sub _easter {
    my ($y, $s, $e) = @_;
    my $m = 3;
    my $d;
    my $n = $y * 365 + ($y >> 2);
    if ($e <= $y) {
	my $g = 0 <= $y? $y / 100: -((99 - $y) / 100);
	$n -= $g - ($g >> 2) - 2;
	{ no integer; $g %= 3000 };
	my $h = 15 + $g - (($g << 3) + 13) / 25 - ($g >> 2);
	$g = do { no integer; $y % 19 };
	$d = ($g * 19 + $h) % 30;
	--$d if 28 <= $d && (28 < $d || 11 <= $g);
    }
    else {
	$d = do { no integer; ($y % 19 * 19 + 15) % 30 };
    }
    $d += do { no integer; 28 - ($n + $d) % 7 };
    $n += $d - 1;
    $d -= 31, $m ++ if 31 < $d;
    return ($n, ($s <= $n xor $e <= $y)? undef: [$y, $m, $d]);
}

# $dayno = _dec31dayno($year, $tr_date)
# calculate day number of last day in year (usually December 31)
#
sub _dec31dayno {
    my ($y, $s) = @_;

    my $n = 306 + $y * 365 + ($y >> 2) - 1;
    if ($s <= $n) {
	$y = 0 <= $y? $y / 100: -((99 - $y) / 100);
	$n -= $y - ($y >> 2) - 2;
	if ($n < $s) {
	    return $s-1;
	}
    }
    return $n;
}

# $ydyw = _ydyw($dayno, $tr_date, $year)
#
sub _ydyw {
    my ($n, $s, $y) = @_;
    my $base = _dec31dayno($y-1, $s);
    my $yd = $n - $base;
    $base += 4;
    { no integer; $base -= $base % 7 };
    if ($n < $base) {
	$y --;
	$base = _dec31dayno($y-1, $s) + 4;
	{ no integer; $base -= $base % 7 };
    }
    else {
	my $limit = _dec31dayno($y, $s) + 4;
	{ no integer; $limit -= $limit % 7 };
	if ($limit <= $n) {
	    $base = $limit;
	    $y ++;
	}
    }
    my $yw = ($n - $base) / 7 + 1;
    return [$yd, $y, $yw];
}

# ($gmt_epoch, $gmt_correction) = _init_gmt()
#
sub _init_gmt {
    my ($sec, $min, $hour, $mday, $mon, $year) = gmtime(0);
    return (
	_ymd2dayno(1900 + $year, 1 + $mon, $mday, 1, 1),
	($hour*60 + $min)*60 + $sec
    );
}

# ----- public methods -----

sub new {
    my $class = $_[0];
    my Date::Gregorian $self;
    if (ref $class) {			# called as obj method: clone it
	$self = bless [@{$class}], ref($class);
    }
    else {				# called as class method: create
	$self = bless [@defaults], $class;
    }
    return $self;
}

sub configure {
    my Date::Gregorian $self = shift;
    my ($y, $m, $d, $e) = @_;
    @{$self}[F_TR_DATE, F_YMD, F_YDYW] =
	( _ymd2dayno($y, $m, $d, 1, 1), undef, undef );
    $self->[F_TR_EYR] = $e if defined $e;
    return $self;
}

sub is_gregorian {
    my Date::Gregorian $self = $_[0];
    return $self->[F_TR_DATE] <= $self->[F_DAYNO];
}

sub set_date {
    my Date::Gregorian ($self, $ref) = @_;
    @{$self}[F_DAYNO, F_YMD, F_YDYW] = ( $ref->[F_DAYNO], undef, undef );
    return $self;
}

sub set_ymd {
    my Date::Gregorian $self = shift;
    my ($y, $m, $d) = @_;
    @{$self}[F_DAYNO, F_YMD, F_YDYW] =
	( _ymd2dayno($y, $m, $d, $self->[F_TR_DATE]), undef, undef );
    return $self;
}

sub check_ymd {
    my Date::Gregorian $self = shift;
    my ($y, $m, $d) = @_;
    my ($dayno, $yy, $mm, $dd);
    if (defined($d) && 1 <= $d && $d <= 31 &&
	defined($m) && 1 <= $m && $m <= 12 &&
	defined($y) && -1469871 <= $y && $y <= 5879489
    ) {
	$dayno = _ymd2dayno($y, $m, $d, $self->[F_TR_DATE]);
	($yy, $mm, $dd) = _dayno2ymd($dayno, $self->[F_TR_DATE]);
	if ($dd == $d && $mm == $m && $yy == $y) {
	    @{$self}[F_DAYNO, F_YMD, F_YDYW] =
		( $dayno, [$yy, $mm, $dd], undef );
	    return $self;
	}
    }
    return undef;
}

sub get_ymd {
    my Date::Gregorian $self = $_[0];
    my $ymd = $self->[F_YMD] ||=
	[ _dayno2ymd($self->[F_DAYNO], $self->[F_TR_DATE]) ];
    return @{$ymd};
}

sub get_weekday {
    no integer;
    my Date::Gregorian $self = $_[0];
    return $self->[F_DAYNO] % 7;
}

sub set_yd {
    my Date::Gregorian $self = shift;
    my ($y, $d) = @_;
    my $n = _dec31dayno($y-1, $self->[F_TR_DATE]) + $d;
    @{$self}[F_DAYNO, F_YMD, F_YDYW] = ($n, undef, undef);
    return $self;
}

sub set_ywd {
    no integer;
    my Date::Gregorian $self = shift;
    my ($y, $w, $d) = @_;
    my $n = _dec31dayno($y-1, $self->[F_TR_DATE]) - 3;
    $n += $w * 7 + $d - $n % 7;
    @{$self}[F_DAYNO, F_YMD, F_YDYW] = ($n, undef, undef);
    return $self;
}

sub check_ywd {
    no integer;
    my Date::Gregorian $self = shift;
    my ($y, $w, $d) = @_;
    if (defined($d) && 0 <= $d && $d <= 6 &&
	defined($w) && 1 <= $w && $w <= 53 &&
	defined($y) && -1469871 <= $y && $y <= 5879489
    ) {
	my $n = _dec31dayno($y-1, $self->[F_TR_DATE]) - 3;
	$n += $w * 7 + $d - $n % 7;
	my $ymd = [_dayno2ymd($n, $self->[F_TR_DATE])];
	my $ydyw = _ydyw($n, $self->[F_TR_DATE], $ymd->[0]);
	if ($ydyw->[1] == $y && $ydyw->[2] == $w) {
	    @{$self}[F_DAYNO, F_YMD, F_YDYW] = ($n, $ymd, $ydyw);
	    return $self;
	}
    }
    return undef;
}

sub get_yd {
    my Date::Gregorian $self = $_[0];
    my ($y, $m, $d) = $self->get_ymd;
    return ($y, $d) if 1 == $m;
    my $ydyw = $self->[F_YDYW] ||= _ydyw(@{$self}[F_DAYNO, F_TR_DATE], $y);
    return ($y, $ydyw->[0]);
}

sub get_ywd {
    no integer;
    my Date::Gregorian $self = $_[0];
    my $y = ($self->get_ymd)[0];
    my $ydyw = $self->[F_YDYW] ||= _ydyw(@{$self}[F_DAYNO, F_TR_DATE], $y);
    return (@{$ydyw}[1, 2], $self->[F_DAYNO] % 7);
}

sub add_days {
    my Date::Gregorian $self = $_[0];
    $self->[F_DAYNO] += $_[1];
    @{$self}[F_YMD, F_YDYW] = (undef, undef);
    return $self;
}

sub get_days_until {
    my Date::Gregorian ($self, $then) = @_;
    return $then->[F_DAYNO] - $self->[F_DAYNO];
}

sub get_days_since {
    my Date::Gregorian ($self, $then) = @_;
    return $self->[F_DAYNO] - $then->[F_DAYNO];
}

sub compare {
    my Date::Gregorian ($self, $then) = @_;
    return $self->[F_DAYNO] <=> $then->[F_DAYNO];
}

sub set_easter {
    my Date::Gregorian $self = $_[0];
    @{$self}[F_DAYNO, F_YMD, F_YDYW] =
	( _easter($_[1], @{$self}[F_TR_DATE, F_TR_EYR]), undef );
    return $self;
}

sub set_gmtime {
    no integer;
    my Date::Gregorian $self = $_[0];
    my $time = $_[1] + $gmt_correction;
    $time -= $time % 86400;
    @{$self}[F_DAYNO, F_YMD, F_YDYW] = (
	$gmt_epoch + $time / 86400,
	undef, undef,
    );
    return $self;
}

sub get_gmtime {
    no integer;
    my Date::Gregorian $self = $_[0];
    my $d = $self->[F_DAYNO] - $gmt_epoch;
    return 86400 * $d - $gmt_correction;
}

sub set_today {
    my Date::Gregorian $self = $_[0];
    return $self->set_localtime(time);
}

sub set_localtime {
    my Date::Gregorian $self = $_[0];
    my ($d, $m, $y) = (localtime $_[1])[3..5];
    $y += 1900;
    ++ $m;
    # presuming localtime always to return Gregorian dates,
    # while $self might be configured to interpret Julian,
    # we must ignore $self->[F_TR_DATE] here
    @{$self}[F_DAYNO, F_YMD, F_YDYW] =
	( _ymd2dayno($y, $m, $d, 1, 1), undef, undef );
    return $self;
}

sub get_localtime {
    no integer;
    my Date::Gregorian $self = $_[0];

    my $time = $self->get_gmtime - $localtime_offset;
    foreach my $step (0..3) {
	my ($S, $M, $H, $d, $m, $y) = localtime $time;
	my $dd = _ymd2dayno(1900+$y, 1+$m, $d, 1, 1) - $self->[F_DAYNO];
	return undef if 24855 < abs($dd);
	my $delta = (($dd * 24 + $H) * 60 + $M) * 60 + $S;
	if ($delta || $dd) {
	    if ($dd < 0 && 0 <= $delta) {
		# hours/minutes/seconds should not cancel out date increase
		$delta = -1;
	    }
	    $time -= $delta;
	    $localtime_offset += $delta if !$step;
	    next;
	}
	return $time;
    }
    return undef;
}

sub set_weekday {
    no integer;
    my Date::Gregorian $self = shift;
    my ($wd, $rel) = @_;
    my $delta = ($wd - $self->[F_DAYNO]) % 7;
    if (defined($rel) && '>=' ne $rel) {
	$delta = 7 if !$delta && '>' eq $rel;
	$delta -= 7 if '<' eq $rel || $delta && '<=' eq $rel;
    }
    if ($delta) {
	$self->[F_DAYNO] += $delta;
	@{$self}[F_YMD, F_YDYW] = (undef, undef);
    }
    return $self;
}

sub get_days_in_year {
    my ($self, $year) = @_;
    return
	_dec31dayno($year,   $self->[F_TR_DATE]) -
	_dec31dayno($year-1, $self->[F_TR_DATE]);
}

sub iterate_days_upto {
    my ($self, $limit, $rel, $step) = @_;
    my $dayno = $self->[F_DAYNO];
    my $final = $limit->[F_DAYNO] - ($rel ne '<=');
    $step = abs($step || 1);
    return sub {
	return undef if $dayno > $final;
	@{$self}[F_DAYNO, F_YMD, F_YDYW] = ($dayno, undef, undef);
	$dayno += $step;
	return $self;
    };
}

sub iterate_days_downto {
    my ($self, $limit, $rel, $step) = @_;
    my $dayno = $self->[F_DAYNO];
    my $final = $limit->[F_DAYNO] + ($rel eq '>');
    $step = abs($step || 1);
    return sub {
	return undef if $dayno < $final;
	@{$self}[F_DAYNO, F_YMD, F_YDYW] = ($dayno, undef, undef);
	$dayno -= $step;
	return $self;
    };
}

# --- DateTime interface ---

sub set_datetime {
    my ($self, $datetime) = @_;
    if (!$datetime->time_zone->is_floating) {
	$datetime = $datetime->clone->set_time_zone('floating');
    }
    my ($rd_days, @sec_ns) = $datetime->utc_rd_values;
    @{$self}[F_DAYNO, F_YMD, F_YDYW, F_SEC_NS] =
       ($rd_days + $datetime_epoch, undef, undef, \@sec_ns);
    return $self;
}

sub utc_rd_values {
    my $self = $_[0];
    return (
	$self->[F_DAYNO] - $datetime_epoch,
	@{$self->[F_SEC_NS] || $default_sec_ns}
    );
}

sub truncate_to_day {
    my $self = $_[0];
    undef $self->[F_SEC_NS];
    return $self;
}

sub from_object {
    my ($class, %param) = @_;
    return $class->new->set_datetime($param{'object'});
}

# must not define time_zone and set_time_zone methods

# --- stringification ---

sub get_string {
    my $self = $_[0];
    my $suffix = $self->is_gregorian? 'G': 'J';
    return sprintf "%d-%02d-%02d$suffix", $self->get_ymd;
}

sub set_string {
    my ($self, $string) = @_;
    if ($string =~ /^(-?\d+)-(\d+)-(\d+)([JG]?)\z/) {
	$self->[F_DAYNO] =
	    _ymd2dayno($1, $2, $3, $4? ($JG{$4}, 1): $self->[F_TR_DATE]);
	@{$self}[F_YMD, F_YDYW] = (undef, undef);
	return $self;
    }
    return undef;
}

# no DESTROY method, nothing to clean up

1;

__END__

=head1 NAME

Date::Gregorian - Gregorian calendar

=head1 SYNOPSIS

  use Date::Gregorian;
  use Date::Gregorian qw(:weekdays :months);

  $date = Date::Gregorian->new->set_ymd(1999, 12, 31);
  $date2 = $date->new;

  if ($date->check_ymd($year, $month, $day)) {
    # valid, $date has new value
  }
  else {
    # not valid, $date remains unchanged
  }

  ($year, $month, $day) = $date->get_ymd;

  $wd = (qw(Mon Tue Wed Thu Fri Sat Sun))[$date->get_weekday];
  $date->set_yd(2000, 366);           # Dec 31, 2000
  ($year, $day_in_year) = $date->get_yd;
  $date->set_ywd(1998, 53, 6);        # Sun Jan 3, 1999
  ($year, $week_in_year, $weekday) = $date->get_ywd;

  if ($date->check_ywd($year, $week, $weekday)) {
    # valid, $date has new value
  }
  else {
    # not valid, $date remains unchanged
  }

  $date->add_days(-100);
  $delta = $date->get_days_since($date2);
  $delta = $date2->get_days_until($date);
  $date->set_easter($y);
  $date->set_today;
  $date->set_localtime($time);
  $date->set_gmtime($time);
  $time = $date->get_gmtime;

  # compare two dates
  $cmp = $date->compare($date2);
  # sort dates
  @sorted = sort {$a->compare($b)} @dates;

  $iterator = $date->iterate_days_upto($date2, '<');
  $iterator = $date->iterate_days_upto($date2, '<', $step);
  $iterator = $date->iterate_days_upto($date2, '<=');
  $iterator = $date->iterate_days_upto($date2, '<=', $step);
  $iterator = $date->iterate_days_downto($date2, '>');
  $iterator = $date->iterate_days_downto($date2, '>', $step);
  $iterator = $date->iterate_days_downto($date2, '>=');
  $iterator = $date->iterate_days_downto($date2, '>=', $step);
  while ($iterator->()) {
    printf "%04d-%02d-%02d\n", $date->get_ymd;
  }

  $date->configure(1752, 9, 14);
  $date->configure(1752, 9, 14, 1753);        # United Kingdom
  $date2->configure(1918, 2, 14);             # Russia

  $date2->set_ymd(1917, 10, 25);      # pre-Gregorian Oct 25, 1917
  $date->set_date($date2);            # Gregorian Nov 7, 1917 (same day)

  if ($date->is_gregorian) {
    # date is past configured calendar reformation,
    # thus in Gregorian notation
  }
  else {
    # date is before configured calendar reformation,
    # thus in Julian notation
  }

  # get the first sunday in October:
  $date->set_ymd($year, 10,  1)->set_weekday(6, '>=');
  # get the last sunday in October:
  $date->set_ymd($year, 11,  1)->set_weekday(6, '<');

  # calculate number of days in 2000:
  $days = $date->get_days_in_year(2000);

  # plaintext representation of dates
  $str = $date->get_string;
  $date->set_string($str) or warn "syntax error";

  # DateTime interface
  use DateTime;
  $dt = DateTime->now(time_zone => 'Europe/Berlin');
  $date->set_datetime($dt);
  $dt = DateTime->from_object(object => $date);
  $date = Date::Gregorian->from_object($dt);
  ($rata_die, $sec, $nanosec) = $date->utc_rd_values();
  $date->truncate_to_day;

=head1 DESCRIPTION

Calendars define some notation to identify days in history.  The
Gregorian calendar, now in wide use, was established by Pope
Gregory XIII in AD 1582 as an improvement over the less accurate
Julian calendar that had been in use before.  Both of these calendars
also determine certain holidays.  Unfortunately, the new one was
not adopted everywhere at the same time.  Thus, the correct date
for a given historic event can depend on its location.  Astronomers
usually expand the official Julian/Gregorian calendar backwards
beyond AD 1 using zero and negative numbers, so that year 0 is
1 BC, year -1 is 2 BC, etc.

This module provides an object class representing days in history.
You can get earlier or later dates by way of adding days to them,
determine the difference in days between two of them, and read out
the day, month and year number as the (astronomic) Gregorian calendar
defines them (numbers 1 through 12 representing January through
December).  Moreover, you can find out weekdays, easter sundays,
week in year and day in year numbers.

For convenience, it is also possible to define the switching day
from Julian to Gregorian dates and the switching year from
pre-Gregorian to Gregorian easter schedule.  Use configure with
the first valid date of the new calendar and optionally the first
year the new easter schedule was used (default 1583).

The module is based on an algorithm devised by C. F. Gauss (1777-1855).
It is completely written in Perl for maximum portability.

All methods except get_* and iterate_* return their object.  This
allows for shortcuts like:

  $pentecost = Date::Gregorian->new->set_easter(2000)->add_days(49);

Numbers 0 through 6 represent weekdays Monday through Sunday.  Day
in month ranges from 1 to 31, day in year from 1 to 366, week in
year from 1 to 53.  Weeks are supposed to start on Monday.  The
first week of a year is the one containing January 4th.  These
definitions are slightly closer to ISO 8601 than to Perl's builtin
time conversion functions.  Weekday numbers, however, are zero-based
for ease of use as array indices.

(Author's note: I wish now I had defined 1-based weekdays when the
module was young, to make things nice and consistent, but backwards
compatibility suggests not to revise that decision.  If you prefer
consistent code, subtract JANUARY from a month value and MONDAY
from a weekday value to get a 0-based array index in any case.)

Numeric parameters must be integer numbers throughout the module.

For convenience, weekdays and months can be imported as constants
B<MONDAY>, B<TUESDAY>, B<WEDNESDAY>, B<THURSDAY>, B<FRIDAY>,
B<SATURDAY>, B<SUNDAY>, and B<JANUARY>, B<FEBRUARY>, B<MARCH>,
B<APRIL>, B<MAY>, B<JUNE>, B<JULY>, B<AUGUST>, B<SEPTEMBER>,
B<OCTOBER>, B<NOVEMBER>, B<DECEMBER>.  The tag B<:weekdays> provides
all weekdays, as B<:months> does all month names.  By default,
nothing is exported.

=head2 new

I<new> creates a Date::Gregorian object from scratch (if called as
a class method) or as a copy of an existing object.  The latter is
more efficient than the former.  I<new> does not take any arguments.

=head2 set_date

I<set_date> sets one Date::Gregorian object to the same day another
object represents.  The objects do not need to share a common calendar
configuration.

=head2 set_ymd

I<set_ymd> sets year, month and day to new absolute values.  Days
and months out of range are silently folded to standard dates, in
a way that is intended to preserve continuity: Month 13 is treated
as month 1 of the next year, month 14 as month 2 of the next year,
month 0 as month 12 of the previous year, day 0 as the last day of
the previous month, etc.  Thus, e.g., the date 10000 days before
February 22, 2002 can be defined like this:

  $date->set_ymd(2002, 2, 22-10000)

=head2 check_ymd

I<check_ymd>, on the other hand, checks a given combination of
year, month and day for validity.  Given a valid date, the object
is updated and the object itself is returned, evaluating to true
in boolean context.  Otherwise, the object remains untouched and
B<undef> is returned.

=head2 get_ymd

I<get_ymd> returns year, month and day as a three-item list.

=head2 get_weekday

I<get_weekday> returns the weekday as a number in the range of 0
to 6, with 0 representing Monday, 1 Tuesday, 2 Wednesday, 3 Thursday,
4 Friday, 5 Saturday and 6 representing Sunday.

=head2 set_yd get_yd

I<set_yd> and I<get_yd> set or get dates as a pair of year and day
in year numbers, day 1 representing January 1, day 32 February 1 etc.

=head2 set_ywd get_ywd

I<set_ywd> and I<get_ywd> set or get dates as a tuple of year, week
in year and day in week numbers.  As noted above, weeks are supposed
to start on Mondays.  Weeks containing days of both December and
January belong to the year containing more days of them.  Because
of this, get_ywd and get_ymd may return different year numbers.
Week numbers range from 1 to 53 (max).

=head2 check_ywd

I<check_ywd> checks a given combination of year, week in year and
weekday for validity.  Given a valid date, the object is updated
and the object itself is returned, evaluating to true in boolean
context.  Otherwise, the object remains untouched and B<undef> is
returned.

Note that year 1582 (or whatever year was configured to have the
Gregorian calendar reformation) was considerably shorter than a
normal year.  Such a year has some invalid dates that otherwise
might seem utterly inconspicuos.

=head2 add_days

I<add_days> increases, or, given a negative argument, decreases, a
date by a number of days.  Its new value represents a day that many
days later in history if a positive number of days was added.  Adding
a negative number of days consequently shifts a date back towards
the past.

=head2 get_days_since

I<get_days_since> computes the difference of two dates as a number
of days.  The result is positive if the given date is an earlier
date than the one whose method is called, negative if it is a later
one.  Look at it as a subtraction operation, yielding a positive
result if something smaller is subtracted from something larger,
"smaller" meaning "earlier" in this context.

=head2 get_days_until

I<get_days_until> computes the same value as I<get_days_since>,
only with opposite sign.

=head2 compare

I<compare> compares two dates chronologically.  Result is zero
if the dates refer to the same day, -1 if the method invocant
refers to an earlier day than the parameter and 1 otherwise.

=head2 iterate_days_upto iterate_days_downto

I<iterate_days_upto> and I<iterate_days_downto> provide convenient
methods to iterate over a range of dates.  They return a reference
to a subroutine that can be called without argument in a while
condition to set the given date iteratively to each one of a sequence
of dates.  The current date is always the first one to be visited
(unless the sequence is all empty).  The limit parameter determines
the end of the sequence, together with the relation parameter:  '<'
excludes the upper limit from the sequence, '<=' includes the upper
limit, '>=' includes the lower limit and '>' excludes the lower
limit.  The step parameter is optional.  It must be greater than
zero and defines how many days the dates in the sequence lie apart.
It defaults to one.

Each iterator maintains its own state; therefore it is legal to run
more than one iterator in parallel or even create new iterators
within iterations.

=head2 set_easter

I<set_easter> computes the date of Easter sunday of a given year,
taking into account how the date object was configured.

=head2 set_weekday

I<set_weekday> computes a date matching a given weekday that is
close to the date it is applied to.  The optional relation parameter
may be one of '>=', '>', '<=' or '<', and determines if the resulting
date should be "equal or later", later, "equal or earlier", or
earlier, respectively, than the initial date.  Default is '>='.

=head2 set_today

I<set_today> computes a date value equivalent to the system's notion
of the current date in the local timezone.  System time is assumed
to run in Gregorian mode.

=head2 set_localtime

I<set_localtime> likewise computes a date value equivalent to a
given arbitrary time value in the local timezone.

=head2 set_gmtime

I<set_gmtime> computes a date value equivalent to a given time value
in the "GMT" system timezone.  This timezone represents a time scale
counting a constant number of seconds per day since an OS- and
implementation dependent starting point -- the epoch -- and not
counting leap seconds.  This makes arithmetic on timestamps easy
but forces clocks to be frequently adjusted to the earth rotation.
On POSIX-like systems this timezone is used for timestamps.
On systems using the gmtime call in any other fashion I<set_gmtime>
and I<get_gmtime> are not guaranteed to comply with it.

=head2 get_gmtime

I<get_gmtime> converts a date value back to a timestamp in the "GMT"
timezone explained above.  This method may return undef if the date
seems to be out of range.  Note that the precision of timestamps
represented by Date::Gregorian objects is normally limited to days.
Thus, converting a timestamp to a date and back again usually
truncates the timestamp to midnight.  Extension classes may behave
differently, however.

=head2 get_localtime

I<get_localtime> converts a date value back to a system timestamp
in the current local timezone.  Undef is returned if the date seems
to be out of range.  As with I<get_gmtime>, the precision is normally
limited to days.  However, values returned by I<get_localtime> for
successive days need not follow a simple arithmetic progression,
as they interpolate actual localtime calls, and the local timezone
may incorporate oddities like daylight saving time changes.

Note also that timestamps are not portable.  While the conversion
functions described here make an effort to cover the local clock
behaviour, mostly in order to make set_today work, they depend on
the Perl builtin functions I<localtime> and I<gmtime>, which in
turn are OS- and implementation-specific.  I<localtime> may also
depend on the environment and other dynamic configuration settings.

=head2 get_days_in_year

I<get_days_in_year> computes the number of days in a given year
(independent of the year stored in the date object, but taking
into account its configuration).

=head2 configure

I<configure> defines the way the Gregorian calendar reformation
should be handled in calculations with the date object and any new
ones later cloned with I<new> from this one.  The first three
arguments specify the year, month and day of the first day the new
calendar was in use.  The optional fourth argument defines the first
year the new easter schedule has to be used in easter calculations.
Re-configuring a date object is legal and does not change the day
in history it represents while possibly changing the year, month
and day values related to it.

=head2 is_gregorian

I<is_gregorian> returns a boolean value telling whether a date is
past the configured calendar reformation and thus will yield year,
month and day values in Gregorian mode.

=head2 get_string

I<get_string> returns a plaintext representation of the date represented
by an object.

=head2 set_string

I<set_string> restores a date value from a string returned by I<get_string>.
Strings of the form "YYYY-MM-DD" are also accepted.  The return value
is B<undef> if the syntax could not be recognized, otherwise the object.
I<set_string> handles values out of range the same way I<set_ymd> does.

=head2 DateTime interoperability

Date::Gregorian objects can be converted to DateTime objects and
vice versa.  From the view of DateTime, Date::Gregorian implements
a calendar operating in the floating timezone.  From the view of
Date::Gregorian, DateTime objects represent days in history in a
way suitable for object initialization.  Higher precision
components of DateTime objects, i.e. seconds and nanoseconds,
are preserved for reverse conversion but otherwise ignored.

=over 4

=item set_datetime

I<set_datetime> sets a Date::Gregorian object to the day represented
by a given DateTime object.  It returns the updated object.

=item from_object

I<from_object> is a DateTime compatible constructor.  Arguments are
mapped to a hash.  The value in the 'object' slot is taken to be a
DateTime object.  The result is a Date::Gregorian object.  Note
that Date::Gregorian is not a subclass of DateTime.

=item utc_rd_values

I<utc_rd_values> returns a list of rata die, seconds and nanoseconds
values corresponding to the date currently represented by the object.
Seconds and nanoseconds will default to zero if not initialized from
some DateTime object, and will be ignored by all other Date::Gregorian
methods.  In particular, date objects differing only in their hidden
seconds or nanoseconds values are considered equivalent by I<compare>.

=item truncate_to_day

I<truncate_to_day> drops seconds and nanoseconds from a date.  This
will have an effect on DateTime objects subsequently initialized
from that object.  Return value is the object.

=back

=head1 AUTHOR

Martin Becker <hasch-cpan-dg@cozap.com>, November 1999.

=head1 CAVEATS

Does not work with non-integer values.

=head1 SEE ALSO

The sci.astro Calendar FAQ, L<Date::Calc>, L<Date::Gregorian::Business>,
L<DateTime>.

=cut
