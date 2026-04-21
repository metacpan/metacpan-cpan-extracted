##----------------------------------------------------------------------------
## Lightweight DateTime Alternative - ~/lib/DateTime/Lite.pm
## Version v0.6.3
## Copyright(c) 2026 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2026/04/03
## Modified 2026/04/20
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package DateTime::Lite;
BEGIN
{
    use v5.10.1;
    use strict;
    use warnings;
    use warnings::register;
    use vars qw(
        $VERSION $AUTOLOAD $AUTOLOAD_SUBS $ERROR $FATAL_EXCEPTIONS $IsPurePerl
        @MonthLengths @LeapYearMonthLengths
        @QuarterLengths @LeapYearQuarterLengths
    );
    use Config;
    use DateTime::Locale::FromCLDR;
    use POSIX qw( floor fmod );
    use Scalar::Util ();
    use Wanted;
    use overload (
        fallback => 1,
        '<=>'    => '_compare_overload',
        'cmp'    => '_string_compare_overload',
        q{""}    => 'stringify',
        bool     => sub{1},
        '-'      => '_subtract_overload',
        '+'      => '_add_overload',
        'eq'     => '_string_equals_overload',
        'ne'     => '_string_not_equals_overload',
    );

    our $VERSION = 'v0.6.3';

    @MonthLengths = ( 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 );
    @LeapYearMonthLengths = @MonthLengths;
    $LeapYearMonthLengths[1]++;

    @QuarterLengths = ( 90, 91, 92, 92 );
    @LeapYearQuarterLengths = @QuarterLengths;
    $LeapYearQuarterLengths[0]++;
};

use strict;
use warnings;

# NOTE: Load XS; fall back to pure-Perl implementations if unavailable.
{
    my $loaded = 0;
    unless( $ENV{PERL_DATETIME_LITE_PP} )
    {
        local $@;
        eval
        {
            require XSLoader;
            XSLoader::load(
                __PACKAGE__,
                exists( $DateTime::Lite::{VERSION} ) && ${ $DateTime::Lite::{VERSION} }
                    ? ${ $DateTime::Lite::{VERSION} }
                    : 42
            );
            $loaded     = 1;
            $IsPurePerl = 0;
        };
        if( $@ )
        {
            die( $@ ) if( $@ && $@ !~ /object version|loadable object/ );
        }
    }
    unless( $loaded )
    {
        require DateTime::Lite::PP;
        $IsPurePerl = 1;
    }
}

require DateTime::Lite::Duration;
require DateTime::Lite::TimeZone;

# NOTE: Constants
sub INFINITY        () { 100**100**100**100 }
sub MAX_NANOSECONDS () { 1_000_000_000 }
sub NEG_INFINITY    () { -1 * ( 100**100**100**100 ) }
sub NAN             () { INFINITY - INFINITY }
sub SECONDS_PER_DAY () { 86400 }

# NOTE: subroutine pre-declaration
# for sub in `perl -ln -E 'say "$1" if( /^sub (\w+)[[:blank:]\v]*(?:\{|\Z|[[:blank:]\v]*:[[:blank:]\v]*lvalue)/ )' ./lib/DateTime/Lite.pm | LC_COLLATE=C sort -uV`; do echo "sub $sub;"; done
sub AUTOLOAD;
sub DESTROY;
sub FREEZE;
sub STORABLE_freeze;
sub STORABLE_thaw;
sub THAW;
sub TO_JSON;
sub add;
sub add_duration;
sub am_or_pm;
sub ce_year;
sub christian_era;
sub compare;
sub compare_ignore_floating;
sub datetime;
sub day;
sub day_abbr;
sub day_name;
sub day_of_month_0;
sub day_of_quarter;
sub day_of_quarter_0;
sub day_of_week;
sub day_of_week_0;
sub day_of_year;
sub day_of_year_0;
sub delta_days;
sub delta_md;
sub delta_ms;
sub dmy;
sub end_of;
sub epoch;
sub era_abbr;
sub era_name;
sub error;
sub fatal;
sub formatter;
sub fractional_second;
sub from_day_of_year;
sub from_epoch;
sub from_object;
sub hires_epoch;
sub hms;
sub hour;
sub hour_1;
sub hour_12;
sub hour_12_0;
sub iso8601;
sub is_between;
sub is_dst;
sub is_finite;
sub is_infinite;
sub is_last_day_of_month;
sub is_last_day_of_quarter;
sub is_last_day_of_year;
sub is_leap_year;
sub jd;
sub last_day_of_month;
sub leap_seconds;
sub locale;
sub local_day_of_week;
sub local_rd_as_seconds;
sub local_rd_values;
sub mdy;
sub microsecond;
sub millisecond;
sub minute;
sub mjd;
sub month;
sub month_0;
sub month_abbr;
sub month_length;
sub month_name;
sub nanosecond;
sub new;
sub now;
sub offset;
sub pass_error;
sub quarter;
sub quarter_0;
sub quarter_abbr;
sub quarter_length;
sub quarter_name;
sub rfc3339;
sub second;
sub secular_era;
sub set;
sub set_day;
sub set_formatter;
sub set_hour;
sub set_locale;
sub set_minute;
sub set_month;
sub set_nanosecond;
sub set_second;
sub set_time_zone;
sub set_year;
sub start_of;
sub stringify;
sub subtract;
sub subtract_datetime;
sub subtract_datetime_absolute;
sub subtract_duration;
sub time_zone;
sub time_zone_long_name;
sub time_zone_short_name;
sub today;
sub truncate;
sub utc_rd_as_seconds;
sub utc_rd_values;
sub utc_year;
sub week;
sub weekday_of_month;
sub week_number;
sub week_of_month;
sub week_year;
sub year;
sub year_length;
sub year_with_christian_era;
sub year_with_era;
sub year_with_secular_era;
sub ymd;
sub _add_duration;
sub _add_overload;
sub _adjust_for_positive_difference;
sub _autoload_subs;
sub _calc_local_components;
sub _calc_local_rd;
sub _calc_utc_rd;
sub _compare;
sub _compare_overload;
sub _core_time;
sub _default_time_zone;
sub _duration_object_from_args;
sub _era_index;
sub _format_nanosecs;
sub _handle_offset_modifier;
sub _is_integer;
sub _maybe_future_dst_warning;
sub _month_length;
sub _new;
sub _new_from_self;
sub _normalize_seconds;
sub _offset_for_local_datetime;
sub _resolve_time_zone;
sub _set_get_prop;
sub _set_locale;
sub _string_compare_overload;
sub _string_equals_overload;
sub _string_not_equals_overload;
sub _subtract_overload;
sub _weeks_in_year;
sub _week_values;

# NOTE: Class-level default locale management
{
    my $DefaultLocale;

    sub DefaultLocale
    {
        my $class = shift( @_ );
        if( @_ )
        {
            my $lang = shift( @_ );
            $DefaultLocale = DateTime::Locale::FromCLDR->new( $lang ) ||
                die( DateTime::Locale::FromCLDR->error );
        }
        return( $DefaultLocale );
    }
}

__PACKAGE__->DefaultLocale( 'en-US' );

# NOTE: Constructor
sub new
{
    my $this  = shift( @_ );
    my $class = ref( $this ) || $this;
    my %p     = @_;

    # Required
    unless( exists( $p{year} ) )
    {
        return( $class->error( "Parameter 'year' is required." ) );
    }
    # Validate and apply defaults
    $p{month}      //= 1;
    $p{day}        //= 1;
    $p{hour}       //= 0;
    $p{minute}     //= 0;
    $p{second}     //= 0;
    $p{nanosecond} //= 0;

    return( $class->error( sprintf( "Invalid month value (%s).", $p{month} ) ) )
        unless( _is_integer( $p{month} ) && $p{month} >= 1 && $p{month} <= 12 );

    return( $class->error( sprintf( "Invalid day value (%s).", $p{day} ) ) )
        unless( _is_integer( $p{day} ) && $p{day} >= 1 && $p{day} <= 31 );

    return( $class->error( sprintf( "Invalid hour value (%s).", $p{hour} ) ) )
        unless( _is_integer( $p{hour} ) && $p{hour} >= 0 && $p{hour} <= 23 );

    return( $class->error( sprintf( "Invalid minute value (%s).", $p{minute} ) ) )
        unless( _is_integer( $p{minute} ) && $p{minute} >= 0 && $p{minute} <= 59 );

    return( $class->error( sprintf( "Invalid second value (%s).", $p{second} ) ) )
        unless( _is_integer( $p{second} ) && $p{second} >= 0 && $p{second} <= 61 );

    return( $class->error( sprintf( "Invalid nanosecond value (%s).", $p{nanosecond} ) ) )
        unless( _is_integer( $p{nanosecond} ) && $p{nanosecond} >= 0 && $p{nanosecond} < MAX_NANOSECONDS );

    if( $p{day} > 28 )
    {
        my $max_day = $class->_month_length( $p{year}, $p{month} );
        return( $class->error(
            sprintf( "Invalid day of month (day = %d, month = %d, year = %d).", $p{day}, $p{month}, $p{year} )
        ) ) if( $p{day} > $max_day );
    }

    return( $class->_new( %p ) );
}

sub _new
{
    my $this  = shift( @_ );
    my $class = ref( $this ) || $this;
    my %p     = @_;

    return( $class->error( "Constructor called with reference, expected a package name." ) ) if( ref( $class ) );

    $p{month}      //= 1;
    $p{day}        //= 1;
    $p{hour}       //= 0;
    $p{minute}     //= 0;
    $p{second}     //= 0;
    $p{nanosecond} //= 0;
    # NOTE: time_zone is intentionally NOT defaulted here anymore; we need to
    # resolve any BCP47 -u-tz- extension from the locale first.
    # $p{time_zone}  //= $class->_default_time_zone;
    # Should errors be fatal?
    $p{fatal}      //= ( $FATAL_EXCEPTIONS // 0 );

    my $self = bless( {}, $class );

    $p{time_zone} = $class->_resolve_time_zone( $p{locale}, $p{time_zone} ) //
        $class->_default_time_zone;

    # _set_locale now returns the DateTime::Locale::FromCLDR object
    my $cldr = $self->_set_locale( $p{locale} ) || return( $class->pass_error );

    $self->{tz} = ref( $p{time_zone} )
        ? $p{time_zone}
        : DateTime::Lite::TimeZone->new( name => $p{time_zone} );
    return( $class->pass_error( DateTime::Lite::TimeZone->error ) )
        unless( $self->{tz} );

    $self->{local_rd_days}   = $class->_ymd2rd( @p{ qw( year month day ) } );
    $self->{local_rd_secs}   = $class->_time_as_seconds( @p{ qw( hour minute second ) } );
    $self->{offset_modifier} = 0;
    $self->{rd_nanosecs}     = $p{nanosecond};
    $self->{formatter}       = $p{formatter};

    $self->_normalize_nanoseconds(
        $self->{local_rd_secs},
        $self->{rd_nanosecs},
    );

    # Bootstrap utc_year so TZ offset calculation has a rough year to work with.
    $self->{utc_year} = $p{year} + 1;

    $self->_maybe_future_dst_warning( $p{year}, $p{time_zone} );
    $self->_calc_utc_rd;
    $self->_handle_offset_modifier( $p{second} );
    $self->_calc_local_rd;

    if( $p{second} > 59 )
    {
        if( $self->{tz}->is_floating ||
            ( $self->{utc_rd_secs} - 86399 < $p{second} - 59 ) )
        {
            return( $self->error( "Invalid second value ($p{second})." ) );
        }
    }

    return( $self );
}

# NOTE: Arithmetic
sub add
{
    my $self = shift( @_ );
    return( $self->add_duration( $self->_duration_object_from_args( @_ ) ) );
}

sub add_duration
{
    my $self = shift( @_ );
    my $dur  = shift( @_ );

    unless( Scalar::Util::blessed( $dur ) && $dur->isa( $self->duration_class ) )
    {
        return( $self->error( "Argument to add_duration() must be a " . $self->duration_class . " object." ) );
    }

    return( $self ) if( $dur->is_zero );

    my %deltas = $dur->deltas;

    # Handle infinite durations
    foreach my $val ( values( %deltas ) )
    {
        my $inf;
        if( $val == INFINITY )
        {
            require DateTime::Lite::Infinite;
            $inf = DateTime::Lite::Infinite::Future->new;
        }
        elsif( $val == NEG_INFINITY )
        {
            require DateTime::Lite::Infinite;
            $inf = DateTime::Lite::Infinite::Past->new;
        }
        if( $inf )
        {
            %$self = %$inf;
            bless( $self, ref( $inf ) );
            return( $self );
        }
    }

    return( $self ) if( $self->is_infinite );

    my %orig = %{ $self };
    my $ok   = eval { $self->_add_duration( $dur ); 1 };
    unless( $ok )
    {
        my $err = $@;
        %{ $self } = %orig;
        die( $err );
    }
    return( $self );
}

# NOTE: sub am_or_pm is autoloaded

# NOTE: sub ce_year is autoloaded

# NOTE: sub christian_era is autoloaded

# NOTE: sub clone is implemented in the XS code in DateTime-Lite.xs

# NOTE: Comparison
sub compare { return( shift->_compare( @_, 0 ) ); }

sub compare_ignore_floating
{
    my $class = ref( $_[0] ) ? undef : shift( @_ );
    shift->_compare( @_, 1 );
}

sub datetime
{
    my $self = shift( @_ );
    my $sep  = shift( @_ ) // 'T';
    return( join( $sep, $self->ymd( '-' ), $self->hms( ':' ) ) );
}

sub day { return( $_[0]->{local_c}->{day} ) }

{
    no warnings 'once';
    *day_of_month = \&day;
}

sub day_abbr
{
    my $self = shift( @_ );
    return( $self->{locale}->day_format_abbreviated->[ $self->day_of_week_0 ] );
}

sub day_name
{
    my $self = shift( @_ );
    return( $self->{locale}->day_format_wide->[ $self->day_of_week_0 ] );
}

# NOTE: sub day_of_month_0 is autoloaded

# NOTE: sub day_of_quarter is autoloaded

# NOTE: sub day_of_quarter_0 is autoloaded

sub day_of_week   { return( shift->{local_c}->{day_of_week} ); }

# NOTE: sub day_of_week_0 is autoloaded

sub day_of_year   { return( shift->{local_c}->{day_of_year} ); }

# NOTE: sub day_of_year_0 is autoloaded

sub delta_days
{
    my $self = shift( @_ );
    my $dt   = shift( @_ );
    my $days = abs( ( $self->local_rd_values )[0] - ( $dt->local_rd_values )[0] );
    return( $self->duration_class->new( days => $days ) );
}

sub delta_md
{
    my $self = shift( @_ );
    my $dt   = shift( @_ );

    my( $smaller, $bigger ) = sort( $self, $dt );

    my( $months, $days ) = $dt->_adjust_for_positive_difference(
        $bigger->year  * 12 + $bigger->month,
        $smaller->year * 12 + $smaller->month,
        $bigger->day,         $smaller->day,
        0, 0,
        0, 0,
        0, 0,
        60,
        $smaller->_month_length( $smaller->year, $smaller->month ),
    );

    return( $self->duration_class->new( months => $months, days => $days ) );
}

sub delta_ms
{
    my $self    = shift( @_ );
    my $dt      = shift( @_ );
    my( $smaller, $greater ) = sort( $self, $dt );

    my $days = int( $greater->jd - $smaller->jd );
    my $dur  = $greater->subtract_datetime( $smaller );

    return( $self->duration_class->new(
        hours   => $dur->hours + ( $days * 24 ),
        minutes => $dur->minutes,
        seconds => $dur->seconds,
    ) );
}

# NOTE: sub dmy is autoloaded

sub duration_class () { 'DateTime::Lite::Duration' }

# See also start_of()
sub end_of
{
    my $self = shift( @_ );
    my $unit = shift( @_ ) ||
        return( $self->error( "Parameter 'unit' is required for end_of()." ) );

    my %valid = map{ $_ => 1 } qw(
        year decade century quarter month week local_week day hour minute second
    );
    unless( $valid{ $unit } )
    {
        return( $self->error( "Invalid unit '$unit' for end_of()." ) );
    }

    # Strategy: move to start_of the next unit, then subtract 1 nanosecond.
    # This correctly handles variable-length units (months, years, etc.)
    # without hardcoding boundary values.
    my %next_unit = (
        second     => [ second     => 1  ],
        minute     => [ minute     => 1  ],
        hour       => [ hour       => 1  ],
        day        => [ day        => 1  ],
        week       => [ week       => 1  ],
        local_week => [ week       => 1  ],
        month      => [ month      => 1  ],
        quarter    => [ month      => 3  ],
        year       => [ year       => 1  ],
        decade     => [ year       => 10 ],
        century    => [ year       => 100],
    );

    # Clone internally, compute, then overwrite self
    my $copy = $self->clone || return( $self->pass_error );
    $copy->start_of( $unit ) || return( $self->pass_error );
    my( $add_unit, $add_val ) = @{$next_unit{ $unit }};
    $copy->add( "${add_unit}s" => $add_val ) || return( $self->pass_error );
    $copy->subtract( nanoseconds => 1 ) || return( $self->pass_error );

    %$self = %$copy;
    return( $self );
}

# NOTE: epoch
sub epoch
{
    my $self = shift( @_ );
    return( $self->{utc_c}->{epoch} ) if( exists( $self->{utc_c}->{epoch} ) );

    if( $IsPurePerl )
    {
        return( $self->{utc_c}->{epoch}
            = ( $self->{utc_rd_days} - 719163 ) * SECONDS_PER_DAY
              + $self->{utc_rd_secs} );
    }
    else
    {
        return( $self->{utc_c}->{epoch}
            = $self->_rd_to_epoch( $self->{utc_rd_days}, $self->{utc_rd_secs} ) );
    }
}

# NOTE: sub era_abbr is autoloaded

# NOTE: sub era_name is autoloaded

# NOTE: Error handling
sub error
{
    my $self = shift( @_ );
    if( @_ )
    {
        require DateTime::Lite::Exception;
        my $msg = join( '', map( ( ref( $_ ) eq 'CODE' ) ? $_->() : $_, @_ ) );
        my $e = DateTime::Lite::Exception->new({
            skip_frames => 1,
            message     => $msg,
        });
        $ERROR = $e;
        $self->{error} = $e if( ref( $self ) );
        if( $self->fatal )
        {
            die( $self->{error} );
        }
        else
        {
            warn( $msg ) if( warnings::enabled() );
            rreturn( DateTime::Lite::NullObject->new ) if( want( 'OBJECT' ) );
            return;
        }
    }
    return( ref( $self ) ? $self->{error} : $ERROR );
}

sub fatal
{
    my $this = shift( @_ );
    if( @_ )
    {
        if( ref( $this ) )
        {
            return( $this->_set_get_prop( 'fatal', @_ ) );
        }
        else
        {
            warn( "Cannot call fatal in mutator mode as a class method." ) if( warnings::enabled() );
        }
    }
    return( ref( $this ) ? $this->_set_get_prop( 'fatal' ) : $FATAL_EXCEPTIONS );
}

# NOTE: format_cldr
# TODO: If the user wants to do CLDR formatting, we should instead load DateTime::Format::Unicode, which does a much better job, because CLDR formatting is not easy. So, we should lazy-load DateTime::Format::Unicode instead
{
    my @cldr_patterns = (
        qr/GGGGG/  => sub{ $_[0]->{locale}->era_narrow->[ $_[0]->_era_index ] },
        qr/GGGG/   => 'era_name',
        qr/G{1,3}/ => 'era_abbr',

        qr/(y{3,5})/ => sub{ $_[0]->_zero_padded_number( $1, $_[0]->year ) },
        qr/yy/        => sub {
            my $year = $_[0]->year;
            my $y2   = length( $year ) > 2 ? substr( $year, -2, 2 ) : $year;
            $y2 *= -1 if( $year < 0 );
            $_[0]->_zero_padded_number( 'yy', $y2 );
        },
        qr/y/    => 'year',
        qr/(u+)/ => sub{ $_[0]->_zero_padded_number( $1, $_[0]->year ) },
        qr/(Y+)/ => sub{ $_[0]->_zero_padded_number( $1, $_[0]->week_year ) },

        qr/QQQQ/  => 'quarter_name',
        qr/QQQ/   => 'quarter_abbr',
        qr/(QQ?)/ => sub{ $_[0]->_zero_padded_number( $1, $_[0]->quarter ) },

        qr/qqqq/ => sub{ $_[0]->{locale}->quarter_stand_alone_wide->[ $_[0]->quarter_0 ] },
        qr/qqq/  => sub{ $_[0]->{locale}->quarter_stand_alone_abbreviated->[ $_[0]->quarter_0 ] },
        qr/(qq?)/ => sub{ $_[0]->_zero_padded_number( $1, $_[0]->quarter ) },

        qr/MMMMM/ => sub{ $_[0]->{locale}->month_format_narrow->[ $_[0]->month_0 ] },
        qr/MMMM/  => 'month_name',
        qr/MMM/   => 'month_abbr',
        qr/(MM?)/ => sub{ $_[0]->_zero_padded_number( $1, $_[0]->month ) },

        qr/LLLLL/ => sub{ $_[0]->{locale}->month_stand_alone_narrow->[ $_[0]->month_0 ] },
        qr/LLLL/  => sub{ $_[0]->{locale}->month_stand_alone_wide->[ $_[0]->month_0 ] },
        qr/LLL/   => sub{ $_[0]->{locale}->month_stand_alone_abbreviated->[ $_[0]->month_0 ] },
        qr/(LL?)/ => sub{ $_[0]->_zero_padded_number( $1, $_[0]->month ) },

        qr/(ww?)/ => sub{ $_[0]->_zero_padded_number( $1, $_[0]->week_number ) },
        qr/W/     => 'week_of_month',

        qr/(dd?)/ => sub{ $_[0]->_zero_padded_number( $1, $_[0]->day_of_month ) },
        qr/(D{1,3})/ => sub{ $_[0]->_zero_padded_number( $1, $_[0]->day_of_year ) },

        qr/F/    => 'weekday_of_month',
        qr/(g+)/ => sub{ $_[0]->_zero_padded_number( $1, $_[0]->mjd ) },

        qr/EEEEE/ => sub{ $_[0]->{locale}->day_format_narrow->[ $_[0]->day_of_week_0 ] },
        qr/EEEE/   => 'day_name',
        qr/E{1,3}/ => 'day_abbr',

        qr/eeeee/ => sub{ $_[0]->{locale}->day_format_narrow->[ $_[0]->day_of_week_0 ] },
        qr/eeee/  => 'day_name',
        qr/eee/   => 'day_abbr',
        qr/(ee?)/ => sub{ $_[0]->_zero_padded_number( $1, $_[0]->local_day_of_week ) },

        qr/ccccc/ => sub{ $_[0]->{locale}->day_stand_alone_narrow->[ $_[0]->day_of_week_0 ] },
        qr/cccc/  => sub{ $_[0]->{locale}->day_stand_alone_wide->[ $_[0]->day_of_week_0 ] },
        qr/ccc/   => sub{ $_[0]->{locale}->day_stand_alone_abbreviated->[ $_[0]->day_of_week_0 ] },
        qr/(cc?)/ => sub{ $_[0]->_zero_padded_number( $1, $_[0]->day_of_week ) },

        qr/a/ => 'am_or_pm',

        qr/(hh?)/ => sub{ $_[0]->_zero_padded_number( $1, $_[0]->hour_12 ) },
        qr/(HH?)/ => sub{ $_[0]->_zero_padded_number( $1, $_[0]->hour ) },
        qr/(KK?)/ => sub{ $_[0]->_zero_padded_number( $1, $_[0]->hour_12_0 ) },
        qr/(kk?)/ => sub{ $_[0]->_zero_padded_number( $1, $_[0]->hour_1 ) },
        qr/(jj?)/ => sub {
            my $h = $_[0]->{locale}->prefers_24_hour_time
                ? $_[0]->hour
                : $_[0]->hour_12;
            $_[0]->_zero_padded_number( $1, $h );
        },

        qr/(mm?)/ => sub{ $_[0]->_zero_padded_number( $1, $_[0]->minute ) },
        qr/(ss?)/ => sub{ $_[0]->_zero_padded_number( $1, $_[0]->second ) },
        qr/(S+)/  => sub{ $_[0]->_format_nanosecs( length( $1 ) ) },
        qr/A+/    => sub{ ( $_[0]->{local_rd_secs} * 1000 ) + $_[0]->millisecond },

        qr/zzzz/   => 'time_zone_long_name',
        qr/z{1,3}/ => 'time_zone_short_name',
        qr/ZZZZZ/  => sub{ DateTime::Lite::TimeZone->offset_as_string( $_[0]->offset, ':' ) },
        qr/ZZZZ/   => sub{ $_[0]->time_zone_short_name . DateTime::Lite::TimeZone->offset_as_string( $_[0]->offset ) },
        qr/Z{1,3}/ => sub{ DateTime::Lite::TimeZone->offset_as_string( $_[0]->offset ) },
        qr/vvvv/   => 'time_zone_long_name',
        qr/v{1,3}/ => 'time_zone_short_name',
        qr/VVVV/   => 'time_zone_long_name',
        qr/V{1,3}/ => 'time_zone_short_name',
    );

    # NOTE: format_cldr()
    sub format_cldr
    {
        if( !scalar( @_ ) )
        {
            die( 'Usage: $dt->format_cldr( $format )' );
        }
        my $self = shift( @_ );
        if( !defined( $self ) || !Scalar::Util::blessed( $self // '' ) )
        {
            die( 'Usage: $dt->format_cldr( $format )' );
        }
        my @p    = @_;

        my @r;
        foreach my $p ( @p )
        {
            $p =~ s/\G
                    (?:
                      '((?:[^']|'')*)'   # quote-escaped text
                      |
                      (([a-zA-Z])\3*)    # pattern token
                      |
                      (.)                # literal character
                    )
                   /
                    defined( $1 )
                    ? $1
                    : defined( $2 )
                    ? $self->_cldr_pattern( $2 )
                    : defined( $4 )
                    ? $4
                    : undef
                   /sgex;

            $p =~ s/''/'/g;

            return( $p ) unless( wantarray );
            push( @r, $p );
        }
        return( @r );
    }

    # NOTE: _cldr_pattern()
    sub _cldr_pattern
    {
        my $self    = shift( @_ );
        my $pattern = shift( @_ );

        for( my $i = 0; $i < @cldr_patterns; $i += 2 )
        {
            if( $pattern =~ /$cldr_patterns[$i]/ )
            {
                my $sub = $cldr_patterns[ $i + 1 ];
                return( ref( $sub ) eq 'CODE' ? $sub->( $self ) : $self->$sub() );
            }
        }
        return( $pattern );
    }

    # NOTE: _zero_padded_number()
    sub _zero_padded_number
    {
        my $self = shift( @_ );
        my $size = length( shift( @_ ) );
        my $val  = shift( @_ );
        return( sprintf( "%0${size}d", $val ) );
    }
}

sub formatter { return( shift->{formatter} ); }

# NOTE: sub fractional_second is autoloaded

# NOTE: Alternative constructors
sub from_day_of_year
{
    my $this  = shift( @_ );
    my $class = ref( $this ) || $this;
    my %p     = @_;

    return( $class->error( "Parameter 'year' is required." ) )
        unless( exists( $p{year} ) );
    return( $class->error( "Parameter 'day_of_year' is required." ) )
        unless( exists( $p{day_of_year} ) );

    if( $p{day_of_year} == 366 && !$class->_is_leap_year( $p{year} ) )
    {
        return( $class->error( "$p{year} is not a leap year." ) );
    }

    my $month = 1;
    my $day   = delete( $p{day_of_year} );

    if( $day > 31 )
    {
        my $length = $class->_month_length( $p{year}, $month );
        while( $day > $length )
        {
            $day    -= $length;
            $month++;
            $length  = $class->_month_length( $p{year}, $month );
        }
    }

    return( $class->_new( %p, month => $month, day => $day ) );
}

sub from_epoch
{
    my $this  = shift( @_ );
    my $class = ref( $this ) || $this;
    my %p;

    if( @_ == 1 && !ref( $_[0] ) )
    {
        $p{epoch} = shift( @_ );
    }
    else
    {
        %p = @_;
    }

    return( $class->error( "Parameter 'epoch' is required." ) )
        unless( exists( $p{epoch} ) );

    return( $class->error( "Parameter 'epoch' must be a number." ) )
        unless( defined( $p{epoch} ) && Scalar::Util::looks_like_number( $p{epoch} ) );

    my %args;
    # Handle non-integer epochs - round to microsecond to avoid NV precision loss
    if( int( $p{epoch} ) != $p{epoch} )
    {
        my $floor  = my $nano = fmod( $p{epoch}, 1.0 );
        my $second = floor( $p{epoch} - $floor );
        if( $nano < 0 )
        {
            $nano += 1;
        }
        $p{epoch}         = $second + floor( $floor - $nano );
        $args{nanosecond} = floor( $nano * 1E6 + 0.5 ) * 1E3;
    }

    @args{ qw( second minute hour day month year ) }
        = ( gmtime( $p{epoch} ) )[ 0 .. 5 ];
    $args{year}  += 1900;
    $args{month} += 1;

    my $self = $class->_new( %p, %args, time_zone => 'UTC' ) || return( $class->pass_error );

    my $target_tz = $class->_resolve_time_zone( $p{locale}, $p{time_zone} );
    $self->_maybe_future_dst_warning( $self->year, $target_tz );
    $self->set_time_zone( $target_tz ) if( defined( $target_tz ) );
    # $self->set_time_zone( $target_tz )
    #     unless( !defined( $target_tz ) || $target_tz eq 'floating' );

    return( $self );
}

sub from_object
{
    my $this   = shift( @_ );
    my $class  = ref( $this ) || $this;
    my %p      = @_;

    my $object = delete( $p{object} );
    return( $class->error( "Parameter 'object' is required." ) )
        unless( defined( $object ) );
    return( $class->error( "Parameter 'object' must be a blessed reference." ) )
        unless( Scalar::Util::blessed( $object ) );

    # Pass through Infinite objects unchanged.
    # Accept both our own and the original DateTime::Infinite hierarchy.
    if( $object->isa( 'DateTime::Lite::Infinite' ) ||
        ( $object->can( 'is_infinite' ) && $object->is_infinite ) )
    {
        return( $object->clone );
    }

    my( $rd_days, $rd_secs, $rd_nanosecs ) = $object->utc_rd_values;
    $rd_nanosecs //= 0;

    # Handle objects that happen to sit on a leap second
    my $leap_seconds = 0;
    if( $object->can( 'time_zone' ) &&
        !$object->time_zone->is_floating &&
        $rd_secs > 86399 &&
        $rd_secs <= $class->_day_length( $rd_days ) )
    {
        $leap_seconds = $rd_secs - 86399;
        $rd_secs     -= $leap_seconds;
    }

    my %args;
    @args{ qw( year month day ) }     = $class->_rd2ymd( $rd_days );
    @args{ qw( hour minute second ) } = $class->_seconds_as_components( $rd_secs );
    $args{nanosecond} = $rd_nanosecs;
    $args{second}    += $leap_seconds;

    # Build in UTC first (the RD values we extracted are UTC-based).
    # Strip any time_zone from %p here. We apply it explicitly below.
    my $target_tz = delete( $p{time_zone} );

    my $new = $class->new( %p, %args, time_zone => 'UTC' ) ||
        return( $class->pass_error );

    # Apply timezone in priority order:
    #   1. Caller-supplied time_zone (from %p), or BCP47 -u-tz- from locale
    #   2. Source object's time_zone (if it has one)
    #   3. Default floating timezone
    my $resolved_tz = $class->_resolve_time_zone( $p{locale}, $target_tz );
    if( defined( $resolved_tz ) )
    {
        $new->set_time_zone( $resolved_tz );
    }
    elsif( $object->can( 'time_zone' ) )
    {
        $new->set_time_zone( $object->time_zone );
    }
    else
    {
        $new->set_time_zone( $class->_default_time_zone );
    }

    return( $new );
}

sub hires_epoch
{
    my $self  = shift( @_ );
    my $epoch = $self->epoch;
    return( undef ) unless( defined( $epoch ) );
    return( $epoch + $self->{rd_nanosecs} / MAX_NANOSECONDS );
}

sub hms
{
    my $self = shift( @_ );
    my $sep  = defined( $_[0] ) ? shift( @_ ) : ':';
    return( sprintf( "%02d%s%02d%s%02d",
        $self->hour, $sep, $self->minute, $sep, $self->second ) );
}

sub hour { return( shift->{local_c}->{hour} ); }

# NOTE: hour_1 is autoloaded

# NOTE: hour_12 is autoloaded

# NOTE: hour_12_0 is autoloaded

sub is_between
{
    my $self  = shift( @_ );
    my $lower = shift( @_ );
    my $upper = shift( @_ );
    return( $self->compare( $lower ) > 0 && $self->compare( $upper ) < 0 );
}

sub is_dst
{
    if( !scalar( @_ ) )
    {
        die( 'Usage: $dt->is_dst' );
    }
    my $self = shift( @_ );
    if( !defined( $self ) || !Scalar::Util::blessed( $self // '' ) )
    {
        die( 'Usage: $dt->is_dst' );
    }
    return( $self->{tz}->is_dst_for_datetime( $self ) );
}

sub is_finite   {1}
sub is_infinite {0}

# NOTE: sub is_last_day_of_month is autoloaded

# NOTE: sub is_last_day_of_quarter is autoloaded

# NOTE: sub is_last_day_of_year is autoloaded

sub is_leap_year
{
    if( !scalar( @_ ) )
    {
        die( 'Usage: $dt->is_dst' );
    }
    my $self = shift( @_ );
    if( !defined( $self ) || !Scalar::Util::blessed( $self // '' ) )
    {
        die( 'Usage: $dt->is_dst' );
    }
    return( $self->_is_leap_year( $self->year ) );
}

sub iso8601 { $_[0]->datetime( 'T' ) }

# NOTE: sub jd is autoloaded

sub last_day_of_month
{
    my $this  = shift( @_ );
    my $class = ref( $this ) || $this;
    my %p     = @_;

    return( $class->error( "Parameter 'year' is required." ) )
        unless( exists( $p{year} ) );
    return( $class->error( "Parameter 'month' is required." ) )
        unless( exists( $p{month} ) );

    my $day = $class->_month_length( $p{year}, $p{month} );
    return( $class->_new( %p, day => $day ) );
}

# NOTE: sub leap_seconds is autoloaded

# NOTE: sub local_day_of_week is autoloaded

sub local_rd_as_seconds
{
    my $self = shift( @_ );
    return( $self->{local_rd_days} * SECONDS_PER_DAY + $self->{local_rd_secs} );
}

sub local_rd_values
{
    my $self = shift( @_ );
    return( $self->{local_rd_days}, $self->{local_rd_secs}, $self->{rd_nanosecs} );
}

sub locale { return( shift->{locale} ) }

# NOTE: sub mdy is autoloaded

# NOTE: sub microsecond is autoloaded

# NOTE: sub millisecond is autoloaded

sub minute { return( shift->{local_c}->{minute} ) }

# NOTE: sub mjd is autoloaded

sub month { return( shift->{local_c}->{month} ) }

{
    no warnings 'once';
    *mon = \&month;
}

# NOTE: sub month_0 is autoloaded

{
    no warnings 'once';
    *mon_0 = \&month_0;
}

sub month_abbr
{
    my $self = shift( @_ );
    return( $self->{locale}->month_format_abbreviated->[ $self->month_0 ] );
}

# NOTE: month_length is autoloaded

sub month_name
{
    my $self = shift( @_ );
    return( $self->{locale}->month_format_wide->[ $self->month_0 ] );
}

sub nanosecond { return( $_[0]->{rd_nanosecs} ) }

sub now
{
    my $class = shift( @_ );
    return( $class->from_epoch( epoch => $class->_core_time, @_ ) );
}

sub offset { $_[0]->{tz}->offset_for_datetime( $_[0] ) }

sub pass_error
{
    my $self = shift( @_ );
    my $pack = ref( $self ) || $self;
    my $opts = {};
    my( $err, $class, $code );
    no strict 'refs';
    if( scalar( @_ ) )
    {
        # Either an hash defining a new error and this will be passed along to error(); or
        # an hash with a single property: { class => 'Some::ExceptionClass' }
        if( scalar( @_ ) == 1 && ref( $_[0] ) eq 'HASH' )
        {
            $opts = $_[0];
        }
        else
        {
            if( scalar( @_ ) > 1 && ref( $_[-1] ) eq 'HASH' )
            {
                $opts = pop( @_ );
            }
            $err = $_[0];
        }
    }
    $err = $opts->{error} if( !defined( $err ) && CORE::exists( $opts->{error} ) && defined( $opts->{error} ) && CORE::length( $opts->{error} ) );
    # We set $class only if the hash provided is a one-element hash and not an error-defining hash
    $class = $opts->{class} if( CORE::exists( $opts->{class} ) && defined( $opts->{class} ) && CORE::length( $opts->{class} ) );
    $code  = $opts->{code} if( CORE::exists( $opts->{code} ) && defined( $opts->{code} ) && CORE::length( $opts->{code} ) );

    # called with no argument, most likely from the same class to pass on an error 
    # set up earlier by another method; or
    # with an hash containing just one argument class => 'Some::ExceptionClass'
    if( !defined( $err ) && ( !scalar( @_ ) || defined( $class ) ) )
    {
        # $error is a previous erro robject
        my $error = ref( $self ) ? $self->{error} : length( ${ $pack . '::ERROR' } ) ? ${ $pack . '::ERROR' } : undef;
        if( !defined( $error ) )
        {
            warn( "No error object provided and no previous error set either! It seems the previous method call returned a simple undef" );
        }
        else
        {
            $err = ( defined( $class ) ? bless( $error => $class ) : $error );
            $err->code( $code ) if( defined( $code ) );
        }
    }
    elsif( defined( $err ) && 
           Scalar::Util::blessed( $err ) && 
           ( scalar( @_ ) == 1 || 
             ( scalar( @_ ) == 2 && defined( $class ) ) 
           ) )
    {
        $self->{error} = ${ $pack . '::ERROR' } = ( defined( $class ) ? bless( $err => $class ) : $err );
        $self->{error}->code( $code ) if( defined( $code ) && $self->{error}->can( 'code' ) );

        if( $self->{fatal} || ( defined( ${"${class}\::FATAL_EXCEPTIONS"} ) && ${"${class}\::FATAL_EXCEPTIONS"} ) )
        {
            die( $self->{error} );
        }
    }
    # If the error provided is not an object, we call error to create one
    else
    {
        return( $self->error( @_ ) );
    }

    if( want( 'OBJECT' ) )
    {
        rreturn( DateTime::Lite::NullObject->new );
    }
    return;
}

sub quarter { $_[0]->{local_c}->{quarter} }

# NOTE: quarter_0 is autoloaded

# NOTE: quarter_abbr is autoloaded

# NOTE: quarter_length is autoloaded

# NOTE: quarter_name is autoloaded

sub rfc3339
{
    my $self = shift( @_ );
    my $str  = $self->datetime( 'T' );
    if( $self->{tz}->is_utc )
    {
        $str .= 'Z';
    }
    else
    {
        $str .= DateTime::Lite::TimeZone->offset_as_string( $self->offset, ':' );
    }
    return( $str );
}

# NOTE: secular_era is autoloaded

sub second { return( shift->{local_c}->{second} ) }

# NOTE: Setters
sub set
{
    my $self = shift( @_ );
    my %p    = @_;

    if( $p{locale} )
    {
        warn( 'You passed a locale to the set() method. Use set_locale() instead.' )
            if( warnings::enabled() );
    }

    my $new_dt = $self->_new_from_self( %p ) ||
        return( $self->pass_error );
    %$self = %$new_dt;
    return( $self );
}

sub set_day        { return( shift->set( day        => @_ ) ); }

sub set_formatter
{
    my $self = shift( @_ );
    $self->{formatter} = shift( @_ );
    return( $self );
}

sub set_hour       { return( shift->set( hour       => @_ ) ); }

sub set_locale
{
    my $self   = shift( @_ );
    my $locale = shift( @_ );
    $self->_set_locale( $locale ) || return( $self->pass_error );
    # If the new locale carries a BCP47 -u-tz- extension and the object is
    # currently in the floating timezone (i.e. no explicit timezone was ever
    # set), infer the timezone from the locale extension.
    if( $self->{tz}->is_floating )
    {
        my $resolved = $self->_resolve_time_zone( $locale, undef );
        $self->set_time_zone( $resolved ) if( defined( $resolved ) );
    }
    return( $self );
}

sub set_minute     { return( shift->set( minute     => @_ ) ); }
sub set_month      { return( shift->set( month      => @_ ) ); }
sub set_nanosecond { return( shift->set( nanosecond => @_ ) ); }
sub set_second     { return( shift->set( second     => @_ ) ); }

sub set_time_zone
{
    my( $self, $tz ) = @_;

    if( ref( $tz ) )
    {
        return( $self ) if( $self->{tz} eq $tz );
    }
    else
    {
        return( $self ) if( $self->{tz}->name eq $tz );
    }

    my $was_floating = $self->{tz}->is_floating;
    my $old_tz       = $self->{tz};
    $self->{tz}      = ref( $tz ) ? $tz : DateTime::Lite::TimeZone->new( name => $tz );
    unless( $self->{tz} )
    {
        $self->{tz} = $old_tz;
        return( $self->pass_error( DateTime::Lite::TimeZone->error ) );
    }

    $self->_handle_offset_modifier( $self->second, 1 );

    eval
    {
        if( $self->{tz}->is_floating xor $was_floating )
        {
            $self->_calc_utc_rd;
        }
        elsif( !$was_floating )
        {
            $self->_calc_local_rd;
        }
    };
    if( $@ )
    {
        # Restore old timezone and re-throw; RT #83940
        $self->{tz} = $old_tz;
        die( $@ );
    }

    # Invalidate memoised values that depend on local time or epoch
    delete( $self->{utc_c} );

    return( $self );
}

sub set_year { $_[0]->set( year => $_[1] ) }

# See also end_of()
sub start_of
{
    my $self = shift( @_ );
    my $unit = shift( @_ ) ||
     return( $self->error( "Parameter 'unit' is required for start_of()." ) );

    # Most units map directly to truncate(), which already handles
    # year, quarter, month, week, local_week, day, hour, minute, second.
    # We handle decade and century ourselves.
    if( $unit eq 'decade' )
    {
        my $decade_year = int( $self->year / 10 ) * 10;
        my $new_dt = $self->_new_from_self(
            year       => $decade_year,
            month      => 1,
            day        => 1,
            hour       => 0,
            minute     => 0,
            second     => 0,
            nanosecond => 0,
            _skip_validation => 1,
        ) || return( $self->pass_error );
        %$self = %$new_dt;
        return( $self );
    }
    elsif( $unit eq 'century' )
    {
        # Century: year 1-100 -> year 1, year 101-200 -> year 101, etc.
        my $century_year = ( int( ( $self->year - 1 ) / 100 ) * 100 ) + 1;
        my $new_dt = $self->_new_from_self(
            year       => $century_year,
            month      => 1,
            day        => 1,
            hour       => 0,
            minute     => 0,
            second     => 0,
            nanosecond => 0,
            _skip_validation => 1,
        ) || return( $self->pass_error );
        %$self = %$new_dt;
        return( $self );
    }
    else
    {
        my %valid = map{ $_ => 1 } qw(
            year quarter month week local_week day hour minute second
        );
        unless( $valid{ $unit } )
        {
            return( $self->error( "Invalid unit '$unit' for start_of()." ) );
        }
        return( $self->truncate( to => $unit ) );
    }
}

# NOTE: strftime
{
    my %strftime_patterns;

    %strftime_patterns = (
        'a' => sub{ $_[0]->day_abbr },
        'A' => sub{ $_[0]->day_name },
        'b' => sub{ $_[0]->month_abbr },
        'B' => sub{ $_[0]->month_name },
        'c' => sub{ $_[0]->strftime( '%a %b %e %H:%M:%S %Y' ) },
        'C' => sub{ int( $_[0]->year / 100 ) },
        'd' => sub{ sprintf( '%02d', $_[0]->day ) },
        'D' => sub{ $_[0]->strftime( '%m/%d/%y' ) },
        'e' => sub{ sprintf( '%2d', $_[0]->day ) },
        'F' => sub{ $_[0]->ymd( '-' ) },
        'G' => sub{ $_[0]->week_year },
        'g' => sub{ sprintf( '%02d', $_[0]->week_year % 100 ) },
        'H' => sub{ sprintf( '%02d', $_[0]->hour ) },
        'I' => sub{ sprintf( '%02d', $_[0]->hour_12 ) },
        'j' => sub{ sprintf( '%03d', $_[0]->day_of_year ) },
        'k' => sub{ sprintf( '%2d',  $_[0]->hour ) },
        'l' => sub{ sprintf( '%2d',  $_[0]->hour_12 ) },
        'm' => sub{ sprintf( '%02d', $_[0]->month ) },
        'M' => sub{ sprintf( '%02d', $_[0]->minute ) },
        'n' => sub{ "\n" },
        'N' => sub{ $_[0]->_format_nanosecs(9) },
        'p' => sub{ $_[0]->am_or_pm },
        'P' => sub{ lc( $_[0]->am_or_pm ) },
        'r' => sub{ $_[0]->strftime( '%I:%M:%S %p' ) },
        'R' => sub{ $_[0]->strftime( '%H:%M' ) },
        's' => sub{ $_[0]->epoch },
        'S' => sub{ sprintf( '%02d', $_[0]->second ) },
        't' => sub{ "\t" },
        'T' => sub{ $_[0]->strftime( '%H:%M:%S' ) },
        'u' => sub{ $_[0]->day_of_week },
        'U' => sub{ sprintf( '%02d', int( ( $_[0]->day_of_year - $_[0]->day_of_week_0 + 6 ) / 7 ) ) },
        'V' => sub{ sprintf( '%02d', $_[0]->week_number ) },
        'w' => sub{ $_[0]->day_of_week % 7 },
        'W' => sub{ sprintf( '%02d', int( ( $_[0]->day_of_year - ( $_[0]->day_of_week - 1 ) + 6 ) / 7 ) ) },
        'x' => sub{ $_[0]->strftime( '%m/%d/%y' ) },
        'X' => sub{ $_[0]->strftime( '%H:%M:%S' ) },
        'y' => sub{ sprintf( '%02d', $_[0]->year % 100 ) },
        'Y' => sub{ sprintf( '%04d', $_[0]->year ) },
        'z' => sub{ DateTime::Lite::TimeZone->offset_as_string( $_[0]->offset ) },
        'Z' => sub{ $_[0]->time_zone_short_name },
        '%' => sub{ '%' },
    );

    sub strftime
    {
        my $self     = shift( @_ );
        my @patterns = @_;

        my @r;
        foreach my $p ( @patterns )
        {
            $p =~ s/
                    (?:
                      %\{(\w+)\}        # method name like %{day_name}
                      |
                      %([%a-zA-Z])      # single character specifier like %d
                      |
                      %(\d+)N           # special case for %N
                    )
                   /
                    ( $1
                      ? ( $self->can($1) ? $self->$1() : "\%{$1}" )
                      : $2
                      ? ( $strftime_patterns{$2} ? $strftime_patterns{$2}->($self) : "\%$2" )
                      : $3
                      ? $strftime_patterns{N}->($self, $3)
                      : ''
                    )
                   /sgex;

            return( $p ) unless( wantarray );
            push( @r, $p );
        }
        return( @r );
    }
}

sub stringify
{
    my $self = shift( @_ );
    return( $self->{formatter}->format_datetime( $self ) )
        if( defined( $self->{formatter} ) );
    return( $self->iso8601 );
}

sub subtract
{
    my $self = shift( @_ );
    my %eom;
    if( @_ % 2 == 0 )
    {
        my %p = @_;
        $eom{end_of_month} = delete( $p{end_of_month} ) if( exists( $p{end_of_month} ) );
    }
    my $dur = $self->_duration_object_from_args( @_ )->inverse( %eom );
    return( $self->add_duration( $dur ) );
}

sub subtract_duration { return( $_[0]->add_duration( $_[1]->inverse ) ) }

sub subtract_datetime
{
    my $dt1 = shift( @_ );
    my $dt2 = shift( @_ );

    $dt2 = $dt2->clone->set_time_zone( $dt1->time_zone )
        unless( $dt1->time_zone eq $dt2->time_zone );

    my( $bigger, $smaller, $negative ) = (
        $dt1 >= $dt2
            ? ( $dt1, $dt2, 0 )
            : ( $dt2, $dt1, 1 )
    );

    my $is_floating = $dt1->time_zone->is_floating &&
                      $dt2->time_zone->is_floating;

    my $minute_length = 60;
    unless( $is_floating )
    {
        my( $utc_rd_days, $utc_rd_secs ) = $smaller->utc_rd_values;
        if( $utc_rd_secs >= 86340 )
        {
            $minute_length = $dt1->_day_length( $utc_rd_days ) - 86340;
        }
    }

    # Adjust for DST crossings (23h / 25h days)
    my $bigger_min = $bigger->hour * 60 + $bigger->minute;
    if( $bigger->time_zone->has_dst_changes &&
        $bigger->is_dst != $smaller->is_dst )
    {
        if( $bigger->is_dst )
        {
            my $prev = eval { $bigger->clone->subtract( days => 1 ) };
            $bigger_min -= 60 if( $prev && !$prev->is_dst );
        }
        else
        {
            my $prev = eval { $bigger->clone->subtract( days => 1 ) };
            $bigger_min += 60 if( $prev && $prev->is_dst );
        }
    }

    my( $months, $days, $minutes, $seconds, $nanoseconds )
        = $dt1->_adjust_for_positive_difference(
            $bigger->year * 12  + $bigger->month,
            $smaller->year * 12 + $smaller->month,
            $bigger->day,        $smaller->day,
            $bigger_min,         $smaller->hour * 60 + $smaller->minute,
            $bigger->second,     $smaller->second,
            $bigger->nanosecond, $smaller->nanosecond,
            $minute_length,
            $dt1->_month_length( $smaller->year, $smaller->month ),
        );

    if( $negative )
    {
        foreach( $months, $days, $minutes, $seconds, $nanoseconds )
        {
            $_ *= -1 if( $_ );
        }
    }

    return( $dt1->duration_class->new(
        months      => $months,
        days        => $days,
        minutes     => $minutes,
        seconds     => $seconds,
        nanoseconds => $nanoseconds,
    ) );
}

sub subtract_datetime_absolute
{
    my $self = shift( @_ );
    my $dt   = shift( @_ );

    my $utc_rd_secs1 = $self->utc_rd_as_seconds;
    $utc_rd_secs1 += $self->_accumulated_leap_seconds( $self->{utc_rd_days} )
        if( !$self->time_zone->is_floating );

    my $utc_rd_secs2 = $dt->utc_rd_as_seconds;
    $utc_rd_secs2 += $self->_accumulated_leap_seconds( $dt->{utc_rd_days} )
        if( !$dt->time_zone->is_floating );

    my $seconds     = $utc_rd_secs1 - $utc_rd_secs2;
    my $nanoseconds = $self->nanosecond - $dt->nanosecond;

    if( $nanoseconds < 0 )
    {
        $seconds--;
        $nanoseconds += MAX_NANOSECONDS;
    }

    return( $self->duration_class->new(
        seconds     => $seconds,
        nanoseconds => $nanoseconds,
    ) );
}

sub time_zone { return( $_[0]->{tz} ) }
sub time_zone_long_name  { $_[0]->{tz}->name }
sub time_zone_short_name { $_[0]->{tz}->short_name_for_datetime( $_[0] ) }

sub today { shift->now( @_ )->truncate( to => 'day' ) }

sub truncate
{
    my $self = shift( @_ );
    my %p    = @_;

    return( $self->error( "Parameter 'to' is required for truncate()." ) )
        unless( exists( $p{to} ) );

    my %TruncateDefault = (
        month      => 1,
        day        => 1,
        hour       => 0,
        minute     => 0,
        second     => 0,
        nanosecond => 0,
    );

    my $valid_levels = join( '|', 'year', 'week', 'local_week', 'quarter',
        grep { $_ ne 'nanosecond' } keys( %TruncateDefault ) );
    return( $self->error( "Invalid truncation level '$p{to}'." ) )
        unless( $p{to} =~ /^(?:$valid_levels)$/ );

    my %new;
    if( $p{to} eq 'week' || $p{to} eq 'local_week' )
    {
        my $first_dow = ( $p{to} eq 'local_week' )
            ? $self->{locale}->first_day_of_week
            : 1;

        my $day_diff = ( $self->day_of_week - $first_dow ) % 7;
        $self->add( days => -1 * $day_diff ) if( $day_diff );

        my $ok = eval { $self->truncate( to => 'day' ); 1 };
        unless( $ok )
        {
            $self->add( days => $day_diff );
            die( $@ );
        }
    }
    elsif( $p{to} eq 'quarter' )
    {
        %new = (
            year       => $self->year,
            month      => int( ( $self->month - 1 ) / 3 ) * 3 + 1,
            day        => 1,
            hour       => 0,
            minute     => 0,
            second     => 0,
            nanosecond => 0,
        );
    }
    else
    {
        my $truncate = 0;
        foreach my $f ( qw( year month day hour minute second nanosecond ) )
        {
            $new{$f} = $truncate ? $TruncateDefault{$f} : $self->$f();
            $truncate = 1 if( $p{to} eq $f );
        }
    }

    if( %new )
    {
        my $new_dt = $self->_new_from_self( %new, _skip_validation => 1 ) || return( $self->pass_error );
        %$self = %$new_dt;
    }

    return( $self );
}

sub utc_rd_as_seconds
{
    my $self = shift( @_ );
    return( $self->{utc_rd_days} * SECONDS_PER_DAY + $self->{utc_rd_secs} );
}

sub utc_rd_values
{
    my $self = shift( @_ );
    return( $self->{utc_rd_days}, $self->{utc_rd_secs}, $self->{rd_nanosecs} );
}

sub utc_year { $_[0]->{utc_year} }

sub week
{
    my $self = shift( @_ );

    # Memoised: computing week values requires day_of_year and day_of_week
    # which are already in local_c, so this is cheap after the first call.
    unless( exists( $self->{utc_c}->{week_year} ) )
    {
        $self->{utc_c}->{week_year} = $self->_week_values;
    }
    return( @{$self->{utc_c}->{week_year}}[0, 1] );
}

sub week_number { ( $_[0]->week )[1] }

# ISO: first week of the month is the first week containing a Thursday.
# Direct formula - no clone, no add(), no recursion.
# NOTE: week_of_month is autoloaded

sub week_year { ( $_[0]->week )[0] }

# NOTE: weekday_of_month is autoloaded

sub year
{
    my $self = shift( @_ );
    return( $self->{local_c}->{year} );
}

# NOTE: year_length is autoloaded

# NOTE: year_with_christian_era is autoloaded

# NOTE: year_with_era is autoloaded

# NOTE: year_with_secular_era is autoloaded

sub ymd
{
    my $self = shift( @_ );
    my $sep  = defined( $_[0] ) ? shift( @_ ) : '-';
    return( sprintf( "%04d%s%02d%s%02d",
        $self->year, $sep, $self->month, $sep, $self->day ) );
}

# NOTE:: AUTOLOAD
sub AUTOLOAD
{
    my $self;
    $self = shift( @_ ) if( Scalar::Util::blessed( $_[0] ) && $_[0]->isa( 'DateTime::Lite' ) );
    my( $class, $meth );
    $class = ref( $self ) || $self;
    no overloading;
    no strict 'refs';
    $meth = $AUTOLOAD;
    if( CORE::index( $meth, '::' ) != -1 )
    {
        my $idx = rindex( $meth, '::' );
        $class = substr( $meth, 0, $idx );
        $meth  = substr( $meth, $idx + 2 );
    }

    unless( $AUTOLOAD_SUBS )
    {
        &_autoload_subs();
    }
    my $code;
    if( CORE::exists( $AUTOLOAD_SUBS->{ $meth } ) )
    {
        $code = $AUTOLOAD_SUBS->{ $meth };
        my $saved = $@;
        local $@;
        {
            no strict;
            eval( $code );
        }
        if( $@ )
        {
            $@ =~ s/ at .*\n//;
            die( $@ );
        }
        $@ = $saved;
        my $ref = $class->can( $meth ) || die( "AUTOLOAD inconsistency error for dynamic sub \"$meth\"." );
        return( &$meth( $self, @_ ) ) if( $self );
    }
    my( $pkg, $file, $line ) = caller();
    my $sub = ( caller(1) )[3];
    # NOTE: should we not die ?
    die( "Method $meth() is not defined in class $class and not autoloadable in package $pkg in file $file at line $line", ( defined( $sub ) ? " from within subroutine $sub" : '' ), "." );
}

# So AUTOLOAD does not catch it.
sub DESTROY {}

sub FREEZE
{
    my $self = CORE::shift( @_ );
    my $serialiser = CORE::shift( @_ ) // '';
    my $class = CORE::ref( $self );
    my %hash  = %$self;
    # Return an array reference rather than a list so this works with Sereal and CBOR
    # On or before Sereal version 4.023, Sereal did not support multiple values returned
    CORE::return( [$class, \%hash] ) if( $serialiser eq 'Sereal' && Sereal::Encoder->VERSION <= version->parse( '4.023' ) );
    # But Storable want a list with the first element being the serialised element
    CORE::return( $class, \%hash );
}

# NOTE: Serialisation
sub STORABLE_freeze
{
    my $self = shift( @_ );
    my $serialized = '';
    foreach my $key ( qw( utc_rd_days utc_rd_secs rd_nanosecs ) )
    {
        $serialized .= "$key:$self->{$key}|";
    }
    $serialized .= 'version:' . ( $DateTime::Lite::VERSION || 'git' );
    return( $serialized, $self->{locale}, $self->{tz}, \$self->{formatter} );
}

sub STORABLE_thaw
{
    my $self       = shift( @_ );
    shift( @_ );
    my $serialized = shift( @_ );

    my %s = map { split( /:/, $_, 2 ) } split( /\|/, $serialized );

    my( $locale, $tz, $formatter );

    if( @_ )
    {
        ( $locale, $tz, $formatter ) = @_;
    }
    else
    {
        $tz     = DateTime::Lite::TimeZone->new( name => delete( $s{tz} ) ) ||
            die( DateTime::Lite::TimeZone->error );
        $locale = DateTime::Locale::FromCLDR->new( delete( $s{locale} ) ) ||
            die( DateTime::Locale::FromCLDR->error );
    }

    delete( $s{version} );

    my $object = bless(
    {
        utc_vals => [
            $s{utc_rd_days},
            $s{utc_rd_secs},
            $s{rd_nanosecs},
        ],
        tz => $tz,
    }, 'DateTime::Lite::_Thawed' );

    my %fmt;
    if( defined( $formatter ) && ref( $formatter ) && defined( $$formatter ) )
    {
        %fmt = ( formatter => $$formatter );
    }
    my $new = ( ref( $self ) )->from_object(
        object => $object,
        locale => $locale,
        %fmt,
    ) || die( ref( $self )->error );

    %$self = %$new;
    return( $self );
}

# NOTE: CBOR will call the THAW method with the stored classname as first argument, the constant string CBOR as second argument, and all values returned by FREEZE as remaining arguments.
# NOTE: Storable calls it with a blessed object it created followed with $cloning and any other arguments initially provided by STORABLE_freeze
sub THAW
{
    my( $self, undef, @args ) = @_;
    my $ref = ( CORE::scalar( @args ) == 1 && CORE::ref( $args[0] ) eq 'ARRAY' ) ? CORE::shift( @args ) : \@args;
    my $class = ( CORE::defined( $ref ) && CORE::ref( $ref ) eq 'ARRAY' && CORE::scalar( @$ref ) > 1 ) ? CORE::shift( @$ref ) : ( CORE::ref( $self ) || $self );
    my $hash = CORE::ref( $ref ) eq 'ARRAY' ? CORE::shift( @$ref ) : {};
    my $new;
    # Storable pattern requires to modify the object it created rather than returning a new one
    if( CORE::ref( $self ) )
    {
        foreach( CORE::keys( %$hash ) )
        {
            $self->{ $_ } = CORE::delete( $hash->{ $_ } );
        }
        $new = $self;
    }
    else
    {
        $new = CORE::bless( $hash => $class );
    }
    CORE::return( $new );
}

sub TO_JSON { return( $_[0]->stringify ) }

# NOTE: Private methods (alphabetical)
sub _add_duration
{
    my $self = shift( @_ );
    my $dur  = shift( @_ );

    my %deltas = $dur->deltas;

    if( $deltas{days} )
    {
        $self->{local_rd_days} += $deltas{days};
        $self->{utc_year}      += int( $deltas{days} / 365 ) + 1;
    }

    if( $deltas{months} )
    {
        my( $y, $m, $d ) = (
              $dur->is_preserve_mode
            ? $self->_rd2ymd( $self->{local_rd_days} + 1 )
            : $self->_rd2ymd( $self->{local_rd_days} )
        );

        $d -= 1 if( $dur->is_preserve_mode );

        if( !$dur->is_wrap_mode && $d > 28 )
        {
            $self->{local_rd_days}
                = $self->_ymd2rd( $y, $m + $deltas{months} + 1, 0 );
            my $last_day = ( $self->_rd2ymd( $self->{local_rd_days} ) )[2];
            $self->{local_rd_days} -= $last_day - $d if( $last_day > $d );
        }
        else
        {
            $self->{local_rd_days}
                = $self->_ymd2rd( $y, $m + $deltas{months}, $d );
        }

        $self->{utc_year} += int( $deltas{months} / 12 ) + 1;
    }

    if( $deltas{days} || $deltas{months} )
    {
        $self->_calc_utc_rd;
        $self->_handle_offset_modifier( $self->second );
    }

    if( $deltas{minutes} )
    {
        $self->{utc_rd_secs} += $deltas{minutes} * 60;
        $self->_normalize_tai_seconds(
            $self->{utc_rd_days},
            $self->{utc_rd_secs},
        );
    }

    if( $deltas{seconds} || $deltas{nanoseconds} )
    {
        $self->{utc_rd_secs} += $deltas{seconds};

        if( $deltas{nanoseconds} )
        {
            $self->{rd_nanosecs} += $deltas{nanoseconds};
            $self->_normalize_nanoseconds(
                $self->{utc_rd_secs},
                $self->{rd_nanosecs},
            );
        }

        $self->_normalize_seconds;
        $self->_handle_offset_modifier( $self->second + $deltas{seconds} );
    }

    my $new = ( ref( $self ) )->from_object(
        object    => $self,
        locale    => $self->{locale},
        ( $self->{formatter} ? ( formatter => $self->{formatter} ) : () ),
    );

    %$self = %$new;
    return( $self );
}

sub _add_overload
{
    my( $dt, $dur, $reversed ) = @_;
    ( $dur, $dt ) = ( $dt, $dur ) if( $reversed );

    unless( Scalar::Util::blessed( $dur ) && $dur->isa( 'DateTime::Lite::Duration' ) )
    {
        my $class     = ref( $dt );
        my $dt_string = overload::StrVal( $dt );
        die( "Cannot add $dur to a $class object ($dt_string). Only a DateTime::Lite::Duration can be added." );
    }

    return( $dt->clone->add_duration( $dur ) );
}

sub _adjust_for_positive_difference
{
    my(
        $self,
        $month1, $month2,
        $day1,   $day2,
        $min1,   $min2,
        $sec1,   $sec2,
        $nano1,  $nano2,
        $minute_length,
        $month_length,
    ) = @_;

    if( $nano1 < $nano2 )
    {
        $sec1--;
        $nano1 += MAX_NANOSECONDS;
    }

    if( $sec1 < $sec2 )
    {
        $min1--;
        $sec1 += $minute_length;
    }

    if( $min1 < $min2 )
    {
        $day1--;
        $min1 += 24 * 60;
    }

    if( $day1 < $day2 )
    {
        $month1--;
        $day1 += $month_length;
    }

    return(
        $month1 - $month2,
        $day1   - $day2,
        $min1   - $min2,
        $sec1   - $sec2,
        $nano1  - $nano2,
    );
}

sub _autoload_subs
{
    # This is autogenerated; do not make modifications as they will be lost.
    my $subs = 
    {
        # NOTE: am_or_pm()
        am_or_pm => <<'PERL',
sub am_or_pm
{
    if( !scalar( @_ ) )
    {
        die( 'Usage: $dt->am_or_pm' );
    }
    my $self = shift( @_ );
    if( !defined( $self ) || !Scalar::Util::blessed( $self // '' ) )
    {
        die( 'Usage: $dt->am_or_pm' );
    }
    return( $self->{locale}->am_pm_abbreviated->[ $self->{local_c}->{hour} < 12 ? 0 : 1 ] );
}
PERL
        # NOTE: ce_year()
        ce_year => <<'PERL',
sub ce_year
{
    if( !scalar( @_ ) )
    {
        die( 'Usage: $dt->ce_year' );
    }
    my $self = shift( @_ );
    if( !defined( $self ) || !Scalar::Util::blessed( $self // '' ) )
    {
        die( 'Usage: $dt->ce_year' );
    }
    return( $self->{local_c}->{year} <= 0
        ? $self->{local_c}->{year} - 1
        : $self->{local_c}->{year} );
}
PERL
        # NOTE: christian_era()
        christian_era => <<'PERL',
sub christian_era
{
    if( !scalar( @_ ) )
    {
        die( 'Usage: $dt->christian_era' );
    }
    my $self = shift( @_ );
    if( !defined( $self ) || !Scalar::Util::blessed( $self // '' ) )
    {
        die( 'Usage: $dt->christian_era' );
    }
    return( $self->ce_year > 0 ? 'AD' : 'BC' );
}
PERL
        # NOTE: day_of_month_0()
        day_of_month_0 => <<'PERL',
sub day_of_month_0
{
    if( !scalar( @_ ) )
    {
        die( 'Usage: $dt->day_of_month_0' );
    }
    my $self = shift( @_ );
    if( !defined( $self ) || !Scalar::Util::blessed( $self // '' ) )
    {
        die( 'Usage: $dt->day_of_month_0' );
    }
    return( $self->{local_c}->{day} - 1 );
}
PERL
        # NOTE: day_of_quarter()
        day_of_quarter => <<'PERL',
sub day_of_quarter
{
    if( !scalar( @_ ) )
    {
        die( 'Usage: $dt->day_of_quarter' );
    }
    my $self = shift( @_ );
    if( !defined( $self ) || !Scalar::Util::blessed( $self // '' ) )
    {
        die( 'Usage: $dt->day_of_quarter' );
    }
    return( $self->{local_c}->{day_of_quarter} );
}
PERL
        # NOTE: day_of_quarter_0()
        day_of_quarter_0 => <<'PERL',
sub day_of_quarter_0
{
    if( !scalar( @_ ) )
    {
        die( 'Usage: $dt->day_of_quarter_0' );
    }
    my $self = shift( @_ );
    if( !defined( $self ) || !Scalar::Util::blessed( $self // '' ) )
    {
        die( 'Usage: $dt->day_of_quarter_0' );
    }
    return( $self->{local_c}->{day_of_quarter} - 1 );
}
PERL
        # NOTE: day_of_week_0()
        day_of_week_0 => <<'PERL',
sub day_of_week_0
{
    if( !scalar( @_ ) )
    {
        die( 'Usage: $dt->day_of_week_0' );
    }
    my $self = shift( @_ );
    if( !defined( $self ) || !Scalar::Util::blessed( $self // '' ) )
    {
        die( 'Usage: $dt->day_of_week_0' );
    }
    return( $self->{local_c}->{day_of_week} - 1 );
}
PERL
        # NOTE: day_of_year_0()
        day_of_year_0 => <<'PERL',
sub day_of_year_0
{
    if( !scalar( @_ ) )
    {
        die( 'Usage: $dt->day_of_year_0' );
    }
    my $self = shift( @_ );
    if( !defined( $self ) || !Scalar::Util::blessed( $self // '' ) )
    {
        die( 'Usage: $dt->day_of_year_0' );
    }
    return( $self->{local_c}->{day_of_year} - 1 );
}
PERL
        # NOTE: dmy()
        dmy => <<'PERL',
sub dmy
{
    if( !scalar( @_ ) )
    {
        die( 'Usage: $dt->dmy or $dt->dmy( "-" )' );
    }
    my( $self, $sep ) = @_;
    if( !defined( $self ) || !Scalar::Util::blessed( $self // '' ) )
    {
        die( 'Usage: $dt->dmy or $dt->dmy( "-" )' );
    }
    $sep //= '-';
    return( sprintf( '%0.2d%s%0.2d%s%0.4d',
        $self->{local_c}->{day},   $sep,
        $self->{local_c}->{month}, $sep,
        $self->{local_c}->{year} ) );
}
PERL
        # NOTE: era_abbr()
        era_abbr => <<'PERL',
sub era_abbr
{
    if( !scalar( @_ ) )
    {
        die( 'Usage: $dt->era_abbr' );
    }
    my $self = shift( @_ );
    if( !defined( $self ) || !Scalar::Util::blessed( $self // '' ) )
    {
        die( 'Usage: $dt->era_abbr' );
    }
    return( $self->{locale}->era_abbreviated->[ $self->_era_index ] );
}
PERL
        # NOTE: era_name()
        era_name => <<'PERL',
sub era_name
{
    if( !scalar( @_ ) )
    {
        die( 'Usage: $dt->era_name' );
    }
    my $self = shift( @_ );
    if( !defined( $self ) || !Scalar::Util::blessed( $self // '' ) )
    {
        die( 'Usage: $dt->era_name' );
    }
    return( $self->{locale}->era_wide->[ $self->_era_index ] );
}
PERL
        # NOTE: fractional_second()
        fractional_second => <<'PERL',
sub fractional_second
{
    if( !scalar( @_ ) )
    {
        die( 'Usage: $dt->fractional_second' );
    }
    my $self = shift( @_ );
    if( !defined( $self ) || !Scalar::Util::blessed( $self // '' ) )
    {
        die( 'Usage: $dt->fractional_second' );
    }
    return( $self->second + $self->nanosecond / MAX_NANOSECONDS );
}
PERL
        # NOTE: hour_1()
        hour_1 => <<'PERL',
sub hour_1
{
    if( !scalar( @_ ) )
    {
        die( 'Usage: $dt->hour_1' );
    }
    my $self = shift( @_ );
    if( !defined( $self ) || !Scalar::Util::blessed( $self // '' ) )
    {
        die( 'Usage: $dt->hour_1' );
    }
    return( $self->{local_c}->{hour} == 0 ? 24 : $self->{local_c}->{hour} );
}
PERL
        # NOTE: hour_12()
        hour_12 => <<'PERL',
sub hour_12
{
    if( !scalar( @_ ) )
    {
        die( 'Usage: $dt->hour_12' );
    }
    my $self = shift( @_ );
    if( !defined( $self ) || !Scalar::Util::blessed( $self // '' ) )
    {
        die( 'Usage: $dt->hour_12' );
    }
    my $h = $self->hour % 12;
    return( $h ? $h : 12 );
}
PERL
        # NOTE: hour_12_0()
        hour_12_0 => <<'PERL',
sub hour_12_0
{
    if( !scalar( @_ ) )
    {
        die( 'Usage: $dt->hour_12_0' );
    }
    my $self = shift( @_ );
    if( !defined( $self ) || !Scalar::Util::blessed( $self // '' ) )
    {
        die( 'Usage: $dt->hour_12_0' );
    }
    return( $self->hour % 12 );
}
PERL
        # NOTE: is_last_day_of_month()
        is_last_day_of_month => <<'PERL',
sub is_last_day_of_month
{
    if( !scalar( @_ ) )
    {
        die( 'Usage: $dt->is_last_day_of_month' );
    }
    my $self = shift( @_ );
    if( !defined( $self ) || !Scalar::Util::blessed( $self // '' ) )
    {
        die( 'Usage: $dt->is_last_day_of_month' );
    }
    return( $self->day == $self->_month_length( $self->year, $self->month ) );
}
PERL
        # NOTE: is_last_day_of_quarter()
        is_last_day_of_quarter => <<'PERL',
sub is_last_day_of_quarter
{
    if( !scalar( @_ ) )
    {
        die( 'Usage: $dt->is_last_day_of_quarter' );
    }
    my $self = shift( @_ );
    if( !defined( $self ) || !Scalar::Util::blessed( $self // '' ) )
    {
        die( 'Usage: $dt->is_last_day_of_quarter' );
    }
    return( $self->day_of_quarter == $self->quarter_length );
}
PERL
        # NOTE: is_last_day_of_year()
        is_last_day_of_year => <<'PERL',
sub is_last_day_of_year
{
    if( !scalar( @_ ) )
    {
        die( 'Usage: $dt->is_last_day_of_year' );
    }
    my $self = shift( @_ );
    if( !defined( $self ) || !Scalar::Util::blessed( $self // '' ) )
    {
        die( 'Usage: $dt->is_last_day_of_year' );
    }
    return( $self->day_of_year == $self->year_length );
}
PERL
        # NOTE: jd()
        jd => <<'PERL',
sub jd
{
    if( !scalar( @_ ) )
    {
        die( 'Usage: $dt->jd' );
    }
    my $self = shift( @_ );
    if( !defined( $self ) || !Scalar::Util::blessed( $self // '' ) )
    {
        die( 'Usage: $dt->jd' );
    }
    return( $self->mjd + 2_400_000.5 );
}
PERL
        # NOTE: leap_seconds()
        leap_seconds => <<'PERL',
sub leap_seconds
{
    if( !scalar( @_ ) )
    {
        die( 'Usage: $dt->leap_seconds' );
    }
    my $self = shift( @_ );
    if( !defined( $self ) || !Scalar::Util::blessed( $self // '' ) )
    {
        die( 'Usage: $dt->leap_seconds' );
    }
    return(0) if( $self->{tz}->is_floating );
    return( $self->_accumulated_leap_seconds( $self->{utc_rd_days} ) );
}
PERL
        # NOTE: local_day_of_week()
        local_day_of_week => <<'PERL',
sub local_day_of_week
{
    if( !scalar( @_ ) )
    {
        die( 'Usage: $dt->local_day_of_week' );
    }
    my $self = shift( @_ );
    if( !defined( $self ) || !Scalar::Util::blessed( $self // '' ) )
    {
        die( 'Usage: $dt->local_day_of_week' );
    }
    return( 1 + ( ( $self->day_of_week - $self->{locale}->first_day_of_week ) % 7 ) );
}
PERL
        # NOTE: mdy()
        mdy => <<'PERL',
sub mdy
{
    if( !scalar( @_ ) )
    {
        die( 'Usage: $dt->mdy or $dt->mdy( "-" )' );
    }
    my( $self, $sep ) = @_;
    if( !defined( $self ) || !Scalar::Util::blessed( $self // '' ) )
    {
        die( 'Usage: $dt->mdy or $dt->mdy( "-" )' );
    }
    $sep //= '-';
    return( sprintf( "%02d%s%02d%s%04d",
        $self->month, $sep, $self->day, $sep, $self->year ) );
}
PERL
        # NOTE: microsecond()
        microsecond => <<'PERL',
sub microsecond
{
    if( !scalar( @_ ) )
    {
        die( 'Usage: $dt->microsecond' );
    }
    my $self = shift( @_ );
    if( !defined( $self ) || !Scalar::Util::blessed( $self // '' ) )
    {
        die( 'Usage: $dt->microsecond' );
    }
    return( POSIX::floor( $self->{rd_nanosecs} / 1000 ) );
}
PERL
        # NOTE: millisecond()
        millisecond => <<'PERL',
sub millisecond
{
    if( !scalar( @_ ) )
    {
        die( 'Usage: $dt->millisecond' );
    }
    my $self = shift( @_ );
    if( !defined( $self ) || !Scalar::Util::blessed( $self // '' ) )
    {
        die( 'Usage: $dt->millisecond' );
    }
    return( POSIX::floor( $self->{rd_nanosecs} / 1000000 ) );
}
PERL
        # NOTE: mjd()
        mjd => <<'PERL',
sub mjd
{
    if( !scalar( @_ ) )
    {
        die( 'Usage: $dt->mjd' );
    }
    my $self = shift( @_ );
    if( !defined( $self ) || !Scalar::Util::blessed( $self // '' ) )
    {
        die( 'Usage: $dt->mjd' );
    }
    my $mjd = $self->{utc_rd_days} - 678_576;
    my $day_length = $self->_day_length( $self->{utc_rd_days} );
    return( $mjd
        + ( $self->{utc_rd_secs}  / $day_length )
        + ( $self->{rd_nanosecs}  / $day_length / MAX_NANOSECONDS() ) );
}
PERL
        # NOTE: month_0()
        month_0 => <<'PERL',
sub month_0
{
    if( !scalar( @_ ) )
    {
        die( 'Usage: $dt->month_0' );
    }
    my $self = shift( @_ );
    if( !defined( $self ) || !Scalar::Util::blessed( $self // '' ) )
    {
        die( 'Usage: $dt->month_0' );
    }
    return( $self->{local_c}->{month} - 1 );
}
PERL
        # NOTE: month_length()
        month_length => <<'PERL',
sub month_length
{
    if( !scalar( @_ ) )
    {
        die( 'Usage: $dt->month_length' );
    }
    my $self = shift( @_ );
    if( !defined( $self ) || !Scalar::Util::blessed( $self // '' ) )
    {
        die( 'Usage: $dt->month_length' );
    }
    return( $self->_month_length( $self->year, $self->month ) );
}
PERL
        # NOTE: quarter_0()
        quarter_0 => <<'PERL',
sub quarter_0
{
    if( !scalar( @_ ) )
    {
        die( 'Usage: $dt->quarter_0' );
    }
    my $self = shift( @_ );
    if( !defined( $self ) || !Scalar::Util::blessed( $self // '' ) )
    {
        die( 'Usage: $dt->quarter_0' );
    }
    return( $self->{local_c}->{quarter} - 1 );
}
PERL
        # NOTE: quarter_abbr()
        quarter_abbr => <<'PERL',
sub quarter_abbr
{
    if( !scalar( @_ ) )
    {
        die( 'Usage: $dt->quarter_abbr' );
    }
    my $self = shift( @_ );
    if( !defined( $self ) || !Scalar::Util::blessed( $self // '' ) )
    {
        die( 'Usage: $dt->quarter_abbr' );
    }
    return( $self->{locale}->quarter_format_abbreviated->[ $self->quarter_0 ] );
}
PERL
        # NOTE: quarter_length()
        quarter_length => <<'PERL',
sub quarter_length
{
    if( !scalar( @_ ) )
    {
        die( 'Usage: $dt->quarter_length' );
    }
    my $self = shift( @_ );
    if( !defined( $self ) || !Scalar::Util::blessed( $self // '' ) )
    {
        die( 'Usage: $dt->quarter_length' );
    }
    return( $self->_is_leap_year( $self->year )
        ? $LeapYearQuarterLengths[ $self->quarter_0 ]
        : $QuarterLengths[ $self->quarter_0 ] );
}
PERL
        # NOTE: quarter_name()
        quarter_name => <<'PERL',
sub quarter_name
{
    if( !scalar( @_ ) )
    {
        die( 'Usage: $dt->quarter_name' );
    }
    my $self = shift( @_ );
    if( !defined( $self ) || !Scalar::Util::blessed( $self // '' ) )
    {
        die( 'Usage: $dt->quarter_name' );
    }
    return( $self->{locale}->quarter_format_wide->[ $self->quarter_0 ] );
}
PERL
        # NOTE: secular_era()
        secular_era => <<'PERL',
sub secular_era
{
    if( !scalar( @_ ) )
    {
        die( 'Usage: $dt->secular_era' );
    }
    my $self = shift( @_ );
    if( !defined( $self ) || !Scalar::Util::blessed( $self // '' ) )
    {
        die( 'Usage: $dt->secular_era' );
    }
    $self->ce_year > 0 ? 'CE' : 'BCE'
}
PERL
        # NOTE: week_of_month()
        week_of_month => <<'PERL',
sub week_of_month
{
    if( !scalar( @_ ) )
    {
        die( 'Usage: $dt->week_of_month' );
    }
    my $self = shift( @_ );
    if( !defined( $self ) || !Scalar::Util::blessed( $self // '' ) )
    {
        die( 'Usage: $dt->week_of_month' );
    }
    my $thu  = $self->day + 4 - $self->day_of_week;
    return( int( ( $thu + 6 ) / 7 ) );
}
PERL
        # NOTE: weekday_of_month()
        weekday_of_month => <<'PERL',
sub weekday_of_month
{
    if( !scalar( @_ ) )
    {
        die( 'Usage: $dt->weekday_of_month' );
    }
    my $self = shift( @_ );
    if( !defined( $self ) || !Scalar::Util::blessed( $self // '' ) )
    {
        die( 'Usage: $dt->weekday_of_month' );
    }
    use integer;
    return( ( ( $self->day - 1 ) / 7 ) + 1 );
}
PERL
        # NOTE: year_length()
        year_length => <<'PERL',
sub year_length
{
    if( !scalar( @_ ) )
    {
        die( 'Usage: $dt->year_length' );
    }
    my $self = shift( @_ );
    if( !defined( $self ) || !Scalar::Util::blessed( $self // '' ) )
    {
        die( 'Usage: $dt->year_length' );
    }
    return( $self->_is_leap_year( $self->year ) ? 366 : 365 );
}
PERL
        # NOTE: year_with_christian_era()
        year_with_christian_era => <<'PERL',
sub year_with_christian_era
{
    if( !scalar( @_ ) )
    {
        die( 'Usage: $dt->year_with_christian_era' );
    }
    my $self = shift( @_ );
    if( !defined( $self ) || !Scalar::Util::blessed( $self // '' ) )
    {
        die( 'Usage: $dt->year_with_christian_era' );
    }
    return( ( abs $self->ce_year ) . $self->christian_era );
}
PERL
        # NOTE: year_with_era()
        year_with_era => <<'PERL',
sub year_with_era
{
    if( !scalar( @_ ) )
    {
        die( 'Usage: $dt->year_with_era' );
    }
    my $self = shift( @_ );
    if( !defined( $self ) || !Scalar::Util::blessed( $self // '' ) )
    {
        die( 'Usage: $dt->year_with_era' );
    }
    return( ( abs $self->ce_year ) . $self->era_abbr );
}
PERL
        # NOTE: year_with_secular_era()
        year_with_secular_era => <<'PERL',
sub year_with_secular_era
{
    if( !scalar( @_ ) )
    {
        die( 'Usage: $dt->year_with_secular_era' );
    }
    my $self = shift( @_ );
    if( !defined( $self ) || !Scalar::Util::blessed( $self // '' ) )
    {
        die( 'Usage: $dt->year_with_secular_era' );
    }
    return( ( abs $self->ce_year ) . $self->secular_era );
}
PERL
    };

    unless( $AUTOLOAD_SUBS && CORE::scalar( CORE::keys( %$AUTOLOAD_SUBS ) ) )
    {
        # Avoid dependency on HAS_THREADS, and make it explicit
        # Maybe threads were loaded at runtime ?
        if( $Config{useithreads} && $INC{'threads.pm'} )
        {
            my %tmp :shared;
            # Make sure the value is not undefined, before locking it.
            $AUTOLOAD_SUBS = \%tmp;

            # We need to catch any possible error, or they may ripple in other parts of the code and wreak havoc
            # try-catch
            local $@;
            # Get the scoped returned value from lock so it works within our block
            eval
            {
                CORE::lock( $AUTOLOAD_SUBS );
                unless( CORE::scalar( CORE::keys( %$AUTOLOAD_SUBS ) ) )
                {
                    %$AUTOLOAD_SUBS = %$subs;
                }
            };
            if( $@ )
            {
                warn( "Error: unable to get a lock on the shared \$AUTOLOAD_SUBS: $@" );
            }
        }
        else
        {
            $AUTOLOAD_SUBS = $subs;
        }
    }
    return(1);
}

sub _calc_local_components
{
    my $self = shift( @_ );

    @{$self->{local_c}}{ qw( year month day day_of_week day_of_year quarter day_of_quarter ) }
        = $self->_rd2ymd( $self->{local_rd_days}, 1 );

    @{$self->{local_c}}{ qw( hour minute second ) }
        = $self->_seconds_as_components(
            $self->{local_rd_secs},
            $self->{utc_rd_secs},
            $self->{offset_modifier},
        );
}

sub _calc_local_rd
{
    my $self = shift( @_ );
    delete( $self->{local_c} );

    if( $self->{tz}->is_utc || $self->{tz}->is_floating )
    {
        $self->{local_rd_days} = $self->{utc_rd_days};
        $self->{local_rd_secs} = $self->{utc_rd_secs};
    }
    else
    {
        my $offset = $self->offset;
        $self->{local_rd_days} = $self->{utc_rd_days};
        $self->{local_rd_secs} = $self->{utc_rd_secs} + $offset;

        $self->_normalize_tai_seconds(
            $self->{local_rd_days},
            $self->{local_rd_secs},
        );
        $self->{local_rd_secs} += $self->{offset_modifier};
    }

    $self->_calc_local_components;
}

sub _calc_utc_rd
{
    my $self = shift( @_ );
    delete( $self->{utc_c} );

    if( $self->{tz}->is_utc || $self->{tz}->is_floating )
    {
        $self->{utc_rd_days} = $self->{local_rd_days};
        $self->{utc_rd_secs} = $self->{local_rd_secs};
    }
    else
    {
        my $offset = $self->_offset_for_local_datetime;
        $offset += $self->{offset_modifier};
        $self->{utc_rd_days} = $self->{local_rd_days};
        $self->{utc_rd_secs} = $self->{local_rd_secs} - $offset;
    }

    $self->_normalize_tai_seconds(
        $self->{utc_rd_days},
        $self->{utc_rd_secs},
    );
}

sub _compare
{
    my( undef, $dt1, $dt2, $consistent ) = ref( $_[0] ) ? ( undef, @_ ) : @_;

    return unless( defined( $dt2 ) );

    if( !ref( $dt2 ) && ( $dt2 == INFINITY || $dt2 == NEG_INFINITY ) )
    {
        return( $dt1->{utc_rd_days} <=> $dt2 );
    }

    unless( $dt1->can( 'utc_rd_values' ) && $dt2->can( 'utc_rd_values' ) )
    {
        my $s1 = overload::StrVal( $dt1 );
        my $s2 = overload::StrVal( $dt2 );
        die( "A DateTime::Lite object can only be compared to another compatible object ($s1, $s2)." );
    }

    if( !$consistent &&
        $dt1->can( 'time_zone' ) &&
        $dt2->can( 'time_zone' ) )
    {
        my $f1 = $dt1->time_zone->is_floating;
        my $f2 = $dt2->time_zone->is_floating;
        if( $f1 && !$f2 )
        {
            $dt1 = $dt1->clone->set_time_zone( $dt2->time_zone );
        }
        elsif( $f2 && !$f1 )
        {
            $dt2 = $dt2->clone->set_time_zone( $dt1->time_zone );
        }
    }

    # Short-circuit for Infinite objects: their utc_rd_days is ±INFINITY,
    # which overflows an XS IV parameter. Use Perl <=> directly on the NV.
    if( $dt1->is_infinite || $dt2->is_infinite )
    {
        my @c1 = $dt1->utc_rd_values;
        my @c2 = $dt2->utc_rd_values;
        for my $i ( 0 .. 2 )
        {
            return( $c1[$i] <=> $c2[$i] ) if( $c1[$i] != $c2[$i] );
        }
        return(0);
    }

    # Use XS fast-path when available
    if( !$IsPurePerl )
    {
        my @v1 = $dt1->utc_rd_values;
        my @v2 = $dt2->utc_rd_values;
        return( $dt1->_compare_rd( @v1, @v2 ) );
    }

    my @c1 = $dt1->utc_rd_values;
    my @c2 = $dt2->utc_rd_values;
    for my $i ( 0 .. 2 )
    {
        return( $c1[$i] <=> $c2[$i] ) if( $c1[$i] != $c2[$i] );
    }
    return(0);
}

sub _compare_overload
{
    return unless( defined( $_[1] ) );
    return( $_[2] ? -$_[0]->compare( $_[1] ) : $_[0]->compare( $_[1] ) );
}

sub _core_time { return( scalar( time ) ) }

sub _default_time_zone
{
    return( $ENV{PERL_DATETIME_DEFAULT_TZ} || 'floating' );
}

sub _duration_object_from_args
{
    my $self = shift( @_ );
    return( $_[0] )
        if( @_ == 1 &&
            Scalar::Util::blessed( $_[0] ) &&
            $_[0]->isa( $self->duration_class ) );
    return( $self->duration_class->new( @_ ) );
}

sub _era_index { $_[0]->{local_c}->{year} <= 0 ? 0 : 1 }

sub _format_nanosecs
{
    my $self  = shift( @_ );
    my $precision = shift( @_ ) // 9;
    my $rv = sprintf( "%09d", $self->{rd_nanosecs} );
    return( substr( $rv, 0, $precision ) );
}

sub _handle_offset_modifier
{
    my $self = shift( @_ );
    $self->{offset_modifier} = 0;
    return if( $self->{tz}->is_floating );

    my $second       = shift( @_ );
    my $utc_is_valid = shift( @_ );

    my $utc_rd_days  = $self->{utc_rd_days};
    my $offset       = $utc_is_valid
        ? $self->offset
        : $self->_offset_for_local_datetime;

    if( $offset >= 0 && $self->{local_rd_secs} >= $offset )
    {
        if( $second < 60 && $offset > 0 )
        {
            $self->{offset_modifier}
                = $self->_day_length( $utc_rd_days - 1 ) - SECONDS_PER_DAY;
            $self->{local_rd_secs} += $self->{offset_modifier};
        }
        elsif( $second == 60 &&
               ( ( $self->{local_rd_secs} == $offset && $offset > 0 ) ||
                 ( $offset == 0 && $self->{local_rd_secs} > 86399 ) ) )
        {
            my $mod = $self->_day_length( $utc_rd_days - 1 ) - SECONDS_PER_DAY;
            unless( $mod == 0 )
            {
                $self->{utc_rd_secs} -= $mod;
                $self->_normalize_seconds;
            }
        }
    }
    elsif( $offset < 0 &&
           $self->{local_rd_secs} >= SECONDS_PER_DAY + $offset )
    {
        if( $second < 60 )
        {
            $self->{offset_modifier}
                = $self->_day_length( $utc_rd_days - 1 ) - SECONDS_PER_DAY;
            $self->{local_rd_secs} += $self->{offset_modifier};
        }
        elsif( $second == 60 &&
               $self->{local_rd_secs} == SECONDS_PER_DAY + $offset )
        {
            my $mod = $self->_day_length( $utc_rd_days - 1 ) - SECONDS_PER_DAY;
            unless( $mod == 0 )
            {
                $self->{utc_rd_secs} -= $mod;
                $self->_normalize_seconds;
            }
        }
    }
}

# NOTE: Private helper: not a method; checks that a value is an integer (or integer-string)
sub _is_integer
{
    my $v = shift( @_ );
    return(0) unless( defined( $v ) );
    return( $v =~ /\A-?[0-9]+\z/ ? 1 : 0 );
}

sub _maybe_future_dst_warning
{
    shift( @_ );
    my $year = shift( @_ );
    my $tz   = shift( @_ );
    return unless( $year >= 5000 && $tz );
    my $tz_name = ref( $tz ) ? $tz->name : $tz;
    return if( $tz_name eq 'floating' || $tz_name eq 'UTC' );
    warnings::warnif(
        "Creating a DateTime::Lite with a far future year ($year) and time zone ($tz_name). "
        . "If the time zone has future DST changes this will be very slow."
    );
}

sub _month_length
{
    return( $_[0]->_is_leap_year( $_[1] )
        ? $LeapYearMonthLengths[ $_[2] - 1 ]
        : $MonthLengths[ $_[2] - 1 ] );
}

sub _new_from_self
{
    my $self = shift( @_ );
    my %p    = @_;

    my %old = map { $_ => $self->$_() } qw(
        year month day
        hour minute second
        nanosecond locale time_zone
    );
    $old{formatter} = $self->formatter if( defined( $self->formatter ) );

    my $method = delete( $p{_skip_validation} ) ? '_new' : 'new';
    return( ( ref( $self ) )->$method( %old, %p ) );
}

sub _normalize_seconds
{
    my $self = shift( @_ );
    return if( $self->{utc_rd_secs} >= 0 && $self->{utc_rd_secs} <= 86399 );

    if( $self->{tz}->is_floating )
    {
        $self->_normalize_tai_seconds(
            $self->{utc_rd_days},
            $self->{utc_rd_secs},
        );
    }
    else
    {
        $self->_normalize_leap_seconds(
            $self->{utc_rd_days},
            $self->{utc_rd_secs},
        );
    }
}

sub _offset_for_local_datetime
{
    my $self = shift( @_ );
    return( $self->{tz}->offset_for_local_datetime( $self ) );
}

sub _resolve_time_zone
{
    my( $class, $locale, $time_zone ) = @_;

    # Explicit time_zone always takes priority
    if( defined( $time_zone ) &&
        length( $time_zone ) )
    {
        return( $time_zone );
    }

    # Try to infer from the BCP47 -u-tz- locale extension.
    # Must be done BEFORE passing the locale to _set_locale, because
    # DateTime::Locale::FromCLDR->new() calls $locale->core which strips all -u-
    # extensions, making them inaccessible afterwards.
    # Three cases handled:
    #   1. Plain string: instantiate a temporary Locale::Unicode to read ->tz
    #   2. Locale::Unicode object: ->tz is directly accessible
    #   3. DateTime::Locale::FromCLDR object: core() has already stripped
    #      the -u- extensions, so tz will be undef; but this may change in
    #      the future so we try it out anyway.
    my $tz_code;
    if( defined( $locale ) &&
        !ref( $locale ) &&
        length( $locale ) )
    {
        require Locale::Unicode;
        # Plain string: parse it to get the -u-tz- extension
        my $loc = Locale::Unicode->new( $locale );
        $tz_code = $loc->tz if( $loc );
    }
    elsif( defined( $locale ) &&
           Scalar::Util::blessed( $locale ) &&
           $locale->isa( 'Locale::Unicode' ) )
    {
        # Already a Locale::Unicode object; extensions are intact
        $tz_code = $locale->tz;
    }
    elsif( defined( $locale ) &&
           Scalar::Util::blessed( $locale ) &&
           $locale->isa( 'DateTime::Locale::FromCLDR' ) &&
           $locale->can( 'locale' ) )
    {
        # DateTime::Locale::FromCLDR object. core() has already stripped
        # the -u- extensions, so tz will be undef; but this may change in
        # the future so we try it out anyway.
        $tz_code = $locale->locale->tz;
    }

    if( defined( $tz_code ) &&
        length( $tz_code ) )
    {
        require Locale::Unicode;
        my $names = Locale::Unicode->tz_id2names( $tz_code );
        return( $names->[0] ) if( $names && scalar( @$names ) );
    }

    # Nothing found: return undef and let the caller decide the fallback
    return;
}

sub _set_get_prop
{
    my $self = shift( @_ );
    my $prop = shift( @_ ) || die( "No object property was provided." );
    $self->{ $prop } = shift( @_ ) if( @_ );
    return( $self->{ $prop } );
}

sub _set_locale
{
    my $self   = shift( @_ );
    my $locale = shift( @_ );

    # Assuming this is either DateTime::Locale::FromData or DateTime::Locale::FromCLDR
    # But we need better check than this. However, if we check too strictly, we
    # might break things.
    if( defined( $locale ) && Scalar::Util::blessed( $locale ) )
    {
        $self->{locale} = $locale;
    }
    elsif( defined( $locale ) )
    {
        # If this is an unblessed reference, return an error
        return( $self->error( "Locale provided (", overload::StrVal( $locale ), ") is not a string." ) )
            if( ref( $locale ) );
        $locale = DateTime::Locale::FromCLDR->new( $locale ) ||
            return( $self->pass_error( DateTime::Locale::FromCLDR->error ) );
    }
    else
    {
        $locale = $self->DefaultLocale;
    }
    return( $self->{locale} = $locale );
}

sub _string_compare_overload
{
    my( $dt1, $dt2, $flip ) = @_;
    if( !$dt2->can( 'utc_rd_values' ) )
    {
        my $sign = $flip ? -1 : 1;
        return( $sign * ( "$dt1" cmp "$dt2" ) );
    }
    else
    {
        my $meth = $dt1->can( '_compare_overload' );
        goto $meth;
    }
}

sub _string_equals_overload
{
    my( $class, $dt1, $dt2 ) = ref( $_[0] ) ? ( undef, @_ ) : @_;
    return( "$dt1" eq "$dt2" ) unless( $dt2->can( 'utc_rd_values' ) );
    $class ||= ref( $dt1 );
    return( !$class->compare( $dt1, $dt2 ) );
}

sub _string_not_equals_overload { return( !_string_equals_overload( @_ ) ) }

sub _subtract_overload
{
    my( $date1, $date2, $reversed ) = @_;
    ( $date2, $date1 ) = ( $date1, $date2 ) if( $reversed );

    if( Scalar::Util::blessed( $date2 ) && $date2->isa( 'DateTime::Lite::Duration' ) )
    {
        my $new = $date1->clone;
        $new->add_duration( $date2->inverse );
        return( $new );
    }
    elsif( Scalar::Util::blessed( $date2 ) && $date2->can( 'utc_rd_values' ) )
    {
        return( $date1->subtract_datetime( $date2 ) );
    }
    else
    {
        my $class     = ref( $date1 );
        my $dt_string = overload::StrVal( $date1 );
        die( "Cannot subtract $date2 from a $class object ($dt_string). Only a DateTime::Lite::Duration or compatible object can be subtracted." );
    }
}

# Algorithm from https://en.wikipedia.org/wiki/ISO_week_date#Calculating_the_week_number_of_a_given_date
# Pure arithmetic - no clone, no add(), no risk of recursion.
sub _week_values
{
    my $self = shift( @_ );

    my $week = int( ( ( $self->day_of_year - $self->day_of_week ) + 10 ) / 7 );
    my $year = $self->year;

    if( $week == 0 )
    {
        $year--;
        return( [ $year, $self->_weeks_in_year( $year ) ] );
    }
    elsif( $week == 53 && $self->_weeks_in_year( $year ) == 52 )
    {
        return( [ $year + 1, 1 ] );
    }

    return( [ $year, $week ] );
}

sub _weeks_in_year
{
    my $self = shift( @_ );
    my $year = shift( @_ );

    # Day-of-week of January 1st (0=Mon..6=Sun in RD modulo)
    my $dow = $self->_ymd2rd( $year, 1, 1 ) % 7;

    # Years starting on Thursday, and leap years starting on Wednesday,
    # have 53 ISO weeks.
    return( ( $dow == 4 || ( $dow == 3 && $self->_is_leap_year( $year ) ) )
        ? 53
        : 52 );
}

1;

# NOTE: Minimal thaw helper (mirrors DateTime::_Thawed)
# NOTE: DateTime::Lite::_Thawed class
package DateTime::Lite::_Thawed;

sub time_zone     { $_[0]->{tz} }
sub utc_rd_values { @{ $_[0]->{utc_vals} } }

{
    # NOTE: DateTime::Lite::NullObject class
    package
        DateTime::Lite::NullObject;
    BEGIN
    {
        use strict;
        use warnings;
        use overload (
            '""'    => sub{ '' },
            fallback => 1,
        );
        use Wanted;
    };
    use strict;
    use warnings;

    sub new
    {
        my $this = shift( @_ );
        my $ref = @_ ? { @_ } : {};
        return( bless( $ref => ( ref( $this ) || $this ) ) );
    }

    sub AUTOLOAD
    {
        my( $method ) = our $AUTOLOAD =~ /([^:]+)$/;
        my $self = shift( @_ );
        if( want( 'OBJECT' ) )
        {
            rreturn( $self );
        }
        # Otherwise, we return undef; Empty return returns undef in scalar context and empty list in list context
        return;
    };
}

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

DateTime::Lite - Lightweight, low-dependency drop-in replacement for DateTime

=head1 SYNOPSIS

    use DateTime::Lite;

    my $dt = DateTime::Lite->new(
        year       => 2026,
        month      => 4,
        day        => 10,
        hour       => 6,
        minute     => 10,
        second     => 30,
        nanosecond => 0,
        time_zone  => 'Asia/Tokyo',
        locale     => 'ja-JP',
    ) || die( DateTime::Lite->error );

    my $now   = DateTime::Lite->now( time_zone => 'UTC' );
    my $today = DateTime::Lite->today( time_zone => 'Asia/Tokyo' );

    # Timezone from GPS coordinates (nearest IANA zone by haversine distance)
    use DateTime::Lite::TimeZone;
    my $tz = DateTime::Lite::TimeZone->new(
        latitude  => 35.658581,
        longitude => 139.745433,   # Tokyo Tower
    );
    my $dt_local = DateTime::Lite->now( time_zone => $tz );
    say $dt_local->time_zone_long_name;  # Asia/Tokyo

    # BCP47 -u-tz- locale extension: timezone inferred from locale tag
    my $dt_bcp47 = DateTime::Lite->now( locale => 'he-IL-u-ca-hebrew-tz-jeruslm' );
    say $dt_bcp47->time_zone_long_name;  # Asia/Jerusalem

    my $from_epoch = DateTime::Lite->from_epoch( epoch => time() );
    my $from_doy   = DateTime::Lite->from_day_of_year(
        year        => 2026,
        day_of_year => 100,
        time_zone   => 'UTC',
    );
    my $eom = DateTime::Lite->last_day_of_month( year => 2026, month => 2 );

    # Cloning (using XS)
    my $copy = $dt->clone;

    # Accessors
    $dt->year;          # 2026
    $dt->month;         # 4 (can be 1-12)
    # alias
    $dt->mon;
    $dt->day;           # 10 (can be 1-31)
    # alias
    $dt->day_of_month
    $dt->hour;          # 6 (can be 0-23)
    $dt->minute;        # 10 (can be 0-59)
    $dt->second;        # 30 (can be 0-61 only on leap-second days)
    $dt->nanosecond;    # 0 (can be 0-999_999_999)

    $dt->day_of_week;   # 5 (1=Mon .. 7=Sun)
    $dt->day_of_year;   # 99 (1-366)
    $dt->day_abbr;      # "金" (but would be "Fri" if the locale were 'en-US')
    $dt->day_name;      # "金曜日" (but would be "Friday" if the locale were 'en-US')
    $dt->month_0;       # 3 (can be 0-11)
    # alias
    $dt->mon_0;
    $dt->month_abbr;    # "4月" (but would be "Apr" if the locale were 'en-US')
    $dt->month_name;    # "4月" (but would be "April" if the locale were 'en-US')
    $dt->quarter;       # 2 (can be 1-4)
    $dt->week;          # ( 2026, 15 ) ($week_year, $week_number)
    $dt->week_number;   # 15 (can be 1-53)
    $dt->week_year;     # 2026 (ISO week year)

    $dt->epoch;         # 1775769030 (Unix timestamp; integer)
    $dt->hires_epoch;   # 1775769030 (floating-point epoch; IEEE 754 double, ~microsecond precision)
    # hires_epoch: limited to ~microsecond precision by IEEE 754 double
    # For full nanosecond precision, combine epoch() and nanosecond() manually:
    say sprintf "%d.%09d", $dt->epoch, $dt->nanosecond;  # 1775769030.000000005
    # or
    # use Math::BigFloat;
    # say Math::BigFloat->new( $dt->epoch ) + Math::BigFloat->new( $dt->nanosecond ) / 1_000_000_000
    # -> 1775769030.0000001
    $dt->jd;            # 2461140.38229167 (Julian Day Number)
    $dt->mjd;           # 61139.8822916667 (Modified Julian Day)

    $dt->offset;                # 32400 (UTC offset in seconds)
    $dt->time_zone;             # "Asia/Tokyo" (DateTime::Lite::TimeZone object)
    $dt->time_zone_long_name;   # "Asia/Tokyo"
    $dt->time_zone_short_name;  # "JST"
    $dt->locale;                # ja-JP (DateTime::Locale::FromCLDR object)
    $dt->is_dst;                # 1 or 0
    $dt->is_leap_year;          # 1 or 0
    $dt->is_finite;             # 1 for normal objects
    $dt->is_infinite;           # 0 for normal objects

    # Internal Rata Die representation
    my( $days, $secs, $ns ) = $dt->utc_rd_values;         # 739715, 76230, 0
    my $rd_secs             = $dt->utc_rd_as_seconds;     # 63911452230
    my( $ld, $ls, $lns )    = $dt->local_rd_values;       # 739716, 22230, 0
    my $local_secs          = $dt->local_rd_as_seconds;   # 63911484630
    my $utc_y               = $dt->utc_year;              # 2027

    # Formatting
    $dt->iso8601;                        # "2026-04-10T06:10:30"
    # alias
    $dt->datetime;
    $dt->ymd;                            # "2026-04-10"
    $dt->ymd('/');                       # "2026/04/10"
    $dt->hms;                            # "06:10:30"
    $dt->dmy('.');                       # "10.04.2026"
    $dt->mdy('-');                       # "10-04-2026"
    $dt->rfc3339;                        # "2026-04-10T06:10:30+09:00"
    $dt->strftime('%Y-%m-%d %H:%M:%S');  # "2026-04-10 06:10:30"
    $dt->format_cldr('yyyy/MM/dd');      # "2026/04/10" (Unicode CLDR pattern)
    "$dt";                               # stringify via iso8601 (or formatter)

    # Arithmetic
    $dt->add( years => 1, months  => 2, days    => 3,
              hours => 4, minutes => 5, seconds => 6 );
    $dt->subtract( weeks => 2 );

    my $dur = DateTime::Lite::Duration->new( months => 6 );
    $dt->add_duration( $dur );
    $dt->subtract_duration( $dur );

    my $diff     = $dt->subtract_datetime( $other );           # Duration
    my $abs_diff = $dt->subtract_datetime_absolute( $other );  # clock-only Duration
    my $dd       = $dt->delta_days( $other );
    my $dmd      = $dt->delta_md( $other );
    my $dms      = $dt->delta_ms( $other );

    # Mutators
    $dt->set( year => 2027, month => 1, day => 1 );
    $dt->set_year(2027);
    $dt->set_month(1);
    $dt->set_day(1);
    $dt->set_hour(0);
    $dt->set_minute(0);
    $dt->set_second(0);
    $dt->set_nanosecond(0);
    $dt->set_time_zone('America/New_York');
    $dt->set_locale('en-US');  # sets a new DateTime::Locale::FromCLDR object
    $dt->set_formatter( $formatter );
    $dt->truncate( to => 'day' );   # 'year','month','week','day','hour','minute','second'

    # Works for second, minute, hour, day, week, local_week, month, quarter,
    # year, decade, century
    $dt->end_of( 'month' );
    say $dt;  # 2026-04-30T23:59:59.999999999
    $dt->start_of( 'month' );
    say $dt;  # 2026-04-01T00:00:00

    # Comparison
    my @sorted = sort { $a <=> $b } @datetimes;  # overloaded <=>
    DateTime::Lite->compare( $dt1, $dt2 );       # -1, 0, 1
    DateTime::Lite->compare_ignore_floating( $dt1, $dt2 );
    $dt->is_between( $lower, $upper );

    # Class-level settings
    DateTime::Lite->DefaultLocale('fr-FR');
    my $class = $dt->duration_class;  # 'DateTime::Lite::Duration'

    # Constants
    DateTime::Lite::INFINITY();        # +Inf
    DateTime::Lite::NEG_INFINITY();    # -Inf
    DateTime::Lite::NAN();             # NaN
    DateTime::Lite::MAX_NANOSECONDS(); # 1_000_000_000
    DateTime::Lite::SECONDS_PER_DAY(); # 86400

    # Error handling
    my $dt2 = DateTime::Lite->new( %bad_args ) ||
        die( DateTime::Lite->error );
    # Chaining: bad calls return a NullObject so the chain continues safely;
    # check the return value of the last call in the chain.
    my $result = $dt->some_method->another_method ||
        die( $dt->error );

=head1 VERSION

    v0.6.3

=head1 DESCRIPTION

C<DateTime::Lite> is a lightweight, memory-efficient, drop-in replacement for L<DateTime> with the following design goals:

=over 4

=item Low dependency footprint

Runtime dependencies are limited to: L<DateTime::Lite::TimeZone> (bundled SQLite timezone data, with automatic fallback to L<DateTime::TimeZone> if L<DBD::SQLite> is unavailable), L<DateTime::Locale::FromCLDR> (locale data via L<Locale::Unicode::Data>'s SQLite backend), L<Locale::Unicode>, and core modules.

The heavy L<Specio>, L<Params::ValidationCompiler>, L<Try::Tiny>, and C<namespace::autoclean> are eliminated entirely.

=item Low memory footprint

C<DateTime> loads a cascade of modules which inflates C<%INC> significantly. C<DateTime::Lite> avoids this via selective lazy loading.

=item Accurate timezone data from TZif binaries

C<DateTime::TimeZone> derives its zone data from the IANA Olson I<source> files (C<africa>, C<northamerica>, etc.) via a custom text parser (C<DateTime::TimeZone::OlsonDB>), then pre-generates one C<.pm> file per zone at distribution build time. This introduces an extra parsing step that is not part of the official IANA toolchain.

C<DateTime::Lite::TimeZone> instead compiles the IANA source files with C<zic(1)>, which is the official IANA compiler, and reads the resulting TZif binary files directly, following L<RFC 9636|https://www.rfc-editor.org/rfc/rfc9636> (TZif versions 1 through 4). Timestamps are stored as signed 64-bit integers, giving a range of roughly C<+/-> 292 billion years.

Crucially, the POSIX footer TZ string embedded in every TZif v2+ file, such as C<EST5EDT,M3.2.0,M11.1.0>, is extracted and stored in the SQLite database.

This string encodes the recurring DST rule for all dates beyond the last explicit transition. At runtime, C<DateTime::Lite::TimeZone> evaluates the footer rule via an XS implementation of the IANA C<tzcode> reference algorithm (see C<dtl_posix.h>, derived from C<tzcode2026a/localtime.c>, public domain), ensuring correct timezone calculations for any date in the future without expanding the full transition table.

=item XS-accelerated hot paths

The XS layer covers all CPU-intensive calendar arithmetic (C<_rd2ymd>, C<_ymd2rd>, C<_seconds_as_components>, all leap-second helpers), plus new functions not in the original: C<_rd_to_epoch>, C<_epoch_to_rd>, C<_normalize_nanoseconds>, and C<_compare_rd>.

=item Compatible API

The public API mirrors L<DateTime> as closely as possible, so existing code using C<DateTime> should work with C<DateTime::Lite> as a drop-in replacement.

=item Full Unicode CLDR / BCP 47 locale support

C<DateTime> is limited to the set of pre-generated C<DateTime::Locale::*> modules, one per locale. C<DateTime::Lite> accepts any valid Unicode CLDR / BCP 47 locale tag, including complex forms with Unicode extensions (C<-u->), transform extensions (C<-t->), and script subtags.

    my $dt = DateTime::Lite->now( locale => 'en' );    # simple form
    my $dt = DateTime::Lite->now( locale => 'en-GB' ); # simple form
    # And more complex forms too
    my $dt = DateTime::Lite->now( locale => 'he-IL-u-ca-hebrew-tz-jeruslm' );
    my $dt = DateTime::Lite->now( locale => 'ja-Kana-t-it' );
    my $dt = DateTime::Lite->now( locale => 'ar-SA-u-nu-latn' );

Locale data is resolved dynamically by L<DateTime::Locale::FromCLDR> via L<Locale::Unicode::Data>, so tags like C<he-IL-u-ca-hebrew-tz-jeruslm> or C<ja-Kana-t-it> work transparently without any additional installed modules.

Additionally, if the locale tag carries a L<Unicode timezone extension|Locale::Unicode/"Unicode extensions"> (C<-u-tz->), and no explicit C<time_zone> argument is provided to the constructor, C<DateTime::Lite> will automatically resolve the corresponding IANA canonical timezone name from it:

    # time_zone is inferred as 'Asia/Jerusalem' from the -u-tz-jeruslm extension
    my $dt = DateTime::Lite->now( locale => 'he-IL-u-ca-hebrew-tz-jeruslm' );
    say $dt->time_zone;            # Asia/Jerusalem
    say $dt->time_zone_long_name;  # Asia/Jerusalem

An explicit C<time_zone> argument always takes priority over the locale extension.

=item No die() in normal operation

Following the L<Module::Generic> / L<Locale::Unicode> error-handling philosophy, C<DateTime::Lite> never calls C<die()> in normal error paths.

Instead it sets a L<DateTime::Lite::Exception> object and returns C<undef> in scalar context, or an empty list in list context.

However, if you really want this module to C<die> upon error, you can pass the C<fatal> option with a true value upon object instantiation.

=back

=head1 KNOWN DIFFERENCES FROM DateTime

=over 4

=item Validation

C<DateTime> uses L<Specio> / L<Params::ValidationCompiler> for constructor validation. C<DateTime::Lite> performs equivalent checks manually. Error messages are similar but not identical.

=item No warnings::register abuse

C<DateTime::Lite> uses C<warnings::enabled> consistently and does not depend on the C<warnings::register> mechanism for user-facing output.

=back

=head1 METHODS NOT IMPLEMENTED

None at this time. If you encounter a method missing from the L<DateTime> API, please file a report.

=head1 CONSTRUCTORS

=head2 new

Accepted parameters are:

=over 4

=item * C<year> (required)

=item * C<month>

=item * C<day>

=item * C<hour>

=item * C<minute>

=item * C<second>

=item * C<nanosecond>

=item * C<time_zone>

The time zone for the datetime. Accepts a zone name, such as C<Asia/Tokyo>), a fixed-offset string, such as C<+09:00>, a L<DateTime::Lite::TimeZone> object, C<UTC>, C<floating>, or C<local>.

If omitted, and the C<locale> argument carries a BCP47 C<-u-tz-> extension, such as C<he-IL-u-ca-hebrew-tz-jeruslm>, the corresponding IANA canonical timezone is resolved automatically. If neither is provided, the default floating timezone is used (or C<$ENV{PERL_DATETIME_DEFAULT_TZ}> if set).

=item * C<locale>

Any valid locale as defined by the Unicode CLDR (Common Locale Data Repository), and BCP47. See L<Locale::Unicode>

=item * C<formatter>

=item * C<fatal>

=back

Returns the new object upon success, or sets an L<error|DateTime::Lite::Exception> and returns C<undef> in scalar context, or an empty list in list context. In chaining (object context), it returns a dummy object (C<DateTime::Lite::Null>) to avoid the typical C<Can't call method '%s' on an undefined value>

=head2 from_day_of_year

    my $dt2 = DateTime::Lite->from_day_of_year(
        year        => 2026,
        day_of_year => 100,
        time_zone   => 'UTC',
        locale      => 'fr-FR',
    );

Constructs from a year and day-of-year (1-366).

Returns the new object upon success, or sets an L<error|DateTime::Lite::Exception> and returns C<undef> in scalar context, or an empty list in list context. In chaining (object context), it returns a dummy object (C<DateTime::Lite::Null>) to avoid the typical C<Can't call method '%s' on an undefined value>

=head2 from_epoch

    my $dt = DateTime::Lite->from_epoch(
        epoch     => 1775769030,
        time_zone => 'Asia/Tokyo',
        locale    => 'ja-JP',
        formatter => $formatter,
    );

Constructs from a Unix epoch value (integer or float). Non-integer values are rounded to the nearest microsecond.

It accepts the C<time_zone>, C<locale>, and C<formatter> parameters.

The returned object will be in the C<UTC> time zone.

If you provide the C<time_zone> argument, it will be applied I<after> the object is instantiated. Thus, the epoch value provided will always be set in the UTC time zone.

For example:

    my $dt = DateTime->from_epoch(
        epoch     => 0,
        time_zone => 'Asia/Tokyo'
    );
    say $dt; # Prints 1970-01-01T09:00:00 as Asia/Tokyo is +09:00 from UTC.
    $dt->set_time_zone('UTC');
    say $dt; # Prints 1970-01-01T00:00:00

Returns the new object upon success, or sets an L<error|DateTime::Lite::Exception> and returns C<undef> in scalar context, or an empty list in list context. In chaining (object context), it returns a dummy object (C<DateTime::Lite::Null>) to avoid the typical C<Can't call method '%s' on an undefined value>

=head2 from_object

    my $dt1 = DateTime->new;
    my $dt = DateTime::Lite->from_object(
        object    => $dt1,
        time_zone => 'Asia/Tokyo',
        locale    => 'ja-JP'
    );

Converts any object implementing C<utc_rd_values()> to a C<DateTime::Lite> instance.

Returns the new object upon success, or sets an L<error|DateTime::Lite::Exception> and returns C<undef> in scalar context, or an empty list in list context. In chaining (object context), it returns a dummy object (C<DateTime::Lite::Null>) to avoid the typical C<Can't call method '%s' on an undefined value>

=head2 last_day_of_month

    my $dt = DateTime::Lite->last_day_of_month(
        year  => 2026,
        month => 4,
    );
    say $dt;  # 2026-04-30T00:00:00

    my $dt = DateTime::Lite->last_day_of_month(
        year      => 2026,
        month     => 4,
        time_zone => 'Asia/Tokyo',
        locale    => 'ja-JP',
        hour      => 6,
        minute    => 10,
        second    => 30
    );
    say $dt;  # 2026-04-30T06:10:30

Constructs on the last day of the given month.

Returns the new object upon success, or sets an L<error|DateTime::Lite::Exception> and returns C<undef> in scalar context, or an empty list in list context. In chaining (object context), it returns a dummy object (C<DateTime::Lite::Null>) to avoid the typical C<Can't call method '%s' on an undefined value>

=head2 now

    my $now = DateTime::Lite->now(
        time_zone => 'Asia/Tokyo',
        locale    => 'ja-JP'
    );

    # time_zone inferred from the -u-tz- BCP47 extension:
    my $now2 = DateTime::Lite->now( locale => 'he-IL-u-ca-hebrew-tz-jeruslm' );
    say $now2->time_zone;            # Asia/Jerusalem
    say $now2->time_zone_long_name;  # Asia/Jerusalem

Returns the current datetime (calls C<from_epoch( epoch => time )>).

If C<time_zone> is omitted and the C<locale> carries a BCP47 C<-u-tz-> extension, as in the example above, the timezone is inferred automatically. See L</new> for the full priority rules.

Returns the new object upon success, or sets an L<error|DateTime::Lite::Exception> and returns C<undef> in scalar context, or an empty list in list context. In chaining (object context), it returns a dummy object (C<DateTime::Lite::Null>) to avoid the typical C<Can't call method '%s' on an undefined value>

=head2 today

    my $dt = DateTime::Lite->today(
        time_zone => 'Asia/Tokyo',
        locale    => 'ja-JP'
    );

Returns the current date truncated to midnight.

This is equivalent to:

    DateTime::Lite->now( @_ )->truncate( to => 'day' );

Returns the new object upon success, or sets an L<error|DateTime::Lite::Exception> and returns C<undef> in scalar context, or an empty list in list context. In chaining (object context), it returns a dummy object (C<DateTime::Lite::Null>) to avoid the typical C<Can't call method '%s' on an undefined value>

=head2 clone

    my $copy = $dt->clone;
    $copy->set_time_zone( 'Asia/Tokyo' );  # does not affect $dt

Returns a new C<DateTime::Lite> object that is an independent deep copy of the invocant. All scalar fields are duplicated, and nested objects (C<tz> and C<locale>) are also independently copied, so mutating the clone does not affect the original.

=head1 ACCESSORS

=head2 year

    my $year = $dt->year;  # e.g. 2026

Returns the year component of the datetime.

=head2 month

    my $m = $dt->month;  # 1..12

Returns the month as a number from 1 (January) to 12 (December).

=head2 mon

Alias for L</month>.

=head2 day

    my $d = $dt->day;

Returns the day of the month (1-31).

=head2 day_of_month

Alias for L</day>.

=head2 hour

    my $h = $dt->hour;

Returns the hour (0-23).

=head2 minute

    my $min = $dt->minute;

Returns the minute (0-59).

=head2 second

    my $s = $dt->second;

Returns the second (0-59, or 60 on a leap second).

=head2 second

    my $s = $dt->second;

Returns the second component of the datetime. The range is normally 0-59, but may be 60 or 61 in exceptional cases:

=over 4

=item C<60>

A positive B<leap second>. The IERS (International Earth Rotation and Reference Systems Service) occasionally inserts an extra second at the end of a UTC day to keep atomic time aligned with the Earth's rotation. When that happens, the clock reads C<23:59:60> before rolling over to midnight.
Since 1972, all leap seconds have been positive (seconds have been added, never removed).

=item C<61>

Reserved by the POSIX standard for a hypothetical double leap second. This has never occurred in practice and is considered extremely unlikely, but the upper bound of 61 is preserved for full standards compliance.

=back

In practice, the vast majority of datetime objects will always return a value in C<0..59>. The constructor accepts values up to 61 and will return an error for anything higher.

=head2 nanosecond

    my $ns = $dt->nanosecond;

Returns the fractional-second component in nanoseconds (0-999_999_999).

=head2 day_of_week

    my $dow = $dt->day_of_week;  # 1=Mon .. 7=Sun

Returns the day of week as a number from 1 (Monday) to 7 (Sunday), following the ISO 8601 convention.

=head2 day_of_year

    my $doy = $dt->day_of_year;

Returns the day of the year (1-366).

=head2 day_abbr

    my $abbr = $dt->day_abbr;  # e.g. "Mon"

Returns the abbreviated weekday name for the current locale.

=head2 day_name

    my $name = $dt->day_name;  # e.g. "Monday"

Returns the full weekday name for the current locale.

=head2 month_0

    my $m0 = $dt->month_0;  # 0=Jan .. 11=Dec

Returns the month as a zero-based number (0-11).

=head2 mon_0

Alias for L</month_0>.

=head2 month_abbr

    my $abbr = $dt->month_abbr;  # e.g. "Jan"

Returns the abbreviated month name for the current locale.

=head2 month_name

    my $name = $dt->month_name;  # e.g. "January"

Returns the full month name for the current locale.

=head2 week

    my( $wy, $wn ) = $dt->week;

Returns a two-element list C<( $week_year, $week_number )> according to ISO 8601 week numbering.

=head2 week_number

    my $wn = $dt->week_number;

Returns the ISO 8601 week number (1-53).

=head2 week_year

    my $wy = $dt->week_year;

Returns the year that the ISO 8601 week belongs to. This may differ from L</year> for days near the start or end of the calendar year.

=head2 quarter

    my $q = $dt->quarter;

Returns the quarter of the year (1-4).

=head2 epoch

    my $ts = $dt->epoch;

Returns the Unix timestamp (seconds since 1970-01-01T00:00:00 UTC) as an integer.

=head2 hires_epoch

    my $ts = $dt->hires_epoch;

Returns the Unix timestamp as a floating-point number (IEEE 754 double) that includes sub-second precision.

B<Precision caveat:> a 64-bit double has ~15-16 significant decimal digits.
A Unix timestamp around 2026 already consumes 10 digits for the integer part, leaving only ~6 digits for the fractional part. This means precision is effectively limited to the microsecond range (~1 µs); nanosecond values smaller than a few hundred nanoseconds will be lost in floating-point rounding.

For full nanosecond precision, combine L</epoch> and L</nanosecond> directly:

    printf "%d.%09d\n", $dt->epoch, $dt->nanosecond;

=head2 jd

    my $jd = $dt->jd;

Returns the Julian Day Number as a floating-point number.

=head2 mjd

    my $mjd = $dt->mjd;

Returns the Modified Julian Day (Julian Day minus 2,400,000.5).

=head2 offset

    my $off = $dt->offset;

Returns the UTC offset in seconds for the current datetime, such as C<32400> for C<+09:00>.

=head2 time_zone

    my $tz = $dt->time_zone;

Returns the L<DateTime::Lite::TimeZone> object associated with this datetime.

=head2 time_zone_long_name

    my $name = $dt->time_zone_long_name;

Returns the long name of the time zone, such as C<America/New_York>.

=head2 time_zone_short_name

    my $abbr = $dt->time_zone_short_name;

Returns the short abbreviation of the time zone in effect at this datetime (e.g. C<EST> or C<EDT>).

=head2 locale

    my $loc = $dt->locale;

Returns the L<DateTime::Locale::FromCLDR> object associated with this datetime.

=head2 is_leap_year

    if( $dt->is_leap_year ) { ... }

Returns true if the year of this datetime is a leap year.

=head2 is_dst

    if( $dt->is_dst ) { ... }

Returns true if daylight saving time is in effect at this datetime.

=head2 is_finite

Returns true (always, for non-infinite objects). See L<DateTime::Lite::Infinite> for the infinite case.

=head2 is_infinite

Returns false (always, for non-infinite objects).

=head2 stringify

    my $str = $dt->stringify;
    print "$dt";   # same thing

Returns the string representation of this datetime. If a formatter has been set via L</set_formatter>, it delegates to C<< $formatter->format_datetime( $self ) >>; otherwise it returns the L</iso8601> string.

This method is also called by the C<""> overloading operator.

=head2 utc_rd_values

    my( $days, $secs, $ns ) = $dt->utc_rd_values;

Returns a three-element list C<( $utc_rd_days, $utc_rd_secs, $rd_nanosecs )>, the internal UTC Rata Die representation.

=head2 utc_rd_as_seconds

    my $rd_secs = $dt->utc_rd_as_seconds;

Returns the internal UTC representation as a single integer: C<utc_rd_days * 86400 + utc_rd_secs>.

=head2 utc_year

    my $uy = $dt->utc_year;

Returns an internal approximation initialised to C<year + 1> to break the circular dependency that arises when computing the UTC offset (you need an approximate year to look up the timezone offset, but you need the offset to know the exact UTC year). The stored value is deliberately equal to or greater than the real UTC year, so it is B<not> suitable for direct use in application code. To obtain the actual UTC year, use:

    $dt->clone->set_time_zone('UTC')->year;

=head2 local_rd_values

    my( $days, $secs, $ns ) = $dt->local_rd_values;

Returns a three-element list C<( $local_rd_days, $local_rd_secs, $rd_nanosecs )>, the internal local-time Rata Die representation.

=head2 local_rd_as_seconds

    my $rd_secs = $dt->local_rd_as_seconds;

Returns the internal local-time representation as a single integer: C<local_rd_days * 86400 + local_rd_secs>.

=head2 duration_class

    my $class = $dt->duration_class;

Returns the string C<DateTime::Lite::Duration>, the class used to construct duration objects.

=head2 DefaultLocale

    # Read the current default
    my $loc = DateTime::Lite->DefaultLocale;

    # Change the default to French
    DateTime::Lite->DefaultLocale( 'fr-FR' );

Class method. Gets or sets the default locale used when constructing new C<DateTime::Lite> objects that do not specify an explicit locale.

The argument must be a valid L<CLDR locale tag|Locale::Unicode>, such as C<en-US>, C<ja-JP>, C<fr-FR>, or even C<ja-Kana-t-it>, or C<he-IL-u-ca-hebrew-tz-jeruslm>. 
The initial default is C<en-US>.

=head1 CONSTANTS

The following constants are exported as zero-argument subs. They are used internally and exposed for completeness.

=head2 INFINITY

    use DateTime::Lite qw();
    my $inf = DateTime::Lite::INFINITY();

Returns positive infinity (C<100**100**100**100>).

=head2 NEG_INFINITY

    my $neg = DateTime::Lite::NEG_INFINITY();

Returns negative infinity (C<-INFINITY>).

=head2 NAN

    my $nan = DateTime::Lite::NAN();

Returns Not-a-Number (C<INFINITY - INFINITY>).

=head2 MAX_NANOSECONDS

    my $max_ns = DateTime::Lite::MAX_NANOSECONDS();

Returns C<1_000_000_000> (10^9), the number of nanoseconds in one second.

=head2 SECONDS_PER_DAY

    my $spd = DateTime::Lite::SECONDS_PER_DAY();

Returns C<86400>, the number of seconds in one day (excluding leap seconds).

=head1 FORMATTING

=head2 strftime( @patterns )

POSIX-style formatting. Supports all standard C<%x> specifiers plus C<%{method_name}> and C<%NNN> for nanoseconds.

=head2 format_cldr( @patterns )

CLDR / Unicode date format patterns (as used in L<DateTime>). Supports all standard CLDR symbols.

=head2 iso8601

    my $str = $dt->iso8601;

Returns the datetime as an ISO 8601 string, such as C<2026-04-09T12:34:56>.

=head2 datetime

Alias for L</iso8601>.

=head2 ymd( [$sep] )

    my $date = $dt->ymd;          # "2026-04-09"
    my $date = $dt->ymd( '/' );   # "2026/04/09"

Returns the date portion as C<YYYY-MM-DD> (default separator C<"-">).

=head2 hms( [$sep] )

    my $time = $dt->hms;          # "12:34:56"
    my $time = $dt->hms( '.' );   # "12.34.56"

Returns the time portion as C<HH:MM:SS> (default separator C<":">>).

=head2 dmy( [$sep] )

    my $dmy = $dt->dmy;           # "09-04-2026"

Returns the date as C<DD-MM-YYYY>.

=head2 mdy( [$sep] )

    my $mdy = $dt->mdy;           # "04-09-2026"

Returns the date as C<MM-DD-YYYY>.

=head2 rfc3339

    my $str = $dt->rfc3339;       # "2026-04-09T12:34:56+09:00" 

Returns an RFC 3339 string. For a UTC datetime this is the same as L</iso8601> with a C<Z> suffix; for other timezones it appends the numeric offset.

=head1 ARITHMETIC

=head2 add( %args )

    $dt->add( years => 1, months => 3 );
    $dt->add( hours => 2, minutes => 30 );

Adds a duration to the datetime in-place (mutates C<$self>). Accepts the same keys as L<DateTime::Lite::Duration/new>: C<years>, C<months>, C<weeks>, C<days>, C<hours>, C<minutes>, C<seconds>, C<nanoseconds>.

Returns C<$self> to allow chaining.

=head2 subtract( %args )

    $dt->subtract( days => 7 );

Subtracts a duration from the datetime in-place (mutates C<$self>). Equivalent to C<< $dt->add >> with all values negated.

=head2 add_duration( $dur )

    my $dur = DateTime::Lite::Duration->new( months => 2 );
    $dt->add_duration( $dur );

Adds a L<DateTime::Lite::Duration> object to the datetime in-place (mutates C<$self>).

Returns C<$self> to allow chaining.

=head2 subtract_duration( $dur )

    $dt->subtract_duration( $dur );

Subtracts a L<DateTime::Lite::Duration> object from the datetime in-place (mutates C<$self>). Equivalent to C<< $dt->add_duration( $dur->inverse ) >>.

=head2 subtract_datetime( $dt )

Returns a L<DateTime::Lite::Duration> representing the difference between two C<DateTime::Lite> objects (calendar-aware).

=head2 subtract_datetime_absolute( $dt )

Returns a L<DateTime::Lite::Duration> representing the absolute UTC difference in seconds/nanoseconds.

=head2 delta_days( $dt )

    my $dur = $dt1->delta_days( $dt2 );
    printf "%d days apart\n", $dur->days;

Returns a L<DateTime::Lite::Duration> containing only a C<days> component representing the number of whole days between C<$self> and C<$dt>.

=head2 delta_md( $dt )

    my $dur = $dt1->delta_md( $dt2 );

Returns a L<DateTime::Lite::Duration> with C<months> and C<days> components (calendar-aware difference).

=head2 delta_ms( $dt )

    my $dur = $dt1->delta_ms( $dt2 );

Returns a L<DateTime::Lite::Duration> with C<minutes> and C<seconds> components (absolute clock difference).

=head1 SETTERS

=head2 set

    $dt->set( hour => 0, minute => 0, second => 0 );

Sets one or more datetime components in-place. Accepted keys are any of C<year>, C<month>, C<day>, C<hour>, C<minute>, C<second>, C<nanosecond>. Returns C<$self>.

=head2 set_year

    $dt->set_year(2030);

Sets the year component. Returns C<$self>.

=head2 set_month

    $dt->set_month(12);

Sets the month (1-12). Returns C<$self>.

=head2 set_day

    $dt->set_month(31);

Sets the day of the month. Returns C<$self>.

=head2 set_hour

    $dt->set_hour(14);

Sets the hour (0-23). Returns C<$self>.

=head2 set_minute

    $dt->set_minute(40);

Sets the minute (0-59). Returns C<$self>.

=head2 set_second

    $dt->set_second(30);

Sets the second (0-59). Returns C<$self>.

=head2 set_nanosecond

    $dt->set_nanosecond(1000);

Sets the nanosecond component (0-999_999_999). Returns C<$self>.

=head2 set_locale

    $dt->set_locale( 'zh-TW' );

Sets the locale. Accepts a CLDR locale string, such as C<fr-FR>, or a L<DateTime::Locale::FromCLDR> object. Returns C<$self>.

=head2 set_formatter

    $dt->set_formatter( $my_formatter );

Sets the formatter object used by L</stringify>. Must respond to C<format_datetime>. Pass C<undef> to revert to the default ISO 8601 representation.

=head2 set_time_zone

    $dt->set_time_zone( 'Asia/Tokyo' );

Changes the time zone of the datetime in-place. Accepts a time zone name string, such as C<America/New_York>, or a L<DateTime::Lite::TimeZone> object. Returns C<$self>.

=head2 end_of

    my $dt = DateTime::Lite->new(
        year      => 2026,
        month     => 4,
        day       => 15,
        hour      => 14,
        minute    => 32,
        second    => 47,
        time_zone => 'UTC',
    );
    $dt->end_of( 'month' );
    say $dt;  # 2026-04-30T23:59:59.999999999

Modifies the object in place to represent the last instant of the given unit.
Supported units are: C<second>, C<minute>, C<hour>, C<day>, C<week>, C<local_week>, C<month>, C<quarter>, C<year>, C<decade>, C<century>.

The result is the last nanosecond before the start of the next unit, so the timezone and variable-length units such as months and years are handled correctly without hardcoding boundary values.

Returns the modified object on success, or sets an L<error object|DateTime::Lite::Exception> and returns C<undef> in scalar context, or an empty list in list context. In chaining (object context), it returns a dummy object (C<DateTime::Lite::Null>) to avoid the typical C<Can't call method '%s' on an undefined value>

See also L</start_of> and L</truncate>.

=head2 start_of

    my $dt = DateTime::Lite->new(
        year      => 2026,
        month     => 4,
        day       => 15,
        hour      => 14,
        minute    => 32,
        second    => 47,
        time_zone => 'UTC',
    );
    $dt->start_of( 'month' );
    say $dt;  # 2026-04-01T00:00:00

Modifies the object in place to represent the first instant of the given unit.
Supported units are: C<second>, C<minute>, C<hour>, C<day>, C<week>, C<local_week>, C<month>, C<quarter>, C<year>, C<decade>, C<century>.

For most units this delegates to L</truncate>. C<decade> and C<century> are handled independently: C<start_of('decade')> for 2026 returns 2020-01-01, and C<start_of('century')> returns 2001-01-01.

Returns the modified object on success, or sets an L<error object|DateTime::Lite::Exception> and returns C<undef> in scalar context, or an empty list in list context. In chaining (object context), it returns a dummy object (C<DateTime::Lite::Null>) to avoid the typical C<Can't call method '%s' on an undefined value>

See also L</end_of> and L</truncate>.

=head2 truncate

    $dt->truncate( to => 'day' );   # sets h/m/s/ns to zero

Truncates the datetime to the given precision level. Accepted values for C<to>: C<year>, C<month>, C<week>, C<local_week>, C<day>, C<hour>, C<minute>, C<second>.

=head1 COMPARISON

=head2 compare( $dt1, $dt2 )

Class or instance method. Compares two C<DateTime::Lite> objects. Returns -1 if C<$dt1> is earlier, 0 if equal, 1 if later.

Uses the XS C<_compare_rd()> fast-path when the XS layer is loaded.

    my $cmp = DateTime::Lite->compare( $dt1, $dt2 );

Can also be used via the overloaded C<< <=> >> and C<cmp> operators:

    my @sorted = sort { $a <=> $b } @datetimes;

=head2 compare_ignore_floating( $dt1, $dt2 )

Like L</compare>, but treats floating-timezone datetimes as if they share the same UTC offset as the other operand. Useful when comparing local wall-clock times regardless of timezone.

=head2 is_between( $lower, $upper )

Returns true if C<$self> is strictly between the two boundaries.

=head2 error

    my $dt = DateTime::Lite->new( %bad_args );
    if( !defined( $dt ) )
    {
        my $err = DateTime::Lite->error;
        warn "Error: $err";
    }

Instance and class method. When called with a message, constructs a L<DateTime::Lite::Exception> object, stores it internally, and either warns (if C<fatal> mode is off) or C<die>s (if C<fatal> mode is on). Returns C<undef> in scalar context, an empty list in list context.

When called without arguments, returns the most recent error object (or C<undef> if no error has occurred).

=head2 pass_error

    sub my_method
    {
        my $self = shift( @_ );
        my $tz = DateTime::Lite::TimeZone->new( name => 'Invalid' ) ||
            return( $self->pass_error );
        ...
    }

Propagates the error stored in another object (or the class-level error) into the current object's error slot, without constructing a new exception. Used internally when a lower-level call fails and the caller wants to surface the same error to its own caller.

=head1 LOW-LEVEL XS UTILITIES

=head2 posix_tz_lookup

    my $r = DateTime::Lite->posix_tz_lookup( 1775769030, 'EST5EDT,M3.2.0,M11.1.0' );
    my $r = $dt->posix_tz_lookup( 1775769030, 'EST5EDT,M3.2.0,M11.1.0' );
    if( defined( $r ) )
    {
        say $r->{offset};     # -14400  (seconds east of UTC)
        say $r->{is_dst};     # 1
        say $r->{short_name}; # "EDT"
    }

Given a Unix timestamp (signed 64-bit integer, representing the number of seconds since 1970-01-01T00:00:00 UTC), and a POSIX TZ footer string, it parses the footer string, and resolves the UTC offset, DST flag, and timezone abbreviation for the given Unix timestamp.

This is the low-level function used internally by L<DateTime::Lite::TimeZone> to handle dates beyond the last explicit transition stored in the TZif database.

The first argument may be either a class name or an instance; both forms are accepted.

The POSIX TZ footer string comes from the TZif v2+ files, and looks like C<EST5EDT,M3.2.0,M11.1.0> or C<JST-9> or C<< <+0545>-5:45 >>.

The implementation is in C via F<dtl_posix.h>, derived from the IANA C<tzcode> reference implementation (public domain). It handles all POSIX TZ string rule forms (C<Jn> julian day, C<n> zero-based julian day, and C<Mm.w.d> month/week/day), as well as the L<RFC 9636|https://www.rfc-editor.org/rfc/rfc9636.html> extensions for TZif v3+:

=over 4

=item C<Jn>

Julian day (1-365, no leap day)

=item C<n>

zero-based Julian day (0-365, counts leap day)

=item C<Mm.w.d>

month/week/day rule (e.g. C<M3.2.0> = second Sunday of March)

=back

It also handles quoted angle-bracket abbreviations such as C<< <+0545> >>, fractional offsets, negative and greater-than-24-hour transition times (L<RFC 9636 section 3.3.2|https://www.rfc-editor.org/rfc/rfc9636.html#name-tz-string-extension> extensions for TZif v3+), and southern-hemisphere DST where the DST period wraps around the year boundary (start > end).

Returns a hashref with three keys on success:

=over 4

=item C<offset>

The UTC offset in seconds east of UTC (negative for zones west of UTC, such as C<-18000> for EST).

=item C<is_dst>

C<1> if the timestamp falls within a DST period, C<0> otherwise.

=item C<short_name>

The timezone abbreviation, such as C<EDT>, C<JST>, or C<< +0545 >>.

=back

Returns C<undef> if C<$tz_string> cannot be parsed.

This method is primarily intended for advanced use cases, such as building custom timezone libraries on top of C<DateTime::Lite::TimeZone>. Most users will not need to call it directly.

=head1 SERIALISATION

C<STORABLE_freeze> and C<STORABLE_thaw> are implemented, compatible with L<Storable>.

C<FREEZE> and C<THAW> are also implemented compatible with L<Sereal> or L<CBOR>

=head1 ERROR HANDLING

On error, this class methods set an L<exception object|DateTime::Lite::Exception>, and return C<undef> in scalar context, or an empty list in list context. The exception object is accessible via:

    my $err = DateTime::Lite->error;   # class method
    my $err = $dt->error;              # instance method

The exception object stringifies to a human-readable message including file and line number.

C<error> detects the context is chaining, or object, and thus instead of returning C<undef>, it will return a dummy instance of C<DateTime::Lite::Null> to avoid the typical perl error C<Can't call method '%s' on an undefined value>.

So for example:

    $dt->now( %bad_arguments )->subtract( %params );

If there was an error in C<now>, the chain will execute, but the last one, C<subtract> in this example, will return C<undef>, so you can and even should check the return value:

    $dt->now( %bad_arguments )->subtract( %params ) ||
        die( $dt->error );

=head1 PERFORMANCE

This section compares C<DateTime::Lite> with the reference implementation L<DateTime> 1.66 on four axes: module footprint, load time, memory, and CPU throughput. The figures below were recorded on an C<aarch64> machine running Perl 5.36.1. Run C<scripts/benchmark.pl> (bundled in this distribution) to reproduce them on your own hardware.

The goal of this comparison is not to disparage L<DateTime>, which is a mature, feature-complete, and battle-tested library, but to make the trade-offs explicit so you can choose the right tool for your context.

=head2 Module footprint

The number of files loaded into C<%INC>, directly and indirectly through dependencies, when C<use DateTime> or C<use DateTime::Lite> is evaluated:

                          DateTime 1.66   DateTime::Lite
    -------               -------------   --------------
    use Module                      137               67
    TimeZone class alone            105               47
    Runtime prereqs (META)           23               11

C<DateTime> depends on L<Specio>, L<Params::ValidationCompiler>, L<namespace::autoclean>, and several supporting modules that collectively account for the extra overhead. C<DateTime::Lite> replaces this validation layer with lightweight hand-written checks and uses L<DateTime::Locale::FromCLDR> instead of the heavier L<DateTime::Locale> stack.

C<DateTime::TimeZone> loads 105 modules because it ships one C<.pm> file per IANA zone, such as C<DateTime::TimeZone::America::New_York>, all loaded on the first C<new()> call. C<DateTime::Lite::TimeZone> loads, directly and indirectly, 47 modules and stores all zone data in a single SQLite file instead.

=head2 Load time

Measured as C<time()> around a cold C<require> (modules not yet in C<%INC>):

                               DateTime 1.66   DateTime::Lite
    -------                    -------------   --------------
    require Module                     48 ms            32 ms
    require TimeZone standalone       180 ms           100 ms

Startup time matters in short-lived scripts (cron jobs, CLI tools, CGI) where the process initialisation is a significant fraction of total runtime. For a long-running Apache2/mod_perl2, Plack, or Mojolicious service, this cost is paid once and amortised over millions of requests.

=head2 Memory (RSS after loading)

Measured in a clean Perl process immediately after C<use Module>:

                          DateTime 1.66   DateTime::Lite
    -------               -------------   --------------
    use Module (~28 MB)        ~28 MB           ~37 MB
    TimeZone class only        ~19 MB           ~16 MB

The C<use Module> row is somewhat misleading on its own: C<DateTime::Lite> loads C<DBD::SQLite>, which embeds a complete compiled SQLite engine (~14 MB of native code) regardless of how many timezone objects you create. When measuring the C<TimeZone> class in isolation, the component that actually handles date arithmetic, C<DateTime::Lite::TimeZone> is lighter (~16 MB vs ~19 MB) because it does not pre-load all Olson zone data into RAM.

C<DateTime::TimeZone> pre-loads all IANA Olson definitions into memory on the first C<new()> call (roughly 3-4 MB of compiled Perl structures on top of the module overhead). C<DateTime::Lite::TimeZone> queries a compact SQLite database on demand and keeps those structures on disk.

=head2 CPU throughput (10,000 iterations, µs per call)

                                        DateTime 1.66   DateTime::Lite
    -------                             -------------   --------------
    new( UTC )                                 ~13 µs          ~10 µs
    new( named zone, string )                  ~25 µs          ~64 µs  (*)
    new( named zone, all caches enabled )      ~25 µs          ~14 µs
    now( UTC )                                 ~11 µs          ~10 µs
    year + month + day + epoch                ~0.5 µs         ~0.4 µs
    clone + add( days + hours )                ~35 µs          ~25 µs
    strftime                                  ~3.5 µs         ~3.6 µs
    TimeZone->new (warm, no mem cache)          ~2 µs          ~19 µs  (*)
    TimeZone->new (mem cache enabled)           ~2 µs         ~0.4 µs

Rows marked C<(*)> reflect the default behaviour without the memory cache.
With C<< DateTime::Lite::TimeZone->enable_mem_cache >> active, C<TimeZone->new> drops to ~0.4 µs and C<new(named zone)> drops to ~14 µs, which is faster than C<DateTime> (~25 µs). See L</TimeZone caching model> for the full explanation.

For UTC construction, C<now()>, accessors, arithmetic, and formatting, C<DateTime::Lite> is equivalent or faster. The XS-accelerated clone and the lighter validation layer account for the gain in arithmetic.

=head2 TimeZone caching model

This is the single most important trade-off to understand.

B<DateTime::TimeZone> loads the complete set of IANA time zone rules into RAM the first time any named zone is constructed (~180 ms startup, ~4 MB of in-memory hash structures). Every subsequent C<< DateTime::TimeZone->new( name => $name ) >> call is served from that hash in about 4 µs. If you construct thousands of C<DateTime> objects per second in a long-lived process, this model is very fast after the initial warm-up.

B<DateTime::Lite::TimeZone> stores the same IANA data in a compact SQLite database (C<tz.sqlite3>, included in the distribution). The first call for a given zone name runs a query (~22 ms) and populates a per-instance cache; subsequent calls for the same zone use a cached C<DBD::SQLite> prepared statement and return in ~130 µs. There is no process-wide singleton by default, so two calls with the same name each incur the 130 µs cost.

B<Optional memory cache:>  C<DateTime::Lite::TimeZone> also provides an opt-in process-level memory cache that matches or beats C<DateTime::TimeZone> on per-call speed:

    # Enable once at application start-up:
    DateTime::Lite::TimeZone->enable_mem_cache;

    # Or per call:
    my $tz = DateTime::Lite::TimeZone->new(
        name          => 'America/New_York',
        use_cache_mem => 1,
    );

With the memory cache active, repeated C<new()> calls for the same zone return the cached object from a plain hash lookup in about 0.8 µs:

                              DateTime::TimeZone   DateTime::Lite::TimeZone
    ------                    -----------------   ------------------------
    Cold first call                    ~225 ms                      ~22 ms
    Warm (no mem cache)                  ~2 µs                      ~19 µs
    Warm (mem cache only)                ~2 µs                      ~0.4 µs
    Warm (mem+span+footer cache)         ~2 µs                      ~0.4 µs
    new(named zone, all caches)         ~25 µs                      ~14 µs

Practical guidance:

=over 4

=item *

For long-lived services constructing datetime objects with named zones, call C<< DateTime::Lite::TimeZone->enable_mem_cache >> once at startup.
This activates three layers of caching:

=over 4

=item 1. the object cache (avoids SQLite construction);

=item 2. the span cache (avoids the UTC offset query); and

=item 3. the footer cache (avoids the POSIX DST rule calculation).

=back

With all layers warm, C<new(named zone)> costs ~14 µs, which is faster than C<DateTime> (~25 µs).

=item *

If you prefer explicit control, pass C<< use_cache_mem => 1 >> on each individual C<new()> call, or construct one C<TimeZone> object and reuse it:

    my $tz = DateTime::Lite::TimeZone->new( name => 'America/New_York' );
    my $dt = DateTime::Lite->new( ..., time_zone => $tz );

=item *

For batch processing (log parsing, ETL, report generation) where timezone construction is a small fraction of total I/O time, the difference is imperceptible regardless of which option you choose.

=item *

For short-lived scripts and command-line tools, C<DateTime::Lite> wins on both startup time (~120 ms vs ~320 ms) and memory (~19 MB vs ~28 MB).

=back

=head2 Running the benchmark

A self-contained benchmark script is included in the distribution:

    cd DateTime-Lite-vX.X.X
    perl Makefile.PL && make  # make sure the XS code is compiled
    perl -Iblib/lib -Iblib/arch scripts/benchmark.pl

    # More iterations for stable numbers:
    perl -Iblib/lib -Iblib/arch scripts/benchmark.pl --iterations 50000

    # Machine-readable CSV output:
    perl -Iblib/lib -Iblib/arch scripts/benchmark.pl --csv > results.csv

=head1 USAGE

=head2 0-based Versus 1-based Numbers

C<DateTime::Lite> follows a simple rule for 0-based vs. 1-based numbers.

Month, day of month, day of week, and day of year are B<1-based>. Every 1-based method also has a C<_0> variant. For example, C<day_of_week> returns 1 (Monday) through 7 (Sunday), while C<day_of_week_0> returns 0 through 6.

All I<time>-related values (hour, minute, second) are B<0-based>.

Years are neither, as they can be positive or negative. There is a year 0.

There is no C<quarter_0> method.

=head2 Floating DateTimes

The default time zone for new C<DateTime::Lite> objects (except where stated otherwise) is the C<floating> time zone. This concept comes from the iCal standard. A floating datetime is not anchored to any particular time zone and does not include leap seconds, since those require a real time zone to apply.

Date math and comparison between a floating datetime and one with a real time zone produce results of limited validity, because one includes leap seconds and the other does not.

If you plan to use objects with a real time zone, it is strongly recommended that you B<do not> mix them with floating datetimes.

=head2 Determining the Local Time Zone Can Be Slow

If C<$ENV{TZ}> is not set, looking up the local time zone may involve reading several files in F</etc>. If you know the local time zone will not change during your program's lifetime and you need many objects for that zone, cache it once:

    my $local_tz = DateTime::Lite::TimeZone->new( name => 'local' );

    my $dt = DateTime::Lite->new( ..., time_zone => $local_tz );

C<DateTime::Lite::TimeZone> also provides a process-level cache that eliminates
this cost entirely:

    DateTime::Lite::TimeZone->enable_mem_cache;
    my $dt = DateTime::Lite->new( ..., time_zone => 'local' );

=head2 Far Future DST

For dates very far in the future (thousands of years from now), C<DateTime> with named time zones can consume large amounts of memory because C<DateTime::TimeZone> pre-computes all DST transitions from the present to that
date.

C<DateTime::Lite> is not affected by this problem. C<DateTime::Lite::TimeZone> uses a compact SQLite database and a POSIX footer TZ string to derive the correct offset for any future date without expanding the full transition table.

=head2 Globally Setting a Default Time Zone

B<Warning: this is very dangerous. Use at your own risk.>

You can force C<DateTime::Lite> to use a specific default time zone by setting:

    $ENV{PERL_DATETIME_DEFAULT_TZ} = 'America/New_York';

This affects all code that creates a C<DateTime::Lite> object, including any CPAN modules you use. Audit your dependencies before using this in production.

=head2 Upper and Lower Bounds

Internally, dates are stored as the number of days before or after C<0001-01-01>, held in a Perl integer. The usable range depends on your platform's integer size (C<$Config{ivsize}>):

=over 4

=item * B<32-bit Perl:> approximately year C<+/-1,469,903>

=item * B<64-bit Perl:> approximately year C<+/-12,626,367,463,883,278>

=back

=head2 Overloading

C<DateTime::Lite> overloads the following operators:

=over 4

=item * B<C<+>> - adds a L<DateTime::Lite::Duration> to a datetime, returning a new datetime.

=item * B<C<->> - either subtracts a duration from a datetime (returning a new datetime), or subtracts two datetimes (returning a L<DateTime::Lite::Duration>).

=item * B<C<< <=> >>  and  B<C<cmp>>> - numeric and string comparison, for use with C<sort> and comparison operators.

=item * B<C<"">> (stringification) - calls L<stringify|/stringify>, which delegates to the formatter if set, otherwise returns the L<iso8601|/iso8601> string.

=item * B<C<bool>> - always true for finite objects.

=back

The C<fallback> parameter is set, so derived operators (C<+=>, C<-=>, etc.) work as expected. Do not expect C<++> or C<--> to be useful.

    my $dt2 = $dt + $duration;  # new datetime
    my $dt3 = $dt - $duration;  # new datetime
    my $dur = $dt - $other_dt;  # Duration

    for my $dt ( sort @datetimes ) { ... }  # uses <=>

=head2 Formatters And Stringification

You can supply a C<formatter> object to control how a datetime is stringified.
Any constructor accepts a C<formatter> argument:

    my $fmt = DateTime::Format::Unicode->new( locale => 'fr-FR' );
    my $dt  = DateTime::Lite->new( year => 2026, formatter => $fmt );

Or set it afterwards:

    $dt->set_formatter( $fmt );
    my $current_fmt = $dt->formatter;

Once set, C<$dt> will call C<< $fmt->format_datetime($dt) >> instead of L<iso8601|/iso8601>. Pass C<undef> to revert to the default.

A formatter must implement a C<format_datetime($dt)> method. The L<DateTime::Format::Unicode> module (available separately on CPAN) provides a full-featured CLDR formatter with support for date/time intervals and additional pattern tokens not covered by L<format_cldr|/format_cldr>.

=head1 CLDR PATTERNS

The CLDR (Unicode Common Locale Data Repository) pattern language is more powerful and more complex than strftime. Unlike strftime, patterns are plain letters with no prefix, so any literal text must be quoted.

=head2 Quoting and escaping

Surround literal ASCII letters with single quotes (C<'>). To include a literal single quote, write two consecutive single quotes (C<''>). Spaces and non-letter characters are always passed through unchanged.

    my $p1 = q{'Today is ' EEEE};           # "Today is Thursday"
    my $p2 = q{'It is now' h 'o''clock' a}; # "It is now 9 o'clock AM"

=head2 Pattern length and padding

Most patterns pad with leading zeroes when the specifier is longer than one character. For example, C<h> gives C<9> but C<hh> gives C<09>. The exception is that B<five> of a letter usually means the narrow form, such as C<EEEEE> gives C<T> for Thursday, not a five-character wide value.

=head2 Format vs. stand-alone forms

Many tokens have a I<format> form (used inside a larger string) and a I<stand-alone> form (used alone, such as in a calendar header). They are distinguished by case: C<M> is format, C<L> is stand-alone for months; C<E>/C<e> is format, C<c> is stand-alone for weekdays.

=head2 Token reference

    Era
      G{1,3}   abbreviated era (BC, AD)
      GGGG     wide era (Before Christ, Anno Domini)
      GGGGG    narrow era

    Year
      y        year, zero-padded as needed
      yy       two-digit year (special case)
      Y{1,}    week-of-year calendar year (from week_year)
      u{1,}    same as y, but yy is not special

    Quarter
      Q{1,2}   quarter as number (1-4)
      QQQ      abbreviated format quarter
      QQQQ     wide format quarter
      q{1,2}   quarter as number (stand-alone)
      qqq      abbreviated stand-alone quarter
      qqqq     wide stand-alone quarter

    Month
      M{1,2}   numerical month (format)
      MMM      abbreviated format month name
      MMMM     wide format month name
      MMMMM    narrow format month name
      L{1,2}   numerical month (stand-alone)
      LLL      abbreviated stand-alone month name
      LLLL     wide stand-alone month name
      LLLLL    narrow stand-alone month name

    Week
      w{1,2}   week of year (from week_number)
      W        week of month (from week_of_month)

    Day
      d{1,2}   day of month
      D{1,3}   day of year
      F        day of week in month (from weekday_of_month)
      g{1,}    modified Julian day (from mjd)

    Weekday
      E{1,3}   abbreviated format weekday
      EEEE     wide format weekday
      EEEEE    narrow format weekday
      e{1,2}   locale-based numeric weekday (1 = first day of week for locale)
      eee      abbreviated format weekday (same as E{1,3})
      eeee     wide format weekday
      eeeee    narrow format weekday
      c        numeric weekday, Monday = 1 (stand-alone)
      ccc      abbreviated stand-alone weekday
      cccc     wide stand-alone weekday
      ccccc    narrow stand-alone weekday

    Period
      a        AM or PM (localized)

    Hour
      h{1,2}   hour 1-12
      H{1,2}   hour 0-23
      K{1,2}   hour 0-11
      k{1,2}   hour 1-24
      j{1,2}   locale-preferred hour (12h or 24h)

    Minute / Second
      m{1,2}   minute
      s{1,2}   second
      S{1,}    fractional seconds (without decimal point)
      A{1,}    millisecond of day

    Time zone
      z{1,3}   short time zone name
      zzzz     long time zone name
      Z{1,3}   time zone offset (e.g. -0500)
      ZZZZ     short name + offset (e.g. CDT-0500)
      ZZZZZ    sexagesimal offset (e.g. -05:00)
      v{1,3}   short time zone name
      vvvv     long time zone name
      V{1,3}   short time zone name
      VVVV     long time zone name

The following tokens are B<not supported> by C<format_cldr()> but are supported by L<DateTime::Format::Unicode>:

=over 4

=item * C<b> / C<B> - period and flexible period of day (C<noon>, C<at night>...)

=item * C<O> / C<OOOO> - localized GMT format (C<GMT-8>, C<GMT-08:00>)

=item * C<r> - related Gregorian year

=item * C<x>/C<X> - ISO 8601 timezone offsets with optional C<Z>

=back

=head2 CLDR Available Formats

The CLDR data includes locale-specific pre-defined format skeletons. A skeleton is a pattern key that maps to a locale-appropriate rendering pattern. For example, the skeleton C<MMMd> maps to C<MMM d> in C<en-US> (giving C<Apr 9>) and to C<d MMM> in C<fr-FR> (giving C<9 avr.>).

Retrieve the locale-specific pattern via the locale object and pass it to C<format_cldr>:

    say $dt->format_cldr( $dt->locale->available_format('MMMd') );
    say $dt->format_cldr( $dt->locale->available_format('yQQQ') );
    say $dt->format_cldr( $dt->locale->available_format('hm') );

See L<DateTime::Locale::FromCLDR/available_formats> for the full list of skeletons for any given locale.

=head2 DateTime::Format::Unicode

For more advanced formatting, including features not covered by C<format_cldr()>, use L<DateTime::Format::Unicode> (available separately on CPAN). It provides:

=over 4

=item * Support for the additional tokens listed above (C<b>, C<B>, C<O>, C<r>, C<x>, C<X>)

=item * Formatting of datetime B<intervals>, such as "Apr 9 - 12, 2026"

=item * Full CLDR number system support (Arabic-Indic numerals, etc.)

=item * Any CLDR locale, including complex tags such as C<es-419-u-ca-gregory>

=back

    use DateTime::Format::Unicode;

    my $fmt = DateTime::Format::Unicode->new(
        locale  => 'ja-JP',
        pattern => 'GGGGy年M月d日（EEEE）',
    ) || die( DateTime::Format::Unicode->error );

    say $fmt->format_datetime( $dt );

    # Interval formatting:
    my $fmt2 = DateTime::Format::Unicode->new(
        locale  => 'en',
        pattern => 'GyMMMd',
    );
    say $fmt2->format_interval( $dt1, $dt2 );  # e.g. "Apr 9 - 12, 2026"

=head1 HOW DATETIME MATH WORKS

Date math in C<DateTime::Lite> follows the same model as L<DateTime>. The key distinction is between I<calendar units> (months, days) and I<clock units> (minutes, seconds, nanoseconds). Understanding this distinction is essential for correct results.

=head2 Duration buckets

A L<DateTime::Lite::Duration> stores its components in five independent I<buckets>: months, days, minutes, seconds, nanoseconds. Each bucket is kept as a signed integer. The buckets are B<not normalised> against each other: a duration of C<< { months => 1, days => 31 } >> is distinct from C<< { months => 2, days => 0 } >> because the number of days in a month varies.

=head2 Calendar vs. clock units

I<Calendar units> (months, days) are relative: their real duration depends on the datetime to which they are applied. I<Clock units> (minutes, seconds, nanoseconds) are absolute.

When L<add|/add> applies a duration, calendar units are applied first, then clock units:

    $dt->add( months => 1, hours => 2 );
    # Step 1: advance by 1 month  (calendar)
    # Step 2: advance by 2 hours  (clock)

=head2 End-of-month handling

Adding months to a date whose day is beyond the end of the target month requires a policy decision. L<DateTime::Lite::Duration> supports three C<end_of_month> modes:

=over 4

=item * C<wrap> (default) - wrap into the next month. January 31 + 1 month = March 3 (or 2 in leap years).

=item * C<limit> - clamp to the last day of the target month. January 31 + 1 month = February 28 (or 29 in leap years).

=item * C<preserve> - like C<limit>, but remember that the original day was at the end of month, so a further addition of one month will also land on the last day.

=back

=head2 Subtraction

C<< $dt1->subtract_datetime( $dt2 ) >> returns a duration representing the difference. The calendar part is computed in months and days (from the local dates), and the clock part in seconds and nanoseconds (from the UTC representations). This is the most commonly useful result.

C<< $dt1->subtract_datetime_absolute( $dt2 ) >> returns a duration in pure clock units (seconds and nanoseconds), based on the UTC epoch difference. This is useful when you need an exact elapsed time independent of DST changes.

=head2 Leap seconds

C<DateTime::Lite> handles leap seconds when the time zone is not floating.
Adding a duration in clock units across a leap second boundary will correctly account for the extra second.

=head1 SEE ALSO

L<DateTime>, L<DateTime::Lite::Duration>, L<DateTime::Lite::Exception>, L<DateTime::Lite::Infinite>, L<DateTime::Locale::FromCLDR>, L<Locale::Unicode::Data>, L<DateTime::Format::Unicode>

=head1 CREDITS

Credits to the original author of L<DateTime>, Dave Rolsky and all the contributors for their great work on which this module L<DateTime::Lite> is derived.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
