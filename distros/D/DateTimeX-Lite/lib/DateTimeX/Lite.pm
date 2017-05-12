package DateTimeX::Lite;
use strict;
use warnings;
use 5.008;
use constant +{
    INFINITY        =>      (9 ** 9 ** 9),
    NEG_INFINITY    => -1 * (9 ** 9 ** 9),
    SECONDS_PER_DAY => 86400,
    MAX_NANOSECONDS => 1_000_000_000,  # 1E9 = almost 32 bits
    LOCALE_SKIP     => $ENV{DATETIMEX_LITE_LOCALE_SKIP} ? 1 : 0,
};

use constant NAN    => INFINITY - INFINITY;

use Carp ();
use DateTimeX::Lite::Duration;
use DateTimeX::Lite::Infinite;
use DateTimeX::Lite::TimeZone;
use DateTimeX::Lite::LeapSecond;
use DateTimeX::Lite::Util;
use Scalar::Util qw(blessed);

BEGIN {
    if (LOCALE_SKIP) {
        warn "We're skipping locale handling. You shouldn't be doing this unless you're generating locale data";
    } else {
        require DateTimeX::Lite::Locale;
    }
}
our $VERSION = '0.00004';

BEGIN {
    my @local_c_comp = qw(year month day hour minute second quarter);
    foreach my $comp (@local_c_comp) {
        no strict 'refs';
        *{$comp} = sub { $_[0]->{local_c}{$comp} };
    }
}

our $DefaultLocale = 'en_US';

sub import {
    my $class = shift;
    foreach my $component (@_) {
        eval "require DateTimeX::Lite::$component";
        die "DateTimeX::Lite failed to load $component component: $@" if $@;
    }
}

sub utc_rd_values { @{ $_[0] }{ 'utc_rd_days', 'utc_rd_secs', 'rd_nanosecs' } }
sub local_rd_values { @{ $_[0] }{ 'local_rd_days', 'local_rd_secs', 'rd_nanosecs' } }

# NOTE: no nanoseconds, no leap seconds
sub utc_rd_as_seconds   { ( $_[0]->{utc_rd_days} * SECONDS_PER_DAY ) + $_[0]->{utc_rd_secs} }

# NOTE: no nanoseconds, no leap seconds
sub local_rd_as_seconds { ( $_[0]->{local_rd_days} * SECONDS_PER_DAY ) + $_[0]->{local_rd_secs} }

# RD 1 is JD 1,721,424.5 - a simple offset
sub jd
{
    my $self = shift;

    my $jd = $self->{utc_rd_days} + 1_721_424.5;

    my $day_length = DateTimeX::Lite::LeapSecond::day_length( $self->{utc_rd_days} );

    return ( $jd +
             ( $self->{utc_rd_secs} / $day_length )  +
             ( $self->{rd_nanosecs} / $day_length / MAX_NANOSECONDS )
           );
}

sub mjd { $_[0]->jd - 2_400_000.5 }

sub clone { bless { %{ $_[0] } }, ref $_[0] }

sub to_datetime {
    eval {
        require DateTime;
    };
    if ($@) {
        Carp::croak("Could not load DateTime: $@");
    }
    return DateTime->from_object(object => $_[0]);
}

sub set_time_zone {
    my ( $self, $tz ) = @_;

    # This is a bit of a hack but it works because time zone objects
    # are singletons, and if it doesn't work all we lose is a little
    # bit of speed.
    return $self if $self->{tz} eq $tz;

    my $was_floating = $self->{tz}->is_floating;

    $self->{tz} = ref $tz ? $tz : DateTimeX::Lite::TimeZone->load( name => $tz );

    $self->_handle_offset_modifier( $self->second, 1 );

    # if it either was or now is floating (but not both)
    if ( $self->{tz}->is_floating xor $was_floating )
    {
        $self->_calc_utc_rd;
    }
    elsif ( ! $was_floating )
    {
        $self->_calc_local_rd;
    }

    return $self;
}


sub new {
    my ($class, %p) = @_;

    # give default values, first...
    {
        my %spec = (
            day => { default => 1, range => [1, 31] },
            month => { default => 1, range => [1, 12] },
            year => {default => 1},
            hour => {default => 0, range => [0, 23]},
            minute => {default => 0, range => [0, 59]},
            second => {default => 0, range => [0, 61]},
            nanosecond => {default => 0, range => [0,undef]}
        );

        while (my ($key, $spec) = each %spec) {
            my $default = $spec->{default};
            $p{$key} = $default unless defined $p{$key};

            if (my $range = $spec->{range}) {
                my $v = $p{$key};
                if ( (defined $range->[0] && $v < $range->[0]) ||
                     (defined $range->[1] && $v > $range->[1]) ) {
                    Carp::croak(qq|The '$key' parameter ("$p{$key}") to DateTimeX::Lite::new did not pass the range test|); # hmm, almost
                }
            }
        }
    }
    my $day        = $p{day};
    my $month      = $p{month};
    my $year       = $p{year};
    my $hour       = $p{hour};
    my $minute     = $p{minute};
    my $second     = $p{second};
    my $nanosecond = $p{nanosecond};

    if ($day > DateTimeX::Lite::Util::month_length($year, $month)) {
        Carp::croak("Invalid day of month (day = $day - month = $month - year = $year\n");
    }

    my $self = bless {}, $class;

    my $locale = delete $p{language} || delete $p{locale};
    $locale = $DefaultLocale unless defined $locale;
    my $time_zone = $p{time_zone} || 'floating';

    $self->{offset_modifier} = 0; 

    # XXX This only happens when we're generating the locales
    if (! LOCALE_SKIP) {
        $self->{locale} = blessed $locale ?
            $locale : DateTimeX::Lite::Locale->load($locale);
    }

    $self->{tz} = blessed $time_zone ?
        $time_zone : DateTimeX::Lite::TimeZone->load(name => $time_zone);
    $self->{local_rd_days} = DateTimeX::Lite::Util::ymd2rd($year, $month, $day);
    $self->{local_rd_secs} = DateTimeX::Lite::Util::time_as_seconds($hour, $minute, $second);
    $self->{offfset_modifier} = 0;
    $self->{rd_nanosecs} = $nanosecond;
    $self->{formatter} = $p{formatter};

    DateTimeX::Lite::Util::normalize_nanoseconds($self->{local_rd_secs}, $self->{rd_nanosecs});

    $self->{utc_year} = $year + 1;
    $self->_calc_utc_rd;
    $self->_handle_offset_modifier($second);
    $self->_calc_local_rd;

    if ($second > 59) {
        if ($self->{tz}->is_floating || $self->{utc_rd_secs} - SECONDS_PER_DAY + 1 < $second - 59) {
            Carp::croak("Invalid second value ($second)\n");
        }
    }

    return $self;
}

sub _calc_utc_rd {
    my $self = shift;
    delete $self->{utc_c};

    my $time_zone = $self->{tz};
    if ($time_zone->is_utc || $time_zone->is_floating) {
        $self->{utc_rd_days} = $self->{local_rd_days};
        $self->{utc_rd_secs} = $self->{local_rd_secs};
    } else {
        my $offset = $self->_offset_for_local_datetime;
        $offset += $self->{offset_modifier};

        $self->{utc_rd_days} = $self->{local_rd_days};
        $self->{utc_rd_secs} = $self->{local_rd_secs} - $offset;
    }

    # We account for leap seconds in the new() method and nowhere else
    # except date math.
    DateTimeX::Lite::Util::normalize_tai_seconds( $self->{utc_rd_days}, $self->{utc_rd_secs} );
}

sub _handle_offset_modifier
{
    my $self = shift;

    $self->{offset_modifier} = 0;

    return if $self->{tz}->is_floating;

    my $second = shift;
    my $utc_is_valid = shift;

    my $utc_rd_days = $self->{utc_rd_days};

    my $offset = $utc_is_valid ? $self->offset : $self->_offset_for_local_datetime;

    if ( $offset >= 0
         && $self->{local_rd_secs} >= $offset
       )
    {
        if ( $second < 60 && $offset > 0 )
        {
            $self->{offset_modifier} =
                DateTimeX::Lite::LeapSecond::day_length( $utc_rd_days - 1 ) - SECONDS_PER_DAY;

            $self->{local_rd_secs} += $self->{offset_modifier};
        }
        elsif ( $second == 60
                &&
                ( ( $self->{local_rd_secs} == $offset
                    && $offset > 0 )
                  ||
                  ( $offset == 0
                    && $self->{local_rd_secs} > 86399 ) )
              )
        {
            my $mod = DateTimeX::Lite::LeapSecond::day_length( $utc_rd_days - 1 ) - SECONDS_PER_DAY;

            unless ( $mod == 0 )
            {
                $self->{utc_rd_secs} -= $mod;

                DateTimeX::Lite::Util::normalize_seconds($self);
            }
        }
    }
    elsif ( $offset < 0
            && $self->{local_rd_secs} >= SECONDS_PER_DAY + $offset )
    {
        if ( $second < 60 )
        {
            $self->{offset_modifier} =
                DateTimeX::Lite::LeapSecond::day_length( $utc_rd_days - 1 ) - SECONDS_PER_DAY;
            $self->{local_rd_secs} += $self->{offset_modifier};
        }
        elsif ( $second == 60 && $self->{local_rd_secs} == SECONDS_PER_DAY + $offset )
        {
            my $mod = DateTimeX::Lite::LeapSecond::day_length( $utc_rd_days - 1 ) - SECONDS_PER_DAY;

            unless ( $mod == 0 )
            {
                $self->{utc_rd_secs} -= $mod;

                DateTimeX::Lite::Util::normalize_seconds($self);
            }
        }
    }
}

sub _calc_local_rd
{
    my $self = shift;

    delete $self->{local_c};

    # We must short circuit for UTC times or else we could end up with
    # loops between DateTime.pm and DateTimeX::Lite::TimeZone
    if ( $self->{tz}->is_utc || $self->{tz}->is_floating )
    {
        $self->{local_rd_days} = $self->{utc_rd_days};
        $self->{local_rd_secs} = $self->{utc_rd_secs};
    }
    else
    {        my $offset = $self->offset;

        $self->{local_rd_days} = $self->{utc_rd_days};
        $self->{local_rd_secs} = $self->{utc_rd_secs} + $offset;

        # intentionally ignore leap seconds here
        DateTimeX::Lite::Util::normalize_tai_seconds( $self->{local_rd_days}, $self->{local_rd_secs} );

        $self->{local_rd_secs} += $self->{offset_modifier};
    }

    $self->_calc_local_components;
}

sub _calc_local_components
{
    my $self = shift;

    @{ $self->{local_c} }{ qw( year month day day_of_week
                               day_of_year quarter day_of_quarter) } =
        DateTimeX::Lite::Util::rd2ymd( $self->{local_rd_days}, 1 );

    @{ $self->{local_c} }{ qw( hour minute second ) } =
        DateTimeX::Lite::Util::seconds_as_components
            ( $self->{local_rd_secs}, $self->{utc_rd_secs}, $self->{offset_modifier} );
}

sub from_object {
    my ($class, %p) = @_;
    my $object = delete $p{object};

    my ( $rd_days, $rd_secs, $rd_nanosecs ) = $object->utc_rd_values;

    # A kludge because until all calendars are updated to return all
    # three values, $rd_nanosecs could be undef
    $rd_nanosecs ||= 0;

    # This is a big hack to let _seconds_as_components operate naively
    # on the given value.  If the object _is_ on a leap second, we'll
    # add that to the generated seconds value later.
    my $leap_seconds = 0;
    if ( $object->can('time_zone') && ! $object->time_zone->is_floating
         && $rd_secs > 86399 && $rd_secs <= DateTimeX::Lite::LeapSecond::day_length($rd_days) )
    {
        $leap_seconds = $rd_secs - 86399;
        $rd_secs -= $leap_seconds;
    }

    my %args;
    @args{ qw( year month day ) } = DateTimeX::Lite::Util::rd2ymd($rd_days);
    @args{ qw( hour minute second ) } =
        DateTimeX::Lite::Util::seconds_as_components($rd_secs);
    $args{nanosecond} = $rd_nanosecs;

    $args{second} += $leap_seconds;

    my $new = $class->new( %p, %args, time_zone => 'UTC' );

    if ( $object->can('time_zone') )
    {
        $new->set_time_zone( $object->time_zone );
    }
    else
    {
        $new->set_time_zone( 'floating' );
    }

    return $new;
}


sub last_day_of_month {
    my ($class, %p) = @_;
    if ($p{month} > 12 || $p{month} < 1) {
        Carp::croak(qq|The 'month' parameter ("$p{month}") to DateTimeX::Lite::last_day_of_month did not pass the 'is between 1 and 12' callback|);
    }

    return $class->new(%p, day => DateTimeX::Lite::Util::month_length($p{year}, $p{month}));
}

sub offset                     { $_[0]->{tz}->offset_for_datetime( $_[0] ) }
sub _offset_for_local_datetime { $_[0]->{tz}->offset_for_local_datetime( $_[0] ) }


sub nanosecond { $_[0]->{rd_nanosecs} }
sub fractional_second { $_[0]->second + $_[0]->nanosecond / MAX_NANOSECONDS }

sub millisecond { _round( $_[0]->{rd_nanosecs} / 1000000 ) }

sub microsecond { _round( $_[0]->{rd_nanosecs} / 1000 ) }

sub _round
{
    my $val = shift;
    my $int = int $val;

    return $val - $int >= 0.5 ? $int + 1 : $int;
}

sub ce_year { 
    my $year = $_[0]->{local_c}{year};
    return $year <= 0 ? $year - 1 : $year
}

sub era_name { $_[0]->{locale}->era_wide->[ $_[0]->_era_index() ] }

sub era_abbr { $_[0]->{locale}->era_abbreviated->[ $_[0]->_era_index() ] }

sub _era_index { $_[0]->{local_c}{year} <= 0 ? 0 : 1 }

sub christian_era { $_[0]->ce_year > 0 ? 'AD' : 'BC' }
sub secular_era   { $_[0]->ce_year > 0 ? 'CE' : 'BCE' }

sub year_with_era { (abs $_[0]->ce_year) . $_[0]->era_abbr }
sub year_with_christian_era { (abs $_[0]->ce_year) . $_[0]->christian_era }
sub year_with_secular_era   { (abs $_[0]->ce_year) . $_[0]->secular_era }


sub month_name { $_[0]->{locale}->month_format_wide->[ $_[0]->month() - 1] }

sub month_abbr { $_[0]->{locale}->month_format_abbreviated->[ $_[0]->month() - 1] }

sub weekday_of_month { use integer; ( ( $_[0]->day - 1 ) / 7 ) + 1 }

sub quarter_name { $_[0]->{locale}->quarter_format_wide->[ $_[0]->quarter() - 1] }
sub quarter_abbr { $_[0]->{locale}->quarter_format_abbreviated->[ $_[0]->quarter() - 1] }

sub day_of_week { $_[0]->{local_c}{day_of_week} }

sub local_day_of_week
{
    my $self = shift;

    my $day = $self->day_of_week();

    my $local_first_day = $self->{locale}->first_day_of_week();

    my $d = ( ( 8 - $local_first_day ) + $day ) % 7;

    return $d == 0 ? 7 : $d;
}


sub hour_1 { $_[0]->{local_c}{hour} == 0 ? 24 : $_[0]->{local_c}{hour} }

sub hour_12   { my $h = $_[0]->hour % 12; return $h ? $h : 12 }

sub day_name { $_[0]->{locale}->day_format_wide->[ $_[0]->day_of_week() - 1 ] }

sub day_abbr { $_[0]->{locale}->day_format_abbreviated->[ $_[0]->day_of_week() - 1] }

sub day_of_quarter { $_[0]->{local_c}{day_of_quarter} }

sub day_of_year { $_[0]->{local_c}{day_of_year} }

sub am_or_pm { $_[0]->{locale}->am_pm_abbreviated->[ $_[0]->hour() < 12 ? 0 : 1 ] }

# ISO says that the first week of a year is the first week containing
# a Thursday.  Extending that says that the first week of the month is
# the first week containing a Thursday.  ICU agrees.
sub week_of_month
{
    my $self = shift;

    my $thu  = $self->day + 4 - $self->day_of_week;
    return int( ( $thu + 6 ) / 7 );
}

sub week
{
    my $self = shift;

    unless ( defined $self->{local_c}{week_year} )
    {
        # This algorithm was taken from Date::Calc's DateCalc.c file
        my $jan_one_dow_m1 =
            ( ( DateTimeX::Lite::Util::ymd2rd( $self->year, 1, 1 ) + 6 ) % 7 );

        $self->{local_c}{week_number} =
            int( ( ( $self->day_of_year - 1 ) + $jan_one_dow_m1 ) / 7 );
        $self->{local_c}{week_number}++ if $jan_one_dow_m1 < 4;

        if ( $self->{local_c}{week_number} == 0 )
        {
            $self->{local_c}{week_year} = $self->year - 1;
            $self->{local_c}{week_number} =
                $self->_weeks_in_year( $self->{local_c}{week_year} );
        }
        elsif ( $self->{local_c}{week_number} == 53 &&
                $self->_weeks_in_year( $self->year ) == 52 )
        {
            $self->{local_c}{week_number} = 1;
            $self->{local_c}{week_year} = $self->year + 1;
        }
        else
        {
            $self->{local_c}{week_year} = $self->year;
        }
    }

    return @{ $self->{local_c} }{ 'week_year', 'week_number' }
}

# Also from DateCalc.c
sub _weeks_in_year
{
    my $self = shift;
    my $year = shift;

    my $dow = DateTimeX::Lite::Util::ymd2rd($year, 1, 1) % 7;
 
    # Tears starting with a Thursday and leap years starting with a Wednesday
    # have 53 weeks.
    return ( $dow == 4 || ( $dow == 3 && DateTimeX::Lite::Util::is_leap_year( $year ) ) )
        ? 53
        : 52;
}

sub week_year   { ($_[0]->week)[0] }
sub week_number { ($_[0]->week)[1] }

sub ymd
{
    my ( $self, $sep ) = @_;
    $sep = '-' unless defined $sep;

    return sprintf( "%0.4d%s%0.2d%s%0.2d",
                    $self->year, $sep,
                    $self->{local_c}{month}, $sep,
                    $self->{local_c}{day} );
}

sub mdy
{
    my ( $self, $sep ) = @_;
    $sep = '-' unless defined $sep;

    return sprintf( "%0.2d%s%0.2d%s%0.4d",
                    $self->{local_c}{month}, $sep,
                    $self->{local_c}{day}, $sep,
                    $self->year );
}

sub dmy
{
    my ( $self, $sep ) = @_;
    $sep = '-' unless defined $sep;

    return sprintf( "%0.2d%s%0.2d%s%0.4d",
                    $self->{local_c}{day}, $sep,
                    $self->{local_c}{month}, $sep,
                    $self->year );
}

sub hms
{
    my ( $self, $sep ) = @_;
    $sep = ':' unless defined $sep;

    return sprintf( "%0.2d%s%0.2d%s%0.2d",
                    $self->{local_c}{hour}, $sep,
                    $self->{local_c}{minute}, $sep,
                    $self->{local_c}{second} );
}

sub iso8601 { join 'T', $_[0]->ymd('-'), $_[0]->hms(':') }

sub is_leap_year { DateTimeX::Lite::Util::is_leap_year( $_[0]->year ) }

sub time_zone { $_[0]->{tz} }


sub is_dst { $_[0]->{tz}->is_dst_for_datetime( $_[0] ) }

sub time_zone_long_name  { $_[0]->{tz}->name }
sub time_zone_short_name { $_[0]->{tz}->short_name_for_datetime( $_[0] ) }

sub locale { $_[0]->{locale} }

# This method exists for the benefit of internal methods which create
# a new object based on the current object, like set() and truncate().
sub _new_from_self
{
    my $self = shift;

    my %old = map { $_ => $self->$_() }
        qw( year month day hour minute second nanosecond
            locale time_zone );
    $old{formatter} = $self->formatter()
        if defined $self->formatter();

    return (ref $self)->new( %old, @_ );
}

sub set
{
    my ($self, %p) = @_;

    my $new_dt = $self->_new_from_self(%p);

    %$self = %$new_dt;

    return $self;
}

sub set_year   { $_[0]->set( year => $_[1] ) }
sub set_month  { $_[0]->set( month => $_[1] ) }
sub set_day    { $_[0]->set( day => $_[1] ) }
sub set_hour   { $_[0]->set( hour => $_[1] ) }
sub set_minute { $_[0]->set( minute => $_[1] ) }
sub set_second { $_[0]->set( second => $_[1] ) }
sub set_nanosecond { $_[0]->set( nanosecond => $_[1] ) }

sub set_locale { $_[0]->set( locale => $_[1] ) }

sub set_formatter { $_[0]->{formatter} = $_[1] }
 

sub formatter { $_[0]->{formatter} }

    sub from_epoch
    {
        my ($class, %p) = @_;

        my %args;

        # Because epoch may come from Time::HiRes
        my $fraction = $p{epoch} - int( $p{epoch} );
        $args{nanosecond} = int( $fraction * MAX_NANOSECONDS )
            if $fraction;

        # Note, for very large negative values this may give a
        # blatantly wrong answer.
        @args{ qw( second minute hour day month year ) } =
            ( gmtime( int delete $p{epoch} ) )[ 0..5 ];
        $args{year} += 1900;
        $args{month}++;

        my $self = $class->new( %p, %args, time_zone => 'UTC' );

        $self->set_time_zone( $p{time_zone} ) if exists $p{time_zone};

        return $self;
    }

sub _utc_ymd
{
    my $self = shift;

    $self->_calc_utc_components unless exists $self->{utc_c}{year};

    return @{ $self->{utc_c} }{ qw( year month day ) };
}

sub _utc_hms
{
    my $self = shift;

    $self->_calc_utc_components unless exists $self->{utc_c}{hour};

    return @{ $self->{utc_c} }{ qw( hour minute second ) };
}

# use scalar time in case someone's loaded Time::Piece
sub now { shift->from_epoch( epoch => (scalar CORE::time), @_ ) }

sub today { shift->now(@_)->truncate( to => 'day' ) }

my %TruncateDefault = (
    month  => 1,
    day    => 1,
    hour   => 0,
    minute => 0,
    second => 0,
    nanosecond => 0,
);

sub truncate {
    my ($self, %p) = @_;

    my %new;
    if ( $p{to} eq 'week' )
    {
        my $day_diff = $self->day_of_week - 1;

        if ($day_diff)
        {
            $self->add( days => -1 * $day_diff );
        }

        return $self->truncate( to => 'day' );
    }
    else
    {
        my $truncate;
        foreach my $f ( qw( year month day hour minute second nanosecond ) ) {
            $new{$f} = $truncate ? $TruncateDefault{$f} : $self->$f();

            $truncate = 1 if $p{to} eq $f;
        }
    }

    my $new_dt = $self->_new_from_self(%new);

    %$self = %$new_dt;

    return $self;
}


sub epoch
{
    my $self = shift;

    return $self->{utc_c}{epoch}
        if exists $self->{utc_c}{epoch};

    require Time::Local;
    my ( $year, $month, $day ) = $self->_utc_ymd;
    my @hms = $self->_utc_hms;

    $self->{utc_c}{epoch} =
        Time::Local::timegm_nocheck( ( reverse @hms ),
                        $day,
                        $month - 1,
                        $year,
                      );

    return $self->{utc_c}{epoch};
}

sub hires_epoch
{
    my $self = shift;

    my $epoch = $self->epoch;

    return undef unless defined $epoch;

    my $nano = $self->{rd_nanosecs} / MAX_NANOSECONDS;

    return $epoch + $nano;
}

sub is_finite { 1 }
sub is_infinite { 0 }

# added for benefit of DateTime::TimeZone
sub utc_year { $_[0]->{utc_year} }


sub leap_seconds
{
    my $self = shift;

    return 0 if $self->{tz}->is_floating;

    return DateTimeX::Lite::LeapSecond::leap_seconds( $self->{utc_rd_days} );
}

sub _calc_utc_components
{
    my $self = shift;

    die "Cannot get UTC components before UTC RD has been calculated\n"
        unless defined $self->{utc_rd_days};

    @{ $self->{utc_c} }{ qw( year month day ) } =
        DateTimeX::Lite::Util::rd2ymd( $self->{utc_rd_days} );

    @{ $self->{utc_c} }{ qw( hour minute second ) } =
        DateTimeX::Lite::Util::seconds_as_components( $self->{utc_rd_secs} );
}

sub compare
{
    shift->_compare( @_, 0 );
}

sub compare_ignore_floating
{
    shift->_compare( @_, 1 );
}

sub _compare
{
    my ( $class, $dt1, $dt2, $consistent ) = ref $_[0] ? ( undef, @_ ) : @_;

    return undef unless defined $dt2;

    if ( ! ref $dt2 && ( $dt2 == INFINITY || $dt2 == NEG_INFINITY ) )
    {
        return $dt1->{utc_rd_days} <=> $dt2;
    }

    unless ( (blessed $dt1 && $dt1->can( 'utc_rd_values' )) && 
        (blessed $dt2 && $dt2->can( 'utc_rd_values' ) ))
    {
        my $dt1_string = overload::StrVal($dt1);
        my $dt2_string = overload::StrVal($dt2);

        Carp::croak( "A DateTimeX::Lite object can only be compared to"
                     . " another DateTimeX::Lite object ($dt1_string, $dt2_string)." );
    }

    if ( ! $consistent &&
         (blessed $dt1 && $dt1->can( 'time_zone' )) &&
         (blessed $dt2 && $dt2->can( 'time_zone' ))
       )
    {
        my $is_floating1 = $dt1->time_zone->is_floating;
        my $is_floating2 = $dt2->time_zone->is_floating;

        if ( $is_floating1 && ! $is_floating2 )
        {
            $dt1 = $dt1->clone->set_time_zone( $dt2->time_zone );
        }
        elsif ( $is_floating2 && ! $is_floating1 )
        {
            $dt2 = $dt2->clone->set_time_zone( $dt1->time_zone );
        }
    }

    my @dt1_components = $dt1->utc_rd_values;
    my @dt2_components = $dt2->utc_rd_values;

    foreach my $i ( 0..2 )
    {
        return $dt1_components[$i] <=> $dt2_components[$i]
            if $dt1_components[$i] != $dt2_components[$i]
    }

    return 0;
}

sub from_day_of_year
{
    my ($class, %p) = @_;

    my $is_leap_year = DateTimeX::Lite::Util::is_leap_year( $p{year} );

    Carp::croak( "$p{year} is not a leap year.\n" )
        if $p{day_of_year} == 366 && ! $is_leap_year;

    my $month = 1;
    my $day = delete $p{day_of_year};

    while ( $month <= 12 && $day > DateTimeX::Lite::Util::month_length( $p{year}, $month ) )
    {
        $day -= DateTimeX::Lite::Util::month_length( $p{year}, $month );
        $month++;
    }

    return $class->new( %p,
                          month => $month,
                          day   => $day,
                        );
}


1;

__END__

=head1 NAME

DateTimeX::Lite - A Low Calorie DateTime

=head1 SYNOPSIS

    use DateTimeX::Lite;

    my $dt = DateTimeX::Lite->new(year => 2008, month => 12, day => 1);
    $dt->year;
    $dt->month;
    $dt->day;
    $dt->hour;
    $dt->minuute;
    $dt->second;

    # Arithmetic doesn't come with DateTimeX::Lite by default
    use DateTimeX::Lite qw(Arithmetic);
    $dt->add( DateTimeX::Lite::Duration->new(days => 5) );

    # Strftime doesn't come with DateTimeX::Lite by default
    use DateTimeX::Lite qw(Strftime);
    $dt->strftime('%Y %m %d');

    # ZeroBase accessors doesn't come with DateTimeX::Lite by default
    use DateTimeX::Lite qw(ZeroBase);
    $dt->month_0;

    # Overloading is disabled by default
    use DateTimeX::Lite qw(Overload);

    print "the date is $dt\n";
    if ($dt1 < $dt2) {
        print "dt1 is less than dt2\n";
    }

=head1 DESCRIPTION

This is a lightweight version of DateTime.pm, which requires no XS, and aims to be light(er) than the original, for a given B<subset> of the problems that the original DateTime.pm can solve.

The idea is to encourage light users to use DateTime compatible API, while adapting to realistic environments (such as people without access to C compilers, people on rental servers who can't install modules, people who needs to convince pointy-haired bosses that they're not sacrificing performance), so later when they find engineering freedom, they can switch back to the more reliable DateTime.pm.

Please make no mistake: B<THIS IS NOT A REPLACEMENT FOR Datetime.pm>. I will try to keep up with DateTime.pm, but DateTime.pm is the referece implementation. This is just stripped down version.

Please also note that internally, this module is a complete rip-off of the original DateTime.pm module. The author simply copied and pasted about 90% of the code, tweaked it and repackaged it. All credits go to the original DateTime.pm's authors.

=head1 RATIONALE

The aim of this module is as follows:

=over 4

=item (1) Target those who do not need the full feature of DateTime.pm.

In particular, I'm thinking of people who wants to simply grab a date, maybe do some date arithmetic on it, and print the year/month/date or store those values somewhere. These people do not use advanced date logic, sets, or calendars.

=item (2) Target the newbies who are afraid of XS code. 

Let's face it, /we/ the developers know how to deal with XS. But we can't expect that out of everybody. DateTime.pm doesn't require XS, but to get decent performance it's sort of a requirement. We do our best to get there without XS.

=item (3) Get better performance.

In particular,

  * Reduce the amount of memory consumed, and
  * Reduce the time it takes to load the module

Again, /we/ know why it's worth it to use DateTime. Some people don't, and will judge DateTime (and worse yet, maybe perl itself) unusable simply because it takes more memory to load DateTime. We want to avoid that.

=item (4) Make it easy to install on rental servers.

This also ties into (2). No XS code, becuse compilers may not be available, or people simply wouldn't know how to use compilers.

If we can simply copy the DateTimeX::Lite files over via FTP instead of 'make install', that's even better.

=item (5) Bundle everything in one distribution, including timezones and locales

This goes with (4). We like time zones and locales. However, we would like to limit the number of dependencies. It would be even better if we can choose which locales and timezones to install.

=item (6) Be compatible enough with DateTime.pm

While given all of the above, we would like to leave a way for users to easily (relatively speaking) switch back to DateTime.pm, when they so choose to. Hence, the API needs to remain mostly compatible.

=back

=head1 COMPATIBILITY WITH DateTime.pm

As stated elsewhere, DateTimeX::Lite does not intend to be a drop-in replacement for DateTime.pm. 

You should not expect other DateTime::* modules (such as Format and Calendar) to work with it. It might, but we won't guarantee it. 

We feel that if you use the extended features of the DateTime family, you should be using the original DateTime.pm

=head2 NOTABLE DIFFERENCES

DateTimeX::Lite tries to be as compatible as possible with DateTime.pm, but there are a few places it deliberately changed from DateTime.pm. Some notable differences from DateTime.pm are as follows

=over 4

=item Non-essential methods are loaded on demand

For example, A lot of times you don't even need to do date time arithmetic. These methods are separated out onto a different file, so you need to load it on demand. To load, include "Arithmetic" in the use line.

    use DateTimeX::Lite qw(Arithmetic);

Similarly, strftime() imposes a lot of code on DateTime. So if ymd(), iso8601() or the like is sufficient, it would be best not to load it. To load, include "Strftime" in the use line.

    use DateTimeX::Lite qw(Strftime);

A lot of methods in original DateTime have aliases. They are not loaded unless
you ask for them:

    use DateTimeX::Lite qw(Aliases);

Zero-based accessors are also taken out of the core DateTimeX::Lite code.

    use DateTimeX::Lite qw(ZeroBase);

Overload operators are also taken out. If you want to automatically compare or
stringify two DateTimeX::Lite objects using standard operators, you need to
include Overload:

    use DateTimeX::Lite qw(Overload);

And finally, if you want every because you're using pretty much all of
DateTime.pm but want to migrate, you can do

    use DateTimeX::Lite qw(All);

=item DateTimeX::Lite::TimeZone and DateTimeX::Lite::Locale

DateTimeX::Lite::TimeZone and DateTimeX::Lite::Locale have big changes from their original counterparts.

First, you do NOT call new() on these objects (unless this is something you explicitly want to do). Instead, you need to call load(). So if you were mucking with DateTimeX::Lite::TimeZone and DateTime::Locale, you need to find out every occurance of

    DateTime::TimeZone->new( name => 'Asia/Tokyo' );

and change them to

    DateTimeX::Lite::TimeZone->load( name => 'Asia/Tokyo' );

Singletons are okay, they serve a particular purpose. But besides being a memory hog of relative low benefit, I've had claims from users questioning the benefit of timezones and locales when they saw that those two distributions installed hundreds of singleton classes.

With this version, the objects are just regular objects, and the exact definition for each timezone/locale is stored in data files. (TODO: They can be located anywhere DateTimeX::Lite can find them)

TODO: We want to make it easy to pick and choose which locales/timezones to be available -- DateTime::TimeZone and Locale comes with the full-set, and normally we don't need this feature. For example, I only use Asia/Tokyo and UTC time zones for my dayjob. When we ask casual users to install a datetime package, we do not want to overwhelm then with 100+ timezones and locales.

=back

=head1 METHODS

=head2 am_or_pm

=head2 ce_year

=head2 clone

=head2 compare

=head2 compare_ignore_floating

=head2 date

=head2 datetime

=head2 day

=head2 day_abbr

=head2 day_name

=head2 day_of_month

=head2 day_of_quarter

=head2 day_of_week

=head2 day_of_year

=head2 dmy

=head2 doq

=head2 dow

=head2 doy

=head2 epoch

=head2 formatter

=head2 fractional_second

=head2 from_day_of_year

=head2 from_epoch

=head2 from_object

=head2 hires_epoch

=head2 hms

=head2 hour

=head2 hour_1

=head2 hour_12

=head2 is_dst

=head2 is_finite

=head2 is_infinite

=head2 is_leap_year

=head2 iso8601

=head2 jd

=head2 last_day_of_month

=head2 leap_seconds

=head2 local_day_of_week

=head2 local_rd_as_seconds

=head2 local_rd_values

=head2 locale

=head2 mday

=head2 mdy

=head2 microsecond

=head2 millisecond

=head2 min

=head2 minute

=head2 mjd

=head2 mon

=head2 month

=head2 month_abbr

=head2 month_name

=head2 nanosecond

=head2 new

=head2 now

=head2 offset

=head2 quarter

=head2 quarter_abbr

=head2 quarter_name

=head2 sec

=head2 second

=head2 set

=head2 set_day

=head2 set_formatter

=head2 set_hour

=head2 set_locale

=head2 set_minute

=head2 set_month

=head2 set_nanosecond

=head2 set_second

=head2 set_time_zone

=head2 set_year

=head2 time

=head2 time_zone

=head2 time_zone_long_name

=head2 time_zone_short_name

=head2 to_datetime

=head2 today

=head2 truncate

=head2 utc_rd_as_seconds

=head2 utc_rd_values

=head2 wday

=head2 week

=head2 week_number

=head2 week_of_month

=head2 week_year

=head2 weekday_of_month

=head2 year

=head2 ymd

=head1 TODO

=over 4

=item Make it possible to separate locales and time zones

=item Create an easy way to install new locales or time zones.

=item The files for timezones/locales may not be safe-to-load. need to check

=back

=head1 AUTHOR

=over 4

=item Original DateTime.pm:

Copyright (c) 2003-2008 David Rolsky C<< <autarch@urth.org> >>. All rights reserved.  
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=item DateTimeX::Lite tweaks

Daisuke Maki C<< <daisuke@endeworks.jp> >>
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=back

=cut