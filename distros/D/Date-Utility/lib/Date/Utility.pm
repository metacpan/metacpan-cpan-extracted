package Date::Utility;

use 5.006;
use strict;
use warnings;

=head1 NAME

Date::Utility - A class that represents a datetime in various format

=cut

our $VERSION = '1.07';

=head1 SYNOPSIS

    use Date::Utility;

    Date::Utility->new(); # Use current time
    Date::Utility->new(1249637400);
    Date::Utility->new('dd-mmm-yy');
    Date::Utility->new('dd-mmm-yyyy');
    Date::Utility->new('dd-Mmm-yy hh:mm:ssGMT');
    Date::Utility->new('dd-Mmm-yy hhhmm');
    Date::Utility->new('YYYY-MM-DD');
    Date::Utility->new('YYYYMMDD');
    Date::Utility->new('YYYYMMDDHHMMSS');
    Date::Utility->new('YYYY-MM-DD HH:MM:SS');
    Date::Utility->new('YYYY-MM-DDTHH:MM:SSZ');

=head1 DESCRIPTION

A class that represents a datetime in various format

=cut

use Moose;
use Carp qw( confess croak );
use DateTime;
use POSIX qw( floor );
use Scalar::Util qw(looks_like_number);
use Tie::Hash::LRU;
use Time::Local qw(timegm);
use Try::Tiny;
use Time::Duration::Concise::Localize;

my %popular;
my $lru = tie %popular, 'Tie::Hash::LRU', 300;

has epoch => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has [qw(
        datetime_ddmmmyy_hhmmss_TZ
        datetime_ddmmmyy_hhmmss
        datetime_yyyymmdd_hhmmss
        datetime_yyyymmdd_hhmmss_TZ
        datetime_iso8601
        date
        datetime
        date_ddmmyy
        date_ddmmyyyy
        date_ddmmmyy
        date_yyyymmdd
        date_ddmmmyyyy
        days_in_month
        db_timestamp
        day_as_string
        full_day_name
        month_as_string
        http_expires_format
        iso8601
        time
        time_hhmm
        time_hhmmss
        time_cutoff
        timezone
        second
        minute
        hour
        day_of_month
        quarter_of_year
        month
        year
        _gmtime_attrs
        year_in_two_digit
        day_of_week
        day_of_year
        days_since_epoch
        seconds_after_midnight
        is_a_weekend
        is_a_weekday
        )
    ] => (
    is         => 'ro',
    lazy_build => 1,
    );

sub _build__gmtime_attrs {
    my $self = shift;
    my %params;

    @params{qw(second minute hour day_of_month month year day_of_week day_of_year)} = gmtime($self->{epoch});

    return \%params;
}

=head1 ATTRIBUTES

=head2 second

=cut

sub _build_second {
    my $self = shift;

    return sprintf '%02d', $self->_gmtime_attrs->{second};
}

=head2 minute

=cut

sub _build_minute {
    my $self = shift;

    return sprintf '%02d', $self->_gmtime_attrs->{minute};
}

=head2 hour

=cut

sub _build_hour {
    my $self = shift;

    return sprintf '%02d', $self->_gmtime_attrs->{hour};
}

=head2 day_of_month

=cut

sub _build_day_of_month {
    my $self = shift;

    return $self->_gmtime_attrs->{day_of_month};
}

=head2 month

=cut

sub _build_month {
    my $self = shift;

    my $gm_mon = $self->_gmtime_attrs->{month};

    return ++$gm_mon;
}

=head2 quarter_of_year

=cut

sub _build_quarter_of_year {
    my $self = shift;

    return int(($self->month - 0.0000001) / 3) + 1;

}

=head2 day_of_week

=cut

sub _build_day_of_week {
    return ((shift->{epoch} / 86400) + 4) % 7;
}

=head2 day_of_year

=cut

sub _build_day_of_year {
    my $self = shift;

    return $self->_gmtime_attrs->{day_of_year} + 1;
}

=head2 year

=cut

sub _build_year {
    my $self = shift;

    return $self->_gmtime_attrs->{year} + 1900;
}

=head2 time

=cut

sub _build_time {
    my $self = shift;

    return $self->hour . 'h' . $self->minute;
}

=head2 time_hhmm

Returns time in hh:mm format

=cut

sub _build_time_hhmm {
    my $self = shift;

    return join(':', ($self->hour, $self->minute));
}

=head2 time_hhmmss

Returns time in hh:mm:ss format

=cut

sub _build_time_hhmmss {
    my $self = shift;

    return join(':', ($self->time_hhmm, $self->second));
}

=head2 time_cutoff

Set the timezone for cutoff to UTC

=cut

sub _build_time_cutoff {
    my $self = shift;

    return 'UTC ' . $self->time_hhmm;
}

=head2 year_in_two_digit

Returns year in two digit format. Example: 15

=cut

sub _build_year_in_two_digit {
    my $self           = shift;
    my $two_digit_year = $self->year - 2000;

    if ($two_digit_year < 0) {
        $two_digit_year += 100;
    }

    return sprintf '%02d', $two_digit_year;
}

=head2 timezone

Set the timezone to GMT

=cut

sub _build_timezone {
    return 'GMT';
}

=head2 datetime

See, db_timestamp

=cut

sub _build_datetime {
    my $self = shift;

    return $self->db_timestamp;
}

=head2 datetime_ddmmmyy_hhmmss_TZ

Returns datetime in "dd-mmm-yy hh:mm:ssGMT" format

=cut

sub _build_datetime_ddmmmyy_hhmmss_TZ {
    my $self = shift;

    return $self->date_ddmmmyy . ' ' . $self->time_hhmmss . $self->timezone;
}

=head2 datetime_ddmmmyy_hhmmss

Returns datetime in "dd-mmm-yy hh:mm:ss" format

=cut

sub _build_datetime_ddmmmyy_hhmmss {
    my $self = shift;

    return $self->date_ddmmmyy . ' ' . $self->time_hhmmss;
}

=head2 date_ddmmmyyyy

Returns date in dd-mmm-yyyy format

=cut

sub _build_date_ddmmmyyyy {
    my $self = shift;

    return join('-', ($self->day_of_month, $self->month_as_string, $self->year));
}

=head2 date

Returns datetime in YYYY-MM-DD format

=cut

sub _build_date {
    my $self = shift;

    return $self->date_yyyymmdd;
}

=head2 date_ddmmmyy

Returns datetime in dd-Mmm-yy format

=cut

sub _build_date_ddmmmyy {
    my $self = shift;

    return join('-', ($self->day_of_month, $self->month_as_string, $self->year_in_two_digit));
}

=head2 days_since_epoch


Returns number of days since 1970-01-01

=cut

sub _build_days_since_epoch {
    my $self = shift;

    return floor($self->{epoch} / 86400);
}

=head2 seconds_after_midnight

Returns number of seconds after midnight of the same day.

=cut

sub _build_seconds_after_midnight {
    my $self = shift;

    return $self->{epoch} % 86400;
}

=head2 is_a_weekend

=cut

sub _build_is_a_weekend {
    my $self = shift;

    return ($self->day_of_week == 0 || $self->day_of_week == 6) ? 1 : 0;
}

=head2 is_a_weekday

=cut

sub _build_is_a_weekday {
    my $self = shift;

    return ($self->is_a_weekend) ? 0 : 1;
}

my $EPOCH_RE = qr/^-?[0-9]{1,13}$/;

=head2 new

Returns a Date::Utility object.

=cut

sub new {
    my ($self, $params_ref) = @_;
    my $new_params = {};

    if (not defined $params_ref) {
        $new_params->{epoch} = time;
    } elsif (ref $params_ref eq 'Date::Utility') {
        return $params_ref;
    } elsif (ref $params_ref eq 'HASH') {
        if (not($params_ref->{'datetime'} or $params_ref->{epoch})) {
            confess 'Must pass either datetime or epoch to the Date object constructor';
        } elsif ($params_ref->{'datetime'} and $params_ref->{epoch}) {
            confess 'Must pass only one of datetime or epoch to the Date object constructor';
        } elsif ($params_ref->{epoch}) {
            #strip other potential parameters
            $new_params->{epoch} = $params_ref->{epoch};

        } else {
            #strip other potential parameters
            $new_params = _parse_datetime_param($params_ref->{'datetime'});
        }
    } elsif ($params_ref =~ $EPOCH_RE) {
        $new_params->{epoch} = $params_ref;
    } else {
        $new_params = _parse_datetime_param($params_ref);
    }

    my $obj = $popular{$new_params->{epoch}};

    if (not $obj) {
        $obj = $self->_new($new_params);
        $popular{$new_params->{epoch}} = $obj;
    }

    $obj->{_truncated} = !($new_params->{epoch} % 86400);

    return $obj;

}

=head2 _parse_datetime_parm

User may supplies datetime parameters but it currently only supports the following formats:
dd-mmm-yy ddhddGMT, dd-mmm-yy, dd-mmm-yyyy, dd-Mmm-yy hh:mm:ssGMT, YYYY-MM-DD, YYYYMMDD, YYYYMMDDHHMMSS, yyyy-mm-dd hh:mm:ss, yyyy-mm-ddThh:mm:ss or yyyy-mm-ddThh:mm:ssZ.


=cut

my $mon_re            = qr/j(?:an|u[nl])|feb|ma[ry]|a(?:pr|ug)|sep|oct|nov|dec/i;
my $sub_second        = qr/^[0-9]+\.[0-9]+$/;
my $date_only         = qr/^([0-3]?[0-9])-($mon_re)-([0-9]{2}|[0-9]{4})$/;
my $date_with_time    = qr /^([0-3]?[0-9])-($mon_re)-([0-9]{2}) ([0-2]?[0-9])[h:]([0-5][0-9])(?::)?([0-5][0-9])?(?:GMT)?$/;
my $numeric_date_only = qr/^([12][0-9]{3})-?([01]?[0-9])-?([0-3]?[0-9])$/;
my $fully_specced     = qr/^([12][0-9]{3})-?([01]?[0-9])-?([0-3]?[0-9])(?:T|\s)?([0-2]?[0-9]):?([0-5]?[0-9]):?([0-5]?[0-9])(\.[0-9]+)?(?:Z)?$/;
my $numeric_date_only_dd_mm_yyyy = qr/^([0-3]?[0-9])-([01]?[0-9])-([12][0-9]{3})$/;

sub _parse_datetime_param {
    my $datetime = shift;

    # If it's date only, take the epoch at midnight.
    my ($hour, $minute, $second) = (0, 0, 0);
    my ($day, $month, $year);

    # The ordering of these regexes is an attempt to match early
    # to avoid extra comparisons.  If our mix of supplied datetimes changes
    # it might be worth revisiting this.
    if ($datetime =~ $sub_second) {
        # We have an epoch with sub second precision which we can't handle
        return {epoch => int($datetime)};
    } elsif ($datetime =~ $date_only) {
        $day   = $1;
        $month = month_abbrev_to_number($2);
        $year  = $3;
    } elsif ($datetime =~ $date_with_time) {
        $day    = $1;
        $month  = month_abbrev_to_number($2);
        $year   = $3;
        $hour   = $4;
        $minute = $5;
        if (defined $6) {
            $second = $6;
        }
    } elsif ($datetime =~ $numeric_date_only) {
        $day   = $3;
        $month = $2;
        $year  = $1;
    } elsif ($datetime =~ $numeric_date_only_dd_mm_yyyy) {
        $day   = $1;
        $month = $2;
        $year  = $3;
    } elsif ($datetime =~ $fully_specced) {
        $day    = $3;
        $month  = $2;
        $year   = $1;
        $hour   = $4;
        $minute = $5;
        $second = $6;
    }
    # Type constraints mean we can't ever end up in here.
    else {
        confess "Invalid datetime format: $datetime";
    }

    # Now that we've extracted out values, let's turn them into an epoch.
    # The all of following adjustments seem kind of gross:
    if (length $year == 2) {
        if ($year > 30 and $year < 70) {
            croak 'Date::Utility only supports two-digit years from 1970-2030. We got [' . $year . ']';
        }

        $year += ($year <= 30) ? 2000 : 1900;
    }

    my $epoch = timegm($second, $minute, $hour, $day, $month - 1, $year);

    return {
        epoch        => $epoch,
        second       => sprintf("%02d", $second),
        minute       => sprintf("%02d", $minute),
        hour         => sprintf("%02d", $hour),
        day_of_month => $day + 0,
        month        => $month + 0,
        year         => $year + 0,
    };
}

=head2 days_between

Returns number of days between two dates.

=cut

sub days_between {
    my ($self, $date) = @_;

    if (not $date) {
        Carp::croak('Date parameter not defined');
    }
    return $self->days_since_epoch - $date->days_since_epoch;
}

=head2 is_before

Returns a boolena which indicates whether this date object is earlier in time than the supplied date object.

=cut

sub is_before {
    my ($self, $date) = @_;

    if (not $date) {
        Carp::croak('Date parameter not defined');
    }
    return ($self->{epoch} < $date->{epoch}) ? 1 : undef;
}

=head2 is_after

Returns a boolena which indicates whether this date object is later in time than the supplied date object.

=cut

sub is_after {
    my ($self, $date) = @_;

    if (not $date) {
        Carp::croak('Date parameter not defined');
    }
    return ($self->{epoch} > $date->{epoch}) ? 1 : undef;
}

=head2 is_same_as

Returns a boolena which indicates whether this date object is the same time as the supplied date object.

=cut

sub is_same_as {
    my ($self, $date) = @_;

    if (not $date) {
        Carp::croak('Date parameter not defined');
    }
    return ($self->{epoch} == $date->{epoch}) ? 1 : undef;
}

=head2 day_as_string

Returns the name of the current day in short form. Example: Sun.

=cut

sub _build_day_as_string {
    my $self = shift;

    return substr($self->full_day_name, 0, 3);
}

=head2 full_day_name

Returns the name of the current day. Example: Sunday

=cut

# 0..6: Sunday first.
my @day_names   = qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday);
my %days_to_num = map {
    my $day = lc $day_names[$_];
    (
        substr($day, 0, 3) => $_,    # Three letter abbreviation
        $day => $_,                  # Full day name
        $_   => $_,                  # Number as number
    );
} 0 .. $#day_names;

sub _build_full_day_name {
    my $self = shift;

    return $day_names[$self->day_of_week];
}

=head2 month_as_string

Returns the name of current month in short form. Example: Jan

=cut

sub _build_month_as_string {
    my $self = shift;

    return month_number_to_abbrev($self->month);
}

=head2 http_expires_format

Returns datetime in this format: Fri, 27 Nov 2009 02:12:02 GMT

=cut

sub _build_http_expires_format {
    my $self = shift;

    return
          $self->day_as_string . ', '
        . sprintf('%02d', $self->day_of_month) . ' '
        . $self->month_as_string . ' '
        . $self->year . ' '
        . $self->time_hhmmss . ' '
        . $self->timezone;
}

=head2 date_ddmmyy

Returns date in this format "dd-mm-yy" (28-02-10)

=cut

sub _build_date_ddmmyy {
    my $self = shift;

    return join('-', (sprintf('%02d', $self->day_of_month), sprintf('%02d', $self->month), sprintf('%02d', $self->year_in_two_digit)));
}

=head2 date_ddmmyyyy

Returns date in this format "dd-mm-yyyy" (28-02-2010)

=cut

sub _build_date_ddmmyyyy {
    my $self = shift;

    return join('-', (sprintf('%02d', $self->day_of_month), sprintf('%02d', $self->month), $self->year));
}

=head2 date_yyyymmdd

Returns date in this format "yyyy-mm-dd" (2010-03-02)

=cut

sub _build_date_yyyymmdd {
    my $self = shift;

    return join('-', ($self->year, sprintf('%02d', $self->month), sprintf('%02d', $self->day_of_month)));
}

=head2 datetime_yyyymmdd_hhmmss

Returns: "yyyy-mm-dd hh:mm:ss" (2010-03-02 05:09:40)

=cut

sub _build_datetime_yyyymmdd_hhmmss {
    my $self = shift;

    return join(' ', ($self->date_yyyymmdd, $self->time_hhmmss));
}

sub _build_db_timestamp {
    my $self = shift;

    return $self->datetime_yyyymmdd_hhmmss;
}

=head2 datetime_iso8601 iso8601

Since all internal representations are in UTC
Returns "yyyy-mm-ddThh:mm:ssZ" (2010-02-02T05:09:40Z)

=cut

sub _build_datetime_iso8601 {
    my $self = shift;

    return $self->date_yyyymmdd . 'T' . $self->time_hhmmss . 'Z';
}

sub _build_iso8601 {
    my $self = shift;

    return $self->datetime_iso8601;
}

=head2 datetime_yyyymmdd_hhmmss_TZ

Returns datetime in this format "yyyy-mm-dd hh:mm:ssGMT" (2010-03-02 05:09:40GMT)

=cut

sub _build_datetime_yyyymmdd_hhmmss_TZ {
    my $self = shift;

    return $self->datetime_yyyymmdd_hhmmss . $self->timezone;
}

=head2 days_in_month

=cut

sub _build_days_in_month {
    my ($self) = @_;

    my $month = $self->month;
    # 30 days hath September, April, June and November.
    my %shorties = (
        9  => 30,
        4  => 30,
        6  => 30,
        11 => 30
    );
    # All the rest have 31
    my $last_day = $shorties{$month} || 31;
    # Except February.
    if ($month == 2) {
        my $year = $self->year;
        $last_day = (($year % 4 or not $year % 100) and ($year % 400)) ? 28 : 29;
    }

    return $last_day;
}

=head2 timezone_offset

Returns a TimeInterval which represents the difference between UTC and the time in certain timezone

=cut

sub timezone_offset {
    my ($self, $timezone) = @_;

    my $dt = DateTime->from_epoch(
        epoch     => $self->{epoch},
        time_zone => $timezone
    );

    return Time::Duration::Concise::Localize->new(interval => $dt->offset);
}

=head2 is_dst_in_zone

Returns a boolena which indicates whether a certain zone is in DST at the given epoch

=cut

sub is_dst_in_zone {
    my ($self, $timezone) = @_;

    my $dt = DateTime->from_epoch(
        epoch     => $self->{epoch},
        time_zone => $timezone
    );

    return $dt->is_dst;
}

=head2 plus_time_interval

Returns a new Date::Utility plus the supplied Time::Duration::Concise::Localize.  Negative TimeIntervals will move backward.

Will also attempt to create a TimeInterval from a supplied code, if possible.

=cut

sub plus_time_interval {
    my ($self, $ti) = @_;

    return $self->_move_time_interval($ti, 1);
}

=head2 minus_time_interval

Returns a new Date::Utility  minus the supplied Time::Duration::Concise::Localize.  Negative TimeIntervals will move forward.

Will also attempt to create a TimeInterval from a supplied code, if possible.

=cut

sub minus_time_interval {
    my ($self, $ti) = @_;

    return $self->_move_time_interval($ti, -1);
}

sub _move_time_interval {
    my ($self, $ti, $dir) = @_;

    unless (ref($ti)) {
        try { $ti = Time::Duration::Concise::Localize->new(interval => $ti) }
        catch {
            $ti //= 'undef';
            confess "Couldn't create a TimeInterval from the code '$ti': $_";
        };
    }
    my $sec = $ti->seconds;
    return ($sec == 0) ? $self : Date::Utility->new($self->{epoch} + $dir * $sec);
}

=head2 months_ahead

Returns the month ahead or backward from the supplied month in the format of Mmm-yy.
It could hanlde backward or forward move from the supplied month.

=cut

sub months_ahead {
    my ($self, $months_ahead) = @_;

    # Use 0-11 range to make the math easier.
    my $current_month = $self->month - 1;
    my $current_year  = $self->year;

    # take the current month number, add the offset, and shift back to 1-12
    my $new_month = ($current_month + $months_ahead) % 12 + 1;

    # we need to know how many years to go forward
    my $years_ahead = POSIX::floor(($current_month + $months_ahead) / 12);

    # use sprintf to add leading zero, and then shift into the range 0-99
    my $new_year = sprintf '%02d', (($current_year + $years_ahead) % 100);

    return month_number_to_abbrev($new_month) . '-' . $new_year;
}

=head2 move_to_nth_dow

Takes an integer as an ordinal and a day of week representation

The following are all equivalent:
C<move_to_nth_dow(3, 'Monday')>
C<move_to_nth_dow(3, 'Mon')>
C<move_to_nth_dow(3, 1)>

Returning the 3rd Monday of the month represented by the object or
C<undef> if it does not exist.

An exception is thrown on improper day of week representations.

=cut

sub move_to_nth_dow {
    my ($self, $nth, $dow_abb) = @_;

    $dow_abb //= 'undef';    # For nicer error reporting below.

    my $dow = $days_to_num{lc $dow_abb} // croak 'Invalid day of week. We got [' . $dow_abb . ']';

    my $dow_first = (7 - ($self->day_of_month - 1 - $self->day_of_week)) % 7;
    my $dom = ($dow + 7 - $dow_first) % 7 + ($nth - 1) * 7 + 1;

    return try { Date::Utility->new(join '-', $self->year, $self->month, $dom) };
}

=head1 STATIC METHODS

=head2 month_number_to_abbrev

Static method returns a standard mapping from month numbers to our 3
character abbreviated format.

=cut

my %number_abbrev_map = (
    1  => 'Jan',
    2  => 'Feb',
    3  => 'Mar',
    4  => 'Apr',
    5  => 'May',
    6  => 'Jun',
    7  => 'Jul',
    8  => 'Aug',
    9  => 'Sep',
    10 => 'Oct',
    11 => 'Nov',
    12 => 'Dec',
);

my %abbrev_number_map = reverse %number_abbrev_map;

sub month_number_to_abbrev {

    # Deal with leading zeroes.
    my $which = int shift;

    return $number_abbrev_map{$which};
}

=head2 month_abbrev_to_number

Static method returns a standard mapping from 3
character abbreviated format to month numbers

=cut

sub month_abbrev_to_number {

    # Deal with case issues
    my $which = ucfirst lc shift;

    return $abbrev_number_map{$which};
}

=head2 is_epoch_timestamp

Check if a given datetime is an epoch timestemp, i.e. an integer of under 14 digits.

=cut

sub is_epoch_timestamp {
    return (shift // '') =~ $EPOCH_RE;
}

=head2 is_ddmmmyy

Check if a given "date" is in dd-Mmm-yy format (e.g. 1-Oct-10)

=cut

sub is_ddmmmyy {
    my $date = shift;

    return (defined $date and $date =~ /^\d{1,2}\-\w{3}-\d{2}$/) ? 1 : undef;
}

=head2 truncate_to_day

Returns a Date::Utility object with the time part truncated out of it.

For instance, '2011-12-13 23:24:25' will return a new Date::Utility
object representing '2011-12-13 00:00:00'

=cut

sub truncate_to_day {
    my ($self) = @_;

    return $self if $self->{_truncated};

    my $epoch  = $self->{epoch};
    my $tepoch = $epoch - $epoch % 86400;

    return $popular{$tepoch} // Date::Utility->new($tepoch);
}

=head2 today

Returns Date::Utility object for the start of the current day. Much faster than
Date::Utility->new, as it will return the same object till the end of the day.

=cut

my ($today_obj, $today_ends_at, $today_starts_at);

sub today {
    my $time = time;
    if (not $today_obj or $time > $today_ends_at or $time < $today_starts_at) {
        # UNIX time assume that day is always 86400 seconds,
        # that makes life easier
        $time            = 86400 * int($time / 86400);
        $today_obj       = Date::Utility->new($time);
        $today_starts_at = $time;
        $today_ends_at   = $time + 86399;
    }
    return $today_obj;
}

no Moose;

__PACKAGE__->meta->make_immutable(
    constructor_name    => '_new',
    replace_constructor => 1
);
1;
__END__

=head1 DEPENDENCIES

=over 4

=item L<Moose>

=item L<DateTime>

=item L<POSIX>

=item L<Scalar::Util>

=item L<Tie::Hash::LRU>

=item L<Time::Local>

=item L<Try::Tiny>

=back


=head1 AUTHOR

Binary.com, C<< <support at binary.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-date-utility at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Date-Utility>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Date::Utility


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Date-Utility>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Date-Utility>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Date-Utility>

=item * Search CPAN

L<http://search.cpan.org/dist/Date-Utility/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Binary.com.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

