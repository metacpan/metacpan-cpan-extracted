##----------------------------------------------------------------------------
## DateTime Format Intl - ~/lib/DateTime/Format/Intl.pm
## Version v0.1.6
## Copyright(c) 2024 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2024/09/16
## Modified 2024/12/31
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package DateTime::Format::Intl;
BEGIN
{
    use v5.10.1;
    use strict;
    use warnings;
    use warnings::register;
    use vars qw(
        $VERSION $DEBUG $ERROR $FATAL_EXCEPTIONS
        $CACHE $LAST_CACHE_CLEAR $MAX_CACHE_SIZE $BROWSER_DEFAULTS
    );
    use DateTime;
    use DateTime::Locale::FromCLDR;
    use DateTime::Format::Unicode;
    use Locale::Intl;
    use Locale::Unicode::Data;
    use Scalar::Util ();
    use Want;
    our $VERSION = 'v0.1.6';
    our $CACHE = {};
    our $LAST_CACHE_CLEAR = time();
    our $MAX_CACHE_SIZE = 30;
};

use strict;
use warnings;

sub new
{
    my $that = shift( @_ );
    my $self = bless( {} => ( ref( $that ) || $that ) );
    my $this = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts = {%$opts};
    $self->{debug} = delete( $opts->{debug} ) if( exists( $opts->{debug} ) );
    $self->{fatal} = ( delete( $opts->{fatal} ) // $FATAL_EXCEPTIONS // 0 );
    return( $self->error( "No locale was provided." ) ) if( !defined( $this ) || !length( $this ) );
    my $cldr = $self->{_cldr} = Locale::Unicode::Data->new ||
        return( $self->pass_error( Locale::Unicode::Data->error ) );
    my $test_locales = ( Scalar::Util::reftype( $this ) // '' ) eq 'ARRAY' ? $this : [$this];
    my $locale;
    # Test for the locale data availability
    LOCALE_AVAILABILITY: foreach my $loc ( @$test_locales )
    {
        my $tree = $cldr->make_inheritance_tree( $loc ) ||
            return( $self->pass_error( $cldr->error ) );
        # We remove the last 'und' special fallback locale
        pop( @$tree );
        foreach my $l ( @$tree )
        {
            my $ref = $cldr->calendar_formats_l10n(
                locale => $l,
                calendar => 'gregorian',
            );
            return( $self->pass_error( $cldr->error ) ) if( !defined( $ref ) && $cldr->error );
            if( $ref )
            {
                if( Scalar::Util::blessed( $loc ) && ref( $loc ) eq 'Locale::Intl' )
                {
                    $locale = $loc;
                }
                else
                {
                    $locale = Locale::Intl->new( $loc ) ||
                        return( $self->pass_error( Locale::Intl->error ) );
                }
                last LOCALE_AVAILABILITY;
            }
        }
    }
    # Choice of locales provided do not have a supported match, so we fall back to the default 'en'
    $locale = Locale::Intl->new( 'en' ) if( !defined( $locale ) );
    my $unicode = $self->{_unicode} = DateTime::Locale::FromCLDR->new( $locale ) ||
        return( $self->pass_error( DateTime::Locale::FromCLDR->error ) );
    $self->{locale} = $locale;

    my @component_options = qw( weekday era year month day dayPeriod hour minute second fractionalSecondDigits timeZoneName timeStyle dateStyle );
    my @core_options = grep{ exists( $opts->{ $_ } ) } @component_options;
    my $check = {};
    @$check{ @core_options } = (1) x scalar( @core_options );

    # Default values if no options was provided.
    if( !scalar( keys( %$check ) ) )
    {
        # The Mozilla documentation states that "The default value for each date-time component option is undefined, but if all component properties are undefined, then year, month, and day default to "numeric"."
        # However, in reality, this is more nuanced.
        my $defaults = $self->_get_default_options_for_locale ||
            return( $self->pass_error );
        @core_options = qw( day month year );
        @$opts{ @core_options } = @$defaults{ @core_options };
        undef( $defaults );
    }
    else
    {
        # RangeError: invalid value "plop" for option month
        my %valid_options = 
        (
            # calendar is processed separately
            # numberingSystem is processed separately
            calendar                => qr/[a-zA-Z][a-zA-Z0-9]+(?:\-[a-zA-Z][a-zA-Z0-9]+)*/,
            numberingSystem         => qr/[a-zA-Z][a-zA-Z0-9]+/,
            timeZone                => qr/[a-zA-Z0-9\/\_\-\+]+/,
            year                    => [qw( numeric 2-digit )],
            month                   => [qw( numeric 2-digit long short narrow )],
            day                     => [qw( numeric 2-digit )],
            hour                    => [qw( numeric 2-digit )],
            minute                  => [qw( numeric 2-digit )],
            second                  => [qw( numeric 2-digit )],
            hour12                  => [qw( 1 0 ), undef],
            # short: 12/20/2012, GMT+9
            #        12/19/2012, PST
            # long: 12/20/2012, Japan Standard Time
            #       12/19/2012, Pacific Standard Time
            # shortOffset: 12/20/2012, GMT+9
            #              12/19/2012, GMT-8
            # longOffset: 12/20/2012, GMT+09:00
            #             12/19/2012, GMT-08:00
            # shortGeneric: 12/20/2012, Japan Time
            #               12/19/2012, PT
            # longGeneric: 12/20/2012, Japan Standard Time
            #              12/19/2012, Pacific Time
            timeZoneName            => [qw( short long shortOffset longOffset shortGeneric longGeneric )],
            era                     => [qw( narrow short long )],
            weekday                 => [qw( narrow short long )],
            hourCycle               => [qw( h11 h12 h23 h24)],
            # timeZone is processed separately
            dayPeriod               => [qw( narrow short long )],
            fractionalSecondDigits  => [0..3], # 0, 1, 2, or 3 digits
            dateStyle               => [qw( full long medium short )],
            timeStyle               => [qw( full long medium short )],
        );
        
        foreach my $key ( keys( %$opts ) )
        {
            unless( exists( $valid_options{ $key } ) )
            {
                return( $self->error({
                    type => 'RangeError',
                    message => "Invalid option \"${key}\"",
                }) );
            }
            my $value = $opts->{ $key };
            if( ref( $valid_options{ $key} ) eq 'ARRAY' )
            {
                if( !scalar( grep { ( $_ // '' ) eq ( $value // '' ) } @{$valid_options{ $key }} ) )
                {
                    if( $key eq 'fractionalSecondDigits' )
                    {
                        return( $self->error({
                            type => 'RangeError',
                            message => "Invalid value \"${value}\" for option ${key}. Expected an integer between 0 and 3.",
                        }) );
                    }
                    else
                    {
                        return( $self->error({
                            type => 'RangeError',
                            message => "Invalid value \"${value}\" for option ${key}. Expected one of: " . @{$valid_options{ $key }},
                        }) );
                    }
                }
            }
            elsif( ref( $valid_options{ $key} ) eq 'Regexp' )
            {
                if( $value !~ /^$valid_options{ $key}$/ )
                {
                    return( $self->error({
                        type => 'RangeError',
                        message => "Invalid value \"${value}\" for option ${key}.",
                    }) );
                }
            }
        }
    }

    my $has_style = ( $opts->{dateStyle} || $opts->{timeStyle} );
    # my $other_options = scalar( grep{ $opts->{ $_ } } grep{ !/^(date|time)Style$/ } @component_options );
    if( $has_style && (
        $opts->{weekday} ||
        $opts->{era} ||
        $opts->{year} ||
        $opts->{month} ||
        $opts->{day} ||
        $opts->{hour} ||
        $opts->{minute} ||
        $opts->{second} ||
        $opts->{fractionalSecondDigits} ||
        $opts->{timeZoneName}
        ) )
    {
        return( $self->error( "You cannot specify any date-time option while using either dateStyle or timeStyle" ) );
    }

    my $resolved = 
    {
        locale => $locale,
    };
    @$resolved{ @core_options } = @$opts{ @core_options };
    my $calendar = $opts->{calendar};
    my $tz = $opts->{timeZone};
    my $tzNameOpt = $opts->{timeZoneName};
    my $date_style = $opts->{dateStyle};
    my $time_style = $opts->{timeStyle};

    my $hc = $opts->{hourCycle};
    my $h12 = $opts->{hour12};
    my $pattern;

    my $num_sys = $opts->{numberingSystem};

    if( !$calendar )
    {
        if( $calendar = $locale->calendar )
        {
            $opts->{calendar} = $calendar;
        }
        else
        {
            $opts->{calendar} = $calendar = 'gregorian';
        }
    }
    $calendar = 'gregorian' if( $calendar eq 'gregory' );
    if( lc( $calendar ) ne 'gregory' &&
        lc( $calendar ) ne 'gregorian' )
    {
        warn( "The local provided has the calendar attribute set to \"${calendar}\", but this API only supports \"gregory\" or \"gregorian\"." ) if( warnings::enabled() );
        $calendar = 'gregorian';
    }
    $resolved->{calendar} = $calendar;

    # NOTE: timeStyle or hour is define, we do some check and processing for interdependency
    if( length( $time_style // '' ) || $opts->{hour} )
    {
        # Surprisingly, the 'hour12' option takes precedence over the 'hourCycle' even though the latter is more specific.
        # I tried it in browser console:
        # const date = new Date(Date.UTC(2012, 11, 20, 3, 0, 0));
        # hour12: true, hour: "numeric", hourCycle: "h24"
        # console.log( new Intl.DateTimeFormat('en-US', { hour12: true, hour: "numeric", hourCycle: "h24" }).resolvedOptions() );
        # results in the following resolvedOptions:
        # {
        #     calendar: "gregory",
        #     hour: "2-digit",
        #     hour12: false,
        #     hourCycle: "h23",
        #     locale: "en-US",
        #     numberingSystem: "latn",
        #     timeZone: "Asia/Tokyo
        # }
        # "When true, this option sets hourCycle to either "h11" or "h12", depending on the locale. When false, it sets hourCycle to "h23". hour12 overrides both the hc locale extension tag and the hourCycle option, should either or both of those be present." (Mozilla documentation)
        if( defined( $h12 ) )
        {
            # There are 156 occurrences of 'H', and 115 occurrences of 'h', so we default to 'H'
            my $pref_hour_cycle = $unicode->time_format_preferred || 'H';
            $resolved->{hour12} = $h12;
            # Our implementation is more locale sensitive than the browsers' one where the browser would simply revert to h23 if h12 is false, and h12 if hour12 is true
            $resolved->{hourCycle} = $h12
                ? ( ( $pref_hour_cycle eq 'H' || $pref_hour_cycle eq 'K' ) ? 'h11' : 'h12' )
                : ( ( $pref_hour_cycle eq 'h' || $pref_hour_cycle eq 'k' ) ? 'h24' : 'h23' );
        }
        # "The hour cycle to use. Possible values are "h11", "h12", "h23", and "h24". This option can also be set through the hc Unicode extension key; if both are provided, this options property takes precedence." (Mozilla documentation)
        elsif( $hc )
        {
            $resolved->{hourCycle} = $hc;
            $resolved->{hour12} = ( $hc eq 'h12' || $hc eq 'h11' ) ? 1 : 0;
        }
        elsif( $hc = $locale->hc )
        {
            $resolved->{hourCycle} = $hc;
            $resolved->{hour12} = ( $hc eq 'h12' || $hc eq 'h11' ) ? 1 : 0;
        }
        else
        {
            my $pref_hour_cycle = $unicode->time_format_preferred || 'H';
            if( $pref_hour_cycle eq 'h' )
            {
                $resolved->{hourCycle} = 'h12';
                $resolved->{hour12} = 1;
            }
            elsif( $pref_hour_cycle eq 'H' )
            {
                $resolved->{hourCycle} = 'h23';
                $resolved->{hour12} = 0;
            }
            # Although in the Unicode CLDR data for preferred time format, the 'k', or 'K' value is never used, we put it just in case in the future it might be.
            elsif( $pref_hour_cycle eq 'k' )
            {
                $resolved->{hourCycle} = 'h24';
                $resolved->{hour12} = 0;
            }
            elsif( $pref_hour_cycle eq 'K' )
            {
                $resolved->{hourCycle} = 'h11';
                $resolved->{hour12} = 1;
            }
        }
        # 2-digit is more specific than 'numeric', and if it is specified, we do not override it. However, if it is 'numeric', we may override it.
        if( $opts->{hour} && $opts->{hour} ne '2-digit' )
        {
            $resolved->{hour} = ( $resolved->{hourCycle} eq 'h23' || $resolved->{hourCycle} eq 'h24' ) ? '2-digit' : 'numeric';
        }
    }

    my $systems = $unicode->number_systems;
    my $ns_default = $unicode->number_system;
    my $ns_default_def = $cldr->number_system( number_system => $ns_default ) ||
        return( $self->pass_error( $cldr->error ) );
    undef( $ns_default ) unless( $ns_default_def->{type} eq 'numeric' );
    # NOTE: number system check
    if( $num_sys )
    {
        my $num_sys_def = $cldr->number_system( number_system => $num_sys );
        return( $self->pass_error( $cldr->error ) ) if( !defined( $num_sys_def ) && $cldr->error );
        # The proper behaviour is to ignore bad value and fall back to 'latn'
        if( !$num_sys_def )
        {
            warn( "Warning only: invalid numbering system provided \"${num_sys}\"." ) if( warnings::enabled() );
            undef( $num_sys );
            $num_sys_def = {};
        }
        # 'latn' is always supported by all locale as per the LDML specifications
        # We reject the specified if it is not among the locale's default, and if it is not 'numeric' (e.g. if it is algorithmic)
        if( !( $num_sys eq 'latn' || scalar( grep( ( $systems->{ $_ } // '' ) eq $num_sys, qw( number_system native ) ) ) ) && $num_sys_def->{type} ne 'numeric' )
        {
            warn( "Warning only: unsupported numbering system provided \"${num_sys}\" for locale \"${locale}\"." ) if( warnings::enabled() );
            undef( $num_sys );
        }
    }
    if( !defined( $num_sys ) && ( my $locale_num_sys = $locale->number ) )
    {
        my $num_sys_def = $cldr->number_system( number_system => $locale_num_sys );
        return( $self->pass_error( $cldr->error ) ) if( !defined( $num_sys_def ) && $cldr->error );
        $num_sys_def ||= {};
        if( $locale_num_sys eq 'latn' || 
            (
                scalar( grep( ( $systems->{ $_ } // '' ) eq $locale_num_sys, qw( number_system native ) ) ) && 
                $num_sys_def->{type} ne 'numeric'
            ) )
        {
            $num_sys = $locale_num_sys;
        }
        else
        {
            warn( "Warning only: unsupported numbering system provided (${locale_num_sys}) via the locale \"nu\" extension (${locale})." ) if( warnings::enabled() );
        }
    }
    # Still have not found anything
    if( !length( $num_sys // '' ) )
    {
        $num_sys //= $ns_default || 'latn';
    }
    $resolved->{numberingSystem} = $num_sys;

    # NOTE: time zone check
    if( length( $tz // '' ) )
    {
        my $actual = $cldr->timezone_canonical( $tz ) ||
            return( $self->pass_error( $cldr->error ) );
        my $ref = $cldr->timezones( timezone => $actual );
        return( $self->pass_error( $cldr->error ) ) if( !defined( $ref ) && $cldr->error );
        if( !$ref )
        {
            return( $self->error({
                message => "Invalid time zone in " . ref( $self ) . ": ${tz}",
                type => 'RangeError',
            }) );
        }
#         elsif( lc( $tz ) ne lc( $actual ) )
#         {
#             $tz = $actual;
#         }
    }
    elsif( my $bcp47_tz = $locale->timezone )
    {
        my $all = $cldr->timezones( tz_bcpid => $bcp47_tz );
        return( $self->pass_error( $cldr->error ) ) if( !defined( $all ) && $cldr->error );
        if( $all && 
            scalar( @$all ) && 
            $all->[0]->{timezone} )
        {
            $tz = $all->[0]->{timezone};
        }
        else
        {
            warn( "No time zone could be found for the locale's time zone extension value '${bcp47_tz}'" );
        }
    }
    # If we still have not a time zone defined, as a last resort
    if( !length( $tz // '' ) )
    {
        # Calling DateTime time_zone with 'local' might die if not found on the system, so we catch it with eval
        my $dt = eval
        {
            DateTime->now( time_zone => 'local' );
        };
        if( $@ )
        {
            $tz = 'UTC';
        }
        else
        {
            $tz = $dt->time_zone->name;
        }
    }
    $resolved->{timeZone} = $tz;

    # NOTE: time zone name
    if( length( $tzNameOpt // '' ) )
    {
        $resolved->{timeZoneName} = $tzNameOpt;
    }

    # NOTE: era
    # long, short, narrow
    if( my $era = $opts->{era} )
    {
        # Only supported values are: long, short and narrow
        my $width_map =
        {
            'abbreviated' => 'short',
            'wide' => 'long',
        };
        my $tree = $cldr->make_inheritance_tree( $locale ) ||
            return( $self->pass_error( $cldr->error ) );
        my $width;
        my $supported = {};
        LOCALE: foreach my $loc ( @$tree )
        {
            my $all = $cldr->calendar_eras_l10n(
                locale => $loc,
                calendar => $calendar,
            );
            return( $self->pass_error( $cldr->error ) ) if( !defined( $all ) && $cldr->error );
            if( $all )
            {
                foreach my $this ( @$all )
                {
                    $supported->{ ( $width_map->{ $this->{era_width} } // $this->{era_width} ) }++;
                }

                if( exists( $supported->{ $era } ) )
                {
                    $width = $era;
                }
                elsif( $era eq 'short' && exists( $supported->{abbreviated} ) )
                {
                    $width = 'abbreviated';
                }
                last LOCALE;
            }
        }
        unless( defined( $width ) )
        {
            $width = exists( $supported->{long} )
                ? 'long'
                : exists( $supported->{short} )
                    ? 'short'
                    : undef;
        }
        $resolved->{era} = $width;
    }

    # NOTE month, weekday check
    my $values_to_check =
    {
        # CLDR data type => [option value, resolvedOption property]
        month => [$opts->{month}, 'month'],
        day => [$opts->{weekday}, 'weekday'],
    };
    foreach my $prop ( keys( %$values_to_check ) )
    {
        # long, short, narrow
        my $val = $values_to_check->{ $prop }->[0];
        next if( !length( $val // '' ) );
        # This is already ok
        next if( $prop eq 'month' && ( $val eq '2-digit' || $val eq 'numeric' ) );
        # Only supported values are: long, short and narrow
        my $width_map =
        {
            'abbreviated' => 'short',
            'wide' => 'long',
        };
        my $tree = $cldr->make_inheritance_tree( $locale ) ||
            return( $self->pass_error( $cldr->error ) );
        my $width;
        my $supported = {};
        LOCALE: foreach my $loc ( @$tree )
        {
            my $all = $cldr->calendar_terms(
                locale => $loc,
                calendar => $calendar,
                term_type => $prop,
                term_context => 'format',
            );
            return( $self->pass_error( $cldr->error ) ) if( !defined( $all ) && $cldr->error );
            if( $all && scalar( @$all ) )
            {
                foreach my $this ( @$all )
                {
                    $supported->{ ( $width_map->{ $this->{term_width} } // $this->{term_width} ) }++;
                }

                if( exists( $supported->{ $val } ) )
                {
                    $width = $val;
                }
                elsif( $val eq 'short' && exists( $supported->{abbreviated} ) )
                {
                    $width = 'abbreviated';
                }
                last LOCALE;
            }
        }
        unless( defined( $width ) )
        {
            $width = exists( $supported->{long} )
                ? 'long'
                : exists( $supported->{short} )
                    ? 'short'
                    : undef;
        }
        $resolved->{ $values_to_check->{ $prop }->[1] } = $width;
    }

    # NOTE: minute check; minute always end up being 2-digit, even if the user explicitly set it to numeric
    if( $opts->{minute} )
    {
        $resolved->{minute} = '2-digit';
    }
    # NOTE: second; same as minute
    if( $opts->{second} )
    {
        $resolved->{second} = '2-digit';
    }
    $self->{resolvedOptions} = $resolved;

    # NOTE: Getting pattern
    my $cache_key = join( '|', map{ $_ . ';' . $resolved->{ $_ } } sort( keys( %$resolved ) ) );
    $pattern = $self->_get_cached_pattern( $locale, $cache_key );
    unless( $pattern )
    {
        # Now, get the most suitable pattern and cache it.
        my $dateStyle = $resolved->{dateStyle};
        my $timeStyle = $resolved->{timeStyle};
        my $mode2number =
        {
            full    => 4,
            medium  => 3,
            long    => 2,
            short   => 1,
        };
        # NOTE: dateStyle or timeStyle was selected with a value of: full, medium, long, short
        if( $dateStyle || $timeStyle )
        {
            my @mode_keys = keys( %$mode2number );
            my $number2mode = {};
            @$number2mode{ @$mode2number{ @mode_keys } } = @mode_keys;
            my( $date_pattern, $time_pattern );
            if( $dateStyle )
            {
                my $code_date = $unicode->can( "date_format_${dateStyle}" ) ||
                    return( $self->error( "No method date_format_${dateStyle} found in ", ref( $unicode ) ) );
                $date_pattern = $code_date->( $unicode );
                return( $self->pass_error( $unicode->error ) ) if( !defined( $date_pattern ) && $unicode->error );
                return( $self->error( "date_format_${dateStyle}() in class ", ref( $unicode ), " returned an empty value." ) ) if( !length( $date_pattern // '' ) );
            }
            if( $timeStyle )
            {
                my $code_time = $unicode->can( "time_format_${timeStyle}" ) ||
                    return( $self->error( "No method time_format_${timeStyle} found in ", ref( $unicode ) ) );
                $time_pattern = $code_time->( $unicode );
                return( $self->pass_error( $unicode->error ) ) if( !defined( $date_pattern ) && $unicode->error );
                return( $self->error( "time_format_${timeStyle}() in class ", ref( $unicode ), " returned an empty value." ) ) if( !length( $time_pattern // '' ) );
            }

            if( defined( $date_pattern ) && defined( $time_pattern ) )
            {
                # Define the combine mode as the most comprehensive mode of either date or time style specified
                my $datetime_mode = $number2mode->{ _max( $mode2number->{ $dateStyle }, $mode2number->{ $timeStyle } ) };
                my $code_datetime = $unicode->can( "datetime_format_${datetime_mode}" ) ||
                    return( $self->error( "No method datetime_format_${datetime_mode} found in ", ref( $unicode ) ) );
                $pattern = $code_datetime->( $unicode );
                return( $self->pass_error( $unicode->error ) ) if( !defined( $date_pattern ) && $unicode->error );
                return( $self->error( "datetime_format_${datetime_mode}() in class ", ref( $unicode ), " returned an empty value." ) ) if( !length( $pattern // '' ) );
                $pattern =~ s/\{1\}/$date_pattern/g;
                $pattern =~ s/\{0\}/$time_pattern/g;
            }
            else
            {
                $pattern = ( $date_pattern // $time_pattern );
            }
        }
        # NOTE: user has specified either no options or some options other than dateStyle and timeStyle
        # We check the options provided
        else
        {
            # If there is no option provided, the fallback is a short date
            my $patterns = $self->_get_available_format_patterns;
            # NOTE: Calling _select_best_pattern
            my $score_object = $self->_select_best_pattern(
                patterns => $patterns,
                options => $resolved,
            ) || return( $self->pass_error );
            $pattern = $score_object->pattern_object->pattern;
            my $skeleton = $score_object->pattern_object->skeleton;

            $self->{_skeleton} = $skeleton;
        }
        $self->_set_cached_pattern( $locale, $cache_key, $pattern ) unless( !defined( $pattern ) );
    }
    $self->{_pattern} = $pattern;
    return( $self );
}

sub error
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $msg = join( '', map( ( ref( $_ ) eq 'CODE' ) ? $_->() : $_, @_ ) );
        $self->{error} = $ERROR = DateTime::Format::Intl::Exception->new({
            skip_frames => 1,
            message => $msg,
        });
        if( $self->fatal )
        {
            die( $self->{error} );
        }
        else
        {
            warn( $msg ) if( warnings::enabled() );
            if( Want::want( 'ARRAY' ) )
            {
                rreturn( [] );
            }
            elsif( Want::want( 'OBJECT' ) )
            {
                rreturn( DateTime::Format::Intl::NullObject->new );
            }
            return;
        }
    }
    return( ref( $self ) ? $self->{error} : $ERROR );
}

sub fatal { return( shift->_set_get_prop( 'fatal', @_ ) ); }

sub format
{
    my $self = shift( @_ );
    return( $self->error( "format() must be called with an object, and not as a class function." ) ) if( !ref( $self ) );
    my $this = shift( @_ );
    if( !defined( $this ) || !length( $this // '' ) )
    {
        $this = DateTime->now;
    }
    elsif( !( Scalar::Util::blessed( $this ) && $this->isa( 'DateTime' ) ) )
    {
        return( $self->error({
            type => 'RangeError',
            message => "Date value provided is not a DateTime object."
        }) );
    }
    my $dt = $this->clone;
    my $opts = $self->resolvedOptions;
    my $tz;
    if( $opts->{timeZone} )
    {
        $dt->set_time_zone( $tz = $opts->{timeZone} );
    }
    elsif( $tz eq 'floating' )
    {
        $dt->set_time_zone( $tz = 'UTC' );
    }
    else
    {
        $tz = $dt->time_zone->name;
    }
    my $cldr = $self->{_cldr} || die( "The Locale::Unicode::Data object is gone." );
    my $unicode = $self->{_unicode} || die( "The DateTime::Locale::FromCLDR object is gone." );
    my $locale = $self->{locale} || die( "Our Locale::Unicode object is gone!" );
    # We share our DateTime::Locale::FromCLDR object with DateTime, because this module fares much better than the DateTime::Locale::FromData one
    $dt->set_locale( $unicode );

    # This is built upon object instantiation, so that format(9 can be called multiple times and run more rapidly.
#     my $pattern = $self->{_pattern} || die( "Saved pattern is gone!" );
#     my $fmt = DateTime::Format::Unicode->new(
#         locale => $locale,
#         pattern => $pattern,
#         time_zone => $tz,
#     );
#     my $str = $fmt->format_datetime( $dt );
#     return( $self->error( "Error formatting CLDR pattern \"${pattern}\" for locale ${locale}: ", $fmt->error ) ) if( !defined( $str ) && $fmt->error );
#     return( $str );


    my $parts = $self->format_to_parts( $this,
        datetime => $dt,
    ) || return( $self->pass_error );
    if( !scalar( @$parts ) )
    {
        return( $self->error( "Error formatting datetime to parts. No data received!" ) );
    }

    my $str = join( '', map( $_->{value}, @$parts ) );
    return( $str );
}

sub format_range
{
    my $self = shift( @_ );
    my( $this1, $this2 ) = @_;
    if( !( Scalar::Util::blessed( $this1 ) && $this1->isa( 'DateTime' ) ) )
    {
        return( $self->error({
            type => 'RangeError',
            message => "Start datetime value provided is not a DateTime object."
        }) );
    }
    elsif( !( Scalar::Util::blessed( $this2 ) && $this2->isa( 'DateTime' ) ) )
    {
        return( $self->error({
            type => 'RangeError',
            message => "End datetime value provided is not a DateTime object."
        }) );
    }
    my $dt1 = $this1->clone;
    my $dt2 = $this2->clone;
    my $opts = $self->resolvedOptions;
    my $cldr = $self->{_cldr} || die( "The Locale::Unicode::Data object is gone." );
    my $unicode = $self->{_unicode} || die( "The DateTime::Locale::FromCLDR object is gone." );
    my $locale = $self->{locale} || die( "Our Locale::Unicode object is gone!" );
    # We share our DateTime::Locale::FromCLDR object with DateTime, because this module fares much better than the DateTime::Locale::FromData one
    $dt1->set_locale( $unicode );
    $dt2->set_locale( $unicode );
    # Get the greatest difference between those two datetime
    # Possible greatest diff: [qw( a B d G h H m M y )]
    my $diff = $unicode->interval_greatest_diff( $dt1, $dt2, ( $opts->{dayPeriod} ? ( day_period_first => 1 ) : () ) );
    return( $self->pass_error( $unicode->error ) ) if( !defined( $diff ) && $unicode->error );
    # If both dates are identical, we return the value from format() instead
    if( !$diff )
    {
        return( $self->format( $this1 ) );
    }
    my $parts = $self->format_range_to_parts( $this1, $this2,
        diff => $diff,
        datetime1 => $dt1,
        datetime2 => $dt2,
    ) || return( $self->pass_error );
    if( !scalar( @$parts ) )
    {
        return( $self->error( "Error formatting datetime range to parts. No data received!" ) );
    }

    my $str = join( '', map( $_->{value}, @$parts ) );
    return( $str );
}

sub format_range_to_parts
{
    my $self = shift( @_ );
    my( $this1, $this2 ) = @_;
    if( !( Scalar::Util::blessed( $this1 ) && $this1->isa( 'DateTime' ) ) )
    {
        return( $self->error({
            type => 'RangeError',
            message => "Start datetime value provided is not a DateTime object."
        }) );
    }
    elsif( !( Scalar::Util::blessed( $this2 ) && $this2->isa( 'DateTime' ) ) )
    {
        return( $self->error({
            type => 'RangeError',
            message => "End datetime value provided is not a DateTime object."
        }) );
    }
    splice( @_, 0 , 2 );
    my $args = $self->_get_args_as_hash( @_ );
    my $opts = $self->resolvedOptions;
    my $cldr = $self->{_cldr} || die( "The Locale::Unicode::Data object is gone." );
    my $unicode = $self->{_unicode} || die( "The DateTime::Locale::FromCLDR object is gone." );
    my $locale = $self->{locale} || die( "Our Locale::Unicode object is gone!" );
    my( $dt1, $dt2 );
    # Save computational time; if it was provided (internally used), then let's use them.
    if( $args->{datetime1} && $args->{datetime2} )
    {
        $dt1 = $args->{datetime1};
        $dt2 = $args->{datetime2};
    }
    else
    {
        $dt1 = $this1->clone;
        $dt2 = $this2->clone;
        # We share our DateTime::Locale::FromCLDR object with DateTime, because this module fares much better than the DateTime::Locale::FromData one
        $dt1->set_locale( $unicode );
        $dt2->set_locale( $unicode );
    }

    # Get the greatest difference between those two datetime
    # Possible greatest diff: [qw( a B d G h H m M y )]
    my $diff;
    # Save computational power, and share with us the already computed greatest difference
    if( exists( $args->{diff} ) && defined( $args->{diff} ) )
    {
        $diff = $args->{diff};
    }
    else
    {
        $diff = $unicode->interval_greatest_diff( $dt1, $dt2, ( $opts->{dayPeriod} ? ( day_period_first => 1 ) : () ) );
        return( $self->pass_error( $unicode->error ) ) if( !defined( $diff ) && $unicode->error );
    }
    # If both dates are identical, we return the value from format() instead
    if( !$diff )
    {
        return( $self->format_to_parts( $this1 ) );
    }
    # Adjust the greatest difference if it is 'h' or 'H' and we have the optionCycle set, meaning the user has selected some hour-related options
    if( ( $diff eq 'h' || $diff eq 'H' ) &&
        exists( $opts->{hourCycle} ) &&
        $opts->{hourCycle} )
    {
        my $should_be_diff = ( $opts->{hourCycle} eq 'h23' || $opts->{hourCycle} eq 'h24' ) ? 'H' : 'h';
        $diff = $should_be_diff;
    }
    # NOTE: Getting patterns
    my $cache_key = "interval_${diff}_" . join( '|', map{ $_ . ';' . $opts->{ $_ } } sort( keys( %$opts ) ) );
    my $def = $self->_get_cached_pattern( $locale, $cache_key );
    unless( $def )
    {
        # Hash reference of format_id to hash of properties
        my $all = $self->_get_available_interval_patterns( $diff );
        if( !defined( $all ) || !scalar( keys( %$all ) ) )
        {
            return( $self->error( "No interval patterns found for locale \"${locale}\"." ) );
        }
        my $patterns = {};
        foreach my $skel ( sort( keys( %$all ) ) )
        {
            my $pat = $all->{ $skel }->{format_pattern};
            if( !length( $pat // '' ) )
            {
                warn( "Empty pattern for skeleton '${skel}' for locale '${locale}' and greatest difference '${diff}'." ) if( warnings::enabled() );
                next;
            }
            my $repeating_pattern = $all->{ $skel }->{repeating_field};
            my $pos_start = index( $pat, $repeating_pattern );
            if( $pos_start != -1 )
            {
                substr( $pat, $pos_start, length( $repeating_pattern ), '' );
            }
            $patterns->{ $skel } = $pat;
        }

        # my $patterns = $unicode->available_format_patterns;
        my $score_object = $self->_select_best_pattern(
            patterns => $patterns,
            options => $opts,
            diff => $diff,
        ) || return( $self->pass_error );

        my $pattern = $score_object->pattern_object->pattern;
        my $interval_skeleton = $score_object->pattern_object->skeleton;
        my $has_missing_components = $score_object->has_missing;
        # If the result has some missing components, well, we're screwed, because the LDML does not explain how to deal with it

        my $ref;
        # "Once a best match is found between requested skeleton and dateFormatItem id, the corresponding dateFormatItem pattern is used, but with adjustments primarily to make the pattern field lengths match the skeleton field lengths."
        # <https://www.unicode.org/reports/tr35/tr35-dates.html#Matching_Skeletons>
        # No need to bother calling this method, if there is no need for adjustment
        if( $score_object->need_adjustment )
        {
            # $ref has a structure like: [ $part1, $sep, $part2, $best ]
            $ref = $cldr->split_interval(
                greatest_diff => $diff,
                pattern => $pattern,
            ) || return( $self->pass_error( $cldr->error ) );
        }
        else
        {
            my $data = $all->{ $interval_skeleton };
            $ref = [@$data{qw( part1 separator part2 )}];
        }

        $def = 
        {
            parts => $ref,
            # Possibly adjusted pattern
            pattern => $pattern,
            skeleton => $interval_skeleton,
        };
        $self->_set_cached_pattern( $locale, $cache_key, $def );
    }
    $self->{_interval_pattern} = $def->{pattern};
    $self->{_interval_skeleton} = $def->{skeleton};
    $self->{_greatest_diff} = $diff;
    my $parts = [];

    my $parts1 = $self->_format_to_parts(
        pattern => $def->{parts}->[0],
        datetime => $dt1,
    ) || return( $self->pass_error );
    for( @$parts1 )
    {
        $_->{source} = 'startRange';
    }
    push( @$parts, @$parts1 );
    # Add the separator
    push( @$parts, {
        type => 'literal',
        value => $def->{parts}->[1],
        source => 'shared',
    });
    my $parts2 = $self->_format_to_parts(
        pattern => $def->{parts}->[2],
        datetime => $dt2,
    ) || return( $self->pass_error );
    for( @$parts2 )
    {
        $_->{source} = 'endRange';
    }
    push( @$parts, @$parts2 );
    return( $parts );
}

sub format_to_parts
{
    my $self = shift( @_ );
    return( $self->error( "format() must be called with an object, and not as a class function." ) ) if( !ref( $self ) );
    my $this = shift( @_ );
    if( !defined( $this ) || !length( $this // '' ) )
    {
        $this = DateTime->now;
    }
    elsif( !( Scalar::Util::blessed( $this ) && $this->isa( 'DateTime' ) ) )
    {
        return( $self->error({
            type => 'RangeError',
            message => "Date value provided is not a DateTime object."
        }) );
    }
    my $args = {};
    $args = $self->_get_args_as_hash( @_ ) if( ( scalar( @_ ) == 1 && ref( $_[0] // '' ) eq 'HASH' ) || !( @_ % 2 ) );
    my $opts = $self->resolvedOptions;
    my $unicode = $self->{_unicode} || die( "The DateTime::Locale::FromCLDR object is gone." );
    # This is built upon object instantiation, so that format(9 can be called multiple times and run more rapidly.
    my $pattern = $self->{_pattern} || die( "Saved pattern is gone!" );
    my $dt;
    # Save computational time; if it was provided (internally used), then let's use them.
    if( $args->{datetime} )
    {
        $dt = $args->{datetime};
    }
    else
    {
        $dt = $this->clone;
        # We share our DateTime::Locale::FromCLDR object with DateTime, because this module fares much better than the DateTime::Locale::FromData one
        $dt->set_locale( $unicode );
    }

    my $tz;
    if( $opts->{timeZone} )
    {
        $dt->set_time_zone( $tz = $opts->{timeZone} );
    }
    elsif( $tz eq 'floating' )
    {
        $dt->set_time_zone( $tz = 'UTC' );
    }
    else
    {
        $tz = $dt->time_zone->name;
    }

    my $parts = $self->_format_to_parts(
        pattern => $pattern,
        datetime => $dt,
    ) || return( $self->pass_error );
    return( $parts );
}

sub formatRange { return( shift->format_range( @_ ) ); }

sub formatRangeToParts { return( shift->format_range_to_parts( @_ ) ); }

sub formatToParts { return( shift->format_to_parts( @_ ) ); }

sub greatest_diff { return( shift->{_greatest_diff} ); }

sub interval_pattern { return( shift->{_interval_pattern} ); }

sub interval_skeleton { return( shift->{_interval_skeleton} ); }

sub pass_error
{
    my $self = shift( @_ );
    if( Want::want( 'OBJECT' ) )
    {
        rreturn( DateTime::Format::Intl::NullObject->new );
    }
    return;
}

sub pattern { return( shift->{_pattern} ); }

sub resolvedOptions { return( shift->_set_get_prop( 'resolvedOptions', @_ ) ); }

sub skeleton { return( shift->{_skeleton} ); }

sub supportedLocalesOf
{
    my $self = shift( @_ );
    my $locales = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $res = [];
    if( !defined( $locales ) || !length( $locales ) || ( ( Scalar::Util::reftype( $locales ) // '' ) eq 'ARRAY' && !scalar( @$locales ) ) )
    {
        return( $res );
    }
    $locales = ( Scalar::Util::reftype( $locales ) // '' ) eq 'ARRAY' ? $locales : [$locales];
    my $cldr = $self->_cldr || return( $self->pass_error );
    LOCALE: for( my $i = 0; $i < scalar( @$locales ); $i++ )
    {
        my $locale = Locale::Intl->new( $locales->[$i] ) ||
            return( $self->pass_error( Locale::Intl->error ) );
        my $tree = $cldr->make_inheritance_tree( $locale->core ) ||
            return( $self->pass_error( $cldr->error ) );
        # Remove the last one, which is 'und', a.k.a 'root'
        pop( @$tree );
        foreach my $loc ( @$tree )
        {
            my $ref = $cldr->locale( locale => $loc );
            if( $ref && ref( $ref ) eq 'HASH' && scalar( keys( %$ref ) ) )
            {
                push( @$res, $loc );
                next LOCALE;
            }
        }
    }
    return( $res );
}

# Adjust pattern to match the specified format for each component:
# "Once a best match is found between requested skeleton and dateFormatItem id, the corresponding dateFormatItem pattern is used, but with adjustments primarily to make the pattern field lengths match the skeleton field lengths."
# <https://www.unicode.org/reports/tr35/tr35-dates.html#Matching_Skeletons>
sub _adjust_pattern
{
    my $self = shift( @_ );
    my $args = $self->_get_args_as_hash( @_ );
    my $pattern = $args->{pattern} || die( "No pattern was provided." );
    my $opts = $args->{options} || die( "No resolved options hash was provided." );
    if( ref( $pattern ) && !overload::Method( $pattern => '""' ) )
    {
        return( $self->error( "Pattern provided (", overload::StrVal( $pattern ), ") is a reference, but does not stringify." ) );
    }
    elsif( ref( $opts ) ne 'HASH' )
    {
        return( $self->error( "Resolved options provided (", overload::StrVal( $opts // 'undef' ), ") is not an hash reference." ) );
    }
    my $request_object = $args->{request_object} || die( "Missing the request object." );
    # Might not be provided.
    my $pattern_object = $args->{pattern_object};
    if( !ref( $request_object ) || ( ref( $request_object ) && !$request_object->isa( 'DateTime::Format::Intl::Skeleton' ) ) )
    {
        return( $self->error( "The request object provided (", overload::StrVal( $request_object // 'undef' ), ") is not a DateTime::Format::Intl::Skeleton object." ) );
    }
    elsif( defined( $pattern_object ) &&
           ( !ref( $pattern_object ) || ( ref( $pattern_object ) && !$pattern_object->isa( 'DateTime::Format::Intl::Skeleton' ) ) ) )
    {
        return( $self->error( "The pattern object provided (", overload::StrVal( $pattern_object // 'undef' ), ") is not a DateTime::Format::Intl::Skeleton object." ) );
    }
    my $unicode = $self->{_unicode} || die( "The DateTime::Locale::FromCLDR object is gone." );
    my $component_precision = {};
    my $options_map = $self->_get_options_map;

    my $component_to_match =
    {
        # Those are not related to pattern, but because they are in our options we add them here to avoid an error, but discard them later
        calendar => undef,
        numberingSystem => undef,
        # This option is used as an ancillary value to hourCycle option
        hour12 => undef,
        # hourCycle itself is only present if the option 'hour' is set
        hourCycle => undef,
        locale => undef,
        timeZone => undef,
        era => sub
            {
                return( ['G' => 'G' x $options_map->{type_to_length}->{ $opts->{era} } ] );
            },
        year => 'y',
        # Possible values: numeric, 2-digit, long, short, narrow
        month => sub
            {
                # We respect the locale's choice for month display, whether it is 'L' or 'M'
                return({
                    'L' => ( 'L' x $options_map->{month}->{ $opts->{month} } ),
                    'M' => ( 'M' x $options_map->{month}->{ $opts->{month} } ),
                });
            },
        day => 'd',
        # Possible values are 'narrow', 'short' and 'long'
        dayPeriod => sub
            {
                return({
                    'a' => ( 'a' x $options_map->{type_to_length}->{ $opts->{dayPeriod} } ),
                    'b' => ( 'b' x $options_map->{type_to_length}->{ $opts->{dayPeriod} } ),
                    'B' => ( 'B' x $options_map->{type_to_length}->{ $opts->{dayPeriod} } ),
                });
            },
        # For hours, whatever the pattern, be it 'h', 'H', 'k', or 'K', it is overriden by the user's explicit preference
        hour => sub
            {
                if( !exists( $opts->{hourCycle} ) || !defined( $opts->{hourCycle} ) )
                {
                    my $pref = $unicode->time_format_preferred;
                    if( $pref eq 'h' )
                    {
                        $opts->{hourCycle} = 'h11';
                    }
                    elsif( $pref eq 'H' )
                    {
                        $opts->{hourCycle} = 'h23';
                    }
                    elsif( $pref eq 'k' )
                    {
                        $opts->{hourCycle} = 'h23';
                    }
                }
                if( $opts->{hourCycle} eq 'h11' )
                {
                    return( [ [qw( h H k K )] => $opts->{hour} eq '2-digit' ? 'KK' : 'K' ] );
                }
                elsif( $opts->{hourCycle} eq 'h12' || $opts->{hour12} )
                {
                    return( [ [qw( h H k K )] => $opts->{hour} eq '2-digit' ? 'hh' : 'h' ] );
                }
                elsif( $opts->{hourCycle} eq 'h23' )
                {
                    return( [ [qw( h H k K )] => $opts->{hour} eq '2-digit' ? 'HH' : 'H' ] );
                }
                elsif( $opts->{hourCycle} eq 'h24' || ( exists( $opts->{hour12} ) && !$opts->{hour12} ) )
                {
                    return( [ [qw( h H k K )] => $opts->{hour} eq '2-digit' ? 'kk' : 'k' ] );
                }
            },
        minute => 'm',
        # NOTE: also: "Finally: If the requested skeleton included both seconds and fractional seconds and the dateFormatItem skeleton included seconds but not fractional seconds, then the seconds field of the corresponding pattern should be adjusted by appending the locale’s decimal separator, followed by the sequence of ‘S’ characters from the requested skeleton."
        # <https://www.unicode.org/reports/tr35/tr35-dates.html#Matching_Skeletons>
        second => sub
            {
                my $seconds = ( $opts->{second} eq '2-digit' ? ( 's' x 2 ) : 's' );
                if( $opts->{second} && $opts->{fractionalSecondDigits} )
                {
                    my @parts = split( /(?:'(?:(?:[^']|'')*)')/, $pattern );
                    my $has_fractional_seconds = scalar( grep( /S/, @parts ) ) ? 1 : 0;
                    if( $has_fractional_seconds )
                    {
                        return( [['s'] => $seconds] );
                    }
                    else
                    {
                        my $symbols = $unicode->number_symbols || die( $unicode->error );
                        my $sep = $symbols->{decimal} || '.';
                        return( [['s'] => $seconds . $sep . ( 'S' x $opts->{fractionalSecondDigits} )] );
                    }
                }
                else
                {
                    return( [['s'] => $seconds] );
                }
            },
        fractionalSecondDigits => sub
            {
                return(['S', sub
                {
                    my( $token, $length ) = @_;
                    # Remove fractional seconds if 0; we do not return undef; undef implies we leave the original string untouched
                    return( '' ) if( $opts->{fractionalSecondDigits} == 0 );
                    return( 'S' x $opts->{fractionalSecondDigits} );
                }]);
            },
        weekday => sub
            {
                return([ [qw( c e E )], sub
                {
                    my( $token, $length ) = @_;
                    # If the pattern component found is 'c' or 'e', and is less or equal to 2 characters, we leave it untouched, because it would translate into the week day number, and we deal only with the week day name, and we do not want to interfere with the locale's preferred pattern
                    if( $token eq 'E' || ( ( $token eq 'c' || $token eq 'e' ) && $length >= 3 ) )
                    {
                        return( 'E' x $options_map->{type_to_length}->{ $opts->{weekday} } );
                    }
                    # The week day in word starts at 3 characters. Below that it is the week day as a number
                    elsif( ( $token eq 'c' || $token eq 'e' ) && $length >= 3 )
                    {
                        return( $token x ( $options_map->{weekday}->{ $opts->{weekday} } + 2 ) );
                    }
                    return;
                }]);
            },
        # Like for hours, the user preference takes precedence over the pattern component found in the locale's pattern
        timeZoneName => sub
            {
                return( [ [qw( O v V z Z )] => $options_map->{timezone}->{ $opts->{timeZoneName} } ] );
            },
    };

    foreach my $option ( sort( keys( %$opts ) ) )
    {
        if( exists( $component_to_match->{ $option } ) )
        {
            my $val = $component_to_match->{ $option };
            next if( !defined( $val ) );
            if( ref( $val ) )
            {
                if( ref( $val ) eq 'CODE' )
                {
                    my $rv = $val->();
                    # It returned an array reference.
                    # The first part are the LDML pattern components applicable
                    # The second part is how we deal with them when we find them: either we have a string, or a code reference to execute.
                    if( ref( $rv ) eq 'ARRAY' )
                    {
                        # If the first element is an array, it is because there are multiple pattern components to catch
                        # $rv->[1] can be a string, or a code for finer granularity
                        if( ref( $rv->[0] ) eq 'ARRAY' )
                        {
                            foreach my $comp ( @{$rv->[0]} )
                            {
                                $component_precision->{ $comp } = $rv->[1];
                            }
                        }
                        # This should not be happening
                        elsif( ref( $rv->[0] ) )
                        {
                            die( "The first array element returned for option \"${option}\" is a reference, and I do not know what to do with it: '", overload::StrVal( $rv->[0] ), "'" );
                        }
                        else
                        {
                            $component_precision->{ $rv->[0] } = $rv->[1];
                        }
                    }
                    # It returns an hash reference of key-value pairs we add to the final hash
                    elsif( ref( $rv ) eq 'HASH' )
                    {
                        my @keys = keys( %$rv );
                        # Add the given hash keys to our option to pattern component hash reference
                        @$component_precision{ @keys } = @$rv{ @keys };
                    }
                    else
                    {
                        die( "Unsupported value of type '" . ref( $rv ) . "' returned from code reference execution for option \"${option}\"." );
                    }
                }
                elsif( ref( $val ) eq 'HASH' )
                {
                    my @keys = keys( %$val );
                }
                else
                {
                    die( "Unsupported value '", overload::StrVal( $val ), "' returned for option \"${option}\"." );
                }
            }
            else
            {
                $component_precision->{ $val } = ( $opts->{ $option } eq '2-digit' ? ( $val x 2 ) : $val );
            }
        }
        else
        {
            die( "Missing the option \"${option}\" in our configuration!" );
        }
    }

    # "When the pattern field corresponds to an availableFormats skeleton with a field length that matches the field length in the requested skeleton, the pattern field length should not be adjusted. This permits locale data to override a requested field length"
    # <https://www.unicode.org/reports/tr35/tr35-dates.html#Matching_Skeletons>
    # We need the following to perform this LDML check.
    # Character to length. For example: M => 3
    my $request_len = {};
    my $pattern_len = {};
    my $request_tokens = $request_object->tokens;
    foreach my $def ( @$request_tokens )
    {
        $request_len->{ $def->{component} } = $def->{len};
    }
    if( defined( $pattern_object ) )
    {
        my $pattern_tokens = $pattern_object->skeleton_tokens;
        foreach my $def ( @$pattern_tokens )
        {
            $pattern_len->{ $def->{component} } = $def->{len};
        }
    }
    # TODO: An additional rule stipulates that:
    # "Pattern field lengths for hour, minute, and second should by default not be adjusted to match the requested field length (i.e. locale data takes priority)."
    # <https://www.unicode.org/reports/tr35/tr35-dates.html#Matching_Skeletons>
    # However, I am pondering whether to implement it or not.

    $pattern =~ s{
        \G
        (?:
            '((?:[^']|'')*)' # quote escaped bit of text
                             # it needs to end with one
                             # quote not followed by
                             # another
            |
            (([a-zA-Z])\3*)  # could be a pattern
            |
            (.)              # anything else
        )
    }
    {
        if( defined( $1 ) )
        {
            "'" . $1 . "'";
        }
        elsif( defined( $2 ) )
        {
            my $token = $2;
            my $component = $3;
            if( exists( $component_precision->{ $component } ) )
            {
                # either a string or a code reference
                my $this = $component_precision->{ $component };
                # "adjustments should never convert a numeric element in the pattern to an alphabetic element, or the opposite."
                # <https://www.unicode.org/reports/tr35/tr35-dates.html#Matching_Skeletons>
                # For example: skeleton 'yMMM' and pattern actually is 'y年M月'
                # This allows the locale to override
                # The above rule only materialise for the 'month' option, so we check for it here:
                if( ( $component eq 'L' || $component eq 'M' ) &&
                    length( $token ) <= 2 &&
                    $opts->{month} ne 'numeric' &&
                    $opts->{month} ne '2-digit' )
                {
                    $token;
                }
                elsif( exists( $pattern_len->{ $component } ) &&
                       exists( $request_len->{ $component } ) &&
                       $pattern_len->{ $component } == $request_len->{ $component } )
                {
                    $token;
                }
                elsif( ref( $this ) eq 'CODE' )
                {
                    my $rv = $this->( $component, length( $token ) );
                    # If the result is undefined, we leave the original untouched
                    defined( $rv ) ? $rv : $token;
                }
                elsif( ref( $this ) )
                {
                    die( "The value returned for token \"${token}\" is a reference, but I do not know what to do with it: '", overload::StrVal( $this ), "'" );
                }
                else
                {
                    $this;
                }
            }
            # we leave it untouched
            else
            {
                $token;
            }
        }
        elsif( defined( $4 ) )
        {
            $4;
        }
        # Should not get here
        else
        {
            undef;
        }
    }sgex;

    return( $pattern );
}

sub _append_components
{
    my $self = shift( @_ );
    my $args = $self->_get_args_as_hash( @_ );
    my $pattern = $args->{pattern} || die( "No format pattern was provided." );
    my $missing = $args->{missing} || die( "No array reference of missing components was provided." );
    # Possible values: wide (Monday), abbreviated (Mon), short (Mo) and narrow (M)
    # my $width = $args->{width} || die( "No width value provided." );
    if( ref( $pattern ) && !overload::Method( $pattern => '""' ) )
    {
        die( "The pattern value provided (", overload::StrVal( $pattern ), ") is a reference (", ref( $pattern ), "), but it does not stringify." );
    }
    elsif( ref( $missing ) ne 'ARRAY' )
    {
        die( "The value provided for missing components (", overload::StrVal( $missing ), ") is not an array reference." );
    }
    my $cldr = $self->{_cldr} || die( "The Locale::Unicode::Data object is gone." );
    my $locale = $self->{locale} || die( "The locale value is gone!" );
    my $calendar = $self->{calendar} || 'gregorian';
    my $alias =
    {
        'c' => 'E',
        'e' => 'E',
        'H' => 'h',
        'k' => 'h',
        'K' => 'h',
        'L' => 'M',
        'v' => 'Z',
    };
    my $missing_hash = +{ map{ ( $alias->{ $_ } // $_ ) => $_ } @$missing };

    # my @ordered_options = qw( era year month weekday day dayPeriod hour minute second timeZoneName );
    # becomes:
    my @ordered_options = qw( G y M E d B h m s Z );
    # Possible components found in skeleton in CLDR data: [qw( B E G H M Q W Z c d h m s v w y )]
    # All possible format ID known in the CLDR calendar_append_formats table
    my $map =
    {
        # 'B' has no correspondence in table calendar_append_formats, but has in table date_terms
        'c' => ['Day-Of-Week' => 'weekday'],
        'd' => ['Day' => 'day'],
        'e' => ['Day-Of-Week' => 'weekday'],
        'E' => ['Day-Of-Week' => 'weekday'],
        'G' => ['Era' => 'era'],
        'h' => ['Hour' => 'hour'],
        'H' => ['Hour' => 'hour'],
        'k' => ['Hour' => 'hour'],
        'K' => ['Hour' => 'hour'],
        'L' => ['Month' => 'month'],
        'm' => ['Minute' => 'minute'],
        'M' => ['Month' => 'month'],
        # We put it here, but it is actually not used
        'Q' => ['Quarter' => 'quarter'],
        's' => ['Second' => 'second'],
        'v' => ['Timezone' => 'zone'],
        # We put it here, but it is actually not used
        'w' => ['Week' => 'week'],
        'W' => ['Week' => 'week'],
        'y' => ['Year' => 'year'],
        'Z' => ['Timezone' => 'zone'],
    };
    my $tree = $cldr->make_inheritance_tree( $locale ) ||
        return( $self->pass_error( $cldr->error ) );
    my $get_append_pattern = sub
    {
        my $elem = shift( @_ );
        # e.g.: {0} {1}
        # or: {0} ({2}: {1})
        my $pat;
        foreach my $loc ( @$tree )
        {
            my $ref = $cldr->calendar_append_format(
                format_id => $elem,
                locale => $loc,
                calendar => $calendar,
            );
            return( $self->pass_error( $cldr->error ) ) if( !defined( $ref ) && $cldr->error );
            if( $ref )
            {
                $pat = $ref->{format_pattern};
                last;
            }
        }
        return( $pat // '' );
    };
# day
# dayperiod
# month
# quarter
    my $get_term = sub
    {
        my $elem = shift( @_ );
        my $str;
        foreach my $loc ( @$tree )
        {
            my $ref = $cldr->date_term(
                locale => $loc,
                term_type => $elem,
                # Possible choices are 'standard' and 'narrow', but 'narrow' is relatively rare (11.70%).
                term_length => 'standard',
            );
            return( $self->pass_error( $cldr->error ) ) if( !defined( $ref ) && $cldr->error );
            if( $ref )
            {
                $str = $ref->{display_name};
                last;
            }
        }
        return( $str // '' );
    };

    local $" = ', ';
    foreach my $comp ( @ordered_options )
    {
        next unless( exists( $missing_hash->{ $comp } ) );
        if( !exists( $map->{ $comp } ) )
        {
            warn( "Unsupported component (${comp}) requested." );
        }
        my $def = $map->{ $comp };
        my $format = $get_append_pattern->( $def->[0] );
        if( !defined( $format ) )
        {
            return( $self->pass_error );
        }
        elsif( !length( $format ) )
        {
            return( $self->error( "Unable to find an append format pattern for component '${comp}' corresponding to append item '", $def->[0], "' for the locale tree @$tree" ) );
        }
        $format =~ s/\{0\}/$pattern/;
        $format =~ s/\{1\}/$missing_hash->{ $comp }/;
        if( index( $format, '{2}' ) != -1 )
        {
            my $term = $get_term->( $def->[1] );
            if( !defined( $term ) )
            {
                return( $self->pass_error );
            }
            elsif( !length( $term ) )
            {
                return( $self->error( "Unable to find a date term for element '", $def->[1], "' for the locale tree @$tree" ) );
            }
            # Since this is a litteral term, we need to surround it with single quote.
            $format =~ s/\{2\}/\'$term\'/;
        }
        $pattern = $format;
    }
    return( $pattern );
}

sub _cldr
{
    my $self = shift( @_ );
    my $cldr;
    if( ref( $self ) )
    {
        $cldr = $self->{_cldr} ||
            return( $self->error( "The Locale::Unicode::Data object is gone!" ) );
    }
    else
    {
        $cldr = Locale::Unicode::Data->new ||
            return( $self->pass_error( Locale::Unicode::Data->error ) );
    }
    return( $cldr );
}

sub _clear_cache
{
    my $self = shift( @_ );
    my $current_time = time();
    if( $current_time - $LAST_CACHE_CLEAR > 86400 || keys( %$CACHE ) > $MAX_CACHE_SIZE )
    {
        %$CACHE = ();
        $LAST_CACHE_CLEAR = $current_time;
    }
}

# Takes a pattern, break it down into pieces of information as an hash reference and return an array of those hash references
sub _format_to_parts
{
    my $self = shift( @_ );
    my $args = $self->_get_args_as_hash( @_ );
    my $pat = $args->{pattern} || die( "No pattern was provided." );
    my $dt  = $args->{datetime} || die( "No DateTime object was provided." );
    my $locale = $self->{locale} || die( "Our Locale::Unicode object is gone!" );
    my $opts = $self->resolvedOptions;
    unless( $opts->{numberingSystem} eq 'latn' )
    {
        my $clone = Locale::Intl->new( "$locale" ) ||
            return( $self->pass_error( Locale::Intl->error ) );
        $clone->number( $opts->{numberingSystem} );
        $locale = $clone;
    }
    my $fmt = DateTime::Format::Unicode->new( locale => $locale, time_zone => $opts->{timeZone} ) ||
        return( $self->pass_error( DateTime::Format::Unicode->error ) );
    my $map = $fmt->_get_helper_methods ||
        return( $self->pass_error );
    my $comp_map = 
    {
        'a' => 'dayPeriod',
        # Non-standard
        'A' => 'millisecond',
        'b' => 'dayPeriod',
        'B' => 'dayPeriod',
        'c' => 'weekday',
        'C' => 'hour',
        'd' => 'day',
        # Non-standard
        'D' => 'dayOfYear',
        'e' => 'weekday',
        'E' => 'weekday',
        # Non-standard
        'F' => 'dayOfWeekMonth',
        'g' => 'day',
        'G' => 'era',
        'h' => 'hour',
        'H' => 'hour',
        'j' => 'hour',
        'J' => 'hour',
        'k' => 'hour',
        'K' => 'hour',
        'L' => 'month',
        'M' => 'month',
        'm' => 'minute',
        'O' => 'timeZoneName',
        'q' => 'quarter',
        'Q' => 'quarter',
        'r' => 'year',
        's' => 'second',
        'S' => 'secondFractional',
        'u' => 'year',
        # Non-standard
        'U' => 'cyclicYear',
        'v' => 'timeZoneName',
        'V' => 'timeZoneName',
        'w' => 'week',
        'W' => 'week',
        'x' => 'timeZoneName',
        'X' => 'timeZoneName',
        'y' => 'year',
        'Y' => 'year',
        'z' => 'timeZoneName',
        'Z' => 'timeZoneName',
    };

    my $unescape = sub
    {
        my $str = shift( @_ );
        $str =~ s/\'\'/\'/g;
        return( $str );
    };

    my $cldr_pattern = sub
    {
        my $pattern = shift( @_ );
        my $component = substr( $pattern, 0, 1 );
        if( exists( $map->{ $component } ) )
        {
            die( "Unknown component '${component}' in our component to type map." ) if( !exists( $comp_map->{ $component } ) );
            my $code = $map->{ $component };
            my $str = $code->( $fmt, $component, length( $pattern ), $dt );
            return({
                type => $comp_map->{ $component },
                value => ( $str // '' ),
            });
        }
        # Unknown, we return the pattern as-is
        else
        {
            return({
                type => 'literal',
                value => $unescape->( $pattern ),
            });
        }
    };

    my $parts = [];
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
                push( @$parts, { value => $unescape->( $1 ), type => 'literal' });
                $1;
            }
            elsif( defined( $2 ) )
            {
                push( @$parts, $cldr_pattern->( $2 ) );
                $2;
            }
            elsif( defined( $4 ) )
            {
                push( @$parts, { value => $unescape->( $4 ), type => 'literal' });
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
    return( $parts );
}

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

sub _get_available_format_patterns
{
    my $self = shift( @_ );
    my $cldr = $self->{_cldr} || die( "The Locale::Unicode::Data object is gone." );
    my $locale = $self->{locale} || die( "The locale value is gone!" );
    my $calendar = $self->{calendar} || 'gregorian';
    # "The dateFormatItems inherit from their parent locale, so the inherited items need to be considered when processing."
    # <https://www.unicode.org/reports/tr35/tr35-dates.html#Mapping_Requested_Time_Skeletons_To_Patterns>
    my $tree = $cldr->make_inheritance_tree( $locale ) ||
        return( $self->pass_error( $cldr->error ) );
    # Keep track of the format skeleton already found, so we do not replace them while going up the tree
    my $patterns = {};
    local $" = ', ';
    foreach my $loc ( @$tree )
    {
        my $all = $cldr->calendar_available_formats(
            locale      => $loc,
            calendar    => $calendar,
            alt         => undef,
            # count might contain some value
        );
        return( $self->pass_error ) if( !defined( $all ) && $cldr->error );
        if( $all && scalar( @$all ) )
        {
            for( @$all )
            {
                next if( exists( $patterns->{ $_->{format_id} } ) );
                $patterns->{ $_->{format_id} } = $_->{format_pattern};
            }
            # We do not stop here even though we may have a match, because we want to collect all the possible pattern throughout the locale's tree.
        }
    }
    return( $patterns );
}

sub _get_available_interval_patterns
{
    my $self = shift( @_ );
    my $diff = shift( @_ ) || die( "No greatest difference component was provided." );
    my $cldr = $self->{_cldr} || die( "The Locale::Unicode::Data object is gone." );
    my $locale = $self->{locale} || die( "The locale value is gone!" );
    my $calendar = $self->{calendar} || 'gregorian';
    # Get all the interval patterns for the given greatest difference
    # "The dateFormatItems inherit from their parent locale, so the inherited items need to be considered when processing."
    # <https://www.unicode.org/reports/tr35/tr35-dates.html#Mapping_Requested_Time_Skeletons_To_Patterns>
    my $tree = $cldr->make_inheritance_tree( $locale ) ||
        return( $self->pass_error( $cldr->error ) );
    my $patterns = {};
    local $" = ', ';
    foreach my $loc ( @$tree )
    {
        my $all = $cldr->calendar_interval_formats(
            locale => $loc,
            calendar => $calendar,
            greatest_diff_id => $diff,
        );
        if( $all && scalar( @$all ) )
        {
            for( @$all )
            {
                next if( exists( $patterns->{ $_->{format_id} } ) );
                $patterns->{ $_->{format_id} } = $_;
            }
            # We do not stop here even though we may have a match, because we want to collect all the possible pattern throughout the locale's tree.
        }
    }
    return( $patterns );
}

sub _get_cached_pattern
{
    my $self = shift( @_ );
    my( $locale, $key ) = @_;
    $self->_clear_cache;
    if( exists( $CACHE->{ $locale } ) && 
        ref( $CACHE->{ $locale } ) eq 'HASH' &&
        exists( $CACHE->{ $locale }->{ $key } ) )
    {
        return( $CACHE->{ $locale }->{ $key } );
    }
    return;
}

sub _get_datetime_format
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $width = $opts->{width} || die( "No datetime format width was provided." );
    my $type = $opts->{type} || 'atTime';
    die( "Bad datetime format '${type}'" ) if( $type ne 'atTime' && $type ne 'standard' );
    my $cldr = $self->{_cldr} || die( "The Locale::Unicode::Data object is gone." );
    my $locale = $self->{locale} || die( "Our Locale::Unicode object is gone!" );
    my $locales = $cldr->make_inheritance_tree( $locale ) ||
        return( $self->pass_error( $cldr->error ) );
    my $calendar = $self->{calendar} || 'gregorian';
    my $pattern;
    foreach my $loc ( @$locales )
    {
        my $ref = $cldr->calendar_datetime_format(
            locale          => $loc,
            calendar        => $calendar,
            format_type     => $type,
            format_length   => $width,
        );
        return( $self->pass_error ) if( !defined( $ref ) && $cldr->error );
        if( $ref && $ref->{format_pattern} )
        {
            $pattern = $ref->{format_pattern};
            last;
        }
    }
    return( $pattern // '' );
}

sub _get_default_options_for_locale
{
    my $self = shift( @_ );
    my $locale = shift( @_ ) || $self->{locale} ||
        return( $self->error( "No locale was provided to get default options." ) );
    # We want to know basically if the day, and month should be either numeric (i.e. 1 digit), or 2-digit
    # For this, we use the short date locale format and we check for d or d{2} and M and M{2} or L and L{2}
    my $cldr = $self->{_cldr} || die( "The Locale::Unicode::Data object is gone!" );
    # my $unicode = $self->{_unicode} || die( "The DateTime::Locale::FromCLDR object is gone!" );
    my $tree = $cldr->make_inheritance_tree( $locale ) ||
        return( $self->pass_error( $cldr->error ) );
    my $opts =
    {
        day => 'numeric',
        month => 'numeric',
        year => 'numeric',
        hour => 'numeric',
        minute => 'numeric',
        second => 'numeric',
    };
    my $defaults;
    foreach my $loc ( @$tree )
    {
        if( exists( $BROWSER_DEFAULTS->{ $loc } ) )
        {
            $defaults = $BROWSER_DEFAULTS->{ $loc };
            last;
        }
    }
    $defaults = $BROWSER_DEFAULTS->{en} if( !defined( $defaults ) );
    my @keys = keys( %$defaults );
    @$opts{ @keys } = @$defaults{ @keys };
    # $opts->{numberingSystem} = $unicode->number_system;
    return( $opts );
}

# Function to get locale-specific preferences for scoring
sub _get_locale_preferences
{
    my $self = shift( @_ );
    my $locale = $self->{locale} || die( "Locale::Intl object is gone!" );
    my $cldr = $self->_cldr || return( $self->pass_error );
    
    # Define common preference groups
    my $eastern_europe =
    {
        dayPeriod => 3,
        timeZone  => 2
    };
    
    my $western_europe =
    {
        dayPeriod => 3,
        timeZone  => 1
    };

    my $middle_east =
    {
        weekday   => 5,
        era       => 1,
        dayPeriod => 4,
        timeZone  => 3
    };
    
    my $indian_subcontinent =
    {
        dayPeriod => 3,
        timeZone  => 2
    };

    my $east_asia =
    {
        weekday   => 5,
        era       => 5,
        dayPeriod => 1,
        timeZone  => 1
    };

    my $south_east_asia =
    {
        dayPeriod => 3,
        timeZone  => 2
    };

    # Locale-specific preferences with finer granularity
    my %locale_preferences =
    (
        # English locales with finer granularity
        'en-US' => { dayPeriod => 4, timeZone => 1 }, # US uses h12
        'en-GB' => { dayPeriod => 4, timeZone => 1 }, # GB uses h23
        'en-CA' => { dayPeriod => 4, timeZone => 1 }, # Canada uses h12
        'en-AU' => { dayPeriod => 4, timeZone => 1 }, # Australia uses h23
        'en-IN' => { dayPeriod => 4, timeZone => 2 }, # India uses h12
        'en-NZ' => { dayPeriod => 4, timeZone => 1 }, # New Zealand uses h23
        
        # French locales with finer granularity
        'fr-FR' => { dayPeriod => 2, timeZone => 1 }, # France uses h24
        'fr-CA' => { dayPeriod => 2, timeZone => 1 }, # Quebec uses h12
        'fr-BE' => { dayPeriod => 2, timeZone => 1 }, # Belgium uses h24
        'fr-CH' => { dayPeriod => 2, timeZone => 1 }, # Switzerland uses h24

        # Spanish locales with finer granularity
        'es-ES' => { dayPeriod => 3, timeZone => 1 }, # Spain uses h24
        'es-MX' => { dayPeriod => 3, timeZone => 1 }, # Mexico uses h12
        'es-US' => { dayPeriod => 3, timeZone => 1 }, # US Spanish uses h12
        'es-AR' => { dayPeriod => 3, timeZone => 1 }, # Argentina uses h12

        # Chinese locales with finer granularity
        'zh-CN' => { weekday => 5, era => 5, dayPeriod => 2, timeZone => 1 }, # China uses h24
        'zh-TW' => { weekday => 5, era => 5, dayPeriod => 2, timeZone => 1 }, # Taiwan uses h24
        'zh-HK' => { weekday => 5, era => 5, dayPeriod => 2, timeZone => 1 }, # Hong Kong uses h12

        # Russian locale with h24 format
        'ru' => { dayPeriod => 3, timeZone => 2 }, # Russia uses h24

        # Eastern European locales
        'be' => $eastern_europe,
        'bg' => $eastern_europe,
        'cs' => $eastern_europe, 
        'hr' => $eastern_europe,
        'hu' => $eastern_europe,
        'lt' => $eastern_europe,
        'lv' => $eastern_europe,
        'pl' => $eastern_europe,
        'ro' => $eastern_europe, 
        'ru' => $eastern_europe,
        'sk' => $eastern_europe,
        'sl' => $eastern_europe,
        'uk' => $eastern_europe,

        # Western European locales
        'af' => $western_europe,
        'ca' => $western_europe,
        'da' => $western_europe,
        'de' => { dayPeriod => 3, timeZone => 2 },  # Germany uses h24
        'es' => $western_europe,
        'fi' => $western_europe,
        'fr' => { dayPeriod => 3, timeZone => 1 },
        'it' => $western_europe,
        'nl' => $western_europe,
        'sv' => $western_europe,

        # Middle Eastern and Arabic-speaking locales
        'ar' => $middle_east,
        'he' => $middle_east,
        'fa' => $middle_east,
        'ur' => $middle_east,
        
        # Indian subcontinent locales
        'hi' => $indian_subcontinent,
        'bn' => $indian_subcontinent,
        'gu' => $indian_subcontinent,
        'ml' => $indian_subcontinent,
        'mr' => $indian_subcontinent,
        'ta' => $indian_subcontinent,
        'te' => $indian_subcontinent,
        
        # East Asia
        # Japan uses h24
        'ja' => { weekday => 4, era => 6, dayPeriod => 3, timeZone => 2 },
        'zh' => $east_asia,
        'ko' => { weekday => 4, era => 4, dayPeriod => 3, timeZone => 2 },

        # Southeast Asian locales
        'id' => $south_east_asia,
        'ms' => $south_east_asia,
        'vi' => $south_east_asia,
        'th' => $south_east_asia,

        # Default fallback for unspecified locales
        _default =>
        {
            weekday   => 7,
            era       => 4,
            dayPeriod => 4,
            timeZone  => 3,
        }
    );

    my $locales = $cldr->make_inheritance_tree( $locale ) ||
        return( $self->pass_error( $cldr->error ) );
    # Remove the last one: und
    pop( @$locales );
    # Return the specific locale's preferences, or fallback to the default
    foreach my $loc ( @$locales )
    {
        if( exists( $locale_preferences{ $loc } ) )
        {
            return( $locale_preferences{ $loc } );
        }
    }
    # Return the specific locale's preferences, or fallback to the default
    return( $locale_preferences{_default}  );
}

# We return 2 hash reference:
# 1) An hash of components to weight and penalty used for scoring available patterns
# 2) An hash of resolved options related components with their expected length, so we can score higher a pattern that match our option and has the right length.
sub _get_option_dictionary
{
    my $self = shift( @_ );
    my $args = $self->_get_args_as_hash( @_ );
    # Resolved options
    my $opts = $args->{options} ||
        return( $self->error( "No options was provided." ) );
    # For intervals; this is optional and may be undef
    my $diff = $args->{diff};
    # Scoring adjustments based on locale-specific preferences
    my $locale_preferences = $self->_get_locale_preferences;
    # Score based on exact matches in the skeleton, with higher weights for more critical components
    # Define expected lengths and pattern characters for all options
    my $options_dict =
    {
        era =>
        {
            pattern_components => [qw(G)],
            penalty => 15,
            len =>
            {
                short  => [1..3], # G..GGG
                long   => 4,      # GGGG
                narrow => 5,      # GGGGG
            },
            weight => ( $locale_preferences->{era} || 4 ),
        },
        year =>
        {
            pattern_components => [qw(y Y)],
            penalty => 15,
            len =>
            {
                # 4 should be enough, but there is no upper limit actually in the LDML specifications
                numeric   => [1..6], # y (numeric year)
                '2-digit' => 2       # yy (2-digit year)
            },
            weight => 14, # Year is generally important
        },
        month =>
        {
            pattern_components => [qw(M L)], # M and L for month
            penalty => 15,
            len =>
            {
                numeric   => [1, 2], # M (numeric) or MM (2-digit)
                '2-digit' => 2,      # MM (2-digit month)
                short     => 3,      # MMM (abbreviated month)
                long      => 4,      # MMMM (full month name)
                narrow    => 5       # MMMMM (narrow month)
            },
            weight => 17, # Month is usually important
        },
        day =>
        {
            pattern_components => [qw(d)],
            penalty => 15,
            len =>
            {
                numeric   => 1, # d (numeric day)
                '2-digit' => 2  # dd (2-digit day)
            },
            weight => 10,
        },
        weekday =>
        {
            pattern_components => [qw(c e E)],
            # Penalize heavily for unrequested weekday
            penalty => 20,
            len => 
            {
                # length of 1 and 2 are reserved for weekday as a number for pattern component 'c' and 'e', but not for E.
                # Abbreviated in CLDR
                short  =>
                {
                    'c' => 3,      # ccc (Tue)
                    'e' => 3,      # eee (Tue)
                    'E' => [1..3], # E..EEE (Tue)
                },
                # Wide in CLDR
                long   => 4,      # cccc (Tuesday), eeee (Tuesday), EEEE (Tuesday)
                # 6 characters should not happen though
                # Narrow and short in CLDR
                narrow => [5,6],  # ccccc (T), cccccc (Tu), eeeee (T), eeeeee (Tu), EEEEE (T), EEEEEE (Tu)
            },
            weight => ( $locale_preferences->{weekday} || 7 ),
        },
        dayPeriod =>
        {
            # "Patterns for 12-hour-cycle time formats (using h or K) must include a day period field using one of a, b, or B."
            # <https://www.unicode.org/reports/tr35/tr35-dates.html#availableFormats_appendItems>
            # See at the end of this method for the implementation of this rule.
            # pattern_components => [qw(a b B)],
            # Actually, 'a' is AM/PM, not really a day period
            pattern_components => [qw(b B)],
            # Penalize for unrequested day periods
            penalty => 15,
            len => 
            {
                short  => [1..3], # a..aaa, b..bbb, B..BBB (AM/PM)
                long   => 4,      # aaaa, bbbb, BBBB; b or B for specific day periods like noon or midnight
                narrow => 5,      # aaaaa, bbbbb, BBBBB
            },
            weight => ( $locale_preferences->{dayPeriod} || 4 ),
        },
        hour =>
        {
            pattern_components => [qw(h H k K)],
            penalty => 15,
            len =>
            {
                numeric   => [1,2], # h, H, k, K (numeric hour)
                '2-digit' => 2,     # hh, HH, kk, KK (2-digit hour)
            },
            weight => 3,
            alias =>
            {
                # Only 'h' or 'H' are used in our option skeleton built in _options_to_skeleton()
                # and generally also in the CLDR available pattern skeletons
                'H' => ['k'],
                'h' => ['K'],
            },
        },
        minute =>
        {
            pattern_components => [qw(m)],
            penalty => 15,
            len =>
            {
                numeric   => [1,2], # m (numeric minute)
                '2-digit' => 2,     # mm (2-digit minute)
            },
            weight => 3,
        },
        second =>
        {
            pattern_components => [qw(s)],
            penalty => 15,
            len =>
            {
                numeric   => [1,2], # s (numeric second)
                '2-digit' => 2,     # ss (2-digit second)
            },
            weight => 3,
        },
        fractionalSecondDigits =>
        {
            pattern_components => [qw(S)],
            # Default penalty for unrequested components
            penalty => 5,
            len =>
            {
                1 => 1, # S (tenths of a second)
                2 => 2, # SS (hundredths of a second)
                3 => 3, # SSS (milliseconds)
            },
            weight => 3,
        },
        # 'V' is more for the time zone ID, or long time zone name, or exemplar city name
        timeZoneName =>
        {
            pattern_components => [qw(O z Z v V)],
            # Default penalty for unrequested components
            penalty => 5,
            len =>
            {
                short        =>
                {
                    'O' => 1,      # O (GMT-8)
                    'v' => 1,      # v (short generic non-location format; e.g.: PT)
                    'V' => 1,      # V (short time zone ID; e.g. uslax)
                    'z' => [1..3], # z..zzz (short localized GMT offset; e.g.: PDT)
                    'Z' => [1..3], # Z..ZZZ (ISO8601 basic format; e.g.: -0800)
                },
                long         => [4,5], # OOOO (GMT-08:00), zzzz (long localized GMT offset; e.g.: Pacific Daylight Time), ZZZZ (long localized GMT format. e.g.: GMT-8:00), ZZZZZ (ISO8601 extended format with hours, minutes and optional seconds; e.g.: -08:00 or -07:52:58)
                long         =>
                {
                    'O' => 4,      # OOOO (long localized GMT format; e.g.: GMT-08:00)
                    'v' => 4,      # vvvv (long generic non-location format; e.g.: Pacific Time)
                    # I seriously doubt VVV or VVVV would be occurring, but out of abondance of precaution, I add it anyway
                    'V' => [2..4], # VV (long time zone ID; e.g. America/Los_Angeles), VVV (exemplar city; e.g.: Los Angeles), VVVV (generic location format; e.g.: Los Angeles Time)
                    'z' => 4,      # zzzz (long specific non-location format; e.g.: Pacific Daylight Time)
                    # I doubt the ISO8601 extended format occurs, but out of abondance of precaution, I add it here anyway.
                    'Z' => [4,5],  # ZZZZ (long localized GMT format: e.g.: GMT-8:00), ZZZZZ (ISO8601 extended format with hours, minutes and optional seconds; e.g.: -07:52:58)
                },
                shortOffset  => 1, # Z (short ISO-8601 time zone offset)
                longOffset   => 4, # ZZZZ (long ISO-8601 time zone offset with GMT)
                shortGeneric => 1, # v (short generic non-location format; e.g.: PT)
                longGeneric  => 4, # vvvv (long generic non-location format; e.g.: Pacific Time), VVVV (long generic location format; e.g.: Los Angeles Time)
            },
            weight => ( $locale_preferences->{timeZone} || 3 ),
        }
    };
    # The components length for the selected options
    my $components_length = {};
    # The components weight and penalty
    my $components_weight = {};
    # The components aliases only for the resolved options components
    # Because, as the Unicode LDML specifies: "Only one field of each type is allowed; that is, "Hh" is not valid."
    # <https://www.unicode.org/reports/tr35/tr35-dates.html#availableFormats_appendItems>
    my $components_alias = {};
    foreach my $option ( keys( %$options_dict ) )
    {
        my $def = $options_dict->{ $option };
        my $components = $def->{pattern_components};
        foreach my $c ( @$components )
        {
            $components_weight->{ $c } = {};
            for( qw( weight penalty ) )
            {
                $components_weight->{ $c }->{ $_ } = $def->{ $_ };
            }
        }
        if( exists( $opts->{ $option } ) )
        {
            my $len = $def->{len};
            # Should not happen though
            die( "Misconfiguration: missing option value \"", $opts->{ $option }, "\" in our option length dictionary." ) if( !exists( $len->{ $opts->{ $option } } ) );
            if( ref( $len->{ $opts->{ $option } } ) eq 'HASH' )
            {
                foreach my $c ( keys( %{$len->{ $opts->{ $option } }} ) )
                {
                    $components_length->{ $c } = $len->{ $opts->{ $option } }->{ $c };
                }
            }
            else
            {
                foreach my $c ( @$components )
                {
                    # which could be an integer, or an array reference of integer, such as [1,2]
                    $components_length->{ $c } = $len->{ $opts->{ $option } };
                }
            }

            if( exists( $def->{alias} ) )
            {
                foreach my $k ( keys( %{$def->{alias}} ) )
                {
                    die( "Configuration error: I was expecting an array reference for this alias value for component \"${k}\", but instead I got '", $def->{alias}->{ $k }, "'" ) if( ref( $def->{alias}->{ $k } ) ne 'ARRAY' );
                    my $keys = $def->{alias}->{ $k };
                    $components_alias->{ $k } = [@$keys];
                }
            }
            else
            {
                foreach my $c ( @$components )
                {
                    # Any other, we alias to
                    my @keys = grep( $_ ne $c, @$components );
                    $components_alias->{ $c } = \@keys;
                }
            }
        }
        # If this option possible components match the greatest difference component if provided
        elsif( defined( $diff ) && scalar( grep( $_ eq $diff, @{$def->{pattern_components}} ) ) )
        {
            # We build an array of all possible length for this option
            my $len = $def->{len};
            foreach my $comp ( keys( %$len ) )
            {
                if( ref( $len->{ $comp } ) eq 'HASH' )
                {
                    foreach my $c ( keys( %{$len->{ $comp }} ) )
                    {
                        $components_length->{ $c } ||= [];
                        push( @{$components_length->{ $c }}, ref( $len->{ $comp }->{ $c } ) eq 'ARRAY' ? @{$len->{ $comp }->{ $c }} : $len->{ $comp }->{ $c } );
                    }
                }
                else
                {
                    foreach my $c ( @$components )
                    {
                        $components_length->{ $c } ||= [];
                        # which could be an integer, or an array reference of integer, such as [1,2]
                        push( @{$components_length->{ $c }}, ref( $len->{ $comp } ) eq 'ARRAY' ? @{$len->{ $comp }} : $len->{ $comp } );
                    }
                }
            }

            if( exists( $def->{alias} ) )
            {
                foreach my $k ( keys( %{$def->{alias}} ) )
                {
                    die( "Configuration error: I was expecting an array reference for this alias value for component \"${k}\", but instead I got '", $def->{alias}->{ $k }, "'" ) if( ref( $def->{alias}->{ $k } ) ne 'ARRAY' );
                    my $keys = $def->{alias}->{ $k };
                    $components_alias->{ $k } = [@$keys];
                }
            }
            else
            {
                foreach my $c ( @$components )
                {
                    # Any other, we alias to
                    my @keys = grep( $_ ne $c, @$components );
                    $components_alias->{ $c } = \@keys;
                }
            }
        }
    }

    # "Patterns for 12-hour-cycle time formats (using h or K) must include a day period field using one of a, b, or B."
    # <https://www.unicode.org/reports/tr35/tr35-dates.html#availableFormats_appendItems>
    # We add an entry for AM/PM if hour12 is true and dayPeriod is not provided.
    # If dayPeriod is already provided, no need for 'a' as it would be redundant and the CLDR data reflects this.
    if( exists( $opts->{hour12} ) &&
        $opts->{hour12} &&
        !exists( $opts->{dayPeriod} ) )
    {
        $components_length->{a} = [1..3];
        $components_weight->{a} = 5;
        $components_alias->{a} = ['a'];
    }
    # Some adjustments
    if( exists( $opts->{hour12} ) )
    {
        if( $opts->{hour12} )
        {
            # Remove H23 and H24
            delete( @$components_length{ qw( H k ) } );
        }
        else
        {
            # Remove h11 and h12
            delete( @$components_length{ qw( h K ) } );
        }
    }
    return( $components_length, $components_weight, $components_alias );
}

sub _get_options_map
{
    my $self = shift( @_ );
    my $map =
    {
        # Maps for format length adjustments
        type_to_length =>
        {
            # actually 'abbreviated' in LDML parlance
            short   => 1,
            # actually 'wide' in LDML parlance
            long    => 4,
            narrow  => 5,
        },
        # Those have been carefully considered n light of the documentation at:
        # <https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/DateTimeFormat/DateTimeFormat#timezonename>
        # and the LDML symbols at:
        # <https://unicode.org/reports/tr35/tr35-dates.html#dfst-zone>
        # my $timeZoneName_map =
        timezone =>
        {
            # Short localized form (e.g.: "PST", "GMT-8")
            short        => 'z',
            # Long localized form (e.g., "Pacific Standard Time", "Nordamerikanische Westküsten-Normalzeit")
            long         => 'zzzz',
            # Short localized GMT format (e.g., "GMT-8")
            shortOffset  => 'O',
            # Long localized GMT format (e.g., "GMT-08:00")
            longOffset   => 'OOOO',
            # Short generic non-location format (e.g.: "PT", "Los Angeles Zeit").
            shortGeneric => 'v',
            # Long generic non-location format (e.g.: "Pacific Time", "Nordamerikanische Westküstenzeit")
            longGeneric  => 'vvvv'
        },
        # my $month_map =
        month =>
        {
            numeric => 1,
            '2-digit' => 2,
            # 'abbreviated' in LDML parlance
            short => 3,
            # 'wide' in LDML parlance
            long => 4,
            narrow => 5,
        },
        # For pattern characters 'c' or 'e'
        # my $weekday_map =
        weekday =>
        {
            # actually 'abbreviated' in LDML parlance -> example: 'Tue'
            short   => 1, # 2, or 3 are also acceptable
            # actually 'wide' in LDML parlance -> example: 'Tuesday'
            long    => 4,
            # also matches 'narrow' in LDML -> example: 'T'
            narrow  => 5,
            
        },
    };
    return( $map );
}

sub _max
{
    my( $x, $y ) = @_;
    return( ( $x > $y ) ? $x : $y );
}

sub _new_request_object
{
    my $self = shift( @_ );
    my $args = $self->_get_args_as_hash( @_ );
    my $opts = $args->{options} || die( "No resolved options hash reference provided." );
    my $diff = $args->{diff};
    # $tokens is an array reference of hash with component, token and len properties
    # $components is an array of 1-letter component
    my( $requested_skeleton, $tokens, $components, $date_components, $time_components ) = $self->_options_to_skeleton(
        options => $opts,
        ( defined( $diff ) ? ( diff => $diff ) : () ),
    ) || return( $self->pass_error );

    # Checking for exact match in the available pattern skeleton sounds like a great idea, but it leads to false positive.
    # So, we are best off going through all of the patterns and scoring them
    my $request_object = $self->_new_skeleton_object(
        pattern_skeleton => $requested_skeleton,
        components => $components,
        date_components => $date_components,
        time_components => $time_components,
        tokens => $tokens,
        debug => $DEBUG,
    ) || return( $self->pass_error );
    return( $request_object );
}

sub _new_score_result
{
    my $self = shift( @_ );
    my $obj = DateTime::Format::Intl::ScoreResult->new( @_ ) ||
        return( $self->pass_error( DateTime::Format::Intl::ScoreResult->error ) );
    return( $obj );
}

sub _new_skeleton_object
{
    my $self = shift( @_ );
    my $obj = DateTime::Format::Intl::Skeleton->new( @_ ) ||
        return( $self->pass_error( DateTime::Format::Intl::Skeleton->error ) );
    return( $obj );
}

# Generate a skeleton from the user-provided options, ensuring a consistent order
sub _options_to_skeleton
{
    my $self = shift( @_ );
    my $args = $self->_get_args_as_hash( @_ );
    my $opts = $args->{options} ||
        return( $self->error( "No options provided." ) );
    # Provided if format_range() was called, otherwise this is undef
    my $diff = $args->{diff};

    my $skeleton = '';

    # Ensure a fixed order of components when building the skeleton
    # "The canonical order is from top to bottom in that table; that is, "yM" not "My"."
    # <https://www.unicode.org/reports/tr35/tr35-dates.html#availableFormats_appendItems>
    my @ordered_options = qw( era year month weekday day dayPeriod hour minute second timeZoneName );

    my $options_map = $self->_get_options_map;
    # Map of option keys to skeleton components
    # Possible components found in skeleton in CLDR data: [qw( B E G H M Q W Z c d h m s v w y )]
    # "It is not necessary to supply dateFormatItems with skeletons for every field length; fields in the skeleton and pattern are expected to be adjusted in parallel to handle a request."
    # <https://www.unicode.org/reports/tr35/tr35-dates.html#Matching_Skeletons>
    my $option_to_skeleton = 
    {
        year            => sub
        {
            return( 'y' x ( exists( $opts->{year} ) ? ( $opts->{year} eq '2-digit' ? 2 : 1 ) : 1 ) );
        },
        month           => sub
        {
            return( 'M' x ( exists( $opts->{month} ) ? $options_map->{month}->{ $opts->{month} } : 1 ) );
        },
        day             => sub
        {
            return( 'd' x ( exists( $opts->{day} ) ? ( $opts->{day} eq '2-digit' ? 2 : 1 ) : 1 ) );
        },
        # There are 1 instance in the CLDR data where the skeleton uses 'c' (locale 'fi' with skeleton 'yMMMMccccd')
        weekday         => sub
        {
            return( 'E' x ( exists( $opts->{weekday} ) ? $options_map->{weekday}->{ $opts->{weekday} } : 1 ) );
        },
        # Can switch to 'H' for 24-hour time
        # hour            => 'h',
        hour            => sub
        {
            my $comp = ( exists( $opts->{hourCycle} ) && defined( $opts->{hourCycle} ) && ( $opts->{hourCycle} eq 'h23' || $opts->{hourCycle} eq 'h24' ) ) ? 'H' : 'h';
            return( $comp x ( exists( $opts->{hour} ) ? ( $opts->{hour} eq '2-digit' ? 2 : 1 ) : 1 ) );
        },
        minute          => sub
        {
            return( 'm' x ( exists( $opts->{minute} ) ? ( $opts->{minute} eq '2-digit' ? 2 : 1 ) : 1 ) );
        },
        second          => sub
        {
            return( 's' x ( exists( $opts->{second} ) ? ( $opts->{second} eq '2-digit' ? 2 : 1 ) : 1 ) );
        },
        era             => sub
        {
            return( 'G' x ( exists( $opts->{era} ) ? $options_map->{type_to_length}->{ $opts->{era} } : 1 ) );
        },
        dayPeriod       => sub
        {
            return( 'B' x ( exists( $opts->{dayPeriod} ) ? $options_map->{type_to_length}->{ $opts->{dayPeriod} } : 1 ) );
        },
        # There is 1 instance in the CLDR data where the skeleton uses 'Z' (locale 'fa' with skeleton 'HHmmZ')
        timeZoneName    => sub
        {
            return( exists( $opts->{timeZoneName} ) ? $options_map->{timezone}->{ $opts->{timeZoneName} } : 'v' );
        },
        # 'w' (week of year) and 'W' (week of month) are also found in the skeletons. 309 and 322 times respectively.
        # 'Q' (quarter) is also found 419 times in the skeletons, amazingly enough.
    };
    # SELECT DISTINCT(format_id) FROM calendar_available_formats WHERE format_id regexp('G') ORDER BY LENGTH(format_id), format_id;
#     my $singletons =
#     {
#         # Bh, Bhm, Bhms, EBhm, EBhms
#         'B' => 1,
#         # 'c' can have multiple occurrence
#         # 'd' can have multiple occurrence
#         # E can have multiple occurrence
#         # Gy, GyM, GyMd, GyMMM, GyMMMM, GyMMMd, GyMMMEd, GyMMMMd, GyMEEEEd, GyMMMMEd, GyMMMEEEEd
#         'G' => 1,
#         # H, h, K, k can have multiple occurrence
#         # M, L can have multiple occurrence, although L never appears in skeletons
#         # m can have multiple occurrence
#         # s can have multiple occurrence
#         # Q can have multiple occurrence
#         # v can have multiple occurrence
#         # w can have multiple occurrence
#         # W probably can have multiple occurrence, although it never appears in skeletons
#         # y can have multiple occurrence
#         'Z' => 1,
#     };

    my $date_elements =
    {
        era => 1,
        year => 1,
        month => 1,
        weekday => 1,
        day => 1,
    };
    my $time_elements =
    {
        dayPeriod => 1,
        hour => 1,
        minute => 1,
        second => 1,
        timeZoneName => 1,
    };
    my $components = [];
    my $tokens = [];
    my $date_components = [];
    my $time_components = [];
    foreach my $option ( @ordered_options )
    {
        my $value = ( ref( $option_to_skeleton->{ $option } ) ? $option_to_skeleton->{ $option }->() : $option_to_skeleton->{ $option } );
        if( ( exists( $opts->{ $option } ) && length( $opts->{ $option } // '' ) ) ||
            ( defined( $diff ) && $value eq $diff ) )
        {
            $skeleton .= $value;
            push( @$tokens, {
                component => substr( $value, 0, 1 ),
                token => $value,
                len => length( $value ),
            });
            push( @$components, substr( $value, 0, 1 ) );
            if( exists( $date_elements->{ $option } ) )
            {
                push( @$date_components, substr( $value, 0, 1 ) );
            }
            elsif( exists( $time_elements->{ $option } ) )
            {
                push( @$time_components, substr( $value, 0, 1 ) );
            }
            else
            {
                warn( "Uncategorised option \"${option}\" in either date or time map." ) if( warnings::enabled() );
            }
        }
    }
    return( wantarray ? ( $skeleton, $tokens, $components, $date_components, $time_components ) : $skeleton );
}

# Convert a pattern to a skeleton for comparison
sub _pattern_to_skeleton
{
    my $self = shift( @_ );
    my $pattern = shift( @_ );
    
    # Map format patterns to skeleton components
    # Found 16 skeleton components: [qw( B E G H M Q W Z c d h m s v w y )]
    my $format_to_skeleton =
    {
        'a' => 'B',
        'A' => 'B',
        'b' => 'B',
        'B' => 'B',
        'c' => 'E',
        'C' => 'h',
        'd' => 'd',
        # D (day of year)
        'e' => 'E',
        'E' => 'E',
        # F (Day of Week in Month)
        # g (Modified Julian day)
        'G' => 'G',
        'h' => 'h',
        'H' => 'H',
        'j' => 'h',
        'J' => 'h',
        'k' => 'H',
        'K' => 'h',
        'L' => 'M',
        'M' => 'M',
        'm' => 'm',
        'O' => 'v',
        'q' => 'Q',
        'Q' => 'Q',
        # r (Related Gregorian year)
        's' => 's',
        # S (Fractional Second)
        # u (Extended year)
        # U (Cyclic year name)
        'v' => 'v',
        'V' => 'v',
        'w' => 'w',
        'W' => 'W',
        'x' => 'v',
        'X' => 'v',
        'y' => 'y',
        'Y' => 'y',
        'z' => 'Z',
        'Z' => 'Z',
    };
    
    my $skeleton = '';
    # TODO: needs to be improved
    foreach my $component ( split( //, $pattern ) )
    {
        if( exists( $format_to_skeleton->{ $component } ) )
        {
            # $skeleton .= $format_to_skeleton->{ $component };
            $skeleton .= $component;
        }
    }
    return( $skeleton );
}

sub _remove_literal_text
{
    my $self = shift( @_ );
    my $pattern = shift( @_ );
    # This is an internal mishandling: die
    die( "No pattern was provided!" ) if( !length( $pattern // '' ) );
    # Regex to handle escaped single quotes ('') and remove literal text
    # Matches text inside single quotes and escaped quotes
    $pattern =~ s/'(?:[^']|'')*'//g;
    return( $pattern );
}

# Fine-tuned scoring logic based on real-world usage patterns and cultural preferences
sub _score_pattern
{
    my $self = shift( @_ );
    my $args = $self->_get_args_as_hash( @_ );
    my $pattern_object = $args->{pattern_object} || die( "Missing pattern object." );
    my $request_object = $args->{request_object} || die( "Missing request object." );
    my $opts = $args->{options} || die( "Missing the user options." );
    my $pattern = $pattern_object->pattern;
    my $pattern_skeleton = $pattern_object->pattern_skeleton;
    # Array of descriptive dictionary for each component, such as: { component => 'E', token => 'EEEE', len => 4 }
    my $pattern_tokens = $pattern_object->tokens;
    my $requested_skeleton = $request_object->pattern_skeleton;
    my $requested_tokens = $request_object->tokens;

    my $locale = $self->{locale} || die( "The Locale::Intl object is gone" );
    my $unicode = $self->{_unicode} || die( "The DateTime::Locale::FromCLDR object is gone" );
    
    my $score = 0;

    my $components_length = $self->{_components_length};
    my $components_weight = $self->{_components_weight};
    my $components_alias  = $self->{_components_alias};

    # Collect the components in the pattern skeleton
    my $pattern_chars = $pattern_object->components;
    my $pattern_components = +{ map{ $_->{component} => $_ } @$pattern_tokens };

    # This is used to check if a component found in the pattern is found or not in the skeleton. If it is not, the penalty is not as bad.
    my $skeleton_tokens = $pattern_object->skeleton_tokens;
    my $skeleton_components = +{ map{ $_->{component} => $_ } @$skeleton_tokens };

    # Penalize for extra components not in the requested skeleton
    my $extra_component_penalty = 0;


    # Score for a component that matches perfectly, i.e. the right component and right length
    my $perfect_component_score = 100;
    # Keep track of this hypothetical perfect score separate from the actual score, because we do not want to pollute the latter with the former, since this $perfect_score is just a test whether this available pattern skeleton matches perfectly our requested skeleton or not. If it is, we bump up the review of all available patterns stops.
    my $perfect_score = 0;
    my $missing = [];
    # Determine if this pattern needs adjustment, assuming it will be the one retained in the end.
    # We do this assessment here, because it is easy to check, and it saves us later the trouble of parsing the pattern once more to check for any need for adjustment, by calling the method _adjust_pattern
    my $need_adjustment = 0;

    # We give weight on the existence of a component from the requested skeleton in the available pattern; and
    # on the pertinence (length) of that components, such as MMMM for long (wide)
    # The order is not important, because of variation from locale to locale
    # The best will be retained, and its pattern adjusted to fit the user options; for example 'MMMM' might become 'MMM'
    for( my $i = 0; $i < scalar( @$requested_tokens ); $i++ )
    {
        my $def = $requested_tokens->[$i];
        my $requested_component = $def->{component};
        my $alias;
        # my $alias = ( exists( $pattern_components->{ $requested_component } ) ? $requested_component : [grep( exists( $pattern_components->{ $_ } ), @{$components_alias->{ $requested_component } || []} )]->[0] );
        if( exists( $pattern_components->{ $requested_component } ) )
        {
            $alias = $requested_component;
        }
        # Found the component in our request skeleton, but as an alias, which means that we will need to adjust our pattern
        elsif( my $found_alias = [grep( exists( $pattern_components->{ $_ } ), @{$components_alias->{ $requested_component } || []} )]->[0] )
        {
            $alias = $found_alias;
            $need_adjustment++;
        }
        else
        {
            $alias = $requested_component;
            $need_adjustment++;
        }

        my $exists = ( exists( $pattern_components->{ $alias } ) ? 1 : 0 );
        # Does the current pattern have our requested component, such as 'E' ?
        if( $exists )
        {
            # Our requested component might exist, even though the pattern skeleton is smaller than our requested one.
            # For example: YMMMd (requested skeleton) vs yd (pattern skeleton)
            $score += $components_weight->{ $alias }->{weight};
            my $expected_length = $components_length->{ $alias };

            if( ref( $expected_length ) eq 'ARRAY' )
            {
                if( scalar( grep{ $pattern_components->{ $alias }->{len} == $_ } @$expected_length ) )
                {
                    # Reward for exact numeric match
                    $score += 5;
                    $perfect_score += $perfect_component_score;
                }
                else
                {
                    # Penalize for abbreviation mismatch
                    my $component_penalty = 3 + ( ( $expected_length->[0] > $pattern_components->{ $alias }->{len} ) ? ( $expected_length->[0] - $pattern_components->{ $alias }->{len} ) : ( $pattern_components->{ $alias }->{len} - $expected_length->[0] ) );
                    $score -= $component_penalty;
                    $need_adjustment++;
                }
            }
            else
            {
                # Exact length match (e.g., MMM, EEEE)
                if( $pattern_components->{ $alias }->{len} == $expected_length )
                {
                    # Reward for exact match
                    $score += 5;
                    $perfect_score += $perfect_component_score;
                }
                else
                {
                    # Penalize for mismatched length (e.g., MMM instead of MMMM or MM)
                    my $component_penalty = 3 + ( ( $expected_length > $pattern_components->{ $alias }->{len} ) ? ( $expected_length - $pattern_components->{ $alias }->{len} ) : ( $pattern_components->{ $alias }->{len} - $expected_length ) );
                    $score -= $component_penalty;
                    $need_adjustment++;
                }
            }
        }
        # Requested component is missing, penalising this pattern
        else
        {
            push( @$missing, $alias );
            # my $component_penalty = ( $components_weight->{ $alias }->{weight} || 10 );
            my $component_penalty = 12;
            $score -= $component_penalty;
        }
    }

    # Penalise for extra components in the pattern that were not requested
    foreach my $component ( @$pattern_chars )
    {
        # Possible characters found in skeleton in CLDR data: [qw( B E G H M Q W Z c d h m s v w y )]
        # However, the DateTime::Format::Intl that implements the JavaScript Intl.DateTimeFormat does not support some components.
        # This is an unknown component, maybe W or Q, which is not an option component, i.e. a component derived from DateTimeFormat options
        unless( exists( $components_weight->{ $component } ) )
        {
            # Cancel our perfect score
            $perfect_score = 0;
            $extra_component_penalty += 15;
            next;
        }

        # This component is missing from our requested skeleton, but is also absent from the current pattern skeleton, so this is forgivable.
        if( !exists( $components_length->{ $component } ) &&
            !exists( $skeleton_components->{ $component } ) )
        {
            next;
        }
        # This component is not among our requested component
        elsif( !exists( $components_length->{ $component } ) )
        {
            # "Patterns and skeletons for 24-hour-cycle time formats (using H or k) currently should not include fields with day period components (a, b, or B); these pattern components should be ignored if they appear in skeletons. However, in the future, CLDR may allow use of B (but not a or b) in 24-hour-cycle time formats."
            # <https://www.unicode.org/reports/tr35/tr35-dates.html#availableFormats_appendItems>
            # We increase penalty if the rule aforementioned materialise.
            my $augmented_penalty = 2;
            if( exists( $opts->{hourCycle} ) &&
                # H or k
                ( $opts->{hourCycle} eq 'h23' || $opts->{hourCycle} eq 'h24' ) &&
                ( $component eq 'a' || $component eq 'b' || $component eq 'B' ) )
            {
                $augmented_penalty = 10;
            }
            # "A requested skeleton that includes both seconds and fractional seconds (e.g. “mmssSSS”) is allowed to match a dateFormatItem skeleton that includes seconds but not fractional seconds (e.g. “ms”)."
            # <https://www.unicode.org/reports/tr35/tr35-dates.html#Matching_Skeletons>
            # Although the above rule never happens, as of now (2024-09-29), in the current CLDR data (v35), we implement it anyway.
            elsif( $component eq 'S' &&
                   exists( $opts->{second} ) )
            {
                next;
            }
            $augmented_penalty += ( $components_weight->{ $component }->{penalty} || 15 );
            # Penalise extra components
            $extra_component_penalty += $augmented_penalty;
            # Cancel our perfect score
            $perfect_score = 0;
        }
    }

    # Adjust the final score
    # Penalise for extra components
    $score -= $extra_component_penalty;
    if( $perfect_score == ( scalar( @$requested_tokens ) * $perfect_component_score ) )
    {
        $score += $perfect_score;
    }

    # Adjust score based on specific options (e.g., hour cycle)
    if( exists( $opts->{hourCycle} ) )
    {
        if( $opts->{hourCycle} eq 'h12'
            && index( $pattern_skeleton, 'h' ) != -1 )
        {
            $score += 5;
        }
        elsif( $opts->{hourCycle} eq 'h24' &&
               index( $pattern_skeleton, 'H' ) != -1 )
        {
            $score += 5;
        }
    }
    my $result = $self->_new_score_result(
        missing => $missing,
        need_adjustment => $need_adjustment,
        pattern_object => $pattern_object,
        request_object => $request_object,
        score => $score,
    ) || return( $self->pass_error );
    return( $result );
}

# Select the best pattern from available patterns
sub _select_best_pattern
{
    my $self = shift( @_ );
    my $args = $self->_get_args_as_hash( @_ );
    my $available_patterns = $args->{patterns} ||
        return( $self->error( "No patterns provided." ) );
    my $opts = $args->{options} ||
        return( $self->error( "No options was provided." ) );
    # If we are called by format_range()
    my $diff = $args->{diff};

    # Convert user options to a skeleton (an abstracted form of the requested options)
    my $request_object = $self->_new_request_object(
        options => $opts,
        ( defined( $diff ) ? ( diff => $diff ) : () ),
    ) || return( $self->pass_error );
    my $requested_skeleton = $request_object->pattern_skeleton;
    my @sorted_available_skeletons = sort{ length( $a ) <=> length( $b ) } sort( keys( %$available_patterns ) );
    my $requested_skeleton_len = length( $requested_skeleton );
    for( my $i = 0; $i < scalar( @sorted_available_skeletons ); $i++ )
    {
        # If the next skeleton is equal of greater in length as our requested skeleton, we
        # take all the ones before it and place it at the end of the stack, so we deal with them last,
        # and thus avoid wasting processing power on pattern that have little chance of being satisfactory.
        if( $i <= $#sorted_available_skeletons && 
            length( $sorted_available_skeletons[$i] ) >= $requested_skeleton_len )
        {
            # push( @sorted_available_skeletons, splice( @sorted_available_skeletons, 0, $i ) );
            push( @sorted_available_skeletons, splice( @sorted_available_skeletons, 0, ( $i - 1 ) ) ) if( $i > 0 );
            last;
        }
    }


    my( $components_len, $components_weight, $components_alias ) = $self->_get_option_dictionary(
        options => $opts,
        ( defined( $diff ) ? ( diff => $diff ) : () ),
    );
    return( $self->pass_error ) if( !defined( $components_len ) );
    $self->{_components_length} = $components_len;
    $self->{_components_weight} = $components_weight;
    $self->{_components_alias}  = $components_alias;

    my $best_pattern;
    # Same as in _score_pattern(); maybe should make it a module constant ? Maybe overkill ?
    my $perfect_component_score = 100;
    my $best_score = -1;
    # Merely for tracking and reporting
    my( $best_skeleton, $best_score_object );
    foreach my $skeleton ( @sorted_available_skeletons )
    {
        my $pattern = $available_patterns->{ $skeleton };
        # Handle literal text inside single quotes
        my $raw_pattern = $self->_remove_literal_text( $pattern ) ||
            return( $self->pass_error );

        # Generate a skeleton from the available pattern
        my $pattern_skeleton = $self->_pattern_to_skeleton( $raw_pattern ) ||
            return( $self->pass_error );
        my $pattern_object = $self->_new_skeleton_object(
            # Original skeleton provided by CLDR
            skeleton => $skeleton,
            # Skeleton derived from the format pattern
            pattern_skeleton => $pattern_skeleton,
            # Actual pattern for this format ID
            pattern => $pattern,
            debug => $DEBUG,
        ) || return( $self->pass_error );


        # Score how well the pattern matches the user's options
        my $score_object = $self->_score_pattern(
            request_object => $request_object,
            pattern_object => $pattern_object,
            options => $opts,
        ) || return( $self->pass_error );
        my $score = $score_object->score;
        
        
        # If the score is higher, update the best pattern
        if( $score > $best_score )
        {
            $best_pattern = $pattern;
            $best_score = $score;
            $best_skeleton = $skeleton;
            $best_score_object = $score_object;
        }


        # If the pattern score is equal or higher than the perfect component score, we got a perfect match and we stop checking.
        if( $score > $perfect_component_score )
        {
            # Actually, we keep going, because we could find another perfect match
            # last;
        }
    }

    # No perfect match, and this is a singleton, most likely something that has no equivalent among the available patterns.
    # If so, the requested skeleton in itself is our perfect match
    my $request_tokens = $request_object->tokens || die( "No request tokens array reference set!" );
    if( $best_score < $perfect_component_score &&
        scalar( @$request_tokens ) == 1 &&
        !exists( $available_patterns->{ $request_tokens->[0]->{token} } ) &&
        !exists( $available_patterns->{ $request_tokens->[0]->{component} } ) )
    {
        $best_score += $perfect_component_score;
        $best_skeleton = $best_pattern = ( $request_tokens->[0]->{component} x ( ref( $components_len->{ $request_tokens->[0]->{component} } ) eq 'ARRAY' ? $components_len->{ $request_tokens->[0]->{component} }->[0] : $components_len->{ $request_tokens->[0]->{component} } ) );
        $request_object->pattern( $best_pattern );
        $request_object->skeleton( $best_skeleton );
        $best_score_object = $self->_new_score_result(
            pattern_object => $request_object,
            request_object => $request_object,
            score => $best_score,
        ) || return( $self->pass_error );
        return( $best_score_object );
    }
    # Quoting from the LDML specifications:
    # "If a client-requested set of fields includes both date and time fields, and if the availableFormats data does not include a dateFormatItem whose skeleton matches the same set of fields, then the request should be handled as follows:
    #     1. Divide the request into a date fields part and a time fields part.
    #     2. For each part, find the matching dateFormatItem, and expand the pattern as above.
    #     3. Combine the patterns for the two dateFormatItems using the appropriate dateTimeFormat pattern, determined as follows from the requested date fields:
    #         * If the requested date fields include wide month (MMMM, LLLL) and weekday name of any length (e.g. E, EEEE, c, cccc), use <dateTimeFormatLength type="full">
    #         * Otherwise, if the requested date fields include wide month, use <dateTimeFormatLength type="long">
    #         * Otherwise, if the requested date fields include abbreviated month (MMM, LLL), use <dateTimeFormatLength type="medium">
    #         * Otherwise use <dateTimeFormatLength type="short">"
    # <https://www.unicode.org/reports/tr35/tr35-dates.html#Missing_Skeleton_Fields>
    elsif( (
               ( $best_score >= 0 && scalar( @{$best_score_object->missing // []} ) ) ||
               $best_score < 0
           ) &&
           scalar( @{$request_object->date_components // []} ) &&
           scalar( @{$request_object->time_components // []} ) &&
           !$diff &&
           !$args->{subprocess} )
    {
        my @core_options = qw( calendar hour12 hourCycle locale numberingSystem timeZone );
        my @date_options = ( qw( era year month weekday day ), @core_options );
        my @time_options = ( qw( hour minute second timeZoneName  ), @core_options );
        # "1. Divide the request into a date fields part and a time fields part."
        my $date_opts = +{ map{ $_ => $opts->{ $_ } } grep( exists( $opts->{ $_ } ), @date_options ) };
        my $time_opts = +{ map{ $_ => $opts->{ $_ } } grep( exists( $opts->{ $_ } ), @time_options ) };
        # "2. For each part, find the matching dateFormatItem, and expand the pattern as above."
        my $date_score_object = $self->_select_best_pattern(
            options => $date_opts,
            patterns => $available_patterns,
            # To avoid risk of recurring calls, we tag it
            subprocess => 1,
        );
        my $date_pat = $date_score_object->pattern_object->pattern;
        my $date_skel = $date_score_object->pattern_object->skeleton;
        my $has_missing_date_components = scalar( @{$date_score_object->missing // []} );
# 
#         # If the result has some missing components, we need to add them
#         if( $has_missing_date_components )
#         {
#             $date_pat = $self->_append_components(
#                 pattern => $date_pat,
#                 missing => $date_score_object->missing,
#             );
#         }

        my $time_score_object = $self->_select_best_pattern(
            options => $time_opts,
            patterns => $available_patterns,
            # To avoid risk of recurring calls, we tag it
            subprocess => 1,
        );
        my $time_pat = $time_score_object->pattern_object->pattern;
        my $time_skel = $time_score_object->pattern_object->skeleton;
        my $has_missing_time_components = scalar( @{$time_score_object->missing // []} );
        #     3. Combine the patterns for the two dateFormatItems using the appropriate dateTimeFormat pattern, determined as follows from the requested date fields:
        #         * If the requested date fields include wide month (MMMM, LLLL) and weekday name of any length (e.g. E, EEEE, c, cccc), use <dateTimeFormatLength type="full">
        #         * Otherwise, if the requested date fields include wide month, use <dateTimeFormatLength type="long">
        #         * Otherwise, if the requested date fields include abbreviated month (MMM, LLL), use <dateTimeFormatLength type="medium">
        #         * Otherwise use <dateTimeFormatLength type="short">"
        my $datetime_format_width;
        if( exists( $components_len->{'M'} ) &&
            # wide
            $components_len->{'M'} == 4 && 
            # any length, so we do not have to check the length
            exists( $components_len->{'E'} ) )
        {
            $datetime_format_width = 'full';
        }
        elsif( exists( $components_len->{'M'} ) &&
               # wide
               $components_len->{'M'} == 4 )
        {
            $datetime_format_width = 'long';
        }
        elsif( exists( $components_len->{'M'} ) &&
               # abbreviated
               $components_len->{'M'} == 3 )
        {
            $datetime_format_width = 'medium';
        }
        else
        {
            $datetime_format_width = 'short';
        }
        my $datetime_format = $self->_get_datetime_format(
            width => $datetime_format_width,
        );
        return( $self->pass_error ) if( !defined( $datetime_format ) );
        my $datetime_skel   = $datetime_format;
        $datetime_format =~ s/\{1\}/$date_pat/;
        $datetime_format =~ s/\{0\}/$time_pat/;
        $datetime_skel =~ s/\{1\}/$date_skel/;
        $datetime_skel =~ s/\{0\}/$time_skel/;
        my $raw_pattern = $self->_remove_literal_text( $datetime_format ) ||
            return( $self->pass_error );
        my $pattern_object = $self->_new_skeleton_object(
            pattern => $datetime_format,
            skeleton => $datetime_skel,
            pattern_skeleton => $self->_pattern_to_skeleton( $raw_pattern ),
            debug => $DEBUG,
        ) || return( $self->pass_error );
        $best_score_object = $self->_new_score_result(
            score => ( defined( $best_score_object ) ? $best_score_object->score : _max( $date_score_object->score, $time_score_object->score ) ),
            pattern_object => $pattern_object,
            request_object => $request_object,
            need_adjustment => ( ( $date_score_object->need_adjustment || $time_score_object->need_adjustment ) ? 1 : 0 ),
        ) || return( $self->pass_error );
        return( $best_score_object );
    }
    
    my $has_missing_components = $best_score_object->has_missing;
    # If the result has some missing components, we need to add them
    if( $has_missing_components )
    {
        my $pattern = $self->_append_components(
            # pattern => $pattern,
            pattern => $best_score_object->pattern_object->pattern,
            missing => $best_score_object->missing,
        );
        $best_score_object->pattern_object->pattern( $pattern );
        return( $self->pass_error ) if( !defined( $pattern ) );
    }

    # "Once a best match is found between requested skeleton and dateFormatItem id, the corresponding dateFormatItem pattern is used, but with adjustments primarily to make the pattern field lengths match the skeleton field lengths."
    # <https://www.unicode.org/reports/tr35/tr35-dates.html#Matching_Skeletons>
    # No need to bother calling this method, if there is no need for adjustment
    # We do not append components on a datetime range, so we check if this is one with the $diff variable
    if( !$diff && $best_score_object->need_adjustment )
    {
        my $pattern = $self->_adjust_pattern(
            # pattern => $pattern,
            pattern => $best_score_object->pattern_object->pattern,
            options => $opts,
            request_object => $best_score_object->request_object,
            pattern_object => $best_score_object->pattern_object,
        ) || return( $self->pass_error );
        $best_score_object->pattern_object->pattern( $pattern );
    }

    return( $self->error( "No suitable date pattern found for given options" ) ) unless( $best_pattern );
    return( $best_score_object );
}

sub _set_cached_pattern
{
    my $self = shift( @_ );
    my( $locale, $key, $pattern ) = @_;
    $CACHE->{ $locale } = {} if( !exists( $CACHE->{ $locale } ) );
    $CACHE->{ $locale }->{ $key } = $pattern;
}

sub _set_get_prop
{
    my $self = shift( @_ );
    my $prop = shift( @_ ) || die( "No object property was provided." );
    $self->{ $prop } = shift( @_ ) if( @_ );
    return( $self->{ $prop } );
}

# NOTE: $BROWSER_DEFAULTS
{
    $BROWSER_DEFAULTS =
    {
        af => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "af-NA" => {
            day => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        agq => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        ak => { minute => "2-digit", second => "2-digit" },
        am => { minute => "2-digit", second => "2-digit" },
        ar => { minute => "2-digit", second => "2-digit" },
        "ar-IL" => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        "ar-KM" => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        "ar-MA" => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        as => {
            day => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        asa => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        ast => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        az => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "az-Cyrl" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        bas => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        be => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        bem => { minute => "2-digit", second => "2-digit" },
        bez => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        bg => {
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        bgc => { minute => "2-digit", second => "2-digit" },
        bho => {
            day => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        bm => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        bn => { minute => "2-digit", second => "2-digit" },
        bo => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        "bo-IN" => { minute => "2-digit", second => "2-digit" },
        br => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        brx => {
            day => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        bs => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        "bs-Cyrl" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        ca => { minute => "2-digit", second => "2-digit" },
        ccp => { minute => "2-digit", second => "2-digit" },
        ceb => { minute => "2-digit", second => "2-digit" },
        cgg => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        chr => { minute => "2-digit", second => "2-digit" },
        ckb => { minute => "2-digit", second => "2-digit" },
        "ckb-IR" => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        cs => { minute => "2-digit", second => "2-digit" },
        cv => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        cy => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        da => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        dav => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        de => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        dje => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        doi => { minute => "2-digit", second => "2-digit" },
        dsb => { minute => "2-digit", second => "2-digit" },
        dua => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        dyo => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        dz => { minute => "2-digit", second => "2-digit" },
        ebu => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        ee => { minute => "2-digit", second => "2-digit" },
        "ee-TG" => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        el => { minute => "2-digit", second => "2-digit" },
        en => { minute => "2-digit", second => "2-digit" },
        "en-001" => {
            day => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "en-150" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "en-AE" => {
            day => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "en-AI" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "en-AU" => {
            day => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "en-BE" => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        "en-BI" => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        "en-BW" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "en-BZ" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "en-CA" => {
            day => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "en-CC" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "en-CH" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "en-CK" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "en-CM" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "en-CX" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "en-DG" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "en-DK" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "en-FI" => {
            day => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "en-FK" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "en-GB" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "en-GG" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "en-GI" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "en-HK" => { minute => "2-digit", second => "2-digit" },
        "en-IE" => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        "en-IL" => {
            day => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "en-IM" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "en-IN" => { minute => "2-digit", second => "2-digit" },
        "en-IO" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "en-JE" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "en-JM" => {
            day => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "en-KE" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "en-MG" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "en-MS" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "en-MT" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "en-MU" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "en-MV" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "en-NF" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "en-NG" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "en-NR" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "en-NU" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "en-NZ" => { minute => "2-digit", month => "2-digit", second => "2-digit" },
        "en-PK" => {
            day => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "en-PN" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "en-RW" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "en-SC" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "en-SE" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "en-SG" => {
            day => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "en-SH" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "en-SX" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "en-TK" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "en-TV" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "en-TZ" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "en-UG" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "en-ZA" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "en-ZW" => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        eo => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        es => { minute => "2-digit", second => "2-digit" },
        "es-419" => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        "es-BO" => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        "es-BR" => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        "es-BZ" => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        "es-CL" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "es-CO" => { minute => "2-digit", second => "2-digit" },
        "es-DO" => { minute => "2-digit", second => "2-digit" },
        "es-GT" => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        "es-HN" => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        "es-MX" => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        "es-PA" => {
            day => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "es-PE" => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        "es-PH" => { minute => "2-digit", second => "2-digit" },
        "es-PR" => {
            day => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "es-US" => { minute => "2-digit", second => "2-digit" },
        et => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        eu => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        ewo => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        fa => { minute => "2-digit", second => "2-digit" },
        ff => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        "ff-Adlm" => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        "ff-Adlm-GH" => { minute => "2-digit", second => "2-digit" },
        "ff-Adlm-GM" => { minute => "2-digit", second => "2-digit" },
        "ff-Adlm-LR" => { minute => "2-digit", second => "2-digit" },
        "ff-Adlm-MR" => { minute => "2-digit", second => "2-digit" },
        "ff-Adlm-SL" => { minute => "2-digit", second => "2-digit" },
        "ff-Latn-GH" => { minute => "2-digit", second => "2-digit" },
        "ff-Latn-GM" => { minute => "2-digit", second => "2-digit" },
        "ff-Latn-LR" => { minute => "2-digit", second => "2-digit" },
        "ff-Latn-MR" => { minute => "2-digit", second => "2-digit" },
        "ff-Latn-SL" => { minute => "2-digit", second => "2-digit" },
        fi => { minute => "2-digit", second => "2-digit" },
        fil => { minute => "2-digit", second => "2-digit" },
        fo => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        fr => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "fr-BE" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "fr-CA" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "fr-CH" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "fr-DJ" => {
            day => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "fr-DZ" => {
            day => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "fr-MR" => {
            day => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "fr-SY" => {
            day => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "fr-TD" => {
            day => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "fr-TN" => {
            day => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "fr-VU" => {
            day => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        fur => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        fy => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        ga => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        gd => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        gl => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        gsw => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        gu => { minute => "2-digit", second => "2-digit" },
        guz => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        gv => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        ha => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "ha-GH" => {
            day => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        haw => { minute => "2-digit", second => "2-digit" },
        he => { minute => "2-digit", second => "2-digit" },
        hi => { minute => "2-digit", second => "2-digit" },
        "hi-Latn" => { minute => "2-digit", second => "2-digit" },
        hr => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "hr-BA" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        hsb => { minute => "2-digit", second => "2-digit" },
        hu => {
            day => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        hy => {
            day => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        ia => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        id => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        ig => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        ii => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        is => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        it => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        "it-CH" => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        ja => { minute => "2-digit", second => "2-digit" },
        jgo => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        jmc => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        jv => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        ka => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        kab => { minute => "2-digit", second => "2-digit" },
        kam => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        kde => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        kea => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        kgp => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        khq => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        ki => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        kk => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        kkj => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        kl => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        kln => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        km => { minute => "2-digit", second => "2-digit" },
        kn => { minute => "2-digit", second => "2-digit" },
        ko => { minute => "2-digit", second => "2-digit" },
        kok => { minute => "2-digit", second => "2-digit" },
        ks => { minute => "2-digit", second => "2-digit" },
        "ks-Deva" => { minute => "2-digit", second => "2-digit" },
        ksb => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        ksf => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        ksh => {
            day => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        ku => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        kw => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        ky => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        lag => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        lb => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        lg => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        lkt => { minute => "2-digit", second => "2-digit" },
        ln => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        lo => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        "lrc-IQ" => { minute => "2-digit", second => "2-digit" },
        lt => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        lu => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        luo => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        luy => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        lv => {
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        mai => { minute => "2-digit", second => "2-digit" },
        mas => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        mer => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        mfe => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        mg => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        mgh => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        mgo => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        mi => {
            day => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        mk => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        ml => { minute => "2-digit", second => "2-digit" },
        mn => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        mni => { minute => "2-digit", second => "2-digit" },
        mr => { minute => "2-digit", second => "2-digit" },
        ms => { minute => "2-digit", second => "2-digit" },
        "ms-BN" => { minute => "2-digit", second => "2-digit" },
        "ms-ID" => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        mt => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        mua => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        my => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        naq => { minute => "2-digit", second => "2-digit" },
        nd => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        ne => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "ne-IN" => {
            day => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        nl => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        "nl-BE" => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        nmg => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        nn => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        nnh => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        no => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        nus => { minute => "2-digit", second => "2-digit" },
        nyn => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        om => {
            day => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "om-KE" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        or => { minute => "2-digit", second => "2-digit" },
        os => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        pa => { minute => "2-digit", second => "2-digit" },
        "pa-Arab" => { minute => "2-digit", second => "2-digit" },
        pcm => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        pl => {
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        ps => {
            day => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "ps-PK" => {
            day => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        pt => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "pt-MO" => {
            day => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "pt-PT" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        qu => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        raj => { minute => "2-digit", second => "2-digit" },
        rm => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        rn => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        ro => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        rof => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        ru => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        rw => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        rwk => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        sa => { minute => "2-digit", second => "2-digit" },
        sah => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        saq => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        sat => { minute => "2-digit", second => "2-digit" },
        sbp => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        sc => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        sd => {
            day => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "sd-Deva" => { minute => "2-digit", second => "2-digit" },
        "se-FI" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        seh => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        ses => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        sg => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        shi => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        "shi-Latn" => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        si => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        sk => { minute => "2-digit", second => "2-digit" },
        sl => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        smn => { minute => "2-digit", second => "2-digit" },
        sn => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        so => { minute => "2-digit", second => "2-digit" },
        "so-KE" => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        sq => { minute => "2-digit", second => "2-digit" },
        "sq-MK" => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        "sq-XK" => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        sr => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        "sr-Latn" => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        su => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        sv => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        sw => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        "sw-KE" => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        ta => { minute => "2-digit", second => "2-digit" },
        "ta-LK" => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        te => { minute => "2-digit", second => "2-digit" },
        teo => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        tg => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        th => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        ti => { minute => "2-digit", second => "2-digit" },
        "ti-ER" => { minute => "2-digit", second => "2-digit" },
        tk => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        to => { minute => "2-digit", second => "2-digit" },
        "tr" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "tr-CY" => {
            day => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        tt => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        twq => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        tzm => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        ug => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        uk => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        ur => { minute => "2-digit", second => "2-digit" },
        uz => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "uz-Arab" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "uz-Cyrl" => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        vai => { minute => "2-digit", second => "2-digit" },
        "vai-Latn" => { minute => "2-digit", second => "2-digit" },
        vi => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        vun => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        wae => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        wo => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        xh => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        xog => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        yav => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        yi => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        yo => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        yrl => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "yrl-CO" => {
            day => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        "yrl-VE" => {
            day => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        yue => { minute => "2-digit", second => "2-digit" },
        "yue-Hans" => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        zgh => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
        zh => { hour => "2-digit", minute => "2-digit", second => "2-digit" },
        "zh-Hans-HK" => { minute => "2-digit", second => "2-digit" },
        "zh-Hans-MO" => { minute => "2-digit", second => "2-digit" },
        "zh-Hans-SG" => { minute => "2-digit", second => "2-digit" },
        "zh-Hant" => { minute => "2-digit", second => "2-digit" },
        "zh-Hant-HK" => { minute => "2-digit", second => "2-digit" },
        zu => {
            day => "2-digit",
            hour => "2-digit",
            minute => "2-digit",
            month => "2-digit",
            second => "2-digit",
        },
    };
}

# NOTE: DateTime::Format::Intl::Exception class
package DateTime::Format::Intl::Exception;
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
        elsif( ref( $_[0] ) && $_[0]->isa( 'DateTime::Format::Intl::Exception' ) )
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
    # NOTE: DateTime::Format::Intl::NullObject class
    package
        DateTime::Format::Intl::NullObject;
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

# NOTE: DateTime::Format::Intl::ScoreResult
# This is a private class whose purpose is to contain detailed information about the evaluation of a pattern during scoring, and in particular which fields were missing.
# The information about missing fields is key to whether we need to patch the date and time as specified by the LDML specifications at <https://www.unicode.org/reports/tr35/tr35-dates.html#Missing_Skeleton_Fields>
{
    package
        DateTime::Format::Intl::ScoreResult;
    use strict;
    use warnings;
    use vars qw( $DEBUG $ERROR );
    use Want;

    sub new
    {
        my $this = shift( @_ );
        my $self = bless( {} => ( ref( $this ) || $this ) );
        # Whether there are any missing component that will need to ne appended
        $self->{has_missing} = 0;
        # The components that will need to be appended
        $self->{missing} = [];
        # Whether the pattern has components, but not at the right precision, and thus who will need to be adjusted
        # By default this value is set to undef, so we can differentiate if it has been set or not: 0 or 1
        $self->{need_adjustment} = undef;
        $self->{pattern_object} = undef;
        $self->{request_object} = undef;
        $self->{score} = 0;

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
    
        for( my $i = 0; $i < scalar( @args ); $i += 2 )
        {
            if( $args[$i] eq 'fatal' )
            {
                $self->{fatal} = $args[$i + 1];
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
        $self->{has_missing} = scalar( @{$self->{missing}} );
        return( $self );
    }

    sub error
    {
        my $self = shift( @_ );
        if( @_ )
        {
            my $msg = join( '', map( ( ref( $_ ) eq 'CODE' ) ? $_->() : $_, @_ ) );
            $self->{error} = $ERROR = DateTime::Format::Intl::Exception->new({
                skip_frames => 1,
                message => $msg,
            });
            if( $self->fatal )
            {
                die( $self->{error} );
            }
            else
            {
                warn( $msg ) if( warnings::enabled( 'DateTime::Format::Intl' ) );
                if( Want::want( 'ARRAY' ) )
                {
                    rreturn( [] );
                }
                elsif( Want::want( 'OBJECT' ) )
                {
                    rreturn( DateTime::Format::Intl::NullObject->new );
                }
                return;
            }
        }
        return( ref( $self ) ? $self->{error} : $ERROR );
    }
    
    sub fatal { return( shift->_set_get_prop( 'fatal', @_ ) ); }

    sub has_missing { return( shift->{has_missing} ); }

    sub missing { return( shift->_set_get_prop( 'missing', @_ ) ); }

    sub need_adjustment { return( shift->_set_get_prop( 'need_adjustment', @_ ) ); }

    sub pass_error
    {
        my $self = shift( @_ );
        if( Want::want( 'OBJECT' ) )
        {
            rreturn( DateTime::Format::Intl::NullObject->new );
        }
        return;
    }

    sub pattern_object { return( shift->_set_get_prop( 'pattern_object', @_ ) ); }

    sub request_object { return( shift->_set_get_prop( 'request_object', @_ ) ); }

    sub score { return( shift->_set_get_prop( 'score', @_ ) ); }

    sub _set_get_prop
    {
        my $self = shift( @_ );
        my $prop = shift( @_ ) || die( "No object property was provided." );
        $self->{ $prop } = shift( @_ ) if( @_ );
        return( $self->{ $prop } );
    }
}

# NOTE: DateTime::Format::Intl::Skeleton class
# This object is used to represent a user requested skeleton, or an CLDR available skeleton
# For the requested skeleton, there is obviously no pattern
# For the available format there is a subtlety, whereby we have a tokens containing an array of elements representing the pattern, and we also have a skeleton_tokens representing an tokens for the actual skeleton
{
    # Hide it from CPAN so it does not get registered
    package
        DateTime::Format::Intl::Skeleton;
    use strict;
    use warnings;
    use vars qw( $DEBUG $ERROR );

    sub new
    {
        my $this = shift( @_ );
        my $self = bless( {} => ( ref( $this ) || $this ) );
        $self->{components} = [];
        $self->{date_components} = [];
        $self->{is_interval} = 0;
        $self->{patched_pattern} = undef;
        $self->{patched_skeleton} = undef;
        $self->{pattern} = undef;
        $self->{pattern_skeleton} = undef;
        $self->{skeleton} = undef;
        $self->{skeleton_components} = [];
        $self->{skeleton_date_components} = [];
        $self->{skeleton_time_components} = [];
        $self->{skeleton_tokens} = [];
        $self->{time_components} = [];
        $self->{tokens} = [];
        $self->{debug} = $DateTime::Format::Intl::DEBUG;

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

        PREPROCESS:
        for( my $i = 0; $i < scalar( @args ); $i += 2 )
        {
            if( $args[$i] eq 'fatal' )
            {
                $self->{fatal} = $args[$i + 1];
                splice( @args, $i, 2 );
                goto PREPROCESS;
            }
            elsif( $args[$i] eq 'debug' )
            {
                $self->{debug} = $args[$i + 1];
                splice( @args, $i, 2 );
                goto PREPROCESS;
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
                return( $self->error( "Unknown method \"${name}\" provided." ) );
            }
            elsif( !defined( $meth->( $self, $val ) ) )
            {
                if( defined( $val ) && $self->error )
                {
                    return( $self->pass_error );
                }
            }
        }

        # TODO: We always use the option 'pattern_skeleton', so we should consider simplifying this
        my $pattern_skeleton = $self->{pattern_skeleton} || $self->{skeleton};
        if( scalar( @{$self->{tokens} // []} ) &&
            scalar( @{$self->{components} // []} ) &&
            scalar( @{$self->{date_components} // []} ) &&
            scalar( @{$self->{time_components} // []} ) )
        {
        }
        else
        {
            my( $tokens, $components, $date_components, $time_components ) = $self->_split_skeleton( $pattern_skeleton );
            $self->{tokens} = $tokens;
            # Collect the components in the requested skeleton
            $self->{components} = $components;
            $self->{date_components} = $date_components;
            $self->{time_components} = $time_components;
        }

        if( scalar( @{$self->{skeleton_tokens} // []} ) &&
            scalar( @{$self->{skeleton_components} // []} ) &&
            scalar( @{$self->{skeleton_date_components} // []} ) &&
            scalar( @{$self->{skeleton_time_components} // []} ) )
        {
        }
        # For datetime format skeletons
        elsif( $self->{skeleton} )
        {
            my( $skel_tokens, $skel_components, $skel_date_components, $skel_time_components ) = $self->_split_skeleton( $self->{skeleton} );
            $self->{skeleton_components} = $skel_components;
            $self->{skeleton_date_components} = $skel_date_components;
            $self->{skeleton_time_components} = $skel_time_components;
            $self->{skeleton_tokens} = $skel_tokens;
        }
        return( $self );
    }

    # Array reference of single characters, i.e. component or symbol
    sub components { return( shift->_set_get_prop( 'components', @_ ) ); }

    sub date_components { return( shift->_set_get_prop( 'date_components', @_ ) ); }

    sub error
    {
        my $self = shift( @_ );
        if( @_ )
        {
            my $msg = join( '', map( ( ref( $_ ) eq 'CODE' ) ? $_->() : $_, @_ ) );
            $self->{error} = $ERROR = DateTime::Format::Intl::Exception->new({
                skip_frames => 1,
                message => $msg,
            });
            if( $self->fatal )
            {
                die( $self->{error} );
            }
            else
            {
                warn( $msg ) if( warnings::enabled( 'DateTime::Format::Intl' ) );
                if( Want::want( 'ARRAY' ) )
                {
                    rreturn( [] );
                }
                elsif( Want::want( 'OBJECT' ) )
                {
                    rreturn( DateTime::Format::Intl::NullObject->new );
                }
                return;
            }
        }
        return( ref( $self ) ? $self->{error} : $ERROR );
    }
    
    sub fatal { return( shift->_set_get_prop( 'fatal', @_ ) ); }

    sub is_interval { return( shift->_set_get_prop( 'is_interval', @_ ) ); }

    sub pass_error
    {
        my $self = shift( @_ );
        if( Want::want( 'OBJECT' ) )
        {
            rreturn( DateTime::Format::Intl::NullObject->new );
        }
        return;
    }

    # If the resulting best pattern has missing components, as per the LDML, it is patched
    # If it has been patched, this returns the patched pattern; undef by default
    sub patched_pattern { return( shift->_set_get_prop( 'patched_pattern', @_ ) ); }

    # Same as patched_pattern, but for skeleton
    sub patched_skeleton { return( shift->_set_get_prop( 'patched_skeleton', @_ ) ); }

    # The actual pattern
    sub pattern { return( shift->_set_get_prop( 'pattern', @_ ) ); }

    # This is the skeleton derived from the pattern, so it does not necessarily match the actual skeleton
    sub pattern_skeleton { return( shift->_set_get_prop( 'pattern_skeleton', @_ ) ); }

    # Real skeleton from Unicode CLDR
    # It may be empty if this object is used for representing the user requested options
    sub skeleton { return( shift->_set_get_prop( 'skeleton', @_ ) ); }

    # For datetime format skeletons: array reference of single characters, i.e. component or symbol
    sub skeleton_components { return( shift->_set_get_prop( 'skeleton_components', @_ ) ); }

    sub skeleton_date_components { return( shift->_set_get_prop( 'skeleton_date_components', @_ ) ); }

    sub skeleton_time_components { return( shift->_set_get_prop( 'skeleton_time_components', @_ ) ); }

    # For datetime format skeletons: the array reference of tokens for the skeleton (not the pattern skeleton), i.e. each array entry is an hash with the properties 'component', 'len' and 'token'
    sub skeleton_tokens { return( shift->_set_get_prop( 'skeleton_tokens', @_ ) ); }

    sub time_components { return( shift->_set_get_prop( 'time_components', @_ ) ); }

    # The array reference of tokens, i.e. each array entry is an hash with the properties 'component', 'len' and 'token'
    sub tokens { return( shift->_set_get_prop( 'tokens', @_ ) ); }

    sub _set_get_prop
    {
        my $self = shift( @_ );
        my $prop = shift( @_ ) || die( "No object property was provided." );
        $self->{ $prop } = shift( @_ ) if( @_ );
        return( $self->{ $prop } );
    }

    sub _split_skeleton
    {
        my $self = shift( @_ );
        my $skel = shift( @_ );
        $skel =~ s/[^a-zA-Z]+//g;
        my $tokens = [];
        my $components = [];
        my $date_elements =
        {
            'c' => 1,
            'd' => 1,
            'D' => 1,
            'e' => 1,
            'E' => 1,
            'F' => 1,
            'g' => 1,
            'G' => 1,
            'L' => 1,
            'M' => 1,
            'q' => 1,
            'Q' => 1,
            'r' => 1,
            'u' => 1,
            'U' => 1,
            'w' => 1,
            'W' => 1,
            'y' => 1,
            'Y' => 1,
        };
        my $time_elements =
        {
            'h' => 1,
            'H' => 1,
            'j' => 1,
            'k' => 1,
            'K' => 1,
            'm' => 1,
            'O' => 1,
            's' => 1,
            'S' => 1,
            'v' => 1,
            'V' => 1,
            'x' => 1,
            'X' => 1,
            'z' => 1,
            'Z' => 1,
        };
        my $date_components = [];
        my $time_components = [];
        foreach my $component ( split( //, $skel ) )
        {
            if( scalar( @$tokens ) &&
                $tokens->[-1]->{component} eq $component )
            {
                $tokens->[-1]->{token} .= $component;
            }
            else
            {
                if( exists( $time_elements->{ $component } ) )
                {
                    push( @$time_components, $component );
                }
                elsif( exists( $date_elements->{ $component } ) )
                {
                    push( @$date_components, $component );
                }
                push( @$components, $component );
                $tokens->[-1]->{len} = length( $tokens->[-1]->{token} ) if( scalar( @$tokens ) );
                push( @$tokens, { component => $component, token => $component });
            }
        }
        $tokens->[-1]->{len} = length( $tokens->[-1]->{token} ) if( scalar( @$tokens ) );
        return( $tokens, $components, $date_components, $time_components );
    }
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

DateTime::Format::Intl - A Web Intl.DateTimeFormat Class Implementation

=head1 SYNOPSIS

    use DateTime;
    use DateTime::Format::Intl;
    my $dt = DateTime->now;
    my $fmt = DateTime::Format::Intl->new(
        # You can use ja-JP (Unicode / web-style) or ja_JP (system-style), it does not matter.
        'ja_JP', {
            localeMatcher => 'best fit',
            # The only one supported. You can use 'gregory' or 'gregorian' indifferently
            calendar => 'gregorian',
            # see getNumberingSystems() in Locale::Intl for the supported number systems
            numberingSystem => 'latn',
            formatMatcher => 'best fit',
            dateStyle => 'long',
            timeStyle => 'long',
        },
    ) || die( DateTime::Format::Intl->error );
    say $fmt->format( $dt );

    my $fmt = DateTime::Format::Intl->new(
        # You can also use ja-JP (Unicode / web-style) or ja_JP (system-style), it does not matter.
        'ja_JP', {
            localeMatcher => 'best fit',
            # The only one supported
            calendar => 'gregorian',
            numberingSystem => 'latn',
            hour12 => 0,
            timeZone => 'Asia/Tokyo',
            weekday => 'long',
            era => 'short',
            year => 'numeric',
            month => '2-digit',
            day => '2-digit',
            dayPeriod => 'long',
            hour => '2-digit',
            minute => '2-digit',
            second => '2-digit',
            fractionalSecondDigits => 3,
            timeZoneName => 'long',
            formatMatcher => 'best fit',
        },
    ) || die( DateTime::Format::Intl->error );
    say $fmt->format( $dt );

In basic use without specifying a locale, C<DateTime::Format::Intl> uses the default locale and default options:

    use DateTime;
    my $date = DateTime->new(
        year    => 2012,
        month   => 11,
        day     => 20,
        hour    => 3,
        minute  => 0,
        second  => 0,
        # Default
        time_zone => 'UTC',
    );
    # toLocaleString without arguments depends on the implementation,
    # the default locale, and the default time zone
    say DateTime::Format::Intl->new->format( $date );
    # "12/19/2012" if run with en-US locale (language) and time zone America/Los_Angeles (UTC-0800)

Using C<timeStyle> and C<dateStyle>:

Possible values are: C<full>, C<long>, C<medium> and C<short>

    my $now = DateTime->new(
        year => 2024,
        month => 9,
        day => 13,
        hour => 14,
        minute => 12,
        second => 10,
        time_zone => 'Europe/Paris',
    );
    my $shortTime = DateTime::Format::Intl->new('en', {
        timeStyle => 'short',
    });
    say $shortTime->format( $now ); # "2:12 PM"
    
    my $shortDate = DateTime::Format::Intl->new('en', {
        dateStyle => 'short',
    });
    say $shortDate->format( $now ); # "09/13/24"
    
    my $mediumTime = DateTime::Format::Intl->new('en', {
        timeStyle => 'medium',
        dateStyle => 'short',
    });
    say $mediumTime->format( $now ); # "09/13/24, 2:12:10 PM"

    my $shortDate = DateTime::Format::Intl->new('en', {
        dateStyle => 'medium',
    });
    say $shortDate->format( $now ); # "13 Sep 2024"

    my $shortDate = DateTime::Format::Intl->new('en', {
        dateStyle => 'long',
    });
    say $shortDate->format( $now ); # "September 13, 2024"

    my $shortDate = DateTime::Format::Intl->new('en', {
        dateStyle => 'long',
        timeStyle => 'long',
    });
    say $shortDate->format( $now ); # "September 13, 2024 at 2:12:10 PM GMT+1"

    my $shortDate = DateTime::Format::Intl->new('en', {
        dateStyle => 'full',
    });
    say $shortDate->format( $now ); # "Friday, September 13, 2024"

    my $shortDate = DateTime::Format::Intl->new('en', {
        dateStyle => 'full',
        timeStyle => 'full',
    });
    say $shortDate->format( $now ); # "Friday, September 13, 2024 at 2:12:10 PM Central European Standard Time"

Using C<dayPeriod>:

Use the C<dayPeriod> option to output a string for the times of day (C<in the morning>, C<at night>, C<noon>, etc.). Note, that this only works when formatting for a 12 hour clock (C<< hourCycle => 'h12' >> or C<< hourCycle => 'h11' >>) and that for many locales the strings are the same irrespective of the value passed for the C<dayPeriod>.

    my $date = DateTime->new(
        year    => 2012,
        month   => 11,
        day     => 17,
        hour    => 4,
        minute  => 0,
        second  => 42,
        # Default
        time_zone => 'UTC',
    );

    say DateTime::Format::Intl->new( 'en-GB', {
        hour        => 'numeric',
        hourCycle   => 'h12',
        dayPeriod   => 'short',
        # or 'time_zone' is ok too
        timeZone    => 'UTC',
    })->format( $date );
    # "4 at night" (same formatting in en-GB for all dayPeriod values)

    say DateTime::Format::Intl->new( 'fr', {
        hour        => 'numeric',
        hourCycle   => 'h12',
        dayPeriod   => 'narrow',
        # or 'time_zone' is ok too
        timeZone    => 'UTC',
    })->format( $date );
    # "4 mat."  (same output in French for both narrow/short dayPeriod)

    say DateTime::Format::Intl->new( 'fr', {
        hour        => 'numeric',
        hourCycle   => 'h12',
        dayPeriod   => 'long',
        # or 'time_zone' is ok too
        timeZone    => 'UTC',
    })->format( $date );
    # "4 du matin"

Using C<timeZoneName>:

Use the C<timeZoneName> option to output a string for the C<timezone> (C<GMT>, C<Pacific Time>, etc.).

    my $date = DateTime->new(
        year    => 2021,
        month   => 11,
        day     => 17,
        hour    => 3,
        minute  => 0,
        second  => 42,
        # Default
        time_zone => 'UTC',
    );
    my $timezoneNames = [qw(
        short
        long
        shortOffset
        longOffset
        shortGeneric
        longGeneric
    )];

    foreach my $zoneName ( @$timezoneNames )
    {
        # Do something with currentValue
        my $formatter = DateTime::Format::Intl->new( 'en-US', {
            timeZone        => 'America/Los_Angeles',
            timeZoneName    => $zoneName,
        });
        say "${zoneName}: ", $formatter->format( $date);
    }

    # Yields the following:
    # short: 12/16/2021, PST
    # long: 12/16/2021, Pacific Standard Time
    # shortOffset: 12/16/2021, GMT-8
    # longOffset: 12/16/2021, GMT-08:00
    # shortGeneric: 12/16/2021, PT
    # longGeneric: 12/16/2021, Pacific Time

    # Enabling fatal exceptions
    use v5.34;
    use experimental 'try';
    no warnings 'experimental';
    try
    {
        my $fmt = DateTime::Format::Intl->new( 'x', fatal => 1 );
        # More code
    }
    catch( $e )
    {
        say "Oops: ", $e->message;
    }

Or, you could set the global variable C<$FATAL_EXCEPTIONS> instead:

    use v5.34;
    use experimental 'try';
    no warnings 'experimental';
    local $DateTime::Format::Intl::FATAL_EXCEPTIONS = 1;
    try
    {
        my $fmt = DateTime::Format::Intl->new( 'x' );
        # More code
    }
    catch( $e )
    {
        say "Oops: ", $e->message;
    }

=head1 VERSION

    v0.1.6

=head1 DESCRIPTION

This module provides the equivalent of the JavaScript implementation of L<Intl.DateTimeFormat|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/DateTimeFormat>

It relies on L<DateTime::Format::Unicode>, L<DateTime::Locale::FromCLDR>, L<Locale::Unicode::Data>, which provides access to all the L<Unicode CLDR (Common Locale Data Repository)|https://cldr.unicode.org/>, and L<Locale::Intl> to achieve similar results. It requires perl v5.10.1 minimum to run.

It is very elaborate and the algorithm provides the same result you would get with a web browser. The algorithm itself is quite complex and took me several months to implement, given all the dependencies with the modules aforementioned it relies on, that I also had to build to make the whole thing work.

I hope they will benefit you as they benefit me.

Because, just like its JavaScript equivalent, C<DateTime::Format::Intl> does quite a bit of look-ups and sensible guessing upon object instantiation, you want to create an object for a specific format, cache it and re-use it rather than creating a new one for each date formatting.

C<DateTime::Format::Intl> uses a set of culturally sensible default values derived directly from the web browsers own default. Upon object instantiation, it uses a culturally sensitive scoring to find the best matching format pattern available in the Unicode CLDR (Common Locale Data Repository) data for the options provided. It L<appends any missing components|https://www.unicode.org/reports/tr35/tr35-dates.html#Missing_Skeleton_Fields>, if any. Finally, it adjusts the best pattern retained to match perfectly the options of the user.

=head1 CONSTRUCTOR

=head2 new

This takes a C<locale> (a.k.a. language C<code> compliant with L<ISO 15924|https://en.wikipedia.org/wiki/ISO_15924> as defined by L<IETF|https://en.wikipedia.org/wiki/IETF_language_tag#Syntax_of_language_tags>) and an hash or hash reference of options and will return a new L<DateTime::Format::Intl> object, or upon failure C<undef> in scalar context and an empty list in list context.

Each option can also be accessed or changed using their corresponding method of the same name.

See the L<CLDR (Unicode Common Locale Data Repository) page|https://cldr.unicode.org/translation/date-time/date-time-patterns> for more on the format patterns used.

Supported options are:

=head3 Locale options

=over 4

=item * C<localeMatcher>

The locale matching algorithm to use. Possible values are C<lookup> and C<best fit>; the default is C<best fit>. For information about this option, see L<Locale identification and negotiation|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl#locale_identification_and_negotiation>.

Whatever value you provide, does not actually have any influence on the algorithm used. C<best fit> will always be the one used.

=item * C<calendar>

The calendar to use, such as C<chinese>, C<gregorian> (or C<gregory>), C<persian>, and so on. For a list of calendar types, see L<Intl.Locale.prototype.getCalendars()|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/Locale/getCalendars#supported_calendar_types>, and the method L<getAllCalendars|Locale::Intl/getAllCalendars> in the perl module L<Locale::Intl>. This option can also be set through the C<ca> Unicode extension key; if both are provided, this options property takes precedence. See L<Locale::Unicode/ca>

For example, a Japanese locale with the C<japanese> calendar extension set:

    my $fmt = DateTime::Format::Intl->new( 'ja-Kana-JP-u-ca-japanese' );

The only value calendar type supported by this module is C<gregorian>. Any other value will return an error.

=item * C<numberingSystem>

The numbering system to use for number formatting, such as C<fullwide>, C<hant>, C<mathsans>, and so on. For a list of supported numbering system types, see L<getNumberingSystems()|Locale::Intl/getNumberingSystems>. This option can also be set through the L<nu|Locale::Unicode/nu> Unicode extension key; if both are provided, this options property takes precedence.

For example, a Japanese locale with the C<latn> number system extension set and with the C<jptyo> time zone:

    my $fmt = DateTime::Format::Intl->new( 'ja-u-nu-latn-tz-jptyo' );

However, note that you can only provide a number system that is supported by the C<locale>, and whose type is C<numeric>, i.e. not C<algorithmic>. For instance, you cannot specify a C<locale> C<ar-SA> (arab as spoken in Saudi Arabia) with a number system of Japan:

    my $fmt = DateTime::Format::Intl->new( 'ar-SA', { numberingSystem => 'japn' } );
    say $fmt->resolvedOptions->{numberingSystem}; # arab

It would reject it, and issue a warning, if warnings are enabled, and fallback to the C<locale>'s default number system, which is, in this case, C<arab>

Additionally, even though the number system C<jpanfin> is supported by the locale C<ja>, it would not be acceptable, because it is not suitable for datetime formatting, since it is not of type C<numeric>, or at least this is how it is treated by web browsers (see L<here the web browser engine implementation|https://github.com/v8/v8/blob/main/src/objects/intl-objects.cc> and L<here for the Unicode ICU implementation|https://github.com/unicode-org/icu/blob/main/icu4c/source/i18n/numsys.cpp>). This API could easily make it acceptable, but it was designed to closely mimic the web browser implementation of the JavaScript API C<Intl.DateTimeFormat>. Thus:

    my $fmt = DateTime::Format::Intl->new( 'ja-u-nu-jpanfin-tz-jptyo' );
    say $fmt->resolvedOptions->{numberingSystem}; # latn

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/Locale/getNumberingSystems>, and also the perl module L<Locale::Intl>

=item * C<hour12>

Whether to use 12-hour time (as opposed to 24-hour time). Possible values are C<true> (C<1>) and C<false> (C<0>); the default is locale dependent. When C<true>, this option sets C<hourCycle> to either C<h11> or C<h12>, depending on the locale. When C<false>, it sets hourCycle to C<h23>. C<hour12> overrides both the hc locale extension tag and the C<hourCycle> option, should either or both of those be present.

=item * C<hourCycle>

The hour cycle to use. Possible values are C<h11>, C<h12>, C<h23>, and C<h24>. This option can also be set through the C<hc> Unicode extension key; if both are provided, this options property takes precedence.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/DateTimeFormat/DateTimeFormat#hourcycle>

=item * C<timeZone>

The time zone to use. Time zone names correspond to the Zone and Link names of the L<IANA Time Zone Database|https://www.iana.org/time-zones>, such as C<UTC>, C<Asia/Tokyo>, C<Asia/Kolkata>, and C<America/New_York>. Additionally, time zones can be given as UTC offsets in the format C<±hh:mm>, C<±hhmm>, or C<±hh>, for example as C<+01:00>, C<-2359>, or C<+23>. The default is the runtime's default time zone.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/DateTimeFormat/DateTimeFormat#timezone>

=back

=head3 Date-time component options

=over 4

=item * C<weekday>

The representation of the weekday. Possible values are:

=over 8

=item * C<long>

For example: C<Thursday>

=item * C<short>

For example: C<Thu>

=item * C<narrow>

For example: C<T>

Two weekdays may have the same narrow style for some locales (e.g. C<Tuesday>'s narrow style is also C<T>).

=back

=item * C<era>

The representation of the era. Possible values are:

=over 8

=item * C<long>

For example: C<Anno Domini>

=item * C<short>

For example: C<AD>

=item * C<narrow>

For example: C<A>

=back

=item * C<year>

The representation of the year. Possible values are C<numeric> and C<2-digit>.

=item * C<month>

The representation of the month. Possible values are:

=over 8

=item * C<numeric>

For example: C<3>

=item * C<2-digit>

For example: C<03>

=item * C<long>

For example: C<March>

=item * C<short>

For example: C<Mar>

=item * C<narrow>

For example: C<M>.

Two months may have the same narrow style for some locales (e.g. C<May>'s narrow style is also C<M>).

=back

=item * C<day>

The representation of the day. Possible values are C<numeric> and C<2-digit>.

=item * C<dayPeriod> or C<day_period>

The formatting style used for day periods like C<in the morning>, C<am>, C<noon>, C<n> etc. Possible values are C<narrow>, C<short>, and C<long>.

Note: This option only has an effect if a 12-hour clock (C<hourCycle>: C<h12> or C<hourCycle>: C<h11>) is used. Many locales use the same string irrespective of the width specified.

=item * C<hour>

The representation of the hour. Possible values are C<numeric> and C<2-digit>.

=item * C<minute>

The representation of the minute. Possible values are C<numeric> and C<2-digit>.

=item * C<second>

The representation of the second. Possible values are C<numeric> and C<2-digit>.

=item * C<fractionalSecondDigits>

The number of digits used to represent fractions of a second (any additional digits are truncated). Possible values are from C<1> to C<3>.

=item * C<timeZoneName>

The localized representation of the time zone name. Possible values are:

=over 8

=item * C<long>

Long localized form (e.g., C<Pacific Standard Time>, C<Nordamerikanische Westküsten-Normalzeit>)

=item * C<short>

Short localized form (e.g.: C<PST>, C<GMT-8>)

=item * C<shortOffset>

Short localized GMT format (e.g., C<GMT-8>)

=item * C<longOffset>

Long localized GMT format (e.g., C<GMT-08:00>)

=item * C<shortGeneric>

Short generic non-location format (e.g.: C<PT>, C<Los Angeles Zeit>).

=item * C<longGeneric>

Long generic non-location format (e.g.: C<Pacific Time>, C<Nordamerikanische Westküstenzeit>)

The default value for each date-time component option is C<undef>, but if all component properties are C<undef>, then C<year>, C<month>, and C<day> default to C<numeric>. If any of the date-time component options is specified, then C<dateStyle> and C<timeStyle> must be C<undef>.

=back

=item * C<formatMatcher>

The format matching algorithm to use. Possible values are C<basic> and C<best fit>; the default is C<best fit>. 

Whatever value you provide, does not actually have any influence on the algorithm used. C<best fit> will always be the one used.

Implementations are required to support displaying at least the following subsets of date-time components:

=over 8

=item * C<weekday>, C<year>, C<month>, C<day>, C<hour>, C<minute>, C<second>

=item * C<weekday>, C<year>, C<month>, C<day>

=item * C<year>, C<month>, C<day>

=item * C<year>, C<month>

=item * C<month>, C<day>

=item * C<hour>, C<minute>, C<second>

=item * C<hour>, C<minute>>

=back

Implementations may support other subsets, and requests will be negotiated against all available subset-representation combinations to find the best match. The algorithm for C<best fit> is implementation-defined, and C<basic> is defined by the spec. This option is only used when both C<dateStyle> and C<timeStyle> are undefined (so that each date-time component's format is individually customizable).

=back

=head3 Style shortcuts

=over 4

=item * C<dateStyle>

The date formatting style to use when calling C<format()>. Possible values are C<full>, C<long>, C<medium>, and C<short>.

=item * C<timeStyle>

The time formatting style to use when calling C<format()>. Possible values are C<full>, C<long>, C<medium>, and C<short>.

=back

Note: C<dateStyle> and C<timeStyle> can be used with each other, but not with other date-time component options (e.g. C<weekday>, C<hour>, C<month>, etc.).

=head1 METHODS

=head2 format

    my $options = 
    {
      weekday => 'long',
      year => 'numeric',
      month => 'long',
      day => 'numeric',
    };
    my $date = DateTime->new(
        year => 2012,
        month => 6,
        day => 1,
        time_zone => 'UTC',
    );
    
    my $dateTimeFormat1 = DateTime::Format::Intl->new('sr-RS', $options);
    say $dateTimeFormat1->format( $date );
    # Expected output: "петак, 1. јун 2012."
    
    my $dateTimeFormat2 = DateTime::Format::Intl->new('en-GB', $options);
    say $dateTimeFormat2->format( $date );
    # Expected output: "Friday, 1 June 2012"
    
    my $dateTimeFormat3 = DateTime::Format::Intl->new('en-US', $options);
    say $dateTimeFormat3->format( $date );
    # Expected output: "Friday, June 1, 2012"

This takes a L<DateTime> object, and returns a string representing the given date formatted according to the C<locale> and formatting options of this C<DateTime::Format::Intl> object.

=head2 format_range

Same as L<formatRange|/formatRange>

=head2 format_range_to_parts

Same as L<formatRangeToParts|/formatRangeToParts>

=head2 format_to_parts

Same as L<formatToParts|/formatToParts>

=head2 formatRange

    my $d1 = DateTime->new(
        year    => 2024,
        month   => 5,
        day     => 10,
        hour    => 13,
        minute  => 0,
        second  => 0,
    );
    my $d2 = DateTime->new(
        year    => 2024,
        month   => 5,
        day     => 11,
        hour    => 14,
        minute  => 0,
        second  => 0,
    );
    my $fmt = DateTime::Format::Intl->new( 'fr-FR' );
    say $fmt->formatRange( $d1 => $d2 ); # 10/05/2024 - 11/05/2024

    my $fmt2 = DateTime::Format::Intl->new( 'ja-JP' );
    say $fmt2->formatRange( $d1 => $d2 ); # 2024/05/10～2024/05/11

    my $fmt3 = DateTime::Format::Intl->new( 'fr-FR', {
        weekday => 'long',
        year    => 'numeric',
        month   => 'long',
        day     => 'numeric',
    });
    say $fmt3->formatRange( $d1 => $d2 ); # vendredi 10 mai 2024 - samedi 11 mai 2024

This C<formatRange()> method takes 2 L<DateTime> objects, and formats the range between 2 dates and returns a string.

The format used is the most concise way based on the locales and options provided when instantiating the new L<DateTime::Format::Intl> object. When no option were provided upon object instantiation, it default to a short version of the date format using L<date_format_short|DateTime::Locale::FromCLDR/date_format_short>), which, in turn, gets interpreted in various formats depending on the locale chosen. In British English, this would be C<10/05/2024> for May 10th, 2024.

=head2 formatRangeToParts

    my $d1 = DateTime->new(
        year    => 2024,
        month   => 5,
        day     => 10,
        hour    => 13,
        minute  => 0,
        second  => 0,
    );
    my $d2 = DateTime->new(
        year    => 2024,
        month   => 5,
        day     => 11,
        hour    => 14,
        minute  => 0,
        second  => 0,
    );
    my $fmt = DateTime::Format::Intl->new( 'fr-FR', {
        weekday => 'long',
        year    => 'numeric',
        month   => 'long',
        day     => 'numeric',
    });
    say $fmt->formatRange( $d1, $d2 ); # mercredi 10 janvier à 19:00 – jeudi 11 janvier à 20:00
    my $ref = $fmt->formatRangeToParts( $d1, $d2 );

This would return an array containing the following hash references:

    { type => 'weekday', value => 'mercredi',   source => 'startRange' },
    { type => 'literal', value => ' ',          source => 'startRange' },
    { type => 'day',     value => '10',         source => 'startRange' },
    { type => 'literal', value => ' ',          source => 'startRange' },
    { type => 'month',   value => 'janvier',    source => 'startRange' },
    { type => 'literal', value => ' à ',        source => 'startRange' },
    { type => 'hour',    value => '19',         source => 'startRange' },
    { type => 'literal', value => ':',          source => 'startRange' },
    { type => 'minute',  value => '00',         source => 'startRange' },
    { type => 'literal', value => ' – ',        source => 'shared' },
    { type => 'weekday', value => 'jeudi',      source => 'endRange' },
    { type => 'literal', value => ' ',          source => 'endRange' },
    { type => 'day',     value => '11',         source => 'endRange' },
    { type => 'literal', value => ' ',          source => 'endRange' },
    { type => 'month',   value => 'janvier',    source => 'endRange' },
    { type => 'literal', value => ' à ',        source => 'endRange' },
    { type => 'hour',    value => '20',         source => 'endRange' },
    { type => 'literal', value => ':',          source => 'endRange' },
    { type => 'minute',  value => '00',         source => 'endRange' }

The C<formatRangeToParts()> method returns an array of locale-specific tokens representing each part of the formatted date range produced by this L<DateTime::Format::Intl> object. It is useful for custom formatting of date strings.

=head2 formatToParts

    my $d = DateTime->new(
        year    => 2024,
        month   => 5,
        day     => 10,
        hour    => 13,
        minute  => 0,
        second  => 0,
    );
    my $fmt = DateTime::Format::Intl->new( 'fr-FR', {
        weekday => 'long',
        year    => 'numeric',
        month   => 'long',
        day     => 'numeric',
    });
    say $fmt->format( $d ); # mercredi 10 janvier à 19:00
    my $ref = $fmt->formatToParts( $d );

This would return an array containing the following hash references:

    { type => 'weekday', value => 'mercredi' },
    { type => 'literal', value => ' ' },
    { type => 'day',     value => '10' },
    { type => 'literal', value => ' ' },
    { type => 'month',   value => 'janvier' },
    { type => 'literal', value => ' à ' },
    { type => 'hour',    value => '19' },
    { type => 'literal', value => ':' },
    { type => 'minute',  value => '00' }

The C<formatToParts()> method takes an optional L<DateTime> object, and returns an array of locale-specific tokens representing each part of the formatted date produced by this L<DateTime::Format::Intl> object. It is useful for custom formatting of date strings.

If no L<DateTime> object is provided, it will default to the current date and time.

The properties of the hash references returned are as follows:

=over 4

=item * C<day>

The string used for the day, for example C<17>.

=item * C<dayPeriod>

The string used for the day period, for example, C<AM>, C<PM>, C<in the morning>, or C<noon>

=item * C<era>

The string used for the era, for example C<BC> or C<AD>.

=item * C<fractionalSecond>

The string used for the fractional seconds, for example C<0> or C<00> or C<000>.

=item * C<hour>

The string used for the hour, for example C<3> or C<03>.

=item * C<literal>

The string used for separating date and time values, for example C</>, C<,>, C<o'clock>, C<de>, etc.

=item * C<minute>

The string used for the minute, for example C<00>.

=item * C<month>

The string used for the month, for example C<12>.

=item * C<relatedYear>

The string used for the related 4-digit Gregorian year, in the event that the calendar's representation would be a yearName instead of a year, for example C<2019>.

=item * C<second>

The string used for the second, for example C<07> or C<42>.

=item * C<timeZoneName>

The string used for the name of the time zone, for example C<UTC>. Default is the timezone of the current environment.

=item * C<weekday>

The string used for the weekday, for example C<M>, C<Monday>, or C<Montag>.

=item * C<year>

The string used for the year, for example C<2012> or C<96>.

=item * C<yearName>

The string used for the yearName in relevant contexts, for example C<geng-zi>

=back

=head2 resolvedOptions

The C<resolvedOptions()> method returns an hash reference with the following properties reflecting the C<locale> and date and time formatting C<options> computed during the object instantiation.

=over 4

=item * C<locale>

The BCP 47 language tag for the locale actually used. If any Unicode extension values were requested in the input BCP 47 language tag that led to this locale, the key-value pairs that were requested and are supported for this locale are included in locale.

=item * C<calendar>

E.g. C<gregory>

=item * C<numberingSystem>

The values requested using the Unicode extension keys C<ca> and C<nu> or filled in as default values.

=item * C<timeZone>

The value provided for this property in the options argument; defaults to the runtime's default time zone. Should never be undefined.

=item * C<hour12>

The value provided for this property in the options argument or filled in as a default.

=item * C<weekday>, C<era>, C<year>, C<month>, C<day>, C<hour>, C<minute>, C<second>, C<timeZoneName>

The values resulting from format matching between the corresponding properties in the options argument and the available combinations and representations for date-time formatting in the selected locale. Some of these properties may not be present, indicating that the corresponding components will not be represented in formatted output.

=back

=head1 OTHER NON-CORE METHODS

=head2 error

Sets or gets an L<exception object|DateTime::Format::Intl::Exception>

When called with parameters, this will instantiate a new L<DateTime::Format::Intl::Exception> object, passing it all the parameters received.

When called in accessor mode, this will return the latest L<exception object|DateTime::Format::Intl::Exception> set, if any.

=head2 fatal

    $fmt->fatal(1); # Enable fatal exceptions
    $fmt->fatal(0); # Disable fatal exceptions
    my $bool = $fmt->fatal;

Sets or get the boolean value, whether to die upon exception, or not. If set to true, then instead of setting an L<exception object|DateTime::Format::Intl::Exception>, this module will die with an L<exception object|DateTime::Format::Intl::Exception>. You can catch the exception object then after using C<try>. For example:

    use v.5.34; # to be able to use try-catch blocks in perl
    use experimental 'try';
    no warnings 'experimental';
    try
    {
        my $fmt = DateTime::Format::Intl->new( 'x', fatal => 1 );
    }
    catch( $e )
    {
        say "Error occurred: ", $e->message;
        # Error occurred: Invalid locale value "x" provided.
    }

=head2 greatest_diff

    my $fmt = DateTime::Format::Intl->new( 'fr-FR' );
    say $fmt->formatRange( $d1 => $d2 ); # 10/05/2024 - 11/05/2024
    # Found that day ('d') is the greatest difference between the two datetimes
    my $component = $fmt->greatest_diff; # d

Read-only method.

Returns a string representing the component that is the greatest difference between two datetimes.

This value can be retrieved after L<formatRange|/formatRange> or L<formatRangeToParts|/formatRangeToParts> has been called, otherwise, it would merely return C<undef>

This is a non-standard method, not part of the original C<Intl.DateTimeFormat> JavaScript API.

See also L<DateTime::Locale::FromCLDR/interval_greatest_diff> and the L<Unicode LDML specifications|https://unicode.org/reports/tr35/tr35-dates.html#intervalFormats>

=head2 interval_pattern

    my $fmt = DateTime::Format::Intl->new( 'fr-FR' );
    say $fmt->formatRange( $d1 => $d2 ); # 10/05/2024 - 11/05/2024
    my $pattern = $fmt->interval_pattern;

Read-only method.

Returns a string representing the format pattern resulting from calling L<formatRange|/formatRange> or L<formatRangeToParts|/formatRangeToParts>. This format pattern, which is most likely based on interval format patterns available in the Unicode CLDR data, may have been adjusted to match the required options.

This is a non-standard method, not part of the original C<Intl.DateTimeFormat> JavaScript API.

=head2 interval_skeleton

    my $fmt = DateTime::Format::Intl->new( 'fr-FR' );
    say $fmt->formatRange( $d1 => $d2 ); # 10/05/2024 - 11/05/2024
    my $skeleton = $fmt->interval_skeleton;

Read-only method.

Returns a string representing the format skeleton resulting from calling L<formatRange|/formatRange> or L<formatRangeToParts|/formatRangeToParts>. This format skeleton, as called in the Unicode LDML specifications, is like an ID representing the underlying format pattern.

This is a non-standard method, not part of the original C<Intl.DateTimeFormat> JavaScript API.

=for Pod::Coverage pass_error

=head2 pattern

    my $fmt = DateTime::Format::Intl->new( 'en', { weekday => 'short' } ) ||
        die( DateTime::Format::Intl->error );
    my $resolved_pattern = $fmt->pattern;

Read-only method.

Returns a string representing the pattern resolved from the lookup based on the C<locale> provided and C<options> specified.

This is a non-standard method, not part of the original C<Intl.DateTimeFormat> JavaScript API.

=head2 skeleton

    my $fmt = DateTime::Format::Intl->new( 'en', { weekday => 'short' } ) ||
        die( DateTime::Format::Intl->error );
    my $resolved_skeleton = $fmt->skeleton;

Read-only method.

Returns a string representing the skeleton resolved from the lookup based on the C<locale> provided and C<options> specified. This returns a value only if the neither of the constructor options C<dateStyle> or C<timeStyle> have been provided. Otherwise, it would be C<undef>

This is a non-standard method, not part of the original C<Intl.DateTimeFormat> JavaScript API.

=head1 CLASS FUNCTIONS

=head2 supportedLocalesOf

    my $array = DateTime::Format::Intl->supportedLocalesOf( $locales, $options1 );
    # Try 3 locales by order of priority
    my $array = DateTime::Format::Intl->supportedLocalesOf( ['ja-t-de-t0-und-x0-medical', 'he-IL-u-ca-hebrew-tz-jeruslm', 'en-GB'], $options1 );

The C<supportedLocalesOf()> class function returns an array containing those of the provided locales that are supported in L<DateTime::Locale::FromCLDR> without having to fall back to the runtime's default locale.

It takes 2 arguments: C<locales> to look up, and an hash or hash reference of C<options>

=over 4

=item * C<locales>

A string with a L<BCP 47 language tag|https://en.wikipedia.org/wiki/IETF_language_tag#Syntax_of_language_tags>, or an array of such strings. For the general form and interpretation of the locales argument, see the parameter description on the L<object instantiation|/new>.

=item * C<options>

An optional hash or hash reference that may have the following property:

=over 8

=item * C<localeMatcher>

The locale matching algorithm to use. Possible values are C<lookup> and C<best fit>; the default is C<best fit>. For information about this option, see the L<object instantiation|/new>.

In this API, this option is not used.

=back

=back

=head1 EXCEPTIONS

A C<RangeError> exception is thrown if locales or options contain invalid values.

If an error occurs, any given method will set the L<error object|DateTime::Format::Intl::Exception> and return C<undef> in scalar context, or an empty list in list context.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/RangeError> for more information.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Locale::Unicode>, L<Locale::Intl>, L<Locale::Unicode::Data>, L<DateTime::Locale::FromCLDR>, L<DateTime::Format::Unicode>, L<DateTime>

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/DateTimeFormat>

L<CLDR repository for dates and time|https://github.com/unicode-org/cldr-json/tree/main/cldr-json/cldr-dates-full/main>

L<ICU documentation|https://unicode-org.github.io/icu/userguide/format_parse/datetime/>

L<CLDR website|http://cldr.unicode.org/>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2024 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
