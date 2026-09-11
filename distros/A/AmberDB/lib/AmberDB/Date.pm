package AmberDB::Date;

use 5.016;
use warnings;
use Carp qw(croak cluck);
use Encode;         # Encoding management if needed
use Time::Local;    # Core module for time operations

our $VERSION = '5.25.1';
my $CREATED = '2008-02-07';

# Default English Month Names
my $DEFAULT_MONTHS = [
    "January", "February", "March",     "April",   "May",      "June",
    "July",    "August",   "September", "October", "November", "December"
];

# Default English Day Names
my $DEFAULT_DAYS = [
    "Sunday",   "Monday", "Tuesday", "Wednesday",
    "Thursday", "Friday", "Saturday"
];

# ------------------------------------------------
# Constructor
# ------------------------------------------------
sub new {
    my $class = shift;
    my %args  = ( ref $_[0] eq 'HASH' ) ? %{ $_[0] } : @_;
    my $self  = bless {}, $class;

    if ( $args{locale} ) {
        $self->{locale} = $args{locale};
    }
    elsif ( $self->can('months') && $self->can('days') ) {
        # Already a Locale mixin (e.g. AmberDB instance)
    }
    else {
        require AmberDB::Locale;
        $self->{locale} = AmberDB::Locale->new( language => $args{language} );
    }

    $self->{months} //= ( $self->{locale} && $self->{locale}->can('months') ? $self->{locale}->months() : undef )
                     // ( $self->can('months') ? $self->months() : $DEFAULT_MONTHS );
    $self->{days}   //= ( $self->{locale} && $self->{locale}->can('days') ? $self->{locale}->days() : undef )
                     // ( $self->can('days') ? $self->days() : $DEFAULT_DAYS );

    # Populate current timestamp data into self so $date->day_id, $date->year etc. work immediately
    my $d = $self->get_date( $args{time} );
    %$self = ( %$self, %$d );

    return $self;
}

# ------------------------------------------------
# Returns detailed current or specified time as a blessed AmberDB::Date object
# ------------------------------------------------
sub get_date {
    my ( $self, $time ) = @_;
    my $date_hash = {};

    # Set timestamp value
    $date_hash->{time} = $time // time();

    (
        $date_hash->{second}, $date_hash->{minute},
        $date_hash->{hour},   $date_hash->{day},
        $date_hash->{month},  $date_hash->{year},
        $date_hash->{daynumber}
    ) = ( localtime( $date_hash->{time} ) )[ 0, 1, 2, 3, 4, 5, 6 ];

    my $months = ( ref $self && $self->{months} ) // ( $self->can('months') ? $self->months() : $DEFAULT_MONTHS );
    my $days   = ( ref $self && $self->{days} )   // ( $self->can('days')   ? $self->days()   : $DEFAULT_DAYS );

    $date_hash->{monthname}  = $months->[ $date_hash->{month} ];
    $date_hash->{dayname}    = $days->[ $date_hash->{daynumber} ];
    $date_hash->{daynames}   = join( " ", @$days );
    $date_hash->{monthnames} = join( " ", @$months );

    $date_hash->{year}  += 1900;
    $date_hash->{month} += 1;

    # Zero-padding formatting
    $date_hash->{month}  = sprintf "%02d", $date_hash->{month};
    $date_hash->{day}    = sprintf "%02d", $date_hash->{day};
    $date_hash->{hour}   = sprintf "%02d", $date_hash->{hour};
    $date_hash->{minute} = sprintf "%02d", $date_hash->{minute};
    $date_hash->{second} = sprintf "%02d", $date_hash->{second};

    $date_hash->{month_id}  = $date_hash->{year} . $date_hash->{month};
    $date_hash->{day_id}    = $date_hash->{month_id} . $date_hash->{day};
    $date_hash->{hour_id}   = $date_hash->{day_id} . $date_hash->{hour};
    $date_hash->{minute_id} = $date_hash->{hour_id} . $date_hash->{minute};
    $date_hash->{second_id} = $date_hash->{minute_id} . $date_hash->{second};

    $date_hash->{short} =
      "$date_hash->{day}/$date_hash->{month}/$date_hash->{year}";
    $date_hash->{only_time} =
      "$date_hash->{hour}:$date_hash->{minute}:$date_hash->{second}";
    $date_hash->{str} = "$date_hash->{short} - $date_hash->{only_time}";

    # Side-effect: Save year directory to object path
    $date_hash->{year_dir} = $date_hash->{year};

    $date_hash->{months} = $months;
    $date_hash->{days}   = $days;

    return bless $date_hash, 'AmberDB::Date';
}

# ------------------------------------------------
# OOP Accessor / Getter Methods
# Support both $date->day_id and $date->day_id($custom_epoch)
# ------------------------------------------------
sub year {
    my ( $self, $t ) = @_;
    return $self->get_date($t)->{year} if defined $t;
    return $self->{year} // ( ( ref $self && $self->{date} ) ? $self->{date}->{year} : (localtime)[5] + 1900 );
}

sub month {
    my ( $self, $t ) = @_;
    return $self->get_date($t)->{month} if defined $t;
    return $self->{month} // ( ( ref $self && $self->{date} ) ? $self->{date}->{month} : sprintf( "%02d", (localtime)[4] + 1 ) );
}

sub day {
    my ( $self, $t ) = @_;
    return $self->get_date($t)->{day} if defined $t;
    return $self->{day} // ( ( ref $self && $self->{date} ) ? $self->{date}->{day} : sprintf( "%02d", (localtime)[3] ) );
}

sub hour {
    my ( $self, $t ) = @_;
    return $self->get_date($t)->{hour} if defined $t;
    return $self->{hour} // ( ( ref $self && $self->{date} ) ? $self->{date}->{hour} : sprintf( "%02d", (localtime)[2] ) );
}

sub minute {
    my ( $self, $t ) = @_;
    return $self->get_date($t)->{minute} if defined $t;
    return $self->{minute} // ( ( ref $self && $self->{date} ) ? $self->{date}->{minute} : sprintf( "%02d", (localtime)[1] ) );
}

sub second {
    my ( $self, $t ) = @_;
    return $self->get_date($t)->{second} if defined $t;
    return $self->{second} // ( ( ref $self && $self->{date} ) ? $self->{date}->{second} : sprintf( "%02d", (localtime)[0] ) );
}

sub month_id {
    my ( $self, $t ) = @_;
    return $self->get_date($t)->{month_id} if defined $t;
    return $self->{month_id} // ( ( ref $self && $self->{date} ) ? $self->{date}->{month_id} : $self->year . $self->month );
}

sub day_id {
    my ( $self, $t ) = @_;
    return $self->get_date($t)->{day_id} if defined $t;
    return $self->{day_id} // ( ( ref $self && $self->{date} ) ? $self->{date}->{day_id} : $self->month_id . $self->day );
}

sub hour_id {
    my ( $self, $t ) = @_;
    return $self->get_date($t)->{hour_id} if defined $t;
    return $self->{hour_id} // ( ( ref $self && $self->{date} ) ? $self->{date}->{hour_id} : $self->day_id . $self->hour );
}

sub minute_id {
    my ( $self, $t ) = @_;
    return $self->get_date($t)->{minute_id} if defined $t;
    return $self->{minute_id} // ( ( ref $self && $self->{date} ) ? $self->{date}->{minute_id} : $self->hour_id . $self->minute );
}

sub second_id {
    my ( $self, $t ) = @_;
    return $self->get_date($t)->{second_id} if defined $t;
    return $self->{second_id} // ( ( ref $self && $self->{date} ) ? $self->{date}->{second_id} : $self->minute_id . $self->second );
}

sub str {
    my ( $self, $t ) = @_;
    return $self->get_date($t)->{str} if defined $t;
    return $self->{str} // ( ( ref $self && $self->{date} ) ? $self->{date}->{str} : ( $self->short . " - " . $self->only_time ) );
}

sub short {
    my ( $self, $t ) = @_;
    return $self->get_date($t)->{short} if defined $t;
    return $self->{short} // ( ( ref $self && $self->{date} ) ? $self->{date}->{short} : ( $self->day . "/" . $self->month . "/" . $self->year ) );
}

sub only_time {
    my ( $self, $t ) = @_;
    return $self->get_date($t)->{only_time} if defined $t;
    return $self->{only_time} // ( ( ref $self && $self->{date} ) ? $self->{date}->{only_time} : ( $self->hour . ":" . $self->minute . ":" . $self->second ) );
}

sub epoch {
    my ($self) = @_;
    return $self->{time} // ( ( ref $self && $self->{date} ) ? $self->{date}->{time} : time() );
}

sub monthname {
    my ( $self, $t ) = @_;
    return $self->get_date($t)->{monthname} if defined $t;
    return $self->{monthname} // ( ( ref $self && $self->{date} ) ? $self->{date}->{monthname} : undef );
}

sub dayname {
    my ( $self, $t ) = @_;
    return $self->get_date($t)->{dayname} if defined $t;
    return $self->{dayname} // ( ( ref $self && $self->{date} ) ? $self->{date}->{dayname} : undef );
}

sub year_dir {
    my ( $self, $t ) = @_;
    return $self->get_date($t)->{year_dir} if defined $t;
    return $self->{year_dir} // ( ( ref $self && $self->{date} ) ? $self->{date}->{year_dir} : $self->year );
}

# ------------------------------------------------
# Converts date string to numeric date ID (YYYYMMDDHHMMSS)
# ------------------------------------------------
sub str2dateid {
    my ( $self, $datestr ) = @_;
    return unless $datestr;

    my ( $day_id, $hour,  $dateid );
    my ( $day,  $month, $year );

    # DD/MM/YYYY or DD.MM.YYYY format
    if ( $datestr =~ /([0-9]{1,2})[\.\/]([0-9]{1,2})[\.\/]([0-9]{4})/ ) {
        ( $day, $month, $year ) = ( $1, $2, $3 );
    }

    # YYYY-MM-DD format
    elsif ( $datestr =~ /([0-9]{4})\-([0-9]{1,2})\-([0-9]{1,2})/ ) {
        ( $day, $month, $year ) = ( $3, $2, $1 );
    }

    # Already numeric date ID format
    elsif ( $datestr =~ /^(?:[0-9]{14}|[0-9]{12}|[0-9]{8})$/ ) {
        $day_id = $datestr;
    }

    if ( $day && $month && $year ) {
        $day   = sprintf "%02d", $day;
        $month = sprintf "%02d", $month;
        $day_id  = $year . $month . $day;
    }

    # Parse time component if present
    if ( $datestr =~ /([0-9]{1,2}):([0-9]{1,2})(:([0-9]{2}))?/ ) {
        my ( $hor, $min, $sec ) = ( $1, $2, $4 );
        $hor  = sprintf "%02d", $hor;
        $min  = sprintf "%02d", $min;
        $sec  = sprintf "%02d", ( $sec // 0 );
        $hour = $hor . $min . $sec;
    }

    $dateid = ( $day_id // '' ) . ( $hour // '' );
    return $dateid;
}

# ------------------------------------------------
# Converts numeric date ID into human-readable string
# ------------------------------------------------
sub dateid2str {
    my ( $self, $dateid ) = @_;
    return unless $dateid;

    # secondid (14 digits)
    if ( $dateid =~
        /^([0-9]{4})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})/ )
    {
        $dateid = "$3/$2/$1 - $4:$5:$6";
    }

    # minuteid (12 digits)
    elsif ( $dateid =~ /^([0-9]{4})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})/ ) {
        $dateid = "$3/$2/$1 - $4:$5";
    }

    # dayid (8 digits)
    elsif ( $dateid =~ /^([0-9]{4})([0-9]{2})([0-9]{2})/ ) {
        $dateid = "$3/$2/$1";
    }

    # monthid (6 digits)
    elsif ( $dateid =~ /^([0-9]{4})([0-9]{2})/ ) {
        my $year  = $1;
        my $month = $2 - 1;    # 0-indexed

        # Fallback to default months if array missing
        my $months_ref = $self->{months};
        $dateid = "$months_ref->[$month] $year";
    }

    return $dateid;
}

# ------------------------------------------------
# Format timestamp string for emails/HTTP headers
# ------------------------------------------------
sub time2str {
    my ( $self, $time ) = @_;
    $time //= time();

    eval { require HTTP::Date; };
    if ($@) {

        # Basic fallback string format if HTTP::Date is missing
        my $d = $self->get_date($time);
        return $d->{str};
    }
    return HTTP::Date::time2str($time);
}

# ------------------------------------------------
# Lists array of day IDs between two date boundaries
# ------------------------------------------------
sub day_range {
    my ( $self, $start, $end ) = @_;
    return unless $start && $end;

    my ( $start_year, $start_month, $start_day ) =
      ( $start =~ /([0-9]{4})([0-9]{2})([0-9]{2})/ );
    my ( $end_year, $end_month, $end_day ) =
      ( $end =~ /([0-9]{4})([0-9]{2})([0-9]{2})/ );

    return unless $start_year && $end_year;

    my @days;

    # If years differ, divide range into yearly sub-calculations
    if ( $start_year != $end_year ) {
        my @calcs    = ( [ $start, $start_year . "1231" ] );
        my $mid_year = $start_year + 1;
        while ( $mid_year < $end_year ) {
            push @calcs, [ $mid_year . "0101", $mid_year . "1231" ];
            $mid_year++;
        }
        push @calcs, [ $end_year . "0101", $end ];

        foreach my $calc (@calcs) {
            push @days, $self->day_range(@$calc);
        }
    }
    else {
        # Days count table per month
        my @months = (
            [ ( 1 .. 31 ) ],
            [ ( 1 .. 28 ) ],
            [ ( 1 .. 31 ) ],
            [ ( 1 .. 30 ) ],
            [ ( 1 .. 31 ) ],
            [ ( 1 .. 30 ) ],
            [ ( 1 .. 31 ) ],
            [ ( 1 .. 31 ) ],
            [ ( 1 .. 30 ) ],
            [ ( 1 .. 31 ) ],
            [ ( 1 .. 30 ) ],
            [ ( 1 .. 31 ) ]
        );

        # Gregorian calendar leap year check
        my $is_leap = ( ( $start_year % 4 == 0 && $start_year % 100 != 0 )
              || ( $start_year % 400 == 0 ) );
        if ($is_leap) {
            push @{ $months[1] }, 29;
        }

        for ( my $i = 0 ; $i < @months ; $i++ ) {
            my $month = $i + 1;
            $month = sprintf "%02d", $month;

            foreach my $day ( @{ $months[$i] } ) {
                $day = sprintf "%02d", $day;
                my $dayid = $start_year . $month . $day;

                next if $dayid < $start;
                last if $dayid > $end;     # Stop iteration once end boundary exceeded
                push @days, $dayid;
            }
        }
    }
    return @days;
}

# ------------------------------------------------
# Calculates ISO week number for given date ID
# ------------------------------------------------
sub dateid2week {
    my ( $self, $dateid ) = @_;

    my $daytime;
    my ( $y, $m, $d, $h, $min, $s ) = ( 0, 0, 0, 0, 0, 0 );

    # secondid
    if ( $dateid =~
        /^([0-9]{4})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})/ )
    {
        ( $y, $m, $d, $h, $min, $s ) = ( $1, $2, $3, $4, $5, $6 );
    }

    # minuteid
    elsif ( $dateid =~ /^([0-9]{4})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})/ ) {
        ( $y, $m, $d, $h, $min ) = ( $1, $2, $3, $4, $5 );
    }

    # dayid
    elsif ( $dateid =~ /^([0-9]{4})([0-9]{2})([0-9]{2})/ ) {
        ( $y, $m, $d ) = ( $1, $2, $3 );
    }
    else {
        return;
    }

    # Convert to epoch time using Time::Local
    eval { $daytime = timelocal( $s, $min, $h, $d, ( $m - 1 ), $y ); };
    return if $@;

    my ( $wday, $yday ) = ( localtime($daytime) )[ 6, 7 ];
    my $days  = ( $yday - $wday ) / 7;
    my $yweek = ( $days =~ /([0-9]+)\./ ) ? ( $1 + 2 ) : ( $days + 1 );

    return wantarray ? ( $yweek, $wday, $yday ) : $yweek;
}

# ------------------------------------------------
# Calculates new date string based on offset string (e.g. 2D, 1M, 1Y)
# ------------------------------------------------
sub offset2date {
    my ( $self, $string ) = @_;

    my $ls = ( $string =~ /^\-/ )       ? -1 : 1;
    my $dd = ( $string =~ /([0-9]+)D/ ) ? $1 : 0;
    my $mm = ( $string =~ /([0-9]+)M/ ) ? $1 : 0;
    my $yy = ( $string =~ /([0-9]+)Y/ ) ? $1 : 0;

    # Unit durations in seconds
    my $unit = {};
    $unit->{hour}  = 60 * 60;
    $unit->{day}   = 60 * 60 * 24;
    $unit->{week}  = 60 * 60 * 24 * 7;
    $unit->{month} = 60 * 60 * 24 * 30;     # Approximate
    $unit->{year}  = 60 * 60 * 24 * 365;

    my $all_diff =
      $ls *
      ( ( $dd * $unit->{day} ) +
          ( $mm * $unit->{month} ) +
          ( $yy * $unit->{year} ) );

    my ( $second, $minute, $hour, $day, $month, $year, $dnumber ) =
      ( localtime( time() + $all_diff ) )[ 0, 1, 2, 3, 4, 5, 6 ];

    $year  += 1900;
    $month += 1;

    $month = sprintf "%02d", $month;
    $day   = sprintf "%02d", $day;

    return $year . $month . $day;
}

# ------------------------------------------------
# Returns number of days per month for specified year offset
# ------------------------------------------------
sub MonthDaysInYear {
    my ( $self, $year_offset ) = @_;
    $year_offset //= 0;

    my $hour = 60 * 60;
    my $day  = 24 * $hour;

    # Approximate year offset calculation
    my $yy_time = ( ( $day * 365 ) + ( $hour * 6 ) ) * $year_offset;

    my ( $yy_month, $yy_year ) = ( localtime( time() + $yy_time ) )[ 4, 5 ];

    my @MonthDays = ( 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 );

    # Gregorian leap year check
    my $full_year = $yy_year + 1900;
    if (   ( $full_year % 4 == 0 && $full_year % 100 != 0 )
        || ( $full_year % 400 == 0 ) )
    {
        $MonthDays[1] = 29;
    }

    return ( $yy_month, @MonthDays );
}

1;

__END__

=head1 NAME

AmberDB::Date - Date manipulation, chronological ID generation, range calculation, and formatting utility

=head1 SYNOPSIS

  # 1. Direct usage via AmberDB instance ($adb inherits AmberDB::Date):
  my $today_id   = $adb->day_id;                   # "20260828"
  my $now_sec_id = $adb->second_id;                # "20260828143015"
  my $date_id    = $adb->str2dateid('2026-08-28'); # "20260828"
  my $human_str  = $adb->dateid2str('20260828');   # "28/08/2026"
  my @days       = $adb->day_range('20260101', '20260131');
  my $past_id    = $adb->offset2date('-7D');       # Date ID 7 days ago

  # 2. Standalone usage:
  use AmberDB::Date;
  my $date = AmberDB::Date->new();
  my $curr_day = $date->day_id;

=head1 DESCRIPTION

C<AmberDB::Date> provides methods for date parsing, compact chronological date ID conversions (fixed-width numeric format C<YYYYMMDDHHMMSS>), range calculations, relative offset dates (e.g. C<"-2D">, C<"1M">), ISO week numbers, and localized date string formatting.

B<Inheritance Note:> C<AmberDB> inherits from C<AmberDB::Date> via C<use parent>. All methods and timestamp accessors documented below can be invoked directly on any C<$adb> instance (e.g. C<$adb-E<gt>day_id>), as well as on standalone C<AmberDB::Date> objects.

=head1 CONSTRUCTOR

=head2 new([%options | $hashref])

Creates and returns a new C<AmberDB::Date> instance initialized with the current timestamp (or a custom timestamp passed via C<time =E<gt> $epoch>).

  my $date = AmberDB::Date->new();
  my $custom_date = AmberDB::Date->new(time => 1700000000);

=head1 DATE ACCESSORS (GETTERS)

All accessor methods return the formatted component for the instance's active timestamp. Optionally, passing an explicit Unix timestamp (C<$epoch>) calculates the value for that specific time on the fly.

=head2 day_id([$epoch])

Returns the 8-digit numeric date ID (C<YYYYMMDD>).

  my $id = $adb->day_id; # e.g. "20260828"

=head2 second_id([$epoch])

Returns the 14-digit full timestamp ID (C<YYYYMMDDHHMMSS>).

  my $id = $adb->second_id; # e.g. "20260828143015"

=head2 minute_id([$epoch]) / hour_id([$epoch]) / month_id([$epoch])

Returns the corresponding numeric ID:

=over 4

=item * C<month_id>: 6 digits (C<YYYYMM>)

=item * C<hour_id>: 10 digits (C<YYYYMMDDHH>)

=item * C<minute_id>: 12 digits (C<YYYYMMDDHHMM>)

=back

=head2 year([$epoch]) / month([$epoch]) / day([$epoch])

Returns 4-digit year, 2-digit zero-padded month (C<01..12>), or 2-digit day (C<01..31>).

=head2 hour([$epoch]) / minute([$epoch]) / second([$epoch])

Returns 2-digit zero-padded hour (C<00..23>), minute (C<00..59>), or second (C<00..59>).

=head2 str([$epoch]) / short([$epoch]) / only_time([$epoch])

=over 4

=item * C<short>: Returns C<"DD/MM/YYYY"> format.

=item * C<only_time>: Returns C<"HH:MM:SS"> format.

=item * C<str>: Returns combined C<"DD/MM/YYYY - HH:MM:SS"> format.

=back

=head2 epoch()

Returns the underlying Unix epoch timestamp (integer seconds).

=head2 monthname([$epoch]) / dayname([$epoch])

Returns the localized full month name (e.g. C<"January">, C<"August">) or day name (e.g. C<"Friday">, C<"Monday">).

=head1 METHODS

=head2 get_date([$timestamp])

Generates and returns a blessed C<AmberDB::Date> hash containing all parsed date components (year, month, day, hour, minute, second, daynumber, monthname, dayname, IDs, and formatted strings).

  my $d = $adb->get_date(time());
  print $d->{day_id}, " - ", $d->{monthname};

=head2 str2dateid($datestr)

Parses human-readable date strings (e.g. C<"28/08/2026">, C<"2026-08-28">, C<"28.08.2026 14:30">) into a compact numeric date ID (C<YYYYMMDD> or C<YYYYMMDDHHMMSS>).

  my $id = $adb->str2dateid("2026-08-28");          # "20260828"
  my $id = $adb->str2dateid("28/08/2026 14:30:00"); # "20260828143000"

=head2 dateid2str($dateid)

Converts a numeric date ID back into a formatted human-readable string based on its digit length:

=over 4

=item * 14 digits (C<YYYYMMDDHHMMSS>) -E<gt> C<"DD/MM/YYYY - HH:MM:SS">

=item * 12 digits (C<YYYYMMDDHHMM>) -E<gt> C<"DD/MM/YYYY - HH:MM">

=item * 8 digits (C<YYYYMMDD>) -E<gt> C<"DD/MM/YYYY">

=item * 6 digits (C<YYYYMM>) -E<gt> C<"MonthName YYYY">

=back

  my $str = $adb->dateid2str("20260828");         # "28/08/2026"
  my $str = $adb->dateid2str("20260828143015");   # "28/08/2026 - 14:30:15"

=head2 time2str([$timestamp])

Formats a Unix epoch timestamp into an HTTP / RFC 1123 compliant date string suitable for HTTP headers and email timestamps.

  my $http_date = $adb->time2str(time());
  # => "Fri, 28 Aug 2026 11:30:00 GMT"

=head2 day_range($start_dateid, $end_dateid)

Generates a chronological list of 8-digit date IDs (C<YYYYMMDD>) between C<$start_dateid> and C<$end_dateid> inclusive, handling leap years and multi-year spans accurately.

  my @days = $adb->day_range("20260226", "20260302");
  # => ("20260226", "20260227", "20260228", "20260301", "20260302")

=head2 dateid2week($dateid)

Calculates the ISO 8601 week number and day index for a given date ID. In list context, returns C<($week_number, $weekday_index, $day_of_year)>.

  my $week = $adb->dateid2week("20260828"); # e.g. 35

=head2 offset2date($offset_string)

Calculates a new 8-digit date ID (C<YYYYMMDD>) relative to the current timestamp using offset syntax (e.g. C<"-2D"> for 2 days ago, C<"10D"> for 10 days later, C<"1M"> for 1 month later, C<"-1Y"> for 1 year ago).

  my $yesterday = $adb->offset2date("-1D");
  my $next_week = $adb->offset2date("7D");

=head2 MonthDaysInYear([$year_offset])

Returns the 0-indexed month index and a 12-element list containing the number of days in each month for the specified year offset (default is current year, C<0>). Handles leap years.

  my ($current_mon, @days_in_months) = $adb->MonthDaysInYear();
  # @days_in_months = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)

=head1 AUTHOR

Maruf Cetin <marufcetin@gmail.com>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2008-2026 Maruf Cetin.

This library is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0.

=cut
