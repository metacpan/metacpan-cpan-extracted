##----------------------------------------------------------------------------
## DateTime::Format::Unicode - ~/lib/DateTime/Format/Unicode.pm
## Version v0.1.2
## Copyright(c) 2024 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2024/07/21
## Modified 2024/09/17
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package DateTime::Format::Unicode;
BEGIN
{
    use v5.10;
    use strict;
    use warnings;
    use warnings::register;
    use vars qw(
        $ERROR $VERSION $DEBUG $ON_ERROR
    );
    use DateTime::Locale::FromCLDR;
    use POSIX ();
    use Scalar::Util;
    use Want;
    our $VERSION = 'v0.1.2';
};

use strict;
use warnings;

sub new
{
    my $this = shift( @_ );
    my $self = bless( {} => ( ref( $this ) || $this ) );
    my @args = @_;
    if( scalar( @args ) == 1 &&
        defined( $args[0] ) &&
        ref( $args[0] ) eq 'HASH' )
    {
        my $opts = shift( @args );
        @args = %$opts;
    }
    elsif( ( scalar( @args ) % 2 ) )
    {
        return( $self->error( sprintf( "Uneven number of parameters provided (%d). Should receive key => value pairs. Parameters provided are: %s", scalar( @args ), join( ', ', @args ) ) ) );
    }

    $self->{on_error} = $ON_ERROR if( defined( $ON_ERROR ) && ( ref( $ON_ERROR ) eq 'CODE' || $ON_ERROR eq 'fatal' ) );
    for( my $i = 0; $i < scalar( @args ); $i++ )
    {
        if( $args[$i] eq 'on_error' )
        {
            my $v = $args[$i+1];
            splice( @args, $i, 2 );
            unshift( @args, 'on_error', $v );
            last;
        }
    }
    # Then, if the user provided with an hash or hash reference of options, we apply them
    for( my $i = 0; $i < scalar( @args ); $i++ )
    {
        my $name = $args[ $i ];
        my $val  = $args[ ++$i ];
        my $meth = $self->can( $name );
        if( !defined( $meth ) )
        {
            return( $self->error( "Unknown method \"${meth}\" provided." ) );
        }
        elsif( !defined( $meth->( $self, $val ) ) )
        {
            if( defined( $val ) && $self->error )
            {
                return( $self->pass_error );
            }
        }
    }
    my $locale;
    if( !( $locale = $self->{locale} ) )
    {
        $locale = $self->locale( 'en' ) ||
            return( $self->pass_error );
    }
    if( !$self->{time_zone} )
    {
        $self->time_zone( 'floating' ) || return( $self->pass_error );
    }
    if( !$self->{pattern} )
    {
        $self->{pattern} = $locale->date_format_medium ||
            return( $self->error( "No default pattern (medium date format) available for locale ${locale} in DateTime::Locale::FromCLDR" ) );
    }
    return( $self );
}

sub error
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $msg = join( '', map( ( ref( $_ ) eq 'CODE' ) ? $_->() : $_, @_ ) );
        $self->{error} = $ERROR = DateTime::Format::Unicode::Exception->new({
            skip_frames => 1,
            message => $msg,
        });
        warn( $msg ) if( warnings::enabled() );
        my $on_error = $self->{on_error};
        if( ref( $on_error ) eq 'CODE' )
        {
            $on_error->( $self->{error} );
        }
        elsif( $on_error eq 'fatal' )
        {
            die( $self->{error} );
        }
        rreturn( DateTime::Format::Unicode::NullObject->new ) if( Want::want( 'OBJECT' ) );
        return;
    }
    return( ref( $self ) ? $self->{error} : $ERROR );
}

sub format_datetime
{
    my $self = shift( @_ );
    my $dt   = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    local $@;
    if( defined( $dt ) )
    {
        unless( Scalar::Util::blessed( $dt ) &&
                $dt->isa( 'DateTime' ) )
        {
            return( $self->error( "Value provided is not a DateTime object." ) );
        }
        $dt = $dt->clone;
    }
    else
    {
        # try-catch
        eval
        {
            require DateTime;
        } || return( $self->error( "Unable to load the module DateTime: $@" ) );
        $dt = DateTime->now;
    }

    my $locale = $self->{locale} || die( "Locale object value is gone!" );
    my $pat = $opts->{pattern} || $self->{pattern};
    return( "No format pattern was provided." ) if( !length( $pat // '' ) );
    eval
    {
        # $dt->set_locale( "${locale}" );
        $dt->set_locale( $locale );
    } || return( $self->error( "Error setting the locale value ${locale} to the DateTime object: $@" ) );

    my $map =
    {
    'a' => \&_format_am_pm,
    'A' => \&_format_millisecond,
    'b' => \&_format_day_period,
    'B' => \&_format_day_period,
    'c' => \&_format_week_day,
    'C' => \&_format_hour_allowed,
    'd' => \&_format_day_of_month,
    'D' => \&_format_day_of_year,
    'e' => \&_format_day_of_week,
    'E' => \&_format_day_of_week,
    'F' => \&_format_day_of_week_in_month,
    'g' => \&_format_day_julian,
    'G' => \&_format_era,
    'h' => \&_format_hour_1_12,
    'H' => \&_format_hour_0_23,
    'j' => \&_format_hour_flexible,
    'J' => \&_format_hour_preferred,
    'k' => \&_format_hour_1_24,
    'K' => \&_format_hour_0_11,
    'L' => \&_format_month_standalone,
    'm' => \&_format_minute,
    'M' => \&_format_month,
    'O' => \&_format_timezone_gmt_offset,
    'q' => \&_format_quarter_standalone,
    'Q' => \&_format_quarter,
    'r' => \&_format_year_related,
    's' => \&_format_second,
    'S' => \&_format_second_fractional,
    'u' => \&_format_year_extended,
    'U' => \&_format_cyclic_year_name,
    'v' => \&_format_timezone_non_location,
    'V' => \&_format_timezone_location,
    'w' => \&_format_week_number,
    'W' => \&_format_week_of_month,
    'x' => \&_format_zone_offset,
    'X' => \&_format_zone_offset_gmt,
    'y' => \&_format_year,
    'Y' => \&_format_week_year,
    'z' => \&_format_timezone,
    'Z' => \&_format_timezone_offset,
    };

    my $cldr_pattern = sub
    {
        my $pattern = shift( @_ );
        my $token = substr( $pattern, 0, 1 );
        if( exists( $map->{ $token } ) )
        {
            my $code = $map->{ $token };
            my $str = $code->( $self, $token, length( $pattern ), $dt );
            return( $str // '' );
        }
        # Unknown, we return the pattern as-is
        else
        {
            return( $pattern );
        }
    };

    # try-catch
    eval
    {
        $pat =~ s{
            \G
            (?:
                '((?:[^']|'')*)' # quote escaped bit of text
                                 # it needs to end with one
                                 # quote not followed by
                                 # another
                |
                (([a-zA-Z])\3*)  # could be a pattern
                |
                (.)                 # anything else
            )
        }
        {
            if( defined( $1 ) )
            {
                $1;
            }
            elsif( defined( $2 ) )
            {
                $cldr_pattern->( $2 );
            }
            elsif( defined( $4 ) )
            {
                $4;
            }
            else
            {
                undef;
            }
        }sgex;
    };
    if( $@ )
    {
        return( $self->error( "Error formatting CLDR pattern for locale $locale: $@" ) );
    }
    $pat =~ s/\'\'/\'/g;
    return( $pat );
}

sub format_interval
{
    my $self = shift( @_ );
    my( $dt1, $dt2 ) = @_;
    if( !defined( $dt1 ) )
    {
        return( $self->error( "No DateTime object provided for the first argument" ) );
    }
    elsif( !defined( $dt2 ) )
    {
        return( $self->error( "No DateTime object provided for the second argument" ) );
    }
    elsif( !Scalar::Util::blessed( $dt1 ) )
    {
        return( $self->error( "First DateTime value provided is not an object." ) );
    }
    elsif( !Scalar::Util::blessed( $dt2 ) )
    {
        return( $self->error( "Second DateTime value provided is not an object." ) );
    }
    elsif( !$dt1->isa( 'DateTime' ) )
    {
        return( $self->error( "First DateTime value provided is not a DateTime object." ) );
    }
    elsif( !$dt2->isa( 'DateTime' ) )
    {
        return( $self->error( "Second DateTime value provided is not a DateTime object." ) );
    }
    splice( @_, 0, 2 );
    my $opts = $self->_get_args_as_hash( @_ );
    my $locale = $self->locale ||
        return( $self->error( "The DateTime::Locale::FromCLDR object is gone!" ) );
    my $diff = $locale->interval_greatest_diff( $dt1, $dt2 );
    if( !defined( $diff ) )
    {
        return( $self->pass_error( $locale->error ) );
    }
    elsif( !length( $diff ) )
    {
        warn( "Warning only: both DateTime object are equal." ) if( warnings::enabled() );
        $diff = 'd';
    }
    my $pattern = $opts->{pattern} || $self->pattern;
    if( !length( $pattern // '' ) )
    {
        return( $self->error( "No pattern or pattern ID is set." ) );
    }
    my $ref = $locale->interval_format( $pattern, $diff ) ||
        return( $self->pass_error( $locale->error ) );
    # Unable to find an interval pattern for this greatest difference token
    # Maybe the user has provided us with a custom pattern?
    # Let's try to break it down
    if( !scalar( @$ref ) )
    {
        $ref = $locale->locale->split_interval( pattern => $pattern, greatest_diff => $diff ) ||
            return( $self->pass_error( $locale->locale->error ) );
    }
    if( !scalar( @$ref ) )
    {
        return( $self->error( "The pattern provided '${pattern}' does not appear to be a valid interval pattern or pattern ID." ) );
    }
    my $part1 = $self->format_datetime( $dt1, pattern => $ref->[0] );
    return( $self->pass_error ) if( !defined( $part1 ) );
    my $part2 = $self->format_datetime( $dt2, pattern => $ref->[2] );
    return( $self->pass_error ) if( !defined( $part1 ) );
    return( join( $ref->[1], $part1, $part2 ) );
}

sub locale
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $locale = shift( @_ );
        unless( Scalar::Util::blessed( $locale ) &&
                $locale->isa( 'DateTime::Locale::FromCLDR' ) )
        {
            $locale = DateTime::Locale::FromCLDR->new( $locale ) ||
                return( $self->pass_error( DateTime::Locale::FromCLDR->error ) );
        }
        $self->{locale} = $locale;
    }
    return( $self->{locale} );
}

sub on_error
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $on_error = shift( @_ );
        if( defined( $on_error ) )
        {
            unless( ref( $on_error ) eq 'CODE' ||
                    $on_error eq 'fatal' )
            {
                return( $self->error( "The value for 'on_error' can only be either a code reference, such as an ananonymous subroutine or a reference to an existing subroutine, or the string 'fatal', or an undefined value." ) );
            }
            $self->{on_error} = $on_error;
        }
        else
        {
            delete( $self->{on_error} );
        }
    }
    return( $self->{on_error} );
}

sub pass_error
{
    my $self = shift( @_ );
    if( Want::want( 'OBJECT' ) )
    {
        rreturn( DateTime::Format::Unicode::NullObject->new );
    }
    return;
}

sub pattern
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $pattern = shift( @_ );
        defined( $pattern ) || return( $self->error( "Pattern provided is empty." ) );
        $self->{pattern} = $pattern;
    }
    return( $self->{pattern} );
}

sub time_zone
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $tz = shift( @_ );
        local $@;
        unless( Scalar::Util::blessed( $tz ) &&
                $tz->isa( 'DateTime::TimeZone' ) )
        {
            # try-catch
            eval
            {
                require DateTime::TimeZone;
            } || return( $self->error( "Unable to load the module DateTime::TimeZone: $@" ) );

            # try-catch
            $tz = eval
            {
                DateTime::TimeZone->new( name => "${tz}" );
            } || return( $self->error( "Unable to instantiate a new DateTime::TimeZone object from '${tz}': ", ( $@ || 'unknown error' ) ) );
        }
        $self->{time_zone} = $tz;
    }
    return( $self->{time_zone} );
}

# NOTE: pattern a
# AM/PM
sub _format_am_pm
{
    my( $self, $token, $len, $dt ) = @_;
    my $locale = $self->{locale} || die( "Locale object value is gone!" );
    # "a..aaa" (Abbreviated)
    # Example: am. [e.g. 12 am.]
    if( $len >= 1 && $len <= 3 )
    {
        return( $locale->am_pm_format_abbreviated->[ $dt->hour < 12 ? 0 : 1 ] );
    }
    # "aaaa" (Wide)
    # Example: am. [e.g. 12 am.]
    elsif( $len == 4 )
    {
        return( $locale->am_pm_format_wide->[ $dt->hour < 12 ? 0 : 1 ] );
    }
    # "aaaaa" (Narrow)
    # Example: a [e.g. 12a]
    elsif( $len == 5 )
    {
        return( $locale->am_pm_format_narrow->[ $dt->hour < 12 ? 0 : 1 ] );
    }
    else
    {
        warn( "Unknown length '${len}' to format am/pm" ) if( warnings::enabled() );
        return( $token x $len );
    }
}

# NOTE: pattern U
# Missing in DateTime
# "If the calendar does not provide cyclic year name data, or if the year value to be formatted is out of the range of years for which cyclic name data is provided, then numeric formatting is used (behaves like 'y')."
sub _format_cyclic_year_name
{
    my( $self, $token, $len, $dt ) = @_;
    my $locale = $self->{locale} || die( "Locale object value is gone!" );
    my $year = $dt->year;
    # Abbreviated
    if( $len >= 1 && $len <= 3 )
    {
        my $era = $locale->era_abbreviated->[ $year < 0 ? 0 : 1 ];
        $era = $year if( !length( $era // '' ) );
        return( $era );
    }
    # Wide
    elsif( $len == 4 )
    {
        my $era = $locale->era_wide->[ $year < 0 ? 0 : 1 ];
        $era = $year if( !length( $era // '' ) );
        return( $era );
    }
    # Narrow
    elsif( $len == 5 )
    {
        my $era = $locale->era_narrow->[ $year < 0 ? 0 : 1 ];
        $era = $year if( !length( $era // '' ) );
        return( $era );
    }
    else
    {
        warn( "Unknown length '${len}' to format era name" ) if( warnings::enabled() );
        return( $token x $len );
    }
}

# NOTE: pattern g
sub _format_day_julian
{
    my( $self, $token, $len, $dt ) = @_;
    if( $len >= 1 )
    {
        return( sprintf( '%0*d', $len, $dt->mjd ) );
    }
    else
    {
        warn( "Unknown length '${len}' to format julian day" ) if( warnings::enabled() );
        return( $token x $len );
    }
}

# NOTE: pattern d
sub _format_day_of_month
{
    my( $self, $token, $len, $dt ) = @_;
    if( $len >= 1 && $len <= 2 )
    {
        return( sprintf( '%0*d', $len, $dt->day_of_month ) );
    }
    else
    {
        warn( "Unknown length '${len}' to format day of month" ) if( warnings::enabled() );
        return( $token x $len );
    }
}

# NOTE: pattern E or e
# E: Day of week name, format style.
# Same as 'e', but no numeric day
# The short format is left out in DateTime->format_cldr and DateTime::Locale::FromData
#
# e: Local day of week number/name. Same as 'E' except adds a numeric value
# The short format is left out in DateTime->format_cldr and DateTime::Locale::FromData
sub _format_day_of_week
{
    my( $self, $token, $len, $dt ) = @_;
    my $locale = $self->{locale} || die( "Locale object value is gone!" );
    if( $len >= 1 && $len <= 3 && $token eq 'E' )
    {
        return( $locale->day_format_abbreviated->[ $dt->day_of_week_0 ] );
    }
    elsif( $len >= 1 && $len <= 2 && $token eq 'e' )
    {
        return( sprintf( '%0*d', $len, $dt->local_day_of_week  ) );
    }
    elsif( $len == 3 && $token eq 'e' )
    {
        return( $locale->day_format_abbreviated->[ $dt->day_of_week_0 ] );
    }
    # Works for both E and e
    elsif( $len == 4 )
    {
        return( $locale->day_format_wide->[ $dt->day_of_week_0 ] );
    }
    # Works for both E and e
    elsif( $len == 5 )
    {
        return( $locale->day_format_narrow->[ $dt->day_of_week_0 ] );
    }
    # Works for both E and e
    elsif( $len == 6 )
    {
        return( $locale->day_format_short->[ $dt->day_of_week_0 ] );
    }
    else
    {
        warn( "Unknown length '${len}' to format day of week" ) if( warnings::enabled() );
        return( $token x $len );
    }
}

# NOTE: pattern F
# Day of Week in Month (numeric)
# DateTime: "Returns a number from 1..5 indicating which week day of the month this is. For example, June 9, 2003 is the second Monday of the month, and so this method returns 2 for that date."
sub _format_day_of_week_in_month
{
    my( $self, $token, $len, $dt ) = @_;
    if( $len == 1 )
    {
        use integer;
        return(  ( ( $dt->day - 1 ) / 7 ) + 1 );
    }
    else
    {
        warn( "Unknown length '${len}' to format day of week in month" ) if( warnings::enabled() );
        return( $token x $len );
    }
}

# NOTE: pattern D
sub _format_day_of_year
{
    my( $self, $token, $len, $dt ) = @_;
    if( $len >= 1 && $len <= 3 )
    {
        return( sprintf( '%0*d', $len, $dt->day_of_year ) );
    }
    else
    {
        warn( "Unknown length '${len}' to format day of year" ) if( warnings::enabled() );
        return( $token x $len );
    }
}

# NOTE: pattern b or B -> day period
# Day period: am, pm, noon, midnight, etc
# Missing in DateTime and DateTime::Locale::FromData
sub _format_day_period
{
    my( $self, $token, $len, $dt ) = @_;
    my $locale = $self->{locale} || die( "Locale object value is gone!" );
    # "b..bbb" (Abbreviated)
    # Example: mid. [e.g. 12 mid.]
    # "B..BBB" (Abbreviated)
    # Example: at night -> [e.g. 3:00 at night]
    if( $len >= 1 && $len <= 3 )
    {
        if( $token eq 'B' )
        {
            return( $locale->day_period_format_abbreviated( $dt ) );
        }
        # b
        else
        {
            return( $locale->day_period_stand_alone_abbreviated( $dt ) );
        }
    }
    # "bbbb" (Wide)
    # Example: midnight
    # "BBBB" (Wide)
    # Example: at night -> [e.g. 3:00 at night]
    elsif( $len == 4 )
    {
        if( $token eq 'B' )
        {
            return( $locale->day_period_format_wide( $dt ) );
        }
        else
        {
            return( $locale->day_period_stand_alone_wide( $dt ) );
        }
    }
    # "bbbbb" (Narrow)
    # Example: md [e.g. 12 md]
    # "BBBBB" (Narrow)
    # Example: at night -> [e.g. 3:00 at night]
    elsif( $len == 5 )
    {
        if( $token eq 'B' )
        {
            return( $locale->day_period_format_narrow( $dt ) );
        }
        else
        {
            return( $locale->day_period_stand_alone_narrow( $dt ) );
        }
    }
    else
    {
        warn( "Unknown length '${len}' to format day period" ) if( warnings::enabled() );
        return( $token x $len );
    }
}

# NOTE: pattern G
sub _format_era
{
    my( $self, $token, $len, $dt ) = @_;
    my $locale = $self->{locale} || die( "Locale object value is gone!" );
    if( $len > 0 && $len <= 3 )
    {
        return( $locale->era_abbreviated->[ $dt->year < 0 ? 0 : 1 ] );
    }
    elsif( $len == 4 )
    {
        return( $locale->era_wide->[ $dt->year < 0 ? 0 : 1 ] );
    }
    # >= 5
    else
    {
        return( $locale->era_narrow->[ $dt->year < 0 ? 0 : 1 ] );
    }
}

# NOTE: pattern K -> hour (0-11)
sub _format_hour_0_11
{
    my( $self, $token, $len, $dt ) = @_;
    $len = 2 if( $len > 2 );
    return( sprintf( '%0*d', $len, $dt->hour_12_0 ) );
}

# NOTE: pattern H -> hour (0-23)
sub _format_hour_0_23
{
    my( $self, $token, $len, $dt ) = @_;
    $len = 2 if( $len > 2 );
    return( sprintf( '%0*d', $len, $dt->hour ) );
}

# NOTE: pattern h -> hour (1-12)
sub _format_hour_1_12
{
    my( $self, $token, $len, $dt ) = @_;
    $len = 2 if( $len > 2 );
    return( sprintf( '%0*d', $len, $dt->hour_12 ) );
}

# NOTE: pattern k -> hour (1-24)
sub _format_hour_1_24
{
    my( $self, $token, $len, $dt ) = @_;
    $len = 2 if( $len > 2 );
    return( sprintf( '%0*d', $len, $dt->hour_1 ) );
}

# NOTE: pattern C -> hour (allowed, first match)
sub _format_hour_allowed { return( shift->_format_hour_allowed_preferred( 'allowed', @_) ); }

sub _format_hour_allowed_preferred
{
    my( $self, $type, $token, $len, $dt ) = @_;
    my $locale = $self->{locale} || die( "Locale object value is gone!" );
    my $ref;
    if( $type eq 'allowed' )
    {
        $ref = $locale->time_format_allowed;
        return( $self->pass_error( $locale->error ) ) if( !defined( $ref ) && $locale->error );
    }
    elsif( $type eq 'preferred' )
    {
        my $this = $locale->time_format_preferred;
        return( $self->pass_error( $locale->error ) ) if( !defined( $this ) && $locale->error );
        $ref = [$this];
    }
    else
    {
        die( "Unknown type '${type}'. Choose either 'allowed' or 'preferred'." );
    }
    my $pat = $ref->[0];
    # Possible tokens: H, h, K, k, B, b
    my $time_tokens = [split( //, ( $pat // '' ) )];
    my $res = [];
    my $map =
    {
    # "C"
    # Example: 8
    #          8 (morning)
    # Numeric hour (minimum digits), abbreviated dayPeriod if used
    1 => { digits => 1, B => sub{ $locale->day_period_format_abbreviated( $dt ) }, b => sub{ $locale->day_period_stand_alone_abbreviated } },
    # "CC"
    # Example: 08
    #          08 (morning)
    # Numeric hour (2 digits, zero pad if needed), abbreviated dayPeriod if used
    2 => { digits => 2, B => sub{ $locale->day_period_format_abbreviated( $dt ) }, b => sub{ $locale->day_period_stand_alone_abbreviated( $dt ) } },
    3 => { digits => 1, B => sub{ $locale->day_period_format_wide( $dt ) }, b => sub{ $locale->day_period_stand_alone_wide( $dt ) } },
    4 => { digits => 2, B => sub{ $locale->day_period_format_wide( $dt ) }, b => sub{ $locale->day_period_stand_alone_wide( $dt ) } },
    5 => { digits => 1, B => sub{ $locale->day_period_format_narrow( $dt ) }, b => sub{ $locale->day_period_stand_alone_narrow( $dt ) } },
    6 => { digits => 2, B => sub{ $locale->day_period_format_narrow( $dt ) }, b => sub{ $locale->day_period_stand_alone_narrow( $dt ) } },
    };

    # 'J' has only up to 2 characters
    if( $token eq 'J' )
    {
        delete( $map->{ $_ } ) for( 3..6 );
    }

    foreach my $tok ( @$time_tokens )
    {
        my $def = $map->{ $len } || die( "Unknown length '${len}' to format hour allowed" );
        if( $tok eq 'H' )
        {
            push( @$res, sprintf( '%0*d', $def->{digits}, $dt->hour ) );
        }
        elsif( $tok eq 'h' )
        {
            push( @$res, sprintf( '%0*d', $def->{digits}, $dt->hour_12 ) );
        }
        elsif( $tok eq 'K' )
        {
            push( @$res, sprintf( '%0*d', $def->{digits}, $dt->hour_12_0 ) );
        }
        elsif( $tok eq 'k' )
        {
            push( @$res, sprintf( '%0*d', $def->{digits}, $dt->hour_1 ) );
        }
        # J is the flexible "preferred hour format for the locale", except "it requests no dayPeriod marker such as “am/pm”"
        # <https://unicode.org/reports/tr35/tr35-dates.html#dfst-hour>
        elsif( ( $tok eq 'B' || $tok eq 'b' ) && $token ne 'J' )
        {
            my $str = $def->{ $tok }->();
            push( @$res, $str ) if( length( $str // '' ) );
        }
        else
        {
            warn( "Unsupported time format token '${tok}'" ) if( warnings::enabled() );
        }
    }
    return( join( ' ', @$res ) );
}

# NOTE: pattern j -> hour (flexible)
# Flexible hour format depending on the preferred hour format for the locale (h, H, K, or k)
sub _format_hour_flexible { return( shift->_format_hour_allowed_preferred( 'preferred', @_ ) ); }

# NOTE: pattern J -> hour (preferred)
# "like 'j', it requests the preferred hour format for the locale (h, H, K, or k), as determined by the preferred attribute of the hours element. However, unlike 'j', it requests no dayPeriod marker such as “am/pm” (it is typically used where there is enough context that that is not necessary). For example, with "jmm", 18:00 could appear as “6:00 PM”, while with "Jmm", it would appear as “6:00” (no PM)."
sub _format_hour_preferred { return( shift->_format_hour_allowed_preferred( 'preferred', @_) ); }

# NOTE: pattern A -> milliseconds
# Milliseconds in day (numeric)
sub _format_millisecond
{
    my( $self, $token, $len, $dt ) = @_;
    # "A+"
    # Example: 69540000
    if( $len >= 1 )
    {
        # local_rd_days, local_rd_secs, rd_nanosecs
        my @rd_values = $dt->local_rd_values;
        return( ( $rd_values[1] * 1000 ) + $dt->millisecond );
    }
    else
    {
        warn( "Unknown length '${len}' to format milliseconds" ) if( warnings::enabled() );
        return( $token x $len );
    }
}

# NOTE: pattern m
# Minute (numeric). Truncated, not rounded.
sub _format_minute
{
    my( $self, $token, $len, $dt ) = @_;
    if( $len >= 1 && $len <= 2 )
    {
        return( sprintf( '%0*d', $len, $dt->minute ) );
    }
    else
    {
        warn( "Unknown length '${len}' to format minute (numeric)" ) if( warnings::enabled() );
        return( $token x $len );
    }
}

# NOTE: pattern M
# Numeric: minimum digits Format style month number/name
sub _format_month
{
    my( $self, $token, $len, $dt ) = @_;
    my $locale = $self->{locale} || die( "Locale object value is gone!" );
    if( $len >= 1 && $len <= 2 )
    {
        return( sprintf( '%0*d', $len, $dt->month ) );
    }
    elsif( $len == 3 )
    {
        return( $locale->month_format_abbreviated->[ $dt->month_0 ] );
    }
    elsif( $len == 4 )
    {
        return( $locale->month_format_wide->[ $dt->month_0 ] );
    }
    elsif( $len == 5 )
    {
        return( $locale->month_format_narrow->[ $dt->month_0 ] );
    }
    else
    {
        warn( "Unknown length '${len}' to format month" ) if( warnings::enabled() );
        return( $token x $len );
    }
}

sub _format_offset
{
    my $self = shift( @_ );
    my $offset = shift( @_ );
    my $sep = shift( @_ ) || '';
    return( $self->error( "No offset was provided." ) ) unless( defined( $offset ) );
    return( $self->error( "Offset provided (${offset}) is out of bound." ) ) unless( $offset >= -359999 && $offset <= 359999 );

    my $sign = $offset < 0 ? '-' : '+';

    $offset = abs( $offset );

    my $hours = int( $offset / 3600 );
    $offset %= 3600;
    my $mins = int( $offset / 60 );
    $offset %= 60;
    my $secs = int($offset);

    return(
        $secs
        ? sprintf(
            '%s%02d%s%02d%s%02d', $sign, $hours, $sep, $mins, $sep, $secs
            )
        : sprintf( '%s%02d%s%02d', $sign, $hours, $sep, $mins )
    );
}

# NOTE: pattern L
# Stand-Alone month number/name
sub _format_month_standalone
{
    my( $self, $token, $len, $dt ) = @_;
    my $locale = $self->{locale} || die( "Locale object value is gone!" );
    if( $len >= 1 && $len <= 2 )
    {
        return( sprintf( '%0*d', $len, $dt->month ) );
    }
    elsif( $len == 3 )
    {
        return( $locale->month_stand_alone_abbreviated->[ $dt->month_0 ] );
    }
    elsif( $len == 4 )
    {
        return( $locale->month_stand_alone_wide->[ $dt->month_0 ] );
    }
    elsif( $len == 5 )
    {
        return( $locale->month_stand_alone_narrow->[ $dt->month_0 ] );
    }
    else
    {
        warn( "Unknown length '${len}' to format month in stand-alone" ) if( warnings::enabled() );
        return( $token x $len );
    }
}

# NOTE: pattern Q
sub _format_quarter
{
    my( $self, $token, $len, $dt ) = @_;
    my $locale = $self->{locale} || die( "Locale object value is gone!" );
    if( $len >= 1 && $len <= 2 )
    {
        return( sprintf( '%0*d', $len, $dt->quarter ) );
    }
    # Abbreviated
    elsif( $len == 3 )
    {
        return( $locale->quarter_format_abbreviated->[ $dt->quarter_0 ] );
    }
    # Wide
    elsif( $len == 4 )
    {
        return( $locale->quarter_format_wide->[ $dt->quarter_0 ] );
    }
    # Narrow
    elsif( $len == 5 )
    {
        # return( $locale->quarter );
        return( $locale->quarter_format_narrow->[ $dt->quarter_0 ] );
    }
    else
    {
        warn( "Unknown length '${len}' to format quarter" ) if( warnings::enabled() );
        return( $token x $len );
    }
}

# NOTE: pattern q
# Missing in DateTime
sub _format_quarter_standalone
{
    my( $self, $token, $len, $dt ) = @_;
    my $locale = $self->{locale} || die( "Locale object value is gone!" );
    if( $len >= 1 && $len <= 2 )
    {
        return( sprintf( '%0*d', $len, $dt->quarter ) );
    }
    elsif( $len == 3 )
    {
        return( $locale->quarter_stand_alone_abbreviated->[ $dt->quarter_0 ] );
    }
    elsif( $len == 4 )
    {
        return( $locale->quarter_stand_alone_wide->[ $dt->quarter_0 ] );
    }
    elsif( $len == 5 )
    {
        return( $locale->quarter_stand_alone_narrow->[ $dt->quarter_0 ] );
    }
    else
    {
        warn( "Unknown length '${len}' to format quarter (standalone)" ) if( warnings::enabled() );
        return( $token x $len );
    }
}

# NOTE: pattern s -> second
sub _format_second
{
    my( $self, $token, $len, $dt ) = @_;
    if( $len >= 1 && $len <= 2 )
    {
        return( sprintf( '%0*d', $len, $dt->second ) );
    }
    else
    {
        warn( "Unknown length '${len}' to format seconds" ) if( warnings::enabled() );
        return( $token x $len );
    }
}

# NOTE: pattern S -> Fractional Second (numeric)
# "Fractional Second (numeric). Truncates, like other numeric time fields, but in this case to the number of digits specified by the field length. (Example shows display using pattern SSSS for seconds value 12.34567)"
sub _format_second_fractional
{
    my( $self, $token, $len, $dt ) = @_;
    if( $len >= 1 )
    {
        my $nanosecond = $dt->nanosecond;
        # Ensure we are working with a full 9-digit number by padding with zeros if necessary
        my $full_nanosecond = $nanosecond * 10**(9 - length($nanosecond));
        my $exponent     = 9 - $len;
        # Borrowed from DateTime
        my $formatted_ns = POSIX::floor(
            (
                $exponent < 0
                    ? $full_nanosecond * 10**-$exponent
                    : $full_nanosecond / 10**$exponent
            )
        );
        return( sprintf( '%0*u', $len, $formatted_ns ) );
    }
    else
    {
        warn( "Unknown length '${len}' to format fractional seconds" ) if( warnings::enabled() );
        return( $token x $len );
    }
}

# NOTE: pattern z
sub _format_timezone
{
    my( $self, $token, $len, $dt ) = @_;
    my $locale = $self->{locale} || die( "Locale object value is gone!" );
    my $tz = $dt->time_zone->name;
    # The short specific non-location format. Where that is unavailable, falls back to the short localized GMT format ("O").
    # Example:
    # PDT
    if( $len >= 1 && $len <= 3 )
    {
        my $str = $locale->format_timezone_non_location(
            timezone => $tz,
            # type => [($locale->is_dst( $dt ) ? 'daylight' : 'standard'), 'generic'],
            type => ($locale->is_dst( $dt ) ? 'daylight' : 'standard'),
            width => 'short',
        );
        if( !length( $str // '' ) )
        {
            $str = $locale->format_gmt(
                offset => $dt->offset,
                width => 'short',
            );
        }
        return( $str );
    }
    # The long specific non-location format. Where that is unavailable, falls back to the long localized GMT format ("OOOO").
    # Example:
    # Pacific Daylight Time
    elsif( $len == 4 )
    {
        my $str = $locale->format_timezone_non_location(
            timezone => $tz,
            # type => [($locale->is_dst( $dt ) ? 'daylight' : 'standard'), 'generic'],
            type => ($locale->is_dst( $dt ) ? 'daylight' : 'standard'),
            width => 'long',
        );
        if( !length( $str // '' ) )
        {
            $str = $locale->format_gmt(
                offset => $dt->offset,
                width => 'long',
            );
        }
        return( $str );
    }
    else
    {
        warn( "Unknown length '${len}' to format short specific non-location time zone." ) if( warnings::enabled() );
        return( $token x $len );
    }
}

# NOTE: pattern V
sub _format_timezone_location
{
    my( $self, $token, $len, $dt ) = @_;
    my $locale = $self->{locale} || die( "Locale object value is gone!" );
    # Example: Asia/Tokyo
    my $tz = $dt->time_zone_long_name;
    my $str;
    # The short time zone ID (the BCP47 time zone ID)
    # As of CLDR 35, all time zone have a unique short ID
    # Example: America/Los_Angeles -> uslax
    if( $len == 1 )
    {
        # Shortcut
        return( 'unk' ) if( $tz eq 'floating' );
        # The short generic non-location format
        # Where that is unavailable, falls back to the generic location format ("VVVV"),
        # then the short localized GMT format as the final fallback
        $str = $locale->timezone_id(
            timezone => $tz,
        );
        return( $self->pass_error( $locale->error ) ) if( !defined( $str ) && $locale->error );
        $str ||= 'unk';
        return( $str );
    }
    # The long time zone ID
    # Example: America/Los_Angeles
    elsif( $len == 2 )
    {
        # Etc/Unknown
        return( 'unk' ) if( $tz eq 'floating' );
        return( "$tz" );
    }
    # The exemplar city (location) for the time zone
    # Example: America/Los_Angeles -> Los Angeles
    elsif( $len == 3 )
    {
        # The exemplar city (location) for the time zone.
        # Where that is unavailable, the localized exemplar city name for the special zone Etc/Unknown is used as the fallback (for example, "Unknown City").
        # With the Locale::Unicode::Data extended timezones cities data, there are 89 localised versions for each of the 421 time zones exemplar cities
        $str = $locale->timezone_city(
            timezone => $tz,
        ) unless( $tz eq 'floating' );
        return( $self->pass_error( $locale->error ) ) if( !defined( $str ) && $locale->error );
        if( !length( $str // '' ) )
        {
            # Etc/Unknown is guaranteed to exist in each locale
            $str = $locale->timezone_city(
                timezone => 'Etc/Unknown',
            );
            return( $self->pass_error( $locale->error ) ) if( !defined( $str ) && $locale->error );
        }
        return( $str );
    }
    # Example: Los Angeles Time
    elsif( $len == 4 )
    {
        # The generic location format.
        # Where that is unavailable, falls back to the long localized GMT format
        # ("OOOO"; Note: Fallback is only necessary with a GMT-style Time Zone ID, like Etc/GMT-830.)
        $str = $locale->format_timezone_location(
            timezone => $tz,
        ) unless( $tz eq 'floating' );
        return( $self->pass_error( $locale->error ) ) if( !defined( $str ) && $locale->error );
        if( !length( $str // '' ) )
        {
            my $offset = $dt->offset;
            $str = $locale->format_gmt(
                offset => $offset,
                width => 'long',
            );
        }
        return( $str );
    }
    else
    {
        warn( "Unknown length '${len}' to format time zone" ) if( warnings::enabled() );
        return( $token x $len );
    }
}

# NOTE: pattern v
sub _format_timezone_non_location
{
    my( $self, $token, $len, $dt ) = @_;
    my $locale = $self->{locale} || die( "Locale object value is gone!" );
    my $tz = $dt->time_zone->name;
    if( $len == 1 )
    {
        # The short generic non-location format
        # Where that is unavailable, falls back to the generic location format ("VVVV"),
        # then the short localized GMT format as the final fallback
        my $str = $locale->format_timezone_non_location(
            timezone => $tz,
            type => 'generic',
            width => 'short',
        );
        if( !$str )
        {
            $str = $locale->format_timezone_location(
                timezone => $tz,
            );
        }
        if( !$str )
        {
            my $offset = $dt->offset;
            $str = $locale->format_gmt(
                offset => $offset,
                width => 'short',
            );
        }
        # return( $dt->time_zone_short_name );
        return( $str );
    }
    elsif( $len == 4 )
    {
        # The long generic non-location format.
        # Where that is unavailable, falls back to generic location format ("VVVV")
        my $str = $locale->format_timezone_non_location(
            timezone => $tz,
            type => 'generic',
            width => 'long',
        );
        if( !$str )
        {
            $str = $locale->format_timezone_location(
                timezone => $tz,
            );
        }
        # return( $dt->time_zone_long_name );
        return( $str );
    }
    else
    {
        warn( "Unknown length '${len}' to format time zone" ) if( warnings::enabled() );
        return( $token x $len );
    }
}

# NOTE: pattern O -> zone, e.g. GMT-08:00, or GMT-8
# Missing in DateTime
sub _format_timezone_gmt_offset
{
    my( $self, $token, $len, $dt ) = @_;
    if( $len == 1 )
    {
        my $offset = $dt->offset;
        my $sign = $offset < 0 ? '-' : '+';
        $offset = abs( $offset );
        my $hours = int( $offset / 3600 );
        return( 'GMT' . $sign . $hours );
    }
    elsif( $len == 4 )
    {
        return( 'GMT' . $self->_format_offset( $dt->offset, ':' ) );
    }
    else
    {
        warn( "Unknown length '${len}' to format GMT time zone" ) if( warnings::enabled() );
        return( $token x $len );
    }
}

# NOTE: pattern Z
# Example: +09:00
sub _format_timezone_offset
{
    my( $self, $token, $len, $dt ) = @_;
    my $locale = $self->{locale} || die( "Locale object value is gone!" );
    my $offset = $dt->offset;
    # Example: +0900
    if( $len >= 1 && $len <= 3 )
    {
        return( $self->_format_offset( $offset ) );
    }
    # Example: GMT+0900
    elsif( $len == 4 )
    {
        my $str = $locale->format_gmt(
            offset => $offset,
            width => 'long',
        );
    }
    # Example: +09:00
    #          -07:52:58
    # "The ISO8601 UTC indicator "Z" is used when local time offset is 0."
    elsif( $len == 5 )
    {
        if( $offset == 0 )
        {
            return( 'Z' );
        }
        else
        {
            return( $self->_format_offset( $offset, ':' ) );
        }
    }
    else
    {
        warn( "Unknown length '${len}' to format time zone offset" ) if( warnings::enabled() );
        return( $token x $len );
    }
}

# NOTE: pattern c -> week day
# Stand-Alone local day of week number/name
sub _format_week_day
{
    my( $self, $token, $len, $dt ) = @_;
    my $locale = $self->{locale} || die( "Locale object value is gone!" );
    # Not sure the value needs to be padded
    # "c..cc"
    # Example: 2 (numeric, 1 digit)
    if( $len >= 1 && $len <= 2 )
    {
        return( sprintf( '%0*d', $len, $dt->day_of_week ) );
    }
    # "ccc" (Abbreviated)
    # Example: Tue
    elsif( $len == 3 )
    {
        return( $locale->day_stand_alone_abbreviated->[ $dt->day_of_week_0 ] );
    }
    # "cccc" (Wide)
    # Example: Tuesday
    elsif( $len == 4 )
    {
        return( $locale->day_stand_alone_wide->[ $dt->day_of_week_0 ] );
    }
    # "ccccc" (Narrow)
    # Example: T
    elsif( $len == 5 )
    {
        return( $locale->day_stand_alone_narrow->[ $dt->day_of_week_0 ] );
    }
    # "cccccc" (Short)
    # Example: Tu
    # This is missing in DateTime
    elsif( $len == 6 )
    {
        return( $locale->day_stand_alone_short->[ $dt->day_of_week_0 ] );
    }
    else
    {
        warn( "Unknown length '${len}' to format week day" ) if( warnings::enabled() );
        return( $token x $len );
    }
}

# NOTE: pattern w
sub _format_week_number
{
    my( $self, $token, $len, $dt ) = @_;
    my $locale = $self->{locale} || die( "Locale object value is gone!" );
    if( $len >= 1 && $len <= 2 )
    {
        return( sprintf( '%0*d', $len, $dt->week_number ) );
    }
    else
    {
        warn( "Unknown length '${len}' to format week number" ) if( warnings::enabled() );
        return( $token x $len );
    }
}

# NOTE: pattern W
sub _format_week_of_month
{
    my( $self, $token, $len, $dt ) = @_;
    my $locale = $self->{locale} || die( "Locale object value is gone!" );
    if( $len == 1 )
    {
        return( $dt->week_of_month );
    }
    else
    {
        warn( "Unknown length '${len}' to format week of month" ) if( warnings::enabled() );
        return( $token x $len );
    }
}

# NOTE: pattern Y
sub _format_week_year
{
    my( $self, $token, $len, $dt ) = @_;
    my $locale = $self->{locale} || die( "Locale object value is gone!" );
    return( sprintf( '%0*d', $len, $dt->week_year ) );
}

# NOTE: pattern y
sub _format_year
{
    my( $self, $token, $len, $dt ) = @_;
    my $locale = $self->{locale} || die( "Locale object value is gone!" );
    my $year = $dt->year;
    if( $len == 1 )
    {
        return( $year );
    }
    elsif( $len == 2 )
    {
        my $y2 = length( $year > 2 ) ? substr( $year, -2, 2 ) : $year;
        $y2 *= -1 if( $year < 0 );
        return( sprintf( '%02d', $y2 ) );
    }
    # In the CLDR, there is no upper limit
    elsif( $len >= 3 )
    {
        return( sprintf( '%0*d', $len, $year ) );
    }
    # < 0 ??
    else
    {
        warn( "Unknown length '${len}' to format year" ) if( warnings::enabled() );
        return( $token x $len );
    }
}

# NOTE: pattern u
sub _format_year_extended
{
    my( $self, $token, $len, $dt ) = @_;
    my $year = $dt->year;
    return( sprintf( '%0*d', $len, $year ) );
}

# NOTE: pattern r
sub _format_year_related
{
    my( $self, $token, $len, $dt ) = @_;
    my $year = $dt->year;
    return( sprintf( '%0*d', $len, $year ) );
}

# NOTE: pattern x, or X if $has_z is true
sub _format_zone_offset
{
    my( $self, $token, $len, $dt, $has_z ) = @_;
    if( $len < 1 || $len > 5 )
    {
        warn( "Unknown length '${len}' to format time zone offset" ) if( warnings::enabled() );
        return( $token x $len );
    }
    my $offset = $dt->offset;
    # Borrowed from DateTime::TimeZone
    return( '' ) unless( defined( $offset ) );
    return( '' ) unless( $offset >= -359999 && $offset <= 359999 );
    # For X format patterns
    return( 'Z' ) if( $offset == 0 && $has_z );
    my $sign = ( $offset < 0 ? '-' : '+' );
    $offset = abs($offset);
    my $hours = int( $offset / 3600 );
    $offset %= 3600;
    my $mins = int( $offset / 60 );
    $offset %= 60;
    my $secs = int( $offset );
    # ISO8601 basic format.
    # Hours and optional minutes value.
    # Same as X, but without the Z
    # Example:
    # -08
    # +0530
    # +00
    if( $len == 1 )
    {
        return( $mins ? sprintf( '%s%02d%02d', $sign, $hours, $mins ) : sprintf( '%s%02d', $sign, $hours ) );
    }
    # ISO8601 basic format.
    # Hours and minutes values.
    # Same as XX, but without the Z
    # Example:
    # -0800
    # +0000
    elsif( $len == 2 )
    {
        return( sprintf( '%s%02d%02d', $sign, $hours, $mins ) );
    }
    # ISO8601 extended format.
    # Hours and minutes values.
    # Same as XXX, but without the Z
    # Example:
    # -08:00
    # +00:00
    elsif( $len == 3 )
    {
        return( sprintf( '%s%02d:%02d', $sign, $hours, $mins ) );
    }
    # ISO8601 basic format, although the seconds field is not supported by the ISO8601 specification
    # Hours, minutes and optional seconds value.
    # Same as XXXX, but without the Z
    # Example:
    # -0800
    # -075258
    # +0000
    elsif( $len == 4 )
    {
        return( $secs ? sprintf( '%s%02d%02d%02d', $sign, $hours, $mins, $secs ) : sprintf( '%s%02d%02d', $sign, $hours, $mins ) );
    }
    # ISO8601 extended format, although the seconds field is not supported by the ISO8601 specification
    # Hours, minutes and optional seconds value.
    # Same as XXXXX, but without the Z
    # Example:
    # -08:00
    # -07:52:58
    # +00:00
    elsif( $len == 5 )
    {
        return( $secs ? sprintf( '%s%02d:%02d:%02d', $sign, $hours, $mins, $secs ) : sprintf( '%s%02d:%02d', $sign, $hours, $mins ) );
    }
}

sub _format_zone_offset_gmt { return( shift->_format_zone_offset( @_, 1 ) ); }

sub _get_args_as_hash
{
    my $self = shift( @_ );
    my $ref = {};
    if( scalar( @_ ) == 1 &&
        defined( $_[0] ) &&
        ( ref( $_[0] ) || '' ) eq 'HASH' )
    {
        $ref = shift( @_ );
    }
    elsif( !( scalar( @_ ) % 2 ) )
    {
        $ref = { @_ };
    }
    else
    {
        die( "Uneven number of parameters provided." );
    }
    return( $ref );
}

sub FREEZE
{
    my $self = CORE::shift( @_ );
    my $serialiser = CORE::shift( @_ ) // '';
    my $class = CORE::ref( $self );
    my @keys = qw( locale time_zone pattern );
    my $hash = {};
    @$hash{ @keys } = @$self{ @keys };
    $hash->{on_error} = $self->{on_error} if( exists( $self->{on_error} ) && !ref( $self->{on_error} ) );
    $hash->{time_zone} = $hash->{time_zone}->name if( Scalar::Util::blessed( $hash->{time_zone} ) && $hash->{time_zone}->isa( 'DateTime::TimeZone' ) );
    $hash->{locale} = "$hash->{locale}" if( defined( $hash->{locale} ) );
    # Return an array reference rather than a list so this works with Sereal and CBOR
    # On or before Sereal version 4.023, Sereal did not support multiple values returned
    CORE::return( [$class, $hash] ) if( $serialiser eq 'Sereal' && Sereal::Encoder->VERSION <= version->parse( '4.023' ) );
    # But Storable want a list with the first element being the serialised element
    CORE::return( $class, $hash );
}

sub STORABLE_freeze { return( shift->FREEZE( @_ ) ); }

sub STORABLE_thaw { return( shift->THAW( @_ ) ); }

# NOTE: CBOR will call the THAW method with the stored classname as first argument, the constant string CBOR as second argument, and all values returned by FREEZE as remaining arguments.
# NOTE: Storable calls it with a blessed object it created followed with $cloning and any other arguments initially provided by STORABLE_freeze
sub THAW
{
    my( $self, undef, @args ) = @_;
    my $ref = ( CORE::scalar( @args ) == 1 && CORE::ref( $args[0] ) eq 'ARRAY' ) ? CORE::shift( @args ) : \@args;
    my $class = ( CORE::defined( $ref ) && CORE::ref( $ref ) eq 'ARRAY' && CORE::scalar( @$ref ) > 1 ) ? CORE::shift( @$ref ) : ( CORE::ref( $self ) || $self );
    my $hash = CORE::ref( $ref ) eq 'ARRAY' ? CORE::shift( @$ref ) : {};
    $hash->{locale} = DateTime::Locale::FromCLDR->new( $hash->{locale} ) if( $hash->{locale} );
    if( $hash->{time_zone} )
    {
        local $@;
        # try-catch
        $hash->{time_zone} = eval
        {
            require DateTime::TimeZone;
            DateTime::TimeZone->new( name => $hash->{time_zone} );
        };
    }
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

sub TO_JSON
{
    my $self = CORE::shift( @_ );
    my @keys = qw( locale time_zone pattern );
    my $hash = {};
    @$hash{ @keys } = @$self{ @keys };
    $hash->{on_error} = $self->{on_error} if( exists( $self->{on_error} ) && !ref( $self->{on_error} ) );
    $hash->{time_zone} = $hash->{time_zone}->name if( Scalar::Util::blessed( $hash->{time_zone} ) && $hash->{time_zone}->isa( 'DateTime::TimeZone' ) );
    return( $hash );
}

# NOTE: DateTime::Format::Unicode::Exception class
package DateTime::Format::Unicode::Exception;
BEGIN
{
    use strict;
    use warnings;
    use vars qw( $VERSION );
    use overload (
        '""'    => 'as_string',
        bool    => sub{ $_[0] },
        fallback => 1,
    );
    our $VERSION = 'v0.1.0';
};
use strict;
use warnings;

sub new
{
    my $this = shift( @_ );
    my $self = bless( {} => ( ref( $this ) || $this ) );
    my @info = caller;
    @$self{ qw( package file line ) } = @info[0..2];
    my $args = {};
    if( scalar( @_ ) == 1 )
    {
        if( ( ref( $_[0] ) || '' ) eq 'HASH' )
        {
            $args = shift( @_ );
            if( $args->{skip_frames} )
            {
                @info = caller( int( $args->{skip_frames} ) );
                @$self{ qw( package file line ) } = @info[0..2];
            }
            $args->{message} ||= '';
            foreach my $k ( qw( package file line message code type retry_after ) )
            {
                $self->{ $k } = $args->{ $k } if( CORE::exists( $args->{ $k } ) );
            }
        }
        elsif( ref( $_[0] ) && $_[0]->isa( 'DateTime::Format::Unicode::Exception' ) )
        {
            my $o = $args->{object} = shift( @_ );
            $self->{message} = $o->message;
            $self->{code} = $o->code;
            $self->{type} = $o->type;
            $self->{retry_after} = $o->retry_after;
        }
        else
        {
            die( "Unknown argument provided: '", overload::StrVal( $_[0] ), "'" );
        }
    }
    else
    {
        $args->{message} = join( '', map( ref( $_ ) eq 'CODE' ? $_->() : $_, @_ ) );
    }
    return( $self );
}

# This is important as stringification is called by die, so as per the manual page, we need to end with new line
# And will add the stack trace
sub as_string
{
    no overloading;
    my $self = shift( @_ );
    return( $self->{_cache_value} ) if( $self->{_cache_value} && !CORE::length( $self->{_reset} ) );
    my $str = $self->message;
    $str = "$str";
    $str =~ s/\r?\n$//g;
    $str .= sprintf( " within package %s at line %d in file %s", ( $self->{package} // 'undef' ), ( $self->{line} // 'undef' ), ( $self->{file} // 'undef' ) );
    $self->{_cache_value} = $str;
    CORE::delete( $self->{_reset} );
    return( $str );
}

sub code { return( shift->reset(@_)->_set_get_prop( 'code', @_ ) ); }

sub file { return( shift->reset(@_)->_set_get_prop( 'file', @_ ) ); }

sub line { return( shift->reset(@_)->_set_get_prop( 'line', @_ ) ); }

sub message { return( shift->reset(@_)->_set_get_prop( 'message', @_ ) ); }

sub package { return( shift->reset(@_)->_set_get_prop( 'package', @_ ) ); }

# From perlfunc docmentation on "die":
# "If LIST was empty or made an empty string, and $@ contains an
# object reference that has a "PROPAGATE" method, that method will
# be called with additional file and line number parameters. The
# return value replaces the value in $@; i.e., as if "$@ = eval {
# $@->PROPAGATE(__FILE__, __LINE__) };" were called."
sub PROPAGATE
{
    my( $self, $file, $line ) = @_;
    if( defined( $file ) && defined( $line ) )
    {
        my $clone = $self->clone;
        $clone->file( $file );
        $clone->line( $line );
        return( $clone );
    }
    return( $self );
}

sub reset
{
    my $self = shift( @_ );
    if( !CORE::length( $self->{_reset} ) && scalar( @_ ) )
    {
        $self->{_reset} = scalar( @_ );
    }
    return( $self );
}

sub rethrow 
{
    my $self = shift( @_ );
    return if( !ref( $self ) );
    die( $self );
}

sub retry_after { return( shift->_set_get_prop( 'retry_after', @_ ) ); }

sub throw
{
    my $self = shift( @_ );
    my $e;
    if( @_ )
    {
        my $msg  = shift( @_ );
        $e = $self->new({
            skip_frames => 1,
            message => $msg,
        });
    }
    else
    {
        $e = $self;
    }
    die( $e );
}

sub type { return( shift->reset(@_)->_set_get_prop( 'type', @_ ) ); }

sub _set_get_prop
{
    my $self = shift( @_ );
    my $prop = shift( @_ ) || die( "No object property was provided." );
    $self->{ $prop } = shift( @_ ) if( @_ );
    return( $self->{ $prop } );
}

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

sub STORABLE_freeze { return( shift->FREEZE( @_ ) ); }

sub STORABLE_thaw { return( shift->THAW( @_ ) ); }

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

sub TO_JSON { return( shift->as_string ); }

{
    # NOTE: DateTime::Format::Unicode::NullObject class
    package
        DateTime::Format::Unicode::NullObject;
    BEGIN
    {
        use strict;
        use warnings;
        use overload (
            '""'    => sub{ '' },
            fallback => 1,
        );
        use Want;
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
        if( Want::want( 'OBJECT' ) )
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

=encoding utf-8

=head1 NAME

DateTime::Format::Unicode - Unicode CLDR Formatter for DateTime

=head1 SYNOPSIS

    use DateTime::Format::Unicode;
    my $fmt = DateTime::Format::Unicode->new(
        locale      => 'ja-Kana-JP',
        # optional, defaults to the locale medium size date formatting
        # See: DateTime::Locale::FromCLDR for more information
        pattern     => 'HH:mm:ss',
        # optional
        time_zone   => 'Asia/Tokyo',
        # will make error become fatal and have this API die instead of setting an exception object
        on_error    => 'fatal',
    ) || die( DateTime::Format::Unicode->error );

or, maybe, just:

    my $fmt = DateTime::Format::Unicode->new;

which, will default to C<locale> C<en> with date medium-size format pattern C<MMM d, y>

=head1 VERSION

    v0.1.2

=head1 DESCRIPTION

This is a Unicode L<CLDR|https://cldr.unicode.org/> (Common Locale Data Repository) formatter for L<DateTime>

It differs from the default formatter used in L<DateTime> with its method L<format_cldr|DateTime/format_cldr> in several aspects:

=over 4

=item 1. It uses L<DateTime::Locale::FromCLDR>

A much more comprehensive and accurate API to dynamically access the Unicode C<CLDR> data whereas the module L<DateTime> relies on, L<DateTime::Locale>, which uses static data from over 1,000 pre-generated modules.

=item 2. It allows for any C<locale>

Since, it uses dynamic data, you can use any C<locale>, from the simple C<en> to more complex C<es-001-valencia>, or even C<ja-t-de-t0-und-x0-medical>

=item 3. It allows formatting of datetime intervals

Datetime intervals are very important, and unfortunately unsupported by L<DateTime> as of July 2024.

=item 4. It supports more pattern tokens

L<DateTime> L<format_cldr|DateTime/format_cldr> does not support all of the L<CLDR pattern tokens|https://unicode.org/reports/tr35/tr35-dates.html#Date_Format_Patterns>, but L<DateTime::Format::Unicode> does.

Known pattern tokens unsupported by L<DateTime> are:

=over 8

=item * C<b>

Period of the day, such as C<am>, C<pm>, C<noon>, C<midnight>

See L<Locale::Unicode::Data/calendar_term> and its corollary L<Locale::Unicode::Data/day_period>

=item * C<B>

Flexible day periods, such as C<at night>

See L<Locale::Unicode::Data/calendar_term> and its corollary L<Locale::Unicode::Data/day_period>

=item * C<O>

Zone, such as C<O> to get the short localized GMT format C<GMT-8>, or C<OOOO> to get the long localized GMT format C<GMT-08:00>

=item * C<r>

Related Gregorian year (numeric).

The documentation states that "For the Gregorian calendar, the ‘r’ year is the same as the ‘u’ year."

=item * C<U>

Cyclic year name. However, since this is for non gregorian calendars, like Chinese or Hindu calendars, and since L<DateTime> only supports gregorian calendar, we do not support it either.

=item * C<x>

Timezone, such as C<x> would be C<-08>, C<xx> C<-0800> or C<+0800>, C<xxx> would be C<-08:00> or C<+08:00>, C<xxxx> would be C<-0800> or C<+0000> and C<xxxxx> would be C<-08:00>, or C<-07:52:58> or C<+00:00>

=item * C<X>

Timezone, such as C<X> (C<-08> or C<+0530> or C<Z>), C<XX> (C<-0800> or C<Z>), C<XXX> (C<-08:00>), C<XXXX> (C<-0800> or C<-075258> or C<Z>), C<XXXXX> (C<-08:00> or C<-07:52:58> or C<Z>)

=back

=back

L<DateTime::Format::Unicode> only formats C<CLDR> datetime patterns, and does not parse them back into a L<DateTime> object. If you want to achieve that, there is already the module L<DateTime::Format::CLDR> that does this. L<DateTime::Format::CLDR> relies on L<DateTime/format_cldr> for C<CLDR> formatting by the way.

=head1 CONSTRUCTOR

=head2 new

This takes some hash or hash reference of options, instantiates a new L<DateTime::Format::Unicode> object, and returns it.

Supported options are as follows. Each option can be later accessed or modified by their associated method.

=over 4

=item * C<locale>

A L<locale|Locale::Unicode>, which may be very simple like C<en> or much more complex like C<ja-t-de-t0-und-x0-medical> or maybe C<es-039-valencia> (valencian variant of Spanish as spoken in South Europe)

If not provided, this will default to C<en>

=item * C<on_error>

Specifies what to do upon error. Possible values are: C<undef> (default behaviour), C<fatal> (will die), or a C<CODE> reference that will be called with the L<exception object|DateTime::Format::Unicode::Exception> as its sole argument, before C<undef> is returned in scalar context, or an empty list in list context.

=item * C<pattern>

A C<CLDR> pattern. If none is provided, this will default to the medium-size date pattern for the given C<locale>. For example, as per the C<CLDR>, for English, this would be C<MMM d, y> whereas for the C<locale> C<ja>, this would be C<y/MM/dd>

=item * C<time_zone>

Set the timezone by providing either a L<DateTime::TimeZone> object, or a string representing a timezone.

It defaults to the special L<DateTime> timezone L<floating|DateTime::TimeZone::Floating>

=back

=head1 METHODS

=head2 error

Used as a mutator, this sets an L<exception object|DateTime::Format::Unicode::Exception> and returns an C<DateTime::Format::Unicode::NullObject> in object context (such as when chaining), or C<undef> in scalar context, or an empty list in list context.

The C<DateTime::Format::Unicode::NullObject> class prevents the perl error of C<Can't call method "%s" on an undefined value> (see L<perldiag>). Upon the last method chained, C<undef> is returned in scalar context or an empty list in list context.

=head2 format_datetime

    my $fmt = DateTime::Format::Unicode->new(
        locale => 'en',
        pattern => "Hello the time is H:m:s",
    );
    my $str = $fmt->format_datetime( $dt );

or

    my $fmt = DateTime::Format::Unicode->new(
        locale => 'en',
    );
    my $str = $fmt->format_datetime( $dt,
        pattern => "Hello the time is H:m:s",
    );

This takes a L<DateTime> object, or if none is provided, it will instantiate one using L<DateTime/now>, and formats the L<pattern|/pattern> that was set and return the resulting formatted string.

It takes an optional hash or hash reference of options.

The options supported are:

=over 4

=item * pattern

A pattern to use to format the datetime. If provided, it will override the default set with the method L<pattern|/pattern>

=back

=head2 format_interval

    my $fmt = DateTime::Format::Unicode->new(
        locale => 'en',
        pattern => "GyMMMd",
    );
    my $str = $fmt->format_interval( $dt1, $dt2 );

or

    my $fmt = DateTime::Format::Unicode->new(
        locale => 'en',
    );
    my $str = $fmt->format_interval( $dt1, $dt2
        pattern => "GyMMMd",
    );

This takes 2 L<datetime objects|DateTime> and it returns a formatted string according to the specified L<locale|/locale> and based on the L<interval pattern ID|Locale::Unicode::Data/interval_formats> provided with the L<pattern|/pattern> argument or method.

Alternatively, you can pass a C<pattern> option that will override the default value set with the method L<pattern|/pattern>

You can retrieve an hash of interval format ID to its interval format pattern by using L<DateTime::Locale::FromCLDR|/interval_formats>. For example:

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $ref = $locale->interval_formats;

This would produce an hash like this:

    {
        Bh => [qw( B h )],
        Bhm => [qw( B h m )],
        d => ["d"],
        Gy => [qw( G y )],
        GyM => [qw( G M y )],
        GyMd => [qw( d G M y )],
        GyMEd => [qw( d G M y )],
        GyMMM => [qw( G M y )],
        GyMMMd => [qw( d G M y )],
        GyMMMEd => [qw( d G M y )],
        H => ["H"],
        h => [qw( a h )],
        Hm => [qw( H m )],
        hm => [qw( a h m )],
        Hmv => [qw( H m )],
        hmv => [qw( a h m )],
        Hv => ["H"],
        hv => [qw( a h )],
        M => ["M"],
        Md => [qw( d M )],
        MEd => [qw( d M )],
        MMM => ["M"],
        MMMd => [qw( d M )],
        MMMEd => [qw( d M )],
        y => ["y"],
        yM => [qw( M y )],
        yMd => [qw( d M y )],
        yMEd => [qw( d M y )],
        yMMM => [qw( M y )],
        yMMMd => [qw( d M y )],
        yMMMEd => [qw( d M y )],
        yMMMM => [qw( M y )],
    }

The method will try to get the L<interval greatest difference|DateTime::Locale::FromCLDR/interval_greatest_diff> between the two L<DateTime> objects. If the two objects are equal, the greatest difference will be a day (C<d>). Possibile values are: C<B> (day period), C<G> (eras), C<H> (hours 0-23), C<M> (minutes), C<a> (am/pm), C<d> (days), C<h> (hours 1-12), C<m> (minutes), C<y> (years)

If the method is unable to get a format pattern based on the interval format ID provided, it will assume this is a custom format pattern, and will attempt at breaking it down. If that does not succeed, it will return an error.

=head1 Errors

This module does not die upon errors unless requested to. Instead it sets an L<error object|Locale::Unicode::Data::Exception> that can be retrieved.

When an error occurred, an L<error object|Locale::Unicode::Data::Exception> will be set and the method will return C<undef> in scalar context and an empty list in list context.

The only occasions when this module will die is when there is an internal design error, which would be my fault, or if the value set with L<on_error|/on_error> is C<fatal> or also if the C<CODE> reference set with L<on_error|/on_error> would, itself, die.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<DateTime>, L<DateTime::Format::FromCLDR>, L<Locale::Unicode>, L<Locale::Unicode::Data>, L<DateTime::Locale>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2024 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
