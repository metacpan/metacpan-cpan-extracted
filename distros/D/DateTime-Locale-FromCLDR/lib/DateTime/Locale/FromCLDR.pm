##----------------------------------------------------------------------------
## Unicode Locale Identifier - ~/lib/DateTime/Locale/FromCLDR.pm
## Version v0.2.1
## Copyright(c) 2024 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2024/07/07
## Modified 2024/09/10
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package DateTime::Locale::FromCLDR;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use vars qw(
        $ERROR $VERSION $DEBUG $EMPTY_SET
        $TZ_DST_CACHE
    );
    use overload (
        '""'    => 'as_string',
        bool    => sub{ $_[0] },
        fallback => 1,
    );
    use utf8;
    use Locale::Unicode;
    use Locale::Unicode::Data;
    use Scalar::Util ();
    use Want;
    # "If a given short metazone form is known NOT to be understood in a given locale and the parent locale has this value such that it would normally be inherited, the inheritance of this value can be explicitly disabled by use of the 'no inheritance marker' as the value, which is 3 simultaneous empty set characters (U+2205)."
    # <https://unicode.org/reports/tr35/tr35-dates.html#Metazone_Names>
    our $EMPTY_SET = "∅∅∅";
    our $VERSION = 'v0.2.1';
};

use strict;
use warnings;

sub new
{
    my $this = shift( @_ );
    my $self = bless( { calendar => 'gregorian' } => ( ref( $this ) || $this ) );
    my $locale = shift( @_ ) ||
        return( $self->error( "No locale was provided." ) );
    $locale = $self->_locale_object( $locale ) ||
        return( $self->pass_error );
    my $core = $locale->core;
    unless( $core eq $locale )
    {
        $locale = Locale::Unicode->new( $core ) ||
            return( $self->pass_error( Locale::Unicode->error ) );
    }
    $self->{default_date_format_length} = 'medium';
    $self->{default_time_format_length} = 'medium';
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

    # Then, if the user provided with an hash or hash reference of options, we apply them
    for( my $i = 0; $i < scalar( @args ); $i++ )
    {
        my $name = $args[ $i ];
        my $val  = $args[ ++$i ];
        my $meth = $self->can( $name );
        if( !defined( $meth ) )
        {
            return( $self->error( "Unknown method \"${meth}\" provided for locale \"${locale}\"." ) );
        }
        elsif( !defined( $meth->( $self, $val ) ) )
        {
            if( defined( $val ) && $self->error )
            {
                return( $self->pass_error );
            }
        }
    }
    $self->{locale} = $locale;
    $self->{calendar} //= 'gregorian';
    $self->{_cldr} = Locale::Unicode::Data->new ||
        return( $self->pass_error( Locale::Unicode::Data->error ) );
    return( $self );
}

sub am_pm_abbreviated { return( shift->am_pm_format_abbreviated( @_ ) ); }

sub am_pm_format_abbreviated { return( shift->_am_pm(
    context => [qw( format stand-alone )],
    width   => [qw( abbreviated wide )],
) ); }

sub am_pm_format_narrow { return( shift->_am_pm(
    context => [qw( format stand-alone )],
    width   => [qw( narrow abbreviated wide )],
) ); }

sub am_pm_format_wide { return( shift->_am_pm(
    context => [qw( format stand-alone )],
    width   => [qw( wide abbreviated )],
) ); }

sub am_pm_standalone_abbreviated { return( shift->_am_pm(
    context => [qw( stand-alone format )],
    width   => [qw( abbreviated wide )],
) ); }

sub am_pm_standalone_narrow { return( shift->_am_pm(
    context => [qw( stand-alone format )],
    width   => [qw( narrow abbreviated wide )],
) ); }

sub am_pm_standalone_wide { return( shift->_am_pm(
    context => [qw( stand-alone format )],
    width   => [qw( wide abbreviated )],
) ); }

sub as_string
{
    my $self = shift( @_ );
    my $str;
    unless( defined( $str = $self->{as_string} ) )
    {
        my $locale = $self->{locale} ||
            die( "No locale is set!" );
        $str = $self->{as_string} = "$locale";
    }
    return( $str );
}

sub available_formats
{
    my $self = shift( @_ );
    my $ref;
    unless( defined( $ref = $self->{available_formats} ) )
    {
        my $locale = $self->{locale} || die( "Locale value is gone!" );
        my $cldr = $self->{_cldr} || die( "The Locale::Unicode::Data object is gone!" );
        my $tree = $cldr->make_inheritance_tree( $locale ) ||
            return( $self->pass_error( $cldr->error ) );
        my $calendar = $self->{calendar} || 'gregorian';
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
                # Make sure we have unique keys
                my $uniq = sub
                {
                    my %seen;
                    grep( !$seen{ $_ }++, @_ );
                };

                # $ref = [map( $_->{format_id}, @$all )];
                $ref = [$uniq->( map( $_->{format_id}, @$all ) )];
                last;
            }
        }
        $self->{available_formats} = $ref;
    }
    return( $ref );
}

sub calendar
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $cal_id = shift( @_ );
        if( defined( $cal_id ) )
        {
            if( $cal_id !~ /^[a-zA-Z][a-zA-Z0-9]+(\-[a-zA-Z][a-zA-Z0-9]+)*$/ )
            {
                return( $self->error( "Calendar ID provided (", ( $cal_id // 'undef' ), ") is invalid." ) );
            }
            $cal_id = lc( $cal_id );
        }
        $self->{calendar} = $cal_id;
    }
    return( $self->{calendar} );
}

sub code { return( shift->{locale} ); }

sub date_at_time_format_full { return( shift->_datetime_format(
    type        => 'atTime',
    width       => 'full',
) ); }

sub date_at_time_format_long { return( shift->_datetime_format(
    type        => 'atTime',
    width       => 'long',
) ); }

sub date_at_time_format_medium { return( shift->_datetime_format(
    type        => 'atTime',
    width       => 'medium',
) ); }

sub date_at_time_format_short { return( shift->_datetime_format(
    type        => 'atTime',
    width       => 'short',
) ); }

sub date_format_default { return( shift->date_format_medium ); }

sub date_format_full { return( shift->_date_time_format(
    type        => 'date',
    width       => 'full',
) ); }

sub date_format_long { return( shift->_date_time_format(
    type        => 'date',
    width       => 'long',
) ); }

sub date_format_medium { return( shift->_date_time_format(
    type        => 'date',
    width       => 'medium',
) ); }

sub date_format_short { return( shift->_date_time_format(
    type        => 'date',
    width       => 'short',
) ); }

sub date_formats
{
    my $self = shift( @_ );
    my $formats = {};
    foreach my $t ( qw( full long medium short ) )
    {
        my $code;
        unless( $code = $self->can( "date_format_${t}" ) )
        {
            die( "The method date_format_${t} is not defined in class ", ( ref( $self ) || $self ) );
        }
        $formats->{ $t } = $code->( $self );
    }
    return( $formats );
}

sub datetime_format { return( shift->datetime_format_medium ); }

sub datetime_format_default { return( shift->datetime_format_medium ); }

sub datetime_format_full { return( shift->_datetime_format(
    type        => 'standard',
    width       => 'full',
) ); }

sub datetime_format_long { return( shift->_datetime_format(
    type        => 'standard',
    width       => 'long',
) ); }

sub datetime_format_medium { return( shift->_datetime_format(
    type        => 'standard',
    width       => 'medium',
) ); }

sub datetime_format_short { return( shift->_datetime_format(
    type        => 'standard',
    width       => 'short',
) ); }

sub day_format_abbreviated { return( shift->_calendar_terms(
    id      => 'day_format_abbreviated',
    type    => 'day',
    context => [qw( format stand-alone )],
    width   => [qw( abbreviated wide )],
) ); }

sub day_format_narrow { return( shift->_calendar_terms(
    id      => 'day_format_narrow',
    type    => 'day',
    context => [qw( format stand-alone )],
    width   => [qw( narrow short abbreviated wide )],
) ); }

# NOTE: day short exists in CLDR, but is left out in DateTime::Locale::FromData
sub day_format_short { return( shift->_calendar_terms(
    id      => 'day_format_short',
    type    => 'day',
    context => [qw( format stand-alone )],
    width   => [qw( short narrow abbreviated )],
) ); }

sub day_format_wide { return( shift->_calendar_terms(
    id      => 'day_format_wide',
    type    => 'day',
    context => [qw( format stand-alone )],
    width   => 'wide',
) ); }

sub day_period_format_abbreviated { return( shift->_day_period({
    context => 'format',
    width => 'abbreviated',
}, @_ ) ); }

sub day_period_format_narrow { return( shift->_day_period({
    context => 'format',
    width => [qw( narrow abbreviated )],
}, @_ ) ); }

sub day_period_format_wide { return( shift->_day_period({
    context => 'format',
    width => 'wide',
}, @_ ) ); }

sub day_period_stand_alone_abbreviated { return( shift->_day_period({
    context => 'stand-alone',
    width => 'abbreviated',
}, @_ ) ); }

sub day_period_stand_alone_narrow { return( shift->_day_period({
    context => 'stand-alone',
    width => [qw( narrow abbreviated )],
}, @_ ) ); }

sub day_period_stand_alone_wide { return( shift->_day_period({
    context => 'stand-alone',
    width => 'wide',
}, @_ ) ); }

sub day_periods
{
    my $self = shift( @_ );
    my $periods;
    unless( defined( $periods = $self->{day_periods} ) )
    {
        my $locale = $self->{locale} ||
            return( $self->error( "No locale is set!" ) );
        $locale = $self->_locale_object( $locale ) ||
            return( $self->pass_error );
        my $cldr = $self->{_cldr} ||
            return( $self->error( "Unable to get the Locale::Unicode::Data object!" ) );
        my $tree = $cldr->make_inheritance_tree( $locale ) ||
            return( $self->pass_error( $cldr->error ) );
        $periods = {};
        foreach my $loc ( @$tree )
        {
            my $all = $cldr->day_periods( locale => $loc );
            if( scalar( @$all ) )
            {
                foreach my $ref ( @$all )
                {
                    $periods->{ $ref->{day_period} } = [@$ref{qw( start until )}];
                }
                last;
            }
        }
    }
    return( $periods );
}

sub day_stand_alone_abbreviated { return( shift->_calendar_terms(
    id      => 'day_stand_alone_abbreviated',
    type    => 'day',
    context => [qw( stand-alone format )],
    width   => [qw( abbreviated wide )],
) ); }

sub day_stand_alone_narrow { return( shift->_calendar_terms(
    id      => 'day_stand_alone_narrow',
    type    => 'day',
    context => [qw( stand-alone format )],
    width   => [qw( narrow wide )],
) ); }

# NOTE: day short exists in CLDR, but is left out in DateTime::Locale::FromData
sub day_stand_alone_short { return( shift->_calendar_terms(
    id      => 'day_stand_alone_short',
    type    => 'day',
    context => [qw( stand-alone format )],
    width   => [qw( short abbreviated )],
) ); }

sub day_stand_alone_wide { return( shift->_calendar_terms(
    id      => 'day_stand_alone_wide',
    type    => 'day',
    context => [qw( stand-alone format )],
    width   => 'wide',
) ); }

sub default_date_format_length { return( shift->{default_date_format_length} ); }

sub default_time_format_length { return( shift->{default_time_format_length} ); }

sub era_abbreviated { return( shift->_calendar_eras(
    id      => 'era_abbreviated',
    width   => [qw( abbreviated wide )],
    alt     => undef,
) ); }

sub era_narrow { return( shift->_calendar_eras(
    id      => 'era_narrow',
    width   => [qw( narrow abbreviated wide )],
    alt     => undef,
) ); }

sub era_wide { return( shift->_calendar_eras(
    id      => 'era_wide',
    width   => [qw( wide abbreviated )],
    alt     => undef,
) ); }

sub error
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $msg = join( '', map( ( ref( $_ ) eq 'CODE' ) ? $_->() : $_, @_ ) );
        $self->{error} = $ERROR = DateTime::Locale::FromCLDR::Exception->new({
            skip_frames => 1,
            message => $msg,
        });
        warn( $msg ) if( warnings::enabled() );
        if( Want::want( 'ARRAY' ) )
        {
            rreturn( [] );
        }
        elsif( Want::want( 'OBJECT' ) )
        {
            rreturn( DateTime::Locale::FromCLDR::NullObject->new );
        }
        return;
    }
    return( ref( $self ) ? $self->{error} : $ERROR );
}

sub first_day_of_week
{
    my $self = shift( @_ );
    my $dow;
    unless( defined( $dow = $self->{first_day_of_week} ) )
    {
        my $locale = $self->{locale} ||
            return( $self->error( "No locale is set!" ) );
        my $cldr = $self->{_cldr} ||
            return( $self->error( "Unable to get the Locale::Unicode::Data object!" ) );
        $locale = Locale::Unicode->new( $locale ) unless( Scalar::Util::blessed( $locale ) && $locale->isa( 'Locale::Unicode' ) );
        my $info = $self->_territory_info( locale => $locale ) ||
            return( $self->pass_error );
        if( !defined( $info->{first_day} ) ||
            !length( $info->{first_day} // '' ) )
        {
            $info = $self->_territory_info( territory => '001' ) ||
                return( $self->error( "Unable to get territory information for the World!" ) );
            if( !defined( $info->{first_day} ) ||
                !length( $info->{first_day} // '' ) )
            {
                return( $self->error( "First day of the week property (first_day) for territory '$info->{territory}' is missing in Locale::Unicode::Data" ) );
            }
        }
        return( $dow = $self->{first_day_of_week} = $info->{first_day} );
    }
    return( $dow );
}

sub format_for
{
    my $self = shift( @_ );
    my $id = shift( @_ ) || return( $self->error( "No format ID was provided." ) );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{id} = $id;
    return( $self->_available_formats( %$opts ) );
}

sub format_gmt
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $offset = $opts->{offset};
    $opts->{width} //= 'long';
    if( !defined( $offset ) )
    {
        return( $self->error( "No time offset was provided." ) );
    }
    elsif( $offset !~ /^(?:\-|\+)?\d+$/ )
    {
        return( $self->error( "Invalid offset value '${offset}'" ) );
    }
    elsif( $offset < -359999 ||
           $offset > 359999 )
    {
        return( $self->error( "Out of bound offset value provided: '${offset}'" ) );
    }
    elsif( $opts->{width} !~ /^(?:long|short)$/ )
    {
        return( $self->error( "Bad width used. It must be one of 'long' or 'short'" ) );
    }

    # my $sign = $offset < 0 ? '-' : '+';
    # <https://unicode.org/reports/tr35/tr35-dates.html#Using_Time_Zone_Names>
    my $fmt;
    # "Otherwise (when the offset from GMT is zero, referring to GMT itself) the style specified by the <gmtZeroFormat> element is used"
    # Example: "GMT" or "UTC" or "Гринуич"
    if( !$offset )
    {
        $fmt = $self->timezone_format_gmt_zero;
    }
    else
    {
        $fmt = $self->timezone_format_gmt;
        # Example: ["+HH:mm", "-HH:mm"]
        my $ref = $self->timezone_format_hour || [];
        $offset = abs( $offset );
        my $map =
        {
            hour => 'H',
            minute => 'm',
            second => 's',
        };
        my $def = {};
        $def->{hour} = int( $offset / 3600 );
        $offset %= 3600;
        $def->{minute} = int( $offset / 60 );
        $offset %= 60;
        $def->{second} = int( $offset );
        # We localise the numerals
        # "The digits should be whatever are appropriate for the locale used to format the time zone, not necessarily from the western digits, 0..9. For example, they might be from ०..९."
        # <https://unicode.org/reports/tr35/tr35-dates.html#Using_Time_Zone_Names>
        my $num_sys = $self->locale_number_system ||
            return( $self->pass_error );
        # No need to bother if the numbering system is 'latn', since we are using it by default.
        unless( $num_sys->[0] eq 'latn' )
        {
            # Now, the specifications say that all languages, including those with rtl layout write their numerals left-to-right
            # In Hebrew, it is traditionally rtl, but there is no agreemennt
            foreach my $k ( qw( hour minute second ) )
            {
                next unless( length( $def->{ $k } // '' ) );
                my @digits = split( //, $def->{ $k } );
                for( my $i = 0; $i < scalar( @digits ); $i++ )
                {
                    $digits[$i] = $num_sys->[1]->[ $digits[$i] ];
                }
                $def->{ $k } = join( '', @digits );
            }
        }
        # "The digits should be whatever are appropriate for the locale used to format the time zone, not necessarily from the western digits, 0..9. For example, they might be from ०..९."
        # <https://unicode.org/reports/tr35/tr35-dates.html#Using_Time_Zone_Names>
        my $time_fmt;
        # Example: "GMT+3" or "UTC-3"
        if( $opts->{width} eq 'short' && 
            !$def->{minute} &&
            !$def->{second} )
        {
            $time_fmt = ( $offset < 0 ? '-' : '+' ) . int( $def->{hour} );
        }
        # Example: "GMT+03:30" (long) or "GMT+3:30" (short) or localised like "Гринуич+03:30" (long)
        else
        {
            $time_fmt = $ref->[ $offset < 0 ? 1 : 0 ];
            if( defined( $time_fmt ) )
            {
                foreach my $type ( qw( hour minute second ) )
                {
                    my $token = $map->{ $type };
                    $def->{ $type } //= 0;
                    $time_fmt =~ s{
                        (${token}{1,2})
                    }
                    {
                        my $val = $def->{ $type };
                        my $len = $opts->{width} eq 'short' ? 1 : length( $1 );
                        sprintf( "%0*d", $len, $val );
                    }gexs;
                }
            }
            else
            {
                $time_fmt //= '';
            }
        }
        $fmt =~ s/\{0\}/$time_fmt/g;
    }
    return( $fmt );
}

# "5. For the generic location format"
sub format_timezone_location
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $timezone = $opts->{timezone} ||
        return( $self->error( "No timezone was provided." ) );
    $timezone = $self->timezone_canonical( $timezone );
    return( $self->pass_error ) if( !defined( $timezone ) );
    return( "Unknown time zone '${timezone}'" ) if( !$timezone );
    my $meth_id = 'format_timezone_location_tz=' . $timezone;
    my $str;
    unless( defined( $str = $self->{ $meth_id } ) )
    {
        my $locale = $self->{locale} ||
            return( $self->error( "No locale is set!" ) );
        $locale = $self->_locale_object( $locale ) ||
            return( $self->pass_error );
        my $cldr = $self->{_cldr} ||
            return( $self->error( "Unable to get the Locale::Unicode::Data object!" ) );
        my $tree = $cldr->make_inheritance_tree( $locale ) ||
            return( $self->pass_error( $cldr->error ) );
        my $tz_info = $cldr->timezone( timezone => $timezone ) ||
            return( $self->pass_error( $cldr->error ) );
        if( $tz_info->{territory} eq '001' &&
            warnings::enabled() )
        {
            warn( "The timezone territory is 001, which is abnormal. Something is wrong with the Locale::Unicode::Data." );
        }
        # "5.1 From the TZDB get the country code for the zone, and determine whether there is only one timezone in the country. If there is only one timezone or if the zone id is in the <primaryZones> list, format the country name with the regionFormat, and return it."
        my $all = $tz_info->{territory} eq '001' ? [] : $cldr->timezones( territory => $tz_info->{territory} );
        return( $self->pass_error( $cldr->error ) ) if( !defined( $all ) && $cldr->error );
        if( scalar( @$all ) == 1 ||
            $tz_info->{is_primary} )
        {
            my $fmt = $self->timezone_format_region;
            return( $self->pass_error ) if( !defined( $fmt ) );
            # Get the localised territory name
            my $territory_name;
            foreach my $loc ( @$tree )
            {
                my $name_ref = $cldr->territory_l10n(
                    locale => $loc,
                    territory => $tz_info->{territory},
                );
                return( $self->pass_error( $cldr->error ) ) if( !defined( $name_ref ) && $cldr->error );
                if( $name_ref && $name_ref->{locale_name} )
                {
                    $territory_name = $name_ref->{locale_name};
                    last;
                }
            }
            # Fallback to the country code
            $territory_name //= $tz_info->{territory};
            $fmt =~ s/\{0\}/$territory_name/g;
            $str = $fmt;
        }
        # "5.2 Otherwise format the exemplar city with the regionFormat, and return it."
        else
        {
            my $fmt = $self->timezone_format_region;
            return( $self->pass_error ) if( !defined( $fmt ) );
            my $city = $self->timezone_city( timezone => $timezone );
            return( $self->pass_error ) if( !defined( $city ) );
            # "Composition 3: If the localized exemplar city is not available, use as the exemplar city the last field of the raw TZID, stripping off the prefix and turning _ into space."
            # America/Los_Angeles → "Los Angeles"
            if( !length( $city // '' ) )
            {
                $city = join( ' ', split( '_', [split( '/', $timezone )]->[-1] ) );
            }
            $fmt =~ s/\{0\}/$city/g;
            $str = $fmt;
        }
        $self->{ $meth_id } = $str;
    }
    return( $str );
}

# See for more details:
# <https://unicode.org/reports/tr35/tr35-dates.html#Using_Time_Zone_Names>
sub format_timezone_non_location
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $timezone = $opts->{timezone} ||
        return( $self->error( "No timezone was provided." ) );
    my $type = $opts->{type} ||
        return( $self->error( "No timezone type was provided. It must be one of: generic, standard, or daylight" ) );
    if( $type ne 'generic' &&
        $type ne 'standard' &&
        $type ne 'daylight' )
    {
        return( $self->error( "Invalid timezone type provided (${type}). It must be one of: generic, standard or daylight" ) );
    }
    my $width = $opts->{width} || 'long';
    if( $width ne 'long' &&
        $width ne 'short' )
    {
        return( $self->error( "Invalid timezone width provided (${width}). It must be one of: long or short" ) );
    }
    $timezone = $self->timezone_canonical( $timezone );
    return( $self->pass_error ) if( !defined( $timezone ) );
    return( "Unknown time zone '${timezone}'" ) if( !$timezone );
    my $meth_id = 'format_timezone_non_location_tz=' . $timezone . '_type_' . $type . '_width_' . $width;
    my $str;
    unless( defined( $str = $self->{ $meth_id } ) )
    {
        my $locale = $self->{locale} ||
            return( $self->error( "No locale is set!" ) );
        $locale = $self->_locale_object( $locale ) ||
            return( $self->pass_error );
        my $cldr = $self->{_cldr} ||
            return( $self->error( "Unable to get the Locale::Unicode::Data object!" ) );
        my $tz_info = $cldr->timezone( timezone => $timezone ) ||
            return( $self->pass_error( $cldr->error ) );
        my $need_dst = $self->has_dst( $timezone );
        my $meta_need_dst = $need_dst;
        my $tree = $cldr->make_inheritance_tree( $locale ) ||
            return( $self->pass_error( $cldr->error ) );
        my @types = qw( generic standard daylight );
        my $meta_name_cache = {};
        my $get_meta_names = sub
        {
            return( $meta_name_cache->{ $tz_info->{metazone} }->{ $width } ) if( exists( $meta_name_cache->{ $tz_info->{metazone} }->{ $width } ) && ref( $meta_name_cache->{ $tz_info->{metazone} }->{ $width } ) eq 'HASH' );
            foreach my $loc ( @$tree )
            {
                my $ref = $cldr->metazone_names(
                    locale => $loc,
                    metazone => $tz_info->{metazone},
                    # NOTE: Should we ignore the requested width and use 'long', since there are not many 'short' data?
                    width => $width,
                );
                return( $self->error( $cldr->pass_error ) ) if( !defined( $ref ) && $cldr->error );
                if( $ref )
                {
                    $meta_name_cache->{ $tz_info->{metazone} } //= {};
                    return( $meta_name_cache->{ $tz_info->{metazone} }->{ $width } = $ref );
                }
            }
            return;
        };
        my $get_meta_info = sub
        {
            my $metazone = shift( @_ );
            return( $cldr->metazone( metazone => $metazone ) );
        };
        my $type_fallback;
        my $get_type_fallback = sub
        {
            my $meta_names = shift( @_ );
            # Cached, because this may be called more than once.
            return( $type_fallback ) if( defined( $type_fallback ) );
            unless( defined( $meta_names ) &&
                    ref( $meta_names ) eq 'HASH' )
            {
                $meta_names = $get_meta_names->();
                if( !defined( $meta_names ) )
                {
                    return( $self->error( "Unable to find the metazone information for metazone '$tz_info->{metazone}'." ) );
                }
            }
    
            if( $meta_need_dst )
            {
                if( length( $meta_names->{daylight} // '' ) )
                {
                    return( $type_fallback = $meta_names->{daylight} );
                }
                # "If the daylight type does not exist, then the metazone doesn't require daylight support."
                else
                {
                    $meta_need_dst = 0;
                }
                # "If the generic type exists, use it."
                if( $meta_names->{generic} )
                {
                    return( $type_fallback = $meta_names->{generic} );
                }
                # "Otherwise if the standard type exists, use it."
                elsif( $meta_names->{standard} )
                {
                    return( $type_fallback = $meta_names->{standard} );
                }
            }
            # "Otherwise if the generic type is needed, but not available, and the offset and daylight offset do not change within 184 day +/- interval around the exact formatted time, use the standard type."
            elsif( $type eq 'generic' && 
                   !$meta_names->{generic} &&
                   !$self->has_dst )
            {
                return( $type_fallback = $meta_names->{standard} );
            }
            return( $type_fallback = '' );
        };
        LOCALES: foreach my $loc ( @$tree )
        {
            my $ref = $cldr->timezone_names(
                locale => $loc,
                timezone => $timezone,
                # 'long' or 'short'
                width => $width,
            );
            return( $self->error( $cldr->pass_error ) ) if( !defined( $ref ) && $cldr->error );
            if( $ref )
            {
                # "4.1. if there is an explicit translation for the TZID in <timeZoneNames> according to type (generic, standard, or daylight) in the resolved locale, return it"
                if( length( $ref->{ $type } // '' ) )
                {
                    $str = $ref->{ $type };
                    last LOCALES;
                }
                # "4.1.1 If the requested type is not available, but another type is, and there is a Type Fallback then return that other type."
                my @other_types = grep( length( $ref->{ $_ } // '' ), grep( $_ ne $type, @types ) );
                if( scalar( @other_types ) && 
                    $get_type_fallback->() )
                {
                    foreach my $t ( @other_types )
                    {
                        if( $ref->{ $t } )
                        {
                            $str = $ref->{ $t };
                            last LOCALES;
                        }
                    }
                }
            }
        }
    
        # "4.2. Otherwise, get the requested metazone format according to type (generic, standard, daylight)."
        if( !defined( $str ) && $tz_info->{metazone} )
        {
            my $ref = $get_meta_names->();
            return( $self->error( $cldr->pass_error ) ) if( !defined( $ref ) && $cldr->error );
            if( $ref )
            {
                if( length( $ref->{ $type } // '' ) )
                {
                    $str = $ref->{ $type };
                }
                else
                {
                    # "4.2.1 If the requested type is not available, but another type is, get the format according to Type Fallback."
                    my @other_types = grep( length( $ref->{ $_ } // '' ), grep( $_ ne $type, @types ) );
                    if( scalar( @other_types ) )
                    {
                        my $fallback = $get_type_fallback->( $ref );
                        return( $self->pass_error ) if( !defined( $fallback ) );
                        if( length( $fallback // '' ) )
                        {
                            $str = $fallback;
                        }
                    }
                }
            }
            # "4.2.2 If there is no format for the type, fall back."
        }
    
        # "4.3. Otherwise do the following:"
        if( !defined( $str ) )
        {
            # "4.3.1 Get the country for the current locale. If there is none, use the most likely country based on the likelySubtags data."
            my $cc = $locale->country_code;
            unless( $cc )
            {
                foreach my $loc ( @$tree )
                {
                    my $ref = $cldr->likely_subtag( locale => $loc );
                    if( $ref && $ref->{target} )
                    {
                        my $target = Locale::Unicode->new( $ref->{target} ) ||
                            return( $self->pass_error( Locale::Unicode->error ) );
                        $cc = $target->country_code;
                    }
                }
                # "4.3.1 If there is none, use "OOI""
                $cc ||= '001';
            }
            # "4.3.2 Get the preferred zone for the metazone for the country; if there is none for the country, use the preferred zone for the metazone for "001"."
            my @territories = ( $cc ? $cc : () );
            push( @territories, '001' ) unless( $cc && $cc eq '001' );
            my $ref = $cldr->metazone( metazone => $tz_info->{metazone} );
            return( $self->pass_error( $cldr->error ) ) if( !defined( $ref ) );
            my $preferred_timezone;
            foreach my $territory ( @territories )
            {
                if( $ref->{territories} &&
                    ref( $ref->{territories} ) eq 'ARRAY' &&
                    $ref->{timezones} &&
                    ref( $ref->{timezones} ) eq 'ARRAY' &&
                    scalar( @{$ref->{timezones}} ) &&
                    scalar( grep( $_ eq $territory, @{$ref->{territories}} ) ) )
                {
                    # The "preferred" zone means the first one in the array as per the LDML specifications.
                    $preferred_timezone = $ref->{timezones}->[0];
                    last;
                }
            }
            # "4.3.3 If that preferred zone is the same as the requested zone, use the metazone format. For example, "Pacific Time" for Vancouver if the locale is en_CA, or for Los Angeles if locale is en_US."
            if( defined( $preferred_timezone ) &&
                $preferred_timezone eq $timezone )
            {
                my $name_ref = $get_meta_names->();
                return( $self->pass_error( $cldr->error ) ) if( !defined( $name_ref ) && $cldr->error );
                if( $name_ref && $name_ref->{ $type } )
                {
                    $str = $name_ref->{ $type };
                }
            }
            # "4.3.4 Otherwise, if the zone is the preferred zone for its country but not for the country of the locale, use the metazone format + country in the fallbackFormat."
            if( !defined( $str ) &&
                $tz_info->{is_preferred} &&
                $tz_info->{territory} ne $cc )
            {
                # Get the fallback format
                # Something like {1} ({0})
                my $fmt = $self->timezone_format_fallback;
                return( $self->pass_error ) if( !defined( $fmt ) );
                return( $self->error( "Unable to find the time zone fallback format for locale ${locale} or any of its ancestors in its inheritance tree. This should not happen. Maybe something is wrong with the Locale::Unicode::Data database?" ) ) if( !length( $fmt // '' ) );
                # Get the localised territory name
                my $territory_name;
                foreach my $loc ( @$tree )
                {
                    my $name_ref = $cldr->territory_l10n(
                        locale => $loc,
                        territory => $cc,
                    );
                    return( $self->pass_error( $cldr->error ) ) if( !defined( $name_ref ) && $cldr->error );
                    if( $name_ref && $name_ref->{locale_name} )
                    {
                        $territory_name = $name_ref->{locale_name};
                        last;
                    }
                }
                # return( $self->error( "Unable to get the localised territory name for '${cc}' for locale '${locale}' or any of its ancestors in its inheritance tree. This should not happen. Maybe something is wrong with the Locale::Unicode::Data database?" ) ) if( !defined( $territory_name ) );
                # "Composition 2. If the localized country name is not available, use the code"
                $territory_name //= $cc;
                # Get the localised generic metazone name
                my $metazone_name;
                my $name_ref = $get_meta_names->();
                return( $self->error( $cldr->pass_error ) ) if( !defined( $name_ref ) && $cldr->error );
                if( $name_ref && ( $name_ref->{generic} || $name_ref->{standard} ) )
                {
                    $metazone_name = ( $name_ref->{generic} // $name_ref->{standard} );
                }
                # If the 'generic' format is not available, the 'standard' one should, if not in the initial locale, then in one of its ancestors, otherwise something is wrong with the data
                # The 'standard' format is more often available than the 'generic' one.
                return( $self->error( "Unable to get the localised metazone name for metazone '$tz_info->{metazone}' for locale '${locale}' or any of its ancestors in its inheritance tree. This should not happen. Maybe something is wrong with the Locale::Unicode::Data database?" ) ) if( !defined( $metazone_name ) );
                $fmt =~ s/\{1\}/$metazone_name/;
                $fmt =~ s/\{0\}/$territory_name/;
                $str = $fmt;
            }
            # "4.3.5 Otherwise, use the metazone format + city in the fallbackFormat."
            if( !defined( $str ) )
            {
                my $fmt = $self->timezone_format_fallback;
                return( $self->pass_error ) if( !defined( $fmt ) );
                return( $self->error( "Unable to find the time zone fallback format for locale ${locale} or any of its ancestors in its inheritance tree. This should not happen. Maybe something is wrong with the Locale::Unicode::Data database?" ) ) if( !length( $fmt // '' ) );
                my $city = $self->timezone_city( timezone => $timezone );
                return( $self->pass_error ) if( !defined( $city ) );
                # "Composition 3: If the localized exemplar city is not available, use as the exemplar city the last field of the raw TZID, stripping off the prefix and turning _ into space."
                # America/Los_Angeles → "Los Angeles"
                if( !length( $city // '' ) )
                {
                    $city = join( ' ', split( '_', [split( '/', $timezone )]->[-1] ) );
                }
    
                # my $metazone_name;
                # my $name_ref = $get_meta_names->();
                # return( $self->error( $cldr->pass_error ) ) if( !defined( $name_ref ) && $cldr->error );
                # if( $name_ref && ( $name_ref->{generic} || $name_ref->{standard} ) )
                # {
                #     $metazone_name = ( $name_ref->{generic} // $name_ref->{standard} );
                # }
                # If the 'generic' format is not available, the 'standard' one should, if not in the initial locale, then in one of its ancestors, otherwise something is wrong with the data
                # The 'standard' format is more often available than the 'generic' one.
                # return( $self->error( "Unable to get the localised metazone name for metazone '$tz_info->{metazone}' for locale '${locale}' or any of its ancestors in its inheritance tree. This should not happen. Maybe something is wrong with the Locale::Unicode::Data database?" ) ) if( !defined( $metazone_name ) );
                # $fmt =~ s/\{1\}/$metazone_name/;
                $fmt =~ s/\{1\}/$tz_info->{metazone}/;
                $fmt =~ s/\{0\}/$city/;
                $str = $fmt;
            }
        }
        $str //= '';
        $self->{ $meth_id } = $str;
    }
    return( $str );
}

# NOTE method glibc_date_1_format is not implemented, because we deal only with CLDR format

# NOTE method glibc_date_format is not implemented, because we deal only with CLDR format

# NOTE method glibc_datetime_format is not implemented, because we deal only with CLDR format

# NOTE method glibc_time_12_format is not implemented, because we deal only with CLDR format

# NOTE method glibc_time_format is not implemented, because we deal only with CLDR format

# <https://en.wikipedia.org/wiki/Daylight_saving_time_by_country>
sub has_dst
{
    my $self = shift( @_ );
    my $timezone = shift( @_ ) ||
        return( $self->error( "No time zone was provided." ) );
    $TZ_DST_CACHE //= {};
    $timezone = $self->timezone_canonical( $timezone );
    return( $self->pass_error ) if( !defined( $timezone ) );
    return( "Unknown time zone '${timezone}'" ) if( !$timezone );
    return( $TZ_DST_CACHE->{ lc( $timezone ) } ) if( exists( $TZ_DST_CACHE->{ lc( $timezone ) } ) );
    local $@;
    # try-catch
    eval
    {
        require DateTime;
    };
    if( $@ )
    {
        return( $self->error( "Unable to load the DateTime object: $@" ) );
    }
    my $dt = eval
    {
        DateTime->now( time_zone => $timezone );
    };
    if( $@ )
    {
        return( $self->error( "Unable to instantiate a DateTime object with time zone '${timezone}': $@" ) );
    }
    my $year = $dt->year;
    my $jan = eval
    {
        DateTime->new( year => $year, month => 1, day => 1, time_zone => $dt->time_zone )->offset;
    };
    return( $self->error( "Unable to get the time zone offset for '${timezone}' at ${year}/1/1: $@" ) ) if( $@ );
    my $jul = eval
    {
        DateTime->new( year => $year, month => 7, day => 1, time_zone => $dt->time_zone )->offset;
    };
    return( $self->error( "Unable to get the time zone offset for '${timezone}' at ${year}/7/1: $@" ) ) if( $@ );
    my $bool = ( $jan != $jul ? 1 : 0 );
    $TZ_DST_CACHE->{ lc( $timezone ) } = $bool;
    return( $bool );
}

sub interval_format
{
    my $self = shift( @_ );
    my $id = shift( @_ ) || return( $self->error( "No interval format ID was provided." ) );
    my $greatest_diff = shift( @_ ) ||
        return( $self->error( "No greatest difference token was provided." ) );
    my $locale = $self->{locale} ||
        return( $self->error( "No locale is set!" ) );
    $locale = $self->_locale_object( $locale ) ||
        return( $self->pass_error );
    my $cldr = $self->{_cldr} ||
        return( $self->error( "Unable to get the Locale::Unicode::Data object!" ) );
    my $calendar = $self->{calendar} || 'gregorian';
    my $tree = $cldr->make_inheritance_tree( $locale ) ||
        return( $self->pass_error( $cldr->error ) );
    my $ref;
    foreach my $loc ( @$tree )
    {
        $ref = $cldr->calendar_interval_format(
            locale => $loc,
            calendar => $calendar,
            format_id => $id,
            greatest_diff_id => ( lc( $greatest_diff ) eq 'h' ? [ uc( $greatest_diff ), lc( $greatest_diff )] : $greatest_diff ),
        );
        if( !defined( $ref ) && $cldr->error )
        {
            return( $self->pass_error( $cldr->error ) );
        }
        elsif( $ref )
        {
            last;
        }
    }
    return( [] ) if( !$ref );
    return( [@$ref{qw( part1 separator part2 format_pattern )}] );
}

sub interval_formats
{
    my $self = shift( @_ );
    my $formats;
    unless( defined( $formats = $self->{interval_formats} ) )
    {
        my $locale = $self->{locale} ||
            return( $self->error( "No locale is set!" ) );
        $locale = $self->_locale_object( $locale ) ||
            return( $self->pass_error );
        my $cldr = $self->{_cldr} ||
            return( $self->error( "Unable to get the Locale::Unicode::Data object!" ) );
        my $calendar = $self->{calendar} || 'gregorian';
        my $tree = $cldr->make_inheritance_tree( $locale ) ||
            return( $self->pass_error( $cldr->error ) );
        foreach my $loc ( @$tree )
        {
            $formats = $cldr->interval_formats(
                locale => $loc,
                calendar => $calendar,
            ) || return( $self->pass_error( $cldr->error ) );
            if( !defined( $formats ) && $cldr->error )
            {
                return( $self->pass_error( $cldr->error ) );
            }
            last if( $formats && scalar( keys( %$formats ) ) );
        }
        $formats //= {};
        $self->{interval_formats} = $formats;
    }
    return( $formats );
}

# <https://unicode.org/reports/tr35/tr35-dates.html#intervalFormats>
# a: am, pm period
# B: flexible day periods
#    00:00 (midnight)
#    06:00 - 12:00 (morning1)
#    12:00 - 12:00 (noon)
#    12:00 - 18:00 (afternoon1)
#    18:00 - 21:00 (evening1)
#    21:00 - 06:00 (night1)
# d: day
# G: era
# h: hour
# H: hour
# M: month
# m: minute
# y: year
sub interval_greatest_diff
{
    my $self = shift( @_ );
    my $dt1 = shift( @_ ) ||
        return( $self->error( "No DateTime object was provided. \$locale->interval_greatest_diff( \$dt1, \$dt2 )" ) );
    my $dt2 = shift( @_ ) ||
        return( $self->error( "Missing DateTime object. I was expecting 2 DateTime object, but only 1 was provided. \$locale->interval_greatest_diff( \$dt1, \$dt2 )" ) );
    if( !defined( $dt1 ) ||
        !Scalar::Util::blessed( $dt1 ) ||
        !$dt1->isa( 'DateTime' ) )
    {
        return( $self->error( "The first DateTime value provided (", overload::StrVal( $dt1 // 'undef' ), ") is not a DateTime object." ) );
    }
    if( !defined( $dt2 ) ||
        !Scalar::Util::blessed( $dt2 ) ||
        !$dt2->isa( 'DateTime' ) )
    {
        return( $self->error( "The first DateTime value provided (", overload::StrVal( $dt2 // 'undef' ), ") is not a DateTime object." ) );
    }

    local $@;
    # try-catch
    eval
    {
        require DateTime;
    };
    if( $@ )
    {
        return( $self->error( "Unable to load the DateTime object: $@" ) );
    }
    my $cmp = DateTime->compare_ignore_floating( $dt1, $dt2 );
    my $is_reverse = 0;
    # dt1 > dt2
    if( $cmp > 0 )
    {
        $is_reverse++;
        ( $dt1, $dt2 ) = ( $dt2, $dt1 );
    }
    # dt1 == dt2
    # There is nothing to do
    elsif( $cmp == 0 )
    {
        return( '' );
    }
    my $period2val =
    {
    # 00:00  00:00
    midnight => 1,
    # 06:00  12:00
    # or
    # 05:00  10:00
    morning1 => 2,
    # 10:00  12:00
    morning2 => 3,
    # 12:00  12:00
    noon => 4,
    # 12:00  18:00
    # or
    # 12:00  13:00
    afternoon1 => 5,
    # 13:00  18:00
    afternoon2 => 6,
    # 18:00  21:00
    # or
    # 16:00  18:00
    evening1 => 7,
    # 18:00  21:00
    evening2 => 8,
    # 21:00  06:00
    # or
    # 19:00  23:00
    night1 => 9,
    # 23:00  04:00
    night2 => 10,
    };
    my $greatest_diff;
    my $tokens = {};
    # Seconds are not used in CLDR as the greatest difference between two datetimes, but we want to know so we can issue a proper warning if we failed to find it.
    my $seconds_are_different = 0;
    my $era1 = $dt1->year < 0 ? 0 : 1;
    my $era2 = $dt2->year < 0 ? 0 : 1;
    $tokens->{G} = ( $era1 == $era2 ? 0 : 1 );
    if( $tokens->{G} == 0 )
    {
        $tokens->{'y'} = $dt2->year - $dt1->year;
        if( $tokens->{'y'} == 0 )
        {
            $tokens->{M} = $dt2->month - $dt1->month;
            if( $tokens->{M} == 0 )
            {
                $tokens->{d} = $dt2->day - $dt1->day;
                if( $tokens->{d} == 0 )
                {
                    my $ampm1 = ( $dt1->hour < 12 ? 0 : 1 );
                    my $ampm2 = ( $dt2->hour < 12 ? 0 : 1 );
                    if( $ampm1 == $ampm2 )
                    {
                        # Get the day periods for our locale
                        my $locale = $self->{locale} ||
                            die( "The locale ID is gone!" );
                        my $cldr = $self->{_cldr} ||
                            die( "The Locale::Unicode::Data object is gone!" );
                        # my $ref = $cldr->day_periods( locale => $locale ) ||
                        #    return( $self->pass_error( $cldr->error ) );
                        my $ref = $self->day_periods || return( $self->pass_error );
                        my $period_token1 = $self->_find_day_period( $dt1, day_periods => $ref );
                        my $period_token2 = $self->_find_day_period( $dt2, day_periods => $ref );
                        my $period1 = $period2val->{ $period_token1 };
                        my $period2 = $period2val->{ $period_token2 };

                        if( defined( $period1 ) && defined( $period2 ) )
                        {
                            $tokens->{B} = ( $period1 == $period2 ) ? 0 : 1;
                        }
                        elsif( !defined( $period1 ) )
                        {
                            warn( "Unable to find in which day period the first time '", $dt1->time, "' falls into for locale ${locale}" ) if( warnings::enabled() );
                        }
                        elsif( !defined( $period2 ) )
                        {
                            warn( "Unable to find in which day period the second time '", $dt2->time, "' falls into for locale ${locale}" ) if( warnings::enabled() );
                        }
                        # If either of the period could not be defined, we fallback to null
                        $tokens->{B} //= 0;
                        if( $tokens->{B} == 0 )
                        {
                            $tokens->{h} = ( $dt1->hour == $dt2->hour ) ? 0 : 1;
                            if( $tokens->{h} == 0 )
                            {
                                $tokens->{'m'} = ( $dt1->minute == $dt2->minute ) ? 0 : 1;
                                if( $tokens->{'m'} == 0 )
                                {
                                    $seconds_are_different = ( $dt1->second == $dt2->second ) ? 0 : 1;
                                }
                                # Minute
                                else
                                {
                                    $greatest_diff = 'm';
                                }
                            }
                            # Hour
                            else
                            {
                                $greatest_diff = 'h';
                            }
                        }
                        # Day period
                        else
                        {
                            $greatest_diff = 'B';
                        }
                    }
                    # AM/PN
                    else
                    {
                        $greatest_diff = 'a';
                    }
                }
                # Day
                else
                {
                $greatest_diff = 'd';
                }
            }
            # Month
            else
            {
                $greatest_diff = 'M';
            }
        }
        # Year
        else
        {
            $greatest_diff = 'y';
        }
    }
    # Era
    else
    {
        $greatest_diff = 'G';
    }
    
    if( !defined( $greatest_diff ) )
    {
        warn( "First datetime ", ( $is_reverse ? $dt2->iso8601 : $dt1->iso8601 ), " and second datetime ", ( $is_reverse ? $dt1->iso8601 : $dt2->iso8601 ), " are not the same, but I could not find their greatest difference." ) if( !$seconds_are_different && warnings::enabled() );
        return( '' );
    }
    return( $greatest_diff );
}

# <https://en.wikipedia.org/wiki/Daylight_saving_time_by_country>
sub is_dst
{
    my $self = shift( @_ );
    my $dt = shift( @_ ) ||
        return( $self->error( "No DateTime object was provided." ) );
    if( !Scalar::Util::blessed( $dt // '' ) ||
        !$dt->isa( 'DateTime' ) )
    {
        return( $self->error( "Object provided (", overload::StrVal( $dt ), " is not a DateTime object." ) )
    }
    my $timezone = eval
    {
        $dt->time_zone->name;
    };
    $timezone = $self->timezone_canonical( $timezone );
    return( $self->pass_error ) if( !defined( $timezone ) );
    return( "Unknown time zone '${timezone}'" ) if( !$timezone );
    local $@;
    # try-catch
    eval
    {
        require DateTime;
    };
    if( $@ )
    {
        return( $self->error( "Unable to load the DateTime object: $@" ) );
    }
    my $year = $dt->year;
    my $jan = eval
    {
        DateTime->new( year => $year, month => 1, day => 1, time_zone => $dt->time_zone )->offset;
    };
    return( $self->error( "Unable to get the time zone offset for '${timezone}' at ${year}/1/1: $@" ) ) if( $@ );
    my $jul = eval
    {
        DateTime->new( year => $year, month => 7, day => 1, time_zone => $dt->time_zone )->offset;
    };
    return( $self->error( "Unable to get the time zone offset for '${timezone}' at ${year}/7/1: $@" ) ) if( $@ );
    my $offset = eval
    {
        $dt->offset;
    };
    return( $self->error( "Error getting the offset to GMT for time zone ${timezone} at ${year}/1/1: $@" ) ) if( $@ );
    my $bool = ( ( ( $jan != $jul ) && ( $jul == $offset ) ) ? 1 : 0 );
    return( $bool );
}

# Is the locale left-to-right writing?
sub is_ltr
{
    my $self = shift( @_ );
    my $bool;
    unless( defined( $bool = $self->{is_ltr} ) )
    {
        my $locale = $self->{locale} ||
            return( $self->error( "No locale is set!" ) );
        $locale = $self->_locale_object( $locale ) ||
            return( $self->pass_error );
        my $cldr = $self->{_cldr} ||
            return( $self->error( "Unable to get the Locale::Unicode::Data object!" ) );
        my $tree = $cldr->make_inheritance_tree( $locale ) ||
            return( $self->pass_error( $cldr->error ) );
        foreach my $loc ( @$tree )
        {
            my $ref = $cldr->locales_info(
                locale => $loc,
                property => 'char_orientation',
            );
            return( $self->pass_error( $cldr->error ) ) if( !defined( $ref ) && $cldr->error );
            if( $ref && $ref->{value} )
            {
                $bool = ( $ref->{value} eq 'right-to-left' ? 1 : 0 );
                last;
            }
        }
        # Nothing was found, so by default this is false
        $bool //= 0;
        $self->{is_ltr} = $bool;
    }
    return( $bool );
}

sub is_rtl { return( !shift->is_ltr ); }

{
    no warnings 'once';
    # NOTE: sub id -> code
    *id = \&code;

    # NOTE: sub language_id -> language_code
    *language_id = \&language_code;

    # NOTE: sub script_id -> script_code
    *script_id = \&script_code;

    # NOTE: sub territory_id -> territory_code
    *territory_id = \&territory_code;

    # NOTE: sub variant_id -> variant_code
    *variant_id = \&variant_code;
}

sub language
{
    my $self = shift( @_ );
    my $str;
    unless( defined( $str = $self->{language} ) )
    {
        my $locale = $self->{locale} ||
            return( $self->error( "No locale is set!" ) );
        $locale = $self->_locale_object( $locale ) ||
            return( $self->pass_error );
        my $lang = ( $locale->language || $locale->language3 );
        my $cldr = $self->{_cldr} ||
            return( $self->error( "Unable to get the Locale::Unicode::Data object!" ) );
        my $ref = $cldr->locale_l10n(
            locale      => 'en',
            locale_id   => $lang,
            alt         => undef,
        );
        if( !$ref )
        {
            if( $cldr->error )
            {
                return( $self->pass_error( $cldr->error ) );
            }
            else
            {
                warn( "No localised language information for locale '${lang}' in English (en) in the Unicode CLDR data (Locale::Unicode::Data)" ) if( warnings::enabled );
                return( $str = $self->{language} = '' );
            }
        }
        if( !defined( $ref->{locale_name} ) ||
            !length( $ref->{locale_name} // '' ) )
        {
            return( $self->error( "Data was found for the language ${lang} in English, but somehow the language value is empty. This is strange. The Locale::Unicode::Data data seems corrupted." ) );
        }
        return( $str = $self->{language} = $ref->{locale_name} );
    }
    return( $str );
}

sub language_code
{
    my $self = shift( @_ );
    my $str;
    unless( defined( $str = $self->{language_code} ) )
    {
        my $locale = $self->{locale} ||
            die( "No locale is set!" );
        $str = $self->{language_code} = ( $locale->language || $locale->language3 );
    }
    return( $str );
}

sub locale { return( shift->{locale} ); }

sub locale_number_system
{
    my $self = shift( @_ );
    my $ref;
    unless( defined( $ref = $self->{locale_number_system} ) )
    {
        my $locale = $self->{locale} ||
            die( "No locale is set!" );
        my $cldr = $self->{_cldr} || die( "The Locale::Unicode::Data object is gone!" );
        my $tree = $cldr->make_inheritance_tree( $locale ) ||
            return( $self->pass_error( $cldr->error ) );
        my $str;
        foreach my $loc ( @$tree )
        {
            my $ref = $cldr->locale_number_system(
                locale => $loc,
            );
            return( $self->pass_error( $cldr->error ) ) if( !defined( $ref ) && $cldr->error );
            if( $ref && $ref->{number_system} )
            {
                $str = $ref->{number_system};
                last;
            }
            # "In locales where the native numbering system is the default, it is assumed that the numbering system "latn" (Western digits 0-9) is always acceptable"
            # <https://unicode.org/reports/tr35/tr35-numbers.html#otherNumberingSystems>
            elsif( $ref->{native} )
            {
                $str = 'latn';
                last;
            }
        }
        if( defined( $str ) )
        {
            my $this = $cldr->number_system( number_system => $str );
            return( $self->pass_error( $cldr->error ) ) if( !defined( $this ) && $cldr->error );
            if( $this )
            {
                $ref = [ $str, $this->{digits} ];
            }
            else
            {
                die( "No digits data found numbering system '${str}' for locale '${locale}' !" );
            }
        }
        $ref //= [];
        $self->{locale_number_system} = $ref;
    }
    return( $ref );
}

sub metazone_daylight_long { return( shift->_metazone_name({
    type        => 'daylight',
    width       => 'long',
}, @_ ) ); }

sub metazone_daylight_short { return( shift->_metazone_name({
    type        => 'daylight',
    width       => 'short',
}, @_ ) ); }

sub metazone_generic_long { return( shift->_metazone_name({
    type        => 'generic',
    width       => 'long',
    location    => 1,
}, @_ ) ); }

sub metazone_generic_short { return( shift->_metazone_name({
    type        => 'generic',
    width       => 'short',
    location    => 1,
}, @_ ) ); }

sub metazone_standard_long { return( shift->_metazone_name({
    type        => 'standard',
    width       => 'long',
}, @_ ) ); }

sub metazone_standard_short { return( shift->_metazone_name({
    type        => 'standard',
    width       => 'short',
}, @_ ) ); }

# NOTE: "if the abbreviated format data for Gregorian does not exist in a language X (in the chain up to root), then it inherits from the wide format data in that same language X."
# <https://unicode.org/reports/tr35/tr35-dates.html#months_days_quarters_eras>
sub month_format_abbreviated { return( shift->_calendar_terms(
    id      => 'month_format_abbreviated',
    type    => 'month',
    context => 'format',
    width   => [qw( abbreviated wide )],
) ); }

sub month_format_narrow { return( shift->_calendar_terms(
    id      => 'month_format_narrow',
    type    => 'month',
    context => 'format',
    width   => [qw( narrow wide )],
) ); }

# NOTE: There is no 'short' format for month, but there is for 'day'

sub month_format_wide { return( shift->_calendar_terms(
    id      => 'month_format_wide',
    type    => 'month',
    context => 'format',
    width   => 'wide',
) ); }

sub month_stand_alone_abbreviated { return( shift->_calendar_terms(
    id      => 'month_stand_alone_abbreviated',
    type    => 'month',
    context => 'stand-alone',
    width   => [qw( abbreviated wide )],
) ); }

sub month_stand_alone_narrow { return( shift->_calendar_terms(
    id      => 'month_stand_alone_narrow',
    type    => 'month',
    context => 'stand-alone',
    width   => [qw( narrow wide )],
) ); }

# NOTE: There is no 'short' stand-alone for month, but there is for 'day'

sub month_stand_alone_wide { return( shift->_calendar_terms(
    id      => 'month_stand_alone_narrow',
    type    => 'month',
    context => 'stand-alone',
    width   => 'wide',
) ); }

sub name
{
    my $self = shift( @_ );
    my $name;
    unless( defined( $name = $self->{name} ) )
    {
        my $locale = $self->{locale} || die( "Locale is not set!" );
        $locale = $self->_locale_object( $locale ) ||
            return( $self->pass_error );
        my $cldr = $self->{_cldr} || die( "The Locale::Unicode::Data object is gone!" );
        # my $lang = $locale->language || $locale->language3;
        # Building an inheritance tree just for locale 'en' is not necessary, but in the future
        # This API should change to allow for localisation locales other than 'en'
        my $tree = $cldr->make_inheritance_tree( $locale ) ||
            return( $self->pass_error( $cldr->error ) );
        # We remove the last entry, which is always 'und'
        # because otherwise, we would get 'Unknown language' when we really want an empty string
        pop( @$tree );
        foreach my $loc ( @$tree )
        {
            my $ref = $cldr->locale_l10n(
                locale_id   => $loc,
                locale      => 'en',
                alt         => undef,
            );
            return( $self->pass_error( $cldr->error ) ) if( !defined( $ref ) && $cldr->error );
            if( $ref && $ref->{locale_name} )
            {
                $name = $ref->{locale_name};
                last;
            }
        }
        $name //= '';
        $self->{name} = $name;
    }
    return( $name );
}

sub native_language
{
    my $self = shift( @_ );
    my $name;
    unless( defined( $name = $self->{native_language} ) )
    {
        my $locale = $self->{locale} || die( "Locale is not set!" );
        $locale = $self->_locale_object( $locale ) ||
            return( $self->pass_error );
        my $cldr = $self->{_cldr} || die( "The Locale::Unicode::Data object is gone!" );
        my $lang = ( $locale->language || $locale->language3 );
        my $tree = $cldr->make_inheritance_tree( $locale ) ||
            return( $self->pass_error( $cldr->error ) );
        # We remove the last entry, which is always 'und'
        # because otherwise, we would get 'Unknown language' when we really want an empty string
        pop( @$tree );
        foreach my $loc ( @$tree )
        {
            my $ref = $cldr->locale_l10n(
                locale_id   => $lang,
                locale      => $loc,
                alt         => undef,
            );
            return( $self->pass_error( $cldr->error ) ) if( !defined( $ref ) && $cldr->error );
            if( $ref && $ref->{locale_name} )
            {
                $name = $ref->{locale_name};
                last;
            }
        }

        if( !defined( $name ) )
        {
            warn( "No localised language information found for locale '${locale}' in the Unicode CLDR data (Locale::Unicode::Data)" ) if( warnings::enabled );
        }
        $name //= '';
        $self->{native_language} = $name;
    }
    return( $name );
}

sub native_name
{
    my $self = shift( @_ );
    my $name;
    unless( defined( $name = $self->{native_name} ) )
    {
        my $locale = $self->{locale} || die( "Locale is not set!" );
        $locale = $self->_locale_object( $locale ) ||
            return( $self->pass_error );
        my $cldr = $self->{_cldr} || die( "The Locale::Unicode::Data object is gone!" );
        my $tree = $cldr->make_inheritance_tree( $locale ) ||
            return( $self->pass_error( $cldr->error ) );
        my $locales = [];
        # We remove the last entry, which is always 'und'
        # because otherwise, we would get 'Unknown language' when we really want an empty string
        pop( @$tree );
        @$locales = @$tree;
        LOCALES: foreach my $l10n ( @$locales )
        {
            foreach my $loc ( @$tree )
            {
                my $ref = $cldr->locale_l10n(
                    locale_id   => $loc,
                    locale      => $l10n,
                    alt         => undef,
                );
                return( $self->pass_error( $cldr->error ) ) if( !defined( $ref ) && $cldr->error );
                if( $ref && $ref->{locale_name} )
                {
                    $name = $ref->{locale_name};
                    last LOCALES;
                }
            }
        }
        $name //= '';
        $self->{native_name} = $name;
    }
    return( $name );
}

sub native_script
{
    my $self = shift( @_ );
    my $name;
    unless( defined( $name = $self->{native_script} ) )
    {
        my $locale = $self->{locale} || die( "Locale is not set!" );
        $locale = $self->_locale_object( $locale ) ||
            return( $self->pass_error );
        if( my $script = $locale->script )
        {
            my $cldr = $self->{_cldr} || die( "The Locale::Unicode::Data object is gone!" );
            my $tree = $cldr->make_inheritance_tree( $locale ) ||
                return( $self->pass_error( $cldr->error ) );
            foreach my $loc ( @$tree )
            {
                my $ref = $cldr->script_l10n(
                    script  => $script,
                    locale  => $loc,
                    alt     => undef,
                );
                return( $self->pass_error( $cldr->error ) ) if( !defined( $ref ) && $cldr->error );
                if( $ref && $ref->{locale_name} )
                {
                    $name = $ref->{locale_name};
                    last;
                }
            }
            $name //= '';
            $self->{native_script} = $name;
        }
    }
    return( $name );
}

sub native_territory
{
    my $self = shift( @_ );
    my $name;
    unless( defined( $name = $self->{native_territory} ) )
    {
        my $locale = $self->{locale} || die( "Locale is not set!" );
        $locale = $self->_locale_object( $locale ) ||
            return( $self->pass_error );
        # Could be either a country code, or a region code
        if( my $territory = $locale->territory )
        {
            my $cldr = $self->{_cldr} || die( "The Locale::Unicode::Data object is gone!" );
            my $tree = $cldr->make_inheritance_tree( $locale ) ||
                return( $self->pass_error( $cldr->error ) );
            foreach my $loc ( @$tree )
            {
                my $ref = $cldr->territory_l10n(
                    territory   => $territory,
                    locale      => $loc,
                    alt         => undef,
                );
                return( $self->pass_error( $cldr->error ) ) if( !defined( $ref ) && $cldr->error );
                if( $ref && $ref->{locale_name} )
                {
                    $name = $ref->{locale_name};
                    last;
                }
            }
            $name //= '';
            $self->{native_territory} = $name;
        }
    }
    return( $name );
}

sub native_variant
{
    my $self = shift( @_ );
    my $name;
    unless( defined( $name = $self->{native_variant} ) )
    {
        my $locale = $self->{locale} || die( "Locale is not set!" );
        $locale = $self->_locale_object( $locale ) ||
            return( $self->pass_error );
        my $variants;
        if( ( $variants = $locale->variants ) &&
            scalar( @$variants ) )
        {
            my $variant = $variants->[0];
            my $cldr = $self->{_cldr} || die( "The Locale::Unicode::Data object is gone!" );
            my $tree = $cldr->make_inheritance_tree( $locale ) ||
                return( $self->pass_error( $cldr->error ) );
            foreach my $loc ( @$tree )
            {
                my $ref = $cldr->variant_l10n(
                    variant => $variant,
                    locale  => $loc,
                    alt     => undef,
                );
                return( $self->pass_error( $cldr->error ) ) if( !defined( $ref ) && $cldr->error );
                if( $ref && $ref->{locale_name} )
                {
                    $name = $ref->{locale_name};
                    last;
                }
            }
            $name //= '';
            $self->{native_variant} = $name;
        }
    }
    return( $name );
}

sub native_variants
{
    my $self = shift( @_ );
    my $names;
    unless( defined( $names = $self->{native_variants} ) )
    {
        $names = [];
        my $locale = $self->{locale} || die( "Locale is not set!" );
        $locale = $self->_locale_object( $locale ) ||
            return( $self->pass_error );
        my $variants;
        if( ( $variants = $locale->variants ) &&
            scalar( @$variants ) )
        {
            my $cldr = $self->{_cldr} || die( "The Locale::Unicode::Data object is gone!" );
            my $tree = $cldr->make_inheritance_tree( $locale ) ||
                return( $self->pass_error( $cldr->error ) );
            VARIANT: foreach my $variant ( @$variants )
            {
                my $found = 0;
                foreach my $loc ( @$tree )
                {
                    my $ref = $cldr->variant_l10n(
                        variant => $variant,
                        locale  => $loc,
                        alt     => undef,
                    );
                    return( $self->pass_error( $cldr->error ) ) if( !defined( $ref ) && $cldr->error );
                    if( $ref && $ref->{locale_name} )
                    {
                        push( @$names, $ref->{locale_name} );
                        $found++;
                        next VARIANT;
                    }
                }
                push( @$names, '' ) unless( $found );
            }
            $self->{native_variants} = $names;
        }
    }
    return( $names );
}

sub pass_error
{
    my $self = shift( @_ );
    if( Want::want( 'OBJECT' ) )
    {
        rreturn( DateTime::Locale::FromCLDR::NullObject->new );
    }
    return;
}

sub prefers_24_hour_time
{
    my $self = shift( @_ );
    my $bool;
    unless( defined( $bool = $self->{prefers_24_hour_time} ) )
    {
        my $pat = $self->time_format_short;
        my @parts = split( /(?:'(?:(?:[^']|'')*)')/, $pat );
        $bool = $self->{prefers_24_hour_time} = scalar( grep( /h|K/, @parts ) ) ? 0 : 1;
    }
    return( $bool );
}

sub quarter_format_abbreviated { return( shift->_calendar_terms(
    id      => 'quarter_format_abbreviated',
    type    => 'quarter',
    context => [qw( format stand-alone )],
    width   => [qw( abbreviated wide )],
) ); }

sub quarter_format_narrow { return( shift->_calendar_terms(
    id      => 'quarter_format_narrow',
    type    => 'quarter',
    context => [qw( format stand-alone )],
    width   => [qw( narrow wide )],
) ); }

# NOTE: There is no 'short' format for quarter, but there is for 'day'

sub quarter_format_wide { return( shift->_calendar_terms(
    id      => 'quarter_format_wide',
    type    => 'quarter',
    context => [qw( format stand-alone )],
    width   => 'wide',
) ); }

sub quarter_stand_alone_abbreviated { return( shift->_calendar_terms(
    id      => 'quarter_stand_alone_abbreviated',
    type    => 'quarter',
    context => [qw( stand-alone format )],
    width   => [qw( abbreviated wide )],
) ); }

sub quarter_stand_alone_narrow { return( shift->_calendar_terms(
    id      => 'quarter_stand_alone_narrow',
    type    => 'quarter',
    context => [qw( stand-alone format )],
    width   => [qw( narrow abbreviated wide )],
) ); }

# NOTE: There is no 'short' stand-alone for quarter, but there is for 'day'

sub quarter_stand_alone_wide { return( shift->_calendar_terms(
    id      => 'quarter_stand_alone_narrow',
    type    => 'quarter',
    context => [qw( stand-alone format )],
    width   => 'wide',
) ); }

sub script
{
    my $self = shift( @_ );
    my $name;
    unless( defined( $name = $self->{script} ) )
    {
        my $locale = $self->{locale} || die( "Locale is not set!" );
        $locale = $self->_locale_object( $locale ) ||
            return( $self->pass_error );
        if( my $script = $locale->script )
        {
            my $cldr = $self->{_cldr} || die( "The Locale::Unicode::Data object is gone!" );
            # Building an inheritance tree just for locale 'en' is not necessary, but in the future
            # This API should change to allow for localisation locales other than 'en'
            my $tree = $cldr->make_inheritance_tree( 'en' ) ||
                return( $self->pass_error( $cldr->error ) );
            foreach my $loc ( @$tree )
            {
                my $ref = $cldr->script_l10n(
                    script  => $script,
                    locale  => $loc,
                    alt     => undef,
                );
                return( $self->pass_error( $cldr->error ) ) if( !defined( $ref ) && $cldr->error );
                if( $ref && $ref->{locale_name} )
                {
                    $name = $ref->{locale_name};
                    last;
                }
            }
            $name //= '';
            $self->{script} = $name;
        }
    }
    return( $name );
}

sub script_code
{
    my $self = shift( @_ );
    my $str;
    unless( defined( $str = $self->{script_code} ) )
    {
        my $locale = $self->{locale} ||
            die( "No locale is set!" );
        $str = $self->{script_code} = $locale->script;
    }
    return( $str );
}

sub territory
{
    my $self = shift( @_ );
    my $name;
    unless( defined( $name = $self->{territory} ) )
    {
        my $locale = $self->{locale} || die( "Locale is not set!" );
        $locale = $self->_locale_object( $locale ) ||
            return( $self->pass_error );
        # Could be either a country code, or a region code
        if( my $territory = $locale->territory )
        {
            my $cldr = $self->{_cldr} || die( "The Locale::Unicode::Data object is gone!" );
            # Building an inheritance tree just for locale 'en' is not necessary, but in the future
            # This API should change to allow for localisation locales other than 'en'
            my $tree = $cldr->make_inheritance_tree( 'en' ) ||
                return( $self->pass_error( $cldr->error ) );
            foreach my $loc ( @$tree )
            {
                my $ref = $cldr->territory_l10n(
                    territory   => $territory,
                    locale      => $loc,
                    alt         => undef,
                );
                return( $self->pass_error( $cldr->error ) ) if( !defined( $ref ) && $cldr->error );
                if( $ref && $ref->{locale_name} )
                {
                    $name = $ref->{locale_name};
                    last;
                }
            }
            $name //= '';
            $self->{territory} = $name;
        }
    }
    return( $name );
}

sub territory_code
{
    my $self = shift( @_ );
    my $str;
    unless( defined( $str = $self->{territory_code} ) )
    {
        my $locale = $self->{locale} ||
            die( "No locale is set!" );
        $str = $self->{territory_code} = $locale->territory;
    }
    return( $str );
}

sub time_format_allowed { return( shift->_time_formats( 'allowed', @_ ) ); }

sub time_format_default { return( shift->time_format_medium ); }

sub time_format_full { return( shift->_date_time_format(
    calendar    => 'gregorian',
    type        => 'time',
    width       => 'full',
) ); }

sub time_format_long { return( shift->_date_time_format(
    calendar    => 'gregorian',
    type        => 'time',
    width       => 'long',
) ); }

sub time_format_medium { return( shift->_date_time_format(
    calendar    => 'gregorian',
    type        => 'time',
    width       => 'medium',
) ); }

sub time_format_preferred { return( shift->_time_formats( 'preferred', @_ ) ); }

sub time_format_short { return( shift->_date_time_format(
    calendar    => 'gregorian',
    type        => 'time',
    width       => 'short',
) ); }

sub time_formats
{
    my $self = shift( @_ );
    my $formats = {};
    foreach my $t ( qw( full long medium short ) )
    {
        my $code;
        unless( $code = $self->can( "time_format_${t}" ) )
        {
            die( "The method time_format_${t} is not defined in class ", ( ref( $self ) || $self ) );
        }
        $formats->{ $t } = $code->( $self );
    }
    return( $formats );
}

sub timezone_canonical
{
    my $self = shift( @_ );
    my $tz = shift( @_ ) ||
        return( $self->error( "No timezone was provided." ) );
    my $cldr = $self->{_cldr} || die( "Locale::Unicode::Data object is gone!" );
    my $str = $cldr->timezone_canonical( $tz );
    return( $self->pass_error( $cldr->error ) ) if( !defined( $str ) && $cldr->error );
    return( $str );
}

sub timezone_city
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $timezone = $opts->{timezone} ||
        return( $self->error( "No timezone was provided to get the examplar city." ) );
    my $meth_id = 'timezone_city_for_tz_' . $timezone;
    my $name;
    unless( defined( $name = $self->{ $meth_id } ) )
    {
        my $locale = $self->{locale} || die( "Locale value is gone!" );
        my $cldr = $self->{_cldr} || die( "Locale::Unicode::Data object is gone!" );
        my $locales = $cldr->make_inheritance_tree( $locale ) ||
            return( $self->pass_error( $cldr->error ) );
        my $ref;
        LOCALE: foreach my $loc ( @$locales )
        {
            $ref = $cldr->timezone_city(
                timezone    => $timezone,
                locale      => $loc,
            );
            return( $self->pass_error ) if( !defined( $ref ) && $cldr->error );
            if( $ref )
            {
                $name = $ref->{city};
                last LOCALE;
            }
        }
        # Failed to find a suitable match
        $name //= '';
        $self->{ $meth_id } = $name;
    }
    return( $self->{ $meth_id } );
}

sub timezone_daylight_long { return( shift->_timezone_name({
    type        => 'daylight',
    width       => 'long',
}, @_ ) ); }

sub timezone_daylight_short { return( shift->_timezone_name({
    type        => 'daylight',
    width       => 'short',
}, @_ ) ); }

sub timezone_format_fallback { return( shift->_timezone_formats(
    type => 'fallback',
) ); }

sub timezone_format_gmt { return( shift->_timezone_formats(
    type => 'gmt',
) ); }

sub timezone_format_gmt_zero { return( shift->_timezone_formats(
    type => 'gmt_zero',
) ); }

sub timezone_format_hour { return( shift->_timezone_formats(
    type => 'hour',
) ); }

sub timezone_format_region { return( shift->_timezone_formats(
    type => 'region',
) ); }

sub timezone_format_region_daylight { return( shift->_timezone_formats(
    type => 'region',
    subtype => 'daylight',
) ); }

sub timezone_format_region_standard { return( shift->_timezone_formats(
    type => 'region',
    subtype => 'standard',
) ); }

sub timezone_generic_long { return( shift->_timezone_name({
    type        => 'generic',
    width       => 'long',
    location    => 1,
}, @_ ) ); }

sub timezone_generic_short { return( shift->_timezone_name({
    type        => 'generic',
    width       => 'short',
    location    => 1,
}, @_ ) ); }

# Returns the BCP47 short ID
sub timezone_id
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $tz   = $opts->{timezone} ||
        return( $self->error( "No time zone was provided to get its short ID." ) );
    $tz = $self->timezone_canonical( $tz );
    return( $self->pass_error ) if( !defined( $tz ) && $self->error );
    return( $self->error( "Unable to get the canonical time zone for '$opts->{timezone}'" ) ) if( !length( $tz // '' ) );
    my $cldr = $self->{_cldr} || die( "The Locale::Unicode::Data object is gone!" );
#     my $locale = $self->{locale} || die( "Locale is not set!" );
#     $locale = $self->_locale_object( $locale ) ||
#         return( $self->pass_error );
    my $ref = $cldr->timezone( timezone => $tz );
    return( $self->pass_error( $cldr->error ) ) if( !defined( $ref ) && $cldr->error );
    return( $self->error( "No time zone '${tz}' exists." ) ) if( !$ref );
    if( $ref && $ref->{tz_bcpid} )
    {
        return( $ref->{tz_bcpid} );
    }
    else
    {
        return( $self->error( "Time zone '${tz}' could be found, but not its ID. This should not happen. Maybe there is an issue with the Locale::Unicode::Data database?" ) );
    }
}

sub timezone_standard_long { return( shift->_timezone_name({
    type        => 'standard',
    width       => 'long',
}, @_ ) ); }

sub timezone_standard_short { return( shift->_timezone_name({
    type        => 'standard',
    width       => 'short',
}, @_ ) ); }

sub variant
{
    my $self = shift( @_ );
    my $name;
    unless( defined( $name = $self->{variant} ) )
    {
        my $locale = $self->{locale} || die( "Locale is not set!" );
        $locale = $self->_locale_object( $locale ) ||
            return( $self->pass_error );
        if( my $variant = $locale->variant )
        {
            my $cldr = $self->{_cldr} || die( "The Locale::Unicode::Data object is gone!" );
            # Building an inheritance tree just for locale 'en' is not necessary, but in the future
            # This API should change to allow for localisation locales other than 'en'
            my $tree = $cldr->make_inheritance_tree( 'en' ) ||
                return( $self->pass_error( $cldr->error ) );
            foreach my $loc ( @$tree )
            {
                my $ref = $cldr->variant_l10n(
                    variant => $variant,
                    locale  => $loc,
                    alt     => undef,
                );
                return( $self->pass_error( $cldr->error ) ) if( !defined( $ref ) && $cldr->error );
                if( $ref && $ref->{locale_name} )
                {
                    $name = $ref->{locale_name};
                    last;
                }
            }
            $name //= '';
            $self->{variant} = $name;
        }
    }
    return( $name );
}

sub variant_code
{
    my $self = shift( @_ );
    my $str;
    unless( defined( $str = $self->{variant_code} ) )
    {
        my $locale = $self->{locale} ||
            die( "No locale is set!" );
        $str = $self->{variant_code} = $locale->variant;
    }
    return( $str );
}

sub variants
{
    my $self = shift( @_ );
    my $ref;
    unless( defined( $ref = $self->{variants} ) )
    {
        my $locale = $self->{locale} ||
            die( "No locale is set!" );
        $ref = $self->{variants} = $locale->variants;
    }
    return( $ref );
}

sub version
{
    my $self = shift( @_ );
    my $vers;
    unless( defined( $vers = $self->{version} ) )
    {
        my $cldr = $self->{_cldr} || die( "Locale::Unicode::Data object is gone!" );
        $vers = $cldr->cldr_version;
    }
    return( $vers );
}

sub _am_pm
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    if( !$opts->{context} )
    {
        die( "No context was provided to retrieve AM/PN localised terms." );
    }
    elsif( !$opts->{width} )
    {
        die( "No width was provided to retrieve AM/PN localised terms." );
    }
    my $calendar = $opts->{calendar} || $self->{calendar} || 'gregorian';
    my $meth_id = 'am_pm_' . $calendar . '_' . $opts->{width} . '_' . $opts->{context};
    my $ampm;
    unless( defined( $ampm = $self->{ $meth_id } ) )
    {
        my $locale = $self->{locale} || die( "Locale value is gone!" );
        my $cldr = $self->{_cldr} || die( "The Locale::Unicode::Data object is gone!" );
        my $tree = $cldr->make_inheritance_tree( $locale ) ||
            return( $self->pass_error( $cldr->error ) );
        # We do not want to fallback to the 'und' locale on this.
        pop( @$tree );
        my $widths = ref( $opts->{width} ) eq 'ARRAY' ? $opts->{width} : [$opts->{width}];
        my $contexts = ref( $opts->{context} ) eq 'ARRAY' ? $opts->{context} : [$opts->{context}];
        $ampm = [];
        LOCALES: foreach my $loc ( @$tree )
        {
            foreach my $context ( @$contexts )
            {
                foreach my $width ( @$widths )
                {
                    my $all = $cldr->calendar_term(
                        locale          => $loc,
                        calendar        => $calendar,
                        term_context    => $context,
                        term_width      => $width,
                        term_name       => [qw( am pm )],
                    );
                    return( $self->pass_error ) if( !defined( $all ) );
                    if( scalar( @$all ) )
                    {
                        if( scalar( @$all ) != 2 )
                        {
                            return( $self->error( "Data seems to be corrupted for locale ${loc} in Locale::Unicode::Data. I received ", scalar( @$all ), " sets of data when I expected 2." ) );
                        }
                        @$ampm = map( $_->{term_value}, @$all );
                        last LOCALES;
                    }
                }
            }
        }
        return( $self->{ $meth_id } = $ampm );
    }
    return( $ampm );
}

sub _available_formats
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    if( !$opts->{id} )
    {
        die( "No format ID specified." );
    }
    return( $self->error( "No format ID was provided" ) ) if( !length( $opts->{id} // '' ) );
    my $calendar = $opts->{calendar} || $self->{calendar} || 'gregorian';
    my $meth_id = 'available_formats_' . $calendar . '_' . $opts->{id};
    my $pattern;
    unless( defined( $pattern = $self->{ $meth_id } ) )
    {
        my $locale = $self->{locale} || die( "Locale value is gone!" );
        my $cldr = $self->{_cldr} || die( "Locale::Unicode::Data object is gone!" );
        my $tree = $cldr->make_inheritance_tree( $locale ) ||
            return( $self->pass_error( $cldr->error ) );
        my $ref;
        LOCALE: foreach my $loc ( @$tree )
        {
            $ref = $cldr->calendar_available_format(
                locale      => $loc,
                calendar    => $calendar,
                format_id   => $opts->{id},
                count       => [undef, qw( few many one other two zero)],
            );
            return( $self->pass_error ) if( !defined( $ref ) && $cldr->error );
            if( $ref && $ref->{format_pattern} )
            {
                $pattern = $ref->{format_pattern};
                last LOCALE;
            }
        }
        $self->{ $meth_id } = $pattern;
    }
    return( $pattern );
}

sub _calendar_eras
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $id   = $opts->{id} || die( "Missing ID" );
    my $calendar = $opts->{calendar} || $self->{calendar} || 'gregorian';
    die( "Missing width" ) if( !$opts->{width} );
    die( "Missing alt" ) if( !exists( $opts->{width} ) );
    $opts->{width} = [$opts->{width}] unless( ref( $opts->{width} ) eq 'ARRAY' );
    my $eras;
    unless( defined( $eras = $self->{ "${id}_${calendar}" } ) )
    {
        my $locale = $self->{locale} || die( "Locale value is gone!" );
        my $cldr = $self->{_cldr} || die( "Locale::Unicode::Data object is gone!" );
        my $tree = $cldr->make_inheritance_tree( $locale ) ||
            return( $self->pass_error( $cldr->error ) );
        $eras = [];
        LOCALE: foreach my $loc ( @$tree )
        {
            foreach my $width ( @{$opts->{width}} )
            {
                my $all = $cldr->calendar_eras_l10n(
                    locale          => $loc,
                    calendar        => $calendar,
                    era_width       => $width,
                    ( exists( $opts->{alt} ) ? ( alt => $opts->{alt} ) : () ),
                    order => [era_id => 'integer'],
                );
                return( $self->pass_error( $cldr->error ) ) if( !defined( $all ) && $cldr->error );
                if( $all && scalar( @$all ) )
                {
                    @$eras = map( $_->{locale_name}, @$all );
                    last LOCALE;
                }
            }
        }
        $self->{ $id } = $eras;
    }
    return( $eras );
}

sub _calendar_terms
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $id   = $opts->{id} || die( "Missing ID" );
    my $calendar = $opts->{calendar} || $self->{calendar} || 'gregorian';
    die( "Missing type" ) if( !$opts->{type} );
    die( "Missing context" ) if( !$opts->{context} );
    die( "Missing width" ) if( !$opts->{width} );
    $opts->{width} = [$opts->{width}] unless( ref( $opts->{width} ) eq 'ARRAY' );
    # If some type (e.g. short, narrow, etc) are missing in 'format', we can try to look for it in 'stand-alone'
    $opts->{context} = [$opts->{context}] unless( ref( $opts->{context} ) eq 'ARRAY' );
    my $terms;
    unless( defined( $terms = $self->{ "${id}_${calendar}" } ) )
    {
        my $locale = $self->{locale} || die( "Locale value is gone!" );
        my $cldr = $self->{_cldr} || die( "Locale::Unicode::Data object is gone!" );
        my $locales = $cldr->make_inheritance_tree( $locale ) ||
            return( $self->pass_error( $cldr->error ) );
        my $expects =
        {
            day => 7,
            month => 12,
            quarter => 4,
        };
        LOCALE: foreach my $loc ( @$locales )
        {
            foreach my $ctx ( @{$opts->{context}} )
            {
                foreach my $width ( @{$opts->{width}} )
                {
                    my $all = $cldr->calendar_terms(
                        locale          => $loc,
                        calendar        => $calendar,
                        term_type       => $opts->{type},
                        term_context    => $ctx,
                        term_width      => $width,
                        ( $opts->{type} eq 'day' ? ( order_by_value => [term_name => [qw( mon tue wed thu fri sat sun )]] ) : () ),
                        ( ( $opts->{type} eq 'month' || $opts->{type} eq 'quarter' ) ? ( order => [term_name => 'integer'] ) : () ),
                    );
                    return( $self->pass_error ) if( !defined( $all ) && $cldr->error );
                    if( $all && scalar( @$all ) >= $expects->{ $opts->{type} } )
                    {
                        $terms = [];
                        for( @$all )
                        {
                            push( @$terms, $_->{term_value} );
                        }
                        last LOCALE;
                    }
                }
            }
        }
        # We make it NOT undef, so we do not go through this again, in the unlikely event nothing was found.
        $terms = [] if( !defined( $terms ) );
        $self->{ $id } = $terms;
    }
    return( $terms );
}

# This is the date or time format with CLDR patterns
sub _date_time_format
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    if( !$opts->{width} )
    {
        die( "No date format width specified." );
    }
    elsif( !$opts->{type} )
    {
        die( "No type provided. Please specify either 'date' or 'time'" );
    }
    elsif( $opts->{type} ne 'date' &&
           $opts->{type} ne 'time' )
    {
        die( "Invalid type provided. Please specify either 'date' or 'time'" );
    }
    my $widths = ref( $opts->{width} ) eq 'ARRAY' ? $opts->{width} : [$opts->{width}];
    my $calendar = $opts->{calendar} || $self->{calendar} || 'gregorian';
    my $meth_id = $opts->{type} . '_format_' . $calendar . '_' . $widths->[0];
    my $pattern;
    unless( defined( $pattern = $self->{ $meth_id } ) )
    {
        my $locale = $self->{locale} || die( "Locale value is gone!" );
        my $cldr = $self->{_cldr} || die( "Locale::Unicode::Data object is gone!" );
        my $locales = $cldr->make_inheritance_tree( $locale ) ||
            return( $self->pass_error( $cldr->error ) );
        my $ref;
        LOCALE: foreach my $loc ( @$locales )
        {
            foreach my $width ( @$widths )
            {
                $ref = $cldr->calendar_format_l10n(
                    locale          => $loc,
                    calendar        => $calendar,
                    format_type     => $opts->{type},
                    format_length   => $width,
                );
                return( $self->pass_error ) if( !defined( $ref ) && $cldr->error );
                if( $ref && $ref->{format_pattern} )
                {
                    $pattern = $ref->{format_pattern};
                    last LOCALE;
                }
            }
        }
        # We default to empty string, so we do not recompute it if this locale has no data (should not happen though);
        $pattern //= '';
        $self->{ $meth_id } = $pattern;
    }
    return( $pattern );
}

# This is the datetime, i.e. date and time formatting, such as {1}, {0}
sub _datetime_format
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    if( !$opts->{width} )
    {
        die( "No date format width specified." );
    }
    elsif( ref( $opts->{width} ) && !overload::Method( $opts->{width}, '""' ) )
    {
        die( "The 'width' parameter provided is a reference (", ref( $opts->{width} ), ", but it is not stringifyable." );
    }
    elsif( !$opts->{type} )
    {
        die( "No type provided. Please specify either 'atTime' or 'standard'" );
    }
    elsif( $opts->{type} ne 'atTime' &&
           $opts->{type} ne 'standard' )
    {
        die( "Invalid type provided. Please specify either 'atTime' or 'standard'" );
    }
    my $calendar = $opts->{calendar} || $self->{calendar} || 'gregorian';
    my $meth_id = "datetime_format_" . $calendar . '_' . $opts->{width} . '_' . $opts->{type};
    my $pattern;
    unless( defined( $pattern = $self->{ $meth_id } ) )
    {
        my $locale = $self->{locale} || die( "Locale value is gone!" );
        my $cldr = $self->{_cldr} || die( "Locale::Unicode::Data object is gone!" );
        my $locales = $cldr->make_inheritance_tree( $locale ) ||
            return( $self->pass_error( $cldr->error ) );
        my $ref;
        LOCALE: foreach my $loc ( @$locales )
        {
            $ref = $cldr->calendar_datetime_format(
                locale          => $loc,
                calendar        => $calendar,
                format_type     => $opts->{type},
                format_length   => $opts->{width},
            );
            return( $self->pass_error ) if( !defined( $ref ) && $cldr->error );
            if( $ref && $ref->{format_pattern} )
            {
                $pattern = $ref->{format_pattern};
                last LOCALE;
            }
        }
        # We default to empty string, so we do not recompute it if this locale has no data (should not happen though);
        $pattern //= '';
        if( length( $pattern ) )
        {
            my $pats = {};
            foreach my $t ( qw( date time ) )
            {
                my $meth = $t . '_format_' . $opts->{width};
                my $code;
                unless( $code = $self->can( $meth ) )
                {
                    die( "Something is wrong. Unable to find the method ${meth} in our object class ", ( ref( $self ) || $self ) );
                }
                $pats->{ $t } = $code->( $self );
                return( $self->pass_error ) if( !defined( $pats->{ $t } ) && $self->error );
            }
            $pattern =~ s/\{0\}/$pats->{time}/g;
            $pattern =~ s/\{1\}/$pats->{date}/g;
        }
        $self->{ $meth_id } = $pattern;
    }
    return( $pattern );
}

sub _day_period
{
    my $self = shift( @_ );
    my $def = shift( @_ );
    my $dt = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $period = $self->_find_day_period( $dt ) ||
        return( $self->pass_error );
    my $locale = $self->{locale} ||
        return( $self->error( "The local value is gone!" ) );
    my $cldr = $self->{_cldr} ||
        return( $self->error( "The Locale::Unicode::Data object is gone!" ) );
    my $calendar = $opts->{calendar} || $self->{calendar} || 'gregorian';
    die( "No 'context' argument was provided." ) if( !exists( $def->{context} ) );
    die( "No 'width' argument was provided." ) if( !exists( $def->{width} ) );
    my $width = ref( $def->{width} ) eq 'ARRAY' ? $def->{width} : [$def->{width}];
    my $tree = $cldr->make_inheritance_tree( $locale ) ||
        return( $self->pass_error( $cldr->error ) );
    my $name;
    LOCALE: foreach my $loc ( @$tree )
    {
        foreach my $width ( @$width )
        {
            my $ref = $cldr->calendar_term(
                locale => $loc,
                calendar => $calendar,
                term_context => $def->{context},
                term_width => $width,
                term_name => $period,
            );
            if( !defined( $ref ) && $cldr->error )
            {
                return( $self->pass_error( $cldr->error ) );
            }
            if( $ref )
            {
                $name = $ref->{term_value};
                last LOCALE;
            }
        }
    }
    # LDML: "If the locale doesn't have the notion of a unique "noon" = 12:00, then the PM form may be substituted. Similarly for "midnight" = 00:00 and the AM form"
    if( !defined( $name ) &&
        ( $period eq 'noon' || $period eq 'midnight' ) )
    {
        my $ampm = $self->am_pm_format_abbreviated;
        if( defined( $ampm ) && 
            ref( $ampm ) eq 'ARRAY' && 
            scalar( @$ampm ) )
        {
            if( $period eq 'midnight' )
            {
                $name = $ampm->[0];
            }
            elsif( $period eq 'noon' )
            {
                $name = $ampm->[1];
            }
        }
    }
    $name //= '';
    return( $name );
}

sub _find_day_period
{
    my $self = shift( @_ );
    my $dt = shift( @_ ) ||
        return( $self->error( "No DateTime object was provided." ) );
    unless( Scalar::Util::blessed( $dt ) &&
            $dt->isa( 'DateTime' ) )
    {
        return( $self->error( "The DateTime object provided (", overload::StrVal( $dt ), ") is actually not a DateTime object." ) );
    }
    my $opts = $self->_get_args_as_hash( @_ );

    my $locale = $self->{locale} ||
        die( "The locale ID is gone!" );
    my $cldr = $self->{_cldr} ||
        die( "The Locale::Unicode::Data object is gone!" );
    my $ref;
    # So we can provide a cached data and avoid making useless queries
    unless( $ref = $opts->{day_periods} && 
            ref( $ref // '' ) eq 'HASH' )
    {
        $ref = $self->day_periods || return( $self->pass_error );
    }
    my $period2val =
    {
    # 06:00  12:00
    # or
    # 05:00  10:00
    morning1 => 1,
    # 10:00  12:00
    morning2 => 2,
    # 12:00  18:00
    # or
    # 12:00  13:00
    afternoon1 => 3,
    # 13:00  18:00
    afternoon2 => 4,
    # 18:00  21:00
    # or
    # 16:00  18:00
    evening1 => 5,
    # 18:00  21:00
    evening2 => 6,
    # 21:00  06:00
    # or
    # 19:00  23:00
    night1 => 7,
    # 23:00  04:00
    night2 => 8,
    # midnight and noon have higher score, because they are an exact match
    # 00:00  00:00
    midnight => 9,
    # 12:00  12:00
    noon => 10,
    };
    my $greatest_diff;
    # Check the period of the day
    my( $score, $period );
    my $epoch = $dt->epoch;
    foreach my $token ( keys( %$ref ) )
    {
        my @time_start = split( ':', $ref->{ $token }->[0], 2 );
        my @time_end = split( ':', $ref->{ $token }->[1], 2 );
        my( $start, $end );
        eval
        {
            $start = $dt->clone;
            $end = $dt->clone;
            if( $time_start[0] == 24 )
            {
                $start->set_hour(0);
                $start->add( days => 1 );
            }
            else
            {
                $start->set_hour( $time_start[0] );
            }
            $start->set_minute( $time_start[1] );
            $start->set_second(0);
            # $end->set_hour( $time_end[0] == 24 ? 0 : $time_end[0] );
            if( $time_end[0] == 24 )
            {
                $end->set_hour(0);
                $end->add( days => 1 );
            }
            else
            {
                $end->set_hour( $time_end[0] );
            }
            $end->set_minute( $time_end[1] );
            $end->set_second(0);
            if( $time_end[0] < $time_start[0] )
            {
                # e.g.: 22:00 to 06:00
                # Our time is in the morning, so our first test time must be the day before
                # The start time is in the previous day
                if( $dt->hour < 12 )
                {
                    $start->subtract( days => 1 );
                }
                else
                {
                    $end->add( days => 1 );
                }
            }
        };
        if( $@ )
        {
            return( $self->error( "Error preparing a clone of the DateTime object for a start or end time for day period token '${token}' value '", join( ', ', @{$ref->{ $token }} ), "': $@" ) );
        }
        # We die, because this is an internal error, not a user error
        my $token_val = $period2val->{ $token } ||
            die( "Unknown token \"${token}\"!" );
        if( ( !defined( $score ) ||
              ( defined( $score ) && $score < $token_val )
            ) &&
            $epoch >= $start->epoch &&
            $epoch <= $end->epoch )
        {
            $score = $token_val;
            $period = $token;
        }
    }
    return( $period );
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

sub _get_locale_info
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $ref;
    my $locale = $opts->{locale} ||
        return( $self->error( "No locale provided to get its country information." ) );
    my $cldr = $self->{_cldr} || die( "Locale::Unicode::Data object is gone!" );
    my $tree = $self->_simple_inheritance_tree( $locale ) ||
        return( $self->pass_error );

    foreach my $loc ( @$tree )
    {
        $ref = $cldr->locale(
            locale => $loc,
        );
        last if( $ref );
        return( $self->pass_error( $cldr->error ) ) if( !$ref && $cldr->error );
    }

    if( !$ref )
    {
        return( $self->error( "Unable to find any locale information for '", $tree->[-1], "', which should not happen. Something is wrong with the Locale::Unicode::Data data." ) );
    }
    return( $ref );
}

sub _get_one
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $meth = delete( $opts->{method} ) || die( "No method to query Locale::Unicode::Data was provided." );
    my $cldr = $self->{_cldr} || die( "Locale::Unicode::Data object is gone!" );
    my $locale = $opts->{locale} || die( "No locale value provided to retrieve Locale::Unicode::Data localised data." );
    unless( Scalar::Util::blessed( $locale ) && 
            $locale->isa( 'Locale::Unicode' ) )
    {
        $locale = Locale::Unicode->new( $locale ) ||
            return( $self->pass_error( Locale::Unicode->error ) );
    }
    my $code;
    if( !( $code = $cldr->can( $meth ) ) )
    {
        die( "Method \"${meth}\" is unknown in Locale::Unicode::Data" );
    }
    my $ref = $code->( $cldr, %$opts, locale => $locale );
    if( !defined( $ref ) &&
        $cldr->error )
    {
        return( $self->pass_error( $cldr->error ) );
    }
    # If we found nothing for this locale, and it has a territory code specified
    elsif( !$ref && $locale->territory )
    {
        $locale = Locale::Unicode->new( $locale->language ) ||
            return( $self->pass_error( Locale::Unicode->error ) );
        $ref = $code->( $cldr, %$opts, locale => $locale );
        if( !defined( $ref ) &&
            $cldr->error )
        {
            return( $self->pass_error( $cldr->error ) );
        }
    }
    # If it is undefined, but there is no error, it just means there was no data.
    # DBI fetchrow_hashref and fetchall_arrayref returns undef when there is no data
    # but to make things distinctive and simple, we return an empty string and leave undef for errors
    # so this is either an hash reference or an empty string.
    $ref //= '';
    return( $ref );
}

# This is not designed to get the locale parent in the LDML meaning, but simply, get
# the locale parent if it has one, or else fall back on the language or language3 ID
sub _get_parent
{
    my $self = shift( @_ );
    my $parent;
    unless( $parent = $self->{_parent} )
    {
        my $locale = $self->{locale} ||
            return( $self->error( "No locale provided to get its country information." ) );
        $locale = $self->_locale_object( $locale ) ||
            return( $self->pass_error );
        my $lang = ( $locale->language || $locale->language3 );
        my $info = $self->_locale_info;
        $parent = $self->{_parent} = ( $info && $info->{parent} )
            ? $info->{parent}
            : ( $lang ne $locale )
                ? $lang
                : 'und';
    }
    return( $parent );
}

sub _locale_info
{
    my $self = shift( @_ );
    my $ref;
    unless( $ref = $self->{_locale_info} )
    {
        my $locale = $self->{locale} ||
            return( $self->error( "No locale provided to get its country information." ) );
        $ref = $self->_get_locale_info( locale => $locale ) ||
            return( $self->pass_error );
    }
    return( $ref );
}

sub _locale_object
{
    my $self = shift( @_ );
    my $locale = shift( @_ ) ||
        return( $self->error( "No locale provided to ensure a Locale::Unicode." ) );
    unless( Scalar::Util::blessed( $locale ) &&
            $locale->isa( 'Locale::Unicode' ) )
    {
        $locale = Locale::Unicode->new( "$locale" ) ||
            return( $self->pass_error( Locale::Unicode->error ) );
    }
    return( $locale );
}

sub _metazone_name
{
    my $self = shift( @_ );
    # Our internal arguments
    my $def  = shift( @_ );
    # User's arguments
    my $opts = $self->_get_args_as_hash( @_ );
    if( !$def->{type} )
    {
        die( "No 'type' option provided." );
    }
    elsif( !$def->{width} )
    {
        die( "No 'width' option provided." );
    }
    elsif( $def->{type} !~ /^(?:generic|standard|daylight)$/ )
    {
        die( "Bad type provided. It must be one of: generic, generic or daylight" );
    }
    elsif( $def->{width} !~ /^(?:short|long)$/ )
    {
        die( "Bad width provided. It must be one of: short or long" );
    }
    elsif( !$opts->{metazone} )
    {
        return( $self->error( "No metazone was provided." ) );
    }
    my $meth_id = "metazone_name_" . $def->{type} . '_' . $def->{width} . '_meta_tz=' . $opts->{metazone};
    my $name;
    unless( defined( $name = $self->{ $meth_id } ) )
    {
        my $locale = $self->{locale} || die( "Locale value is gone!" );
        my $cldr = $self->{_cldr} || die( "Locale::Unicode::Data object is gone!" );
        my $locales = $cldr->make_inheritance_tree( $locale ) ||
            return( $self->pass_error( $cldr->error ) );
        my $metazone = $opts->{metazone};
        my $type     = $def->{type};
        my $width    = $def->{width};
        my $location = $def->{location};
        my $ref;
        my $metatz_info = $cldr->metazone(
            metazone => $metazone,
        );
        return( $self->pass_error ) if( !defined( $metatz_info ) && $cldr->error );
        return( $self->error( "No metazone ${metazone} found." ) ) if( !$metatz_info );
        LOCALE: foreach my $loc ( @$locales )
        {
            $ref = $cldr->metazone_names(
                metazone    => $metazone,
                locale      => $loc,
                width       => $width,
            );
            return( $self->pass_error ) if( !defined( $ref ) && $cldr->error );
            if( $ref && $ref->{ $type } )
            {
                if( $ref->{ $type } ne $EMPTY_SET )
                {                
                    $name = $ref->{ $type };
                }
                last LOCALE;
            }
        }
        # Failed to find a suitable match
        $name //= '';
        $self->{ $meth_id } = $name;
    }
    return( $name );
}

# This resembles the one in Locale::Unicode::Data, except, it does not look up real parents.
# This only creates a tree of subtags in the order prescribed by LDML
# <https://unicode.org/reports/tr35/tr35.html#Inheritance_and_Validity>
sub _simple_inheritance_tree
{
    my $self = shift( @_ );
    my $locale = shift( @_ ) || return( $self->error( "No locale ID was provided." ) );
    $locale = $self->_locale_object( $locale ) ||
        return( $self->pass_error );
    # So we do not corrupt the original object provided, if any
    $locale = $locale->clone;
    my $tree = ["$locale"];
    if( $locale->variant )
    {
        $locale->variant( undef );
        push( @$tree, "$locale" );
    }
    if( $locale->territory )
    {
        $locale->territory( undef );
        push( @$tree, "$locale" );
    }
    if( $locale->script )
    {
        $locale->script( undef );
        push( @$tree, "$locale" );
    }
    # Make sure our last resort is not the same as our initial value
    # For example: fr -> fr
    if( !scalar( grep( $_ eq $locale, @$tree ) ) )
    {
        push( @$tree, "$locale" );
    }
    push( @$tree, 'und' ) unless( $tree->[-1] eq 'und' );
    return( $tree );
}

sub _territory_info
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $cldr = $self->{_cldr} || die( "Locale::Unicode::Data object is gone!" );
    my $territory;
    unless( $territory = $opts->{territory} )
    {
        my $locale = $opts->{locale} ||
            return( $self->error( "No locale provided to get its country information." ) );
        unless( Scalar::Util::blessed( $locale ) &&
                $locale->isa( 'Locale::Unicode' ) )
        {
            $locale = Locale::Unicode->new( $locale ) ||
                return( $self->pass_error( Locale::Unicode->error ) );
        }
        unless( $territory = $locale->country_code )
        {
            my $locales = $cldr->make_inheritance_tree( $locale ) ||
                return( $self->pass_error( $cldr->error ) );
            my $ref;
            foreach my $loc ( @$locales )
            {
                $ref = $cldr->likely_subtag(
                    locale => $loc,
                );
                last if( $ref );
            }
            # Unable to find any likely subtag information :/
            # Resorting to 'und' (root)
            if( !$ref )
            {
                $ref = $cldr->likely_subtag(
                    locale => 'und',
                );
            }
            return( $self->error( "Something is wrong with the SQLite database of Locale::Unicode::Data. I could not even find any likely subtag information for root language (und)!" ) ) if( !$ref );
            my $target = Locale::Unicode->new( $ref->{target} );
            $territory = $target->country_code ||
                return( $self->error( "The target locale value returned from the likely subtag search for '$ref->{locale}' does not contain a territory. This should not be happening. Something is wrong with Locale::Unicode::Data" ) );
        }
    }
    my $info = $cldr->territory( territory => $territory );
    if( !$info )
    {
        if( $cldr->error )
        {
            return( $self->pass_error( $cldr->error ) );
        }
        else
        {
            return( $self->error( "Unable to get any information for country code '${territory}'" ) );
        }
    }
    return( $info );
}

sub _time_formats
{
    my $self = shift( @_ );
    my $type = shift( @_ ) ||
        die( "Time format type was not provided." );
    die( "Unsupported type '${type}'. Use one of 'preferred' or 'allowed'." ) if( $type ne 'preferred' && $type ne 'allowed' );
    my $code;
    my $meth_id = "time_formats_${type}";
    my $pattern;
    if( ( !scalar( @_ ) && !defined( $pattern = $self->{ $meth_id } ) ) ||
        @_ )
    {
        my $map =
        {
            allowed => 'time_allowed',
            preferred => 'time_format',
        };
        $type = $map->{ $type };
        my $has_arg = 0;
        my $locale = $self->{locale} || die( "Locale value is gone!" );
        my $cldr = $self->{_cldr} || die( "Locale::Unicode::Data object is gone!" );
        if( @_ )
        {
            $code = shift( @_ );
            $has_arg++;
        }
        else
        {
            if( my $this = $locale->country_code )
            {
                $code = $this;
            }
            else
            {
                my $locales = $cldr->make_inheritance_tree( $locale ) ||
                    return( $self->pass_error( $cldr->error ) );
                my $target;
                LOCALES: foreach my $loc ( @$locales )
                {
                    my $ref = $cldr->likely_subtag(
                        locale => $loc,
                    );
                    if( $ref && $ref->{target} )
                    {
                        $target = $ref->{target};
                        last;
                    }
                }
                if( defined( $target ) )
                {
                    my $new = Locale::Unicode->new( $target ) ||
                        return( $self->pass_error( Locale::Unicode->error ) );
                    if( my $this = $new->country_code )
                    {
                        $code = $this;
                    }
                }
            }
            # By default
            $code //= '001';
        }
        my $territories = [$code];
        push( @$territories, '001' ) unless( $territories->[-1] eq '001' );
        foreach my $territory ( @$territories )
        {
            my $all = $cldr->time_formats(
                territory => $territory,
            );
            if( $all && 
                scalar( @$all ) && 
                defined( $all->[0] ) && 
                ref( $all->[0] ) eq 'HASH' && 
                length( $all->[0]->{ $type } // '' ) )
            {
                $pattern = $all->[0]->{ $type };
                last;
            }
        }
        $pattern //= '';
        # $pattern = [split( /[[:blank:]\h]+/, $pattern )] if( $type eq 'time_allowed' );
        $self->{ $meth_id } = $pattern unless( $has_arg );
    }
    return( $pattern );
}

sub _timezone_formats
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    if( !$opts->{type} )
    {
        die( "No 'type' option provided." );
    }
    my $meth_id = "timezone_formats_" . $opts->{type} . '_' . ( $opts->{subtype} // 'no_subtype' );
    my $pattern;
    unless( defined( $pattern = $self->{ $meth_id } ) )
    {
        my $locale = $self->{locale} || die( "Locale value is gone!" );
        my $cldr = $self->{_cldr} || die( "Locale::Unicode::Data object is gone!" );
        my $locales = $cldr->make_inheritance_tree( $locale ) ||
            return( $self->pass_error( $cldr->error ) );
        my $ref;
        LOCALE: foreach my $loc ( @$locales )
        {
            $ref = $cldr->timezone_formats(
                locale  => $loc,
                type    => $opts->{type},
                subtype => $opts->{subtype},
            );
            return( $self->pass_error ) if( !defined( $ref ) && $cldr->error );
            if( $ref && $ref->{format_pattern} )
            {
                $pattern = $ref->{format_pattern};
                last LOCALE;
            }
        }
        if( $opts->{type} eq 'hour' )
        {
            $pattern = defined( $pattern ) ? [split( /\;/, $pattern, 2 )] : [];
        }
        $pattern //= '';
        $self->{ $meth_id } = $pattern;
    }
    return( $pattern );
}

sub _timezone_name
{
    my $self = shift( @_ );
    # Our internal arguments
    my $def  = shift( @_ );
    # User's arguments
    my $opts = $self->_get_args_as_hash( @_ );
    if( !$def->{type} )
    {
        die( "No 'type' option provided." );
    }
    elsif( !$def->{width} )
    {
        die( "No 'width' option provided." );
    }
    elsif( $def->{type} !~ /^(?:generic|standard|daylight)$/ )
    {
        die( "Bad type provided. It must be one of: generic, generic or daylight" );
    }
    elsif( $def->{width} !~ /^(?:short|long)$/ )
    {
        die( "Bad width provided. It must be one of: short or long" );
    }
    elsif( !$opts->{timezone} )
    {
        return( $self->error( "No timezone was provided." ) );
    }
    my $meth_id = "timezone_name_" . $def->{type} . '_' . $def->{width} . '_tz=' . $opts->{timezone};
    my $name;
    unless( defined( $name = $self->{ $meth_id } ) )
    {
        my $locale = $self->{locale} || die( "Locale value is gone!" );
        my $cldr = $self->{_cldr} || die( "Locale::Unicode::Data object is gone!" );
        my $locales = $cldr->make_inheritance_tree( $locale ) ||
            return( $self->pass_error( $cldr->error ) );
        my $timezone = $opts->{timezone};
        my $type     = $def->{type};
        my $width    = $def->{width};
        my $location = $def->{location};
        my $ref;
        my $tz_info = $cldr->timezone(
            timezone => $timezone,
        );
        return( $self->pass_error ) if( !defined( $tz_info ) && $cldr->error );
        return( $self->error( "No time zone ${timezone} found." ) ) if( !$tz_info );
        LOCALE: foreach my $loc ( @$locales )
        {
            $ref = $cldr->timezone_names(
                timezone    => $timezone,
                locale      => $loc,
                width       => $width,
            );
            return( $self->pass_error ) if( !defined( $ref ) && $cldr->error );
            if( $ref && $ref->{ $type } )
            {
                $name = $ref->{ $type };
                last LOCALE;
            }
        }
        # Failed to find a suitable match
        $name //= '';
        $self->{ $meth_id } = $name;
    }
    return( $name );
}

sub FREEZE
{
    my $self = CORE::shift( @_ );
    my $serialiser = CORE::shift( @_ ) // '';
    my $class = CORE::ref( $self );
    my $locale = "$self->{locale}";
    # Return an array reference rather than a list so this works with Sereal and CBOR
    # On or before Sereal version 4.023, Sereal did not support multiple values returned
    CORE::return( [$class, $locale] ) if( $serialiser eq 'Sereal' && Sereal::Encoder->VERSION <= version->parse( '4.023' ) );
    # But Storable want a list with the first element being the serialised element
    CORE::return( $class, $locale );
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
    my $locale = CORE::ref( $ref ) eq 'ARRAY' ? CORE::shift( @$ref ) : '';
    my $new;
    # Storable pattern requires to modify the object it created rather than returning a new one
    if( CORE::ref( $self ) )
    {
        $locale = Locale::Unicode->new( $locale );
        $self->{locale} = $locale;
        $self->{_cldr} = Locale::Unicode::Data->new;
        $new = $self;
    }
    else
    {
        $new = $class->new( $locale );
    }
    CORE::return( $new );
}

sub TO_JSON { return( shift->as_string ); }

# NOTE: DateTime::Locale::FromCLDR::Exception class
package DateTime::Locale::FromCLDR::Exception;
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
        elsif( ref( $_[0] ) && $_[0]->isa( 'DateTime::Locale::FromCLDR::Exception' ) )
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
    # NOTE: DateTime::Locale::FromCLDR::NullObject class
    package
        DateTime::Locale::FromCLDR::NullObject;
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

DateTime::Locale::FromCLDR - DateTime Localised Data from Unicode CLDR

=head1 SYNOPSIS

    use DateTime::Locale::FromCLDR;
    my $locale = DateTime::Locale::FromCLDR->new( 'ja-Kana-JP' ) ||
        die( DateTime::Locale::FromCLDR->error );
    my $locale = DateTime::Locale::FromCLDR->new( 'ja-Kana-JP', calendar => 'japanese' ) ||
        die( DateTime::Locale::FromCLDR->error );
    my $array = $locale->am_pm_abbreviated;
    my $array = $locale->available_formats;
    $locale->calendar( 'hebrew' );
    my $str = $locale->calendar;
    # a Locale::Unicode object that stringifies to the initial locale value (ja-Kana-JP)
    my $obj = $locale->code;
    my $str = $locale->date_at_time_format_full;
    my $str = $locale->date_at_time_format_long;
    my $str = $locale->date_at_time_format_medium;
    my $str = $locale->date_at_time_format_short;
    my $str = $locale->date_format_default;
    my $str = $locale->date_format_full;
    my $str = $locale->date_format_long;
    my $str = $locale->date_format_medium;
    my $str = $locale->date_format_short;
    my $str = $locale->date_formats;
    my $str = $locale->datetime_format;
    my $str = $locale->datetime_format_default;
    my $str = $locale->datetime_format_full;
    my $str = $locale->datetime_format_long;
    my $str = $locale->datetime_format_medium;
    my $str = $locale->datetime_format_short;
    my $str = $locale->day_format_abbreviated;
    my $str = $locale->day_format_narrow;
    my $str = $locale->day_format_short;
    my $str = $locale->day_format_wide;
    my $str = $locale->day_period_format_abbreviated( $datetime_object );
    my $str = $locale->day_period_format_narrow( $datetime_object );
    my $str = $locale->day_period_format_wide( $datetime_object );
    my $str = $locale->day_period_stand_alone_abbreviated( $datetime_object );
    my $str = $locale->day_period_stand_alone_narrow( $datetime_object );
    my $str = $locale->day_period_stand_alone_wide( $datetime_object );
    my $hashref = $locale->day_periods;
    my $str = $locale->day_stand_alone_abbreviated;
    my $str = $locale->day_stand_alone_narrow;
    my $str = $locale->day_stand_alone_short;
    my $str = $locale->day_stand_alone_wide;
    my $str = $locale->default_date_format_length;
    my $str = $locale->default_time_format_length;
    my $str = $locale->era_abbreviated;
    my $str = $locale->era_narrow;
    my $str = $locale->era_wide;
    my $str = $locale->first_day_of_week;
    my $str = $locale->format_for( 'yMEd' );
    my $str = $locale->gmt_format(0);
    my $str = $locale->gmt_format(3600);
    my $str = $locale->gmt_format(-3600);
    my $str = $locale->gmt_format(-3600, width => 'short');
    my $str = $locale->gmt_format(-3600, { width => 'short' });
    # Alias for method 'code'
    my $obj = $locale->id;
    my $array = $locale->interval_format( GyMEd => 'd' );
    my $hashref = $locale->interval_formats;
    my $greatest_diff = $locale->interval_greatest_diff( $datetime_object_1, $datetime_object_2 );
    my $str = $locale->language;
    my $str = $locale->language_code;
    # Alias for method 'language_code'
    my $str = $locale->language_id;
    # Locale::Unicode object
    my $obj = $locale->locale;
    # Equivalent to $locale->locale->as_string
    my $str = $locale->locale_as_string;
    # As per standard, it falls back to 'wide' format if it is not available
    my $str = $locale->metazone_daylight_long( metazone => 'Taipei' );
    my $str = $locale->metazone_daylight_short( metazone => 'Taipei' );
    my $str = $locale->metazone_generic_long( metazone => 'Taipei' );
    my $str = $locale->metazone_generic_short( metazone => 'Taipei' );
    my $str = $locale->metazone_standard_long( metazone => 'Taipei' );
    my $str = $locale->metazone_standard_short( metazone => 'Taipei' );
    my $str = $locale->month_format_abbreviated;
    my $str = $locale->month_format_narrow;
    my $str = $locale->month_format_wide;
    my $str = $locale->month_stand_alone_abbreviated;
    my $str = $locale->month_stand_alone_narrow;
    my $str = $locale->month_stand_alone_wide;
    # Language name in English. Here: Japanese
    my $str = $locale->name;
    # Alias for the method 'native_name'
    my $str = $locale->native_language;
    # Language name in the locale's original language. Here: 日本語
    my $str = $locale->native_name;
    # The local's script name in the locale's original language. Here: カタカナ
    my $str = $locale->native_script;
    # The local's territory name in the locale's original language. Here: 日本
    my $str = $locale->native_territory;
    # The local's variant name in the locale's original language. Here: undef since there is none
    my $str = $locale->native_variant;
    my $str = $locale->native_variants;
    # Returns 1 or 0
    my $bool = $locale->prefers_24_hour_time;
    my $str = $locale->quarter_format_abbreviated;
    my $str = $locale->quarter_format_narrow;
    my $str = $locale->quarter_format_wide;
    my $str = $locale->quarter_stand_alone_abbreviated;
    my $str = $locale->quarter_stand_alone_narrow;
    my $str = $locale->quarter_stand_alone_wide;
    # The locale's script name in English. Here: Katakana
    my $str = $locale->script;
    # The locale's script ID, if any. Here: Kana
    my $str = $locale->script_code;
    # Alias for method 'script_code'
    my $str = $locale->script_id;
    # The locale's territory name in English. Here: Japan
    my $str = $locale->territory;
    # The locale's territory ID, if any. Here: JP
    my $str = $locale->territory_code;
    # Alias for method 'territory_code'
    my $str = $locale->territory_id;
    my $str = $locale->time_format_default;
    my $str = $locale->time_format_full;
    my $str = $locale->time_format_long;
    my $str = $locale->time_format_medium;
    my $str = $locale->time_format_short;
    # Time patterns for 'full', 'long', 'medium', and 'short' formats
    my $array = $locale->time_formats;
    my $str = $locale->timezone_city( timezone => 'Asia/Tokyo' );
    my $str = $locale->timezone_format_fallback;
    my $str = $locale->timezone_format_gmt;
    my $str = $locale->timezone_format_gmt_zero;
    my $str = $locale->timezone_format_hour;
    my $str = $locale->timezone_format_region;
    my $str = $locale->timezone_format_region_daylight;
    my $str = $locale->timezone_format_region_standard;
    my $str = $locale->timezone_daylight_long( timezone => 'Europe/London' );
    my $str = $locale->timezone_daylight_short( timezone => 'Europe/London' );
    my $str = $locale->timezone_generic_long( timezone => 'Europe/London' );
    my $str = $locale->timezone_generic_short( timezone => 'Europe/London' );
    my $str = $locale->timezone_standard_long( timezone => 'Europe/London' );
    my $str = $locale->timezone_standard_short( timezone => 'Europe/London' );
    # The locale's variant name, if any, in English. Here undef, because there is none
    my $str = $locale->variant;
    # The locale's variant ID, if any. Here undef, since there is none
    my $str = $locale->variant_code;
    # Alias for method 'variant_code'
    my $str = $locale->variant_id;
    my $array = $locale->variants;
    # The CLDR data version. For example: 45.0
    my $str = $locale->version;

    # To get DateTime to use DateTime::Locale::FromCLDR for the locale data
    my $dt = DateTime->now(
        locale => DateTime::Locale::FromCLDR->new( 'en' ),
    );

=head1 VERSION

    v0.2.1

=head1 DESCRIPTION

This is a powerful replacement for L<DateTime::Locale> and L<DateTime::Locale::FromData> that use static data from over 1,000 pre-generated modules, whereas L<DateTime::Locale::FromCLDR> builds a C<locale> object to access its Unicode L<CLDR|https://cldr.unicode.org/> (Common Locale Data Repository) data from SQLite data made available with L<Locale::Unicode::Data>

It provides the same API as L<DateTime::Locale>, but in a dynamic way. This is important since in the Unicode L<LDML specifications|https://unicode.org/reports/tr35/>, a C<locale> inherits from its parent's data.

Once a data is retrieved by a method, it is cached to avoid waste of time.

It also adds a few methods to access the C<locale> L<at time patterns|https://unicode.org/reports/tr35/tr35-dates.html#dateTimeFormats>, such as L<date_at_time_format_full|/date_at_time_format_full>, and L<native_variants|/native_variants>

It also provides key support for L<day period|https://unicode.org/reports/tr35/tr35-dates.html#Day_Period_Rule_Sets>

It also provides support for interval datetime, and L<a method to find the greatest datetime difference element between 2 datetimes|/interval_greatest_diff>, as well as a method to get all the L<available format patterns for intervals|/interval_formats>, and a L<method to retrieve the components of an specific interval patterns|/interval_format>

It adds the C<short> format for day missing in L<DateTime::Locale::FromData>

Note that in C<CLDR> parlance, there are standard pattern formats. For example C<full>, C<long>, C<medium>, C<short> or also C<abbreviated>, C<short>, C<wide>, C<narrow> providing various level of conciseness.

=head1 CONSTRUCTOR

=head2 new

    # Japanese as spoken in Japan
    my $locale = DateTime::Locale::FromCLDR->new( 'ja-JP' ) ||
        die( DateTime::Locale::FromCLDR->error );
    # Okinawan as spoken in Japan Southern islands
    my $locale = DateTime::Locale::FromCLDR->new( 'ryu-Kana-JP-t-de-t0-und-x0-medical' ) ||
        die( DateTime::Locale::FromCLDR->error );

    use Locale::Unicode;
    my $loc = Locale::Unicode->new( 'fr-FR' );
    my $locale = DateTime::Locale::FromCLDR->new( $loc ) ||
        die( DateTime::Locale::FromCLDR->error );

Specifying a calendar ID other than the default C<gregorian>:

    my $locale = DateTime::Locale::FromCLDR->new( 'ja-JP', calendar => 'japanese' ) ||
        die( DateTime::Locale::FromCLDR->error );

or, using an hash reference:

    my $locale = DateTime::Locale::FromCLDR->new( 'ja-JP', { calendar => 'japanese' } ) ||
        die( DateTime::Locale::FromCLDR->error );

Instantiate a new L<DateTime::Locale::FromCLDR> object based on a C<locale> provided, and returns it. By default, it uses the calendar C<gregorian>, but you can specify a different one with the C<calendar> option.

You can provide any C<locale>, even complex one as shown above, and only its core part will be retained. So, for example:

    my $locale = DateTime::Locale::FromCLDR->new( 'ryu-Kana-JP-t-de-t0-und-x0-medical' ) ||
        die( DateTime::Locale::FromCLDR->error );
    say $locale; # ryu-Kana-JP

If an error occurs, it sets an L<exception object|DateTime::Locale::FromCLDR::Exception> and returns C<undef> in scalar context, or an empty list in list context, or possibly a special C<DateTime::Locale::FromCLDR::NullObject> in object context. See L</error> for more information.

The object is overloaded and stringifies into the core part of the original string provided upon instantiation.

The core part is comprised of the C<language> ID, an optional C<script> ID, an optional C<territory> ID and zero or multiple C<variant> IDs. See L<Locale::Unicode> and the L<LDML specifications|https://unicode.org/reports/tr35/tr35.html#Locale> for more information.

=head1 METHODS

All methods are read-only unless stated otherwise.

=head2 am_pm_abbreviated

This is an alias for L<am_pm_format_abbreviated|/am_pm_format_abbreviated>

=head2 am_pm_format_abbreviated

    my $array = $locale->am_pm_format_abbreviated;

Returns an array reference of the terms used to represent C<am> and C<pm>

The array reference could be empty if the C<locale> does not support specifying C<am>/C<pm>

For example:

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $ampm = $locale->am_pm_abbreviated
    say @$ampm; # AM, PM

    my $locale = DateTime::Locale::FromCLDR->new( 'ja' );
    my $ampm = $locale->am_pm_abbreviated
    say @$ampm; # 午前, 午後

    my $locale = DateTime::Locale::FromCLDR->new( 'fr' );
    my $ampm = $locale->am_pm_abbreviated
    say @$ampm; # Empty

See L<Locale::Unicode::Data/calendar_term>

=head2 am_pm_format_narrow

Same as L<am_pm_format_abbreviated|/am_pm_format_abbreviated>, but returns the narrow format of the AM/PM terms.

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    say $locale->am_pm_format_narrow;

=head2 am_pm_format_wide

Same as L<am_pm_format_abbreviated|/am_pm_format_abbreviated>, but returns the wide format of the AM/PM terms.

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    say $locale->am_pm_format_wide;

=head2 am_pm_standalone_abbreviated

Same as L<am_pm_format_abbreviated|/am_pm_format_abbreviated>, but returns the abbreviated stand-alone format of the AM/PM terms.

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    say $locale->am_pm_standalone_abbreviated;

=head2 am_pm_standalone_narrow

Same as L<am_pm_format_abbreviated|/am_pm_format_abbreviated>, but returns the narrow stand-alone format of the AM/PM terms.

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    say $locale->am_pm_standalone_narrow;

=head2 am_pm_standalone_wide

Same as L<am_pm_format_abbreviated|/am_pm_format_abbreviated>, but returns the wide stand-alone format of the AM/PM terms.

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    say $locale->am_pm_standalone_wide;

=for Pod::Coverage as_string

=head2 available_formats

    my $array = $locale->available_formats;

Returns an array reference of all the format ID available for this C<locale>

See L<Locale::Unicode::Data/calendar_available_format>

=head2 calendar

    my $locale = DateTime::Locale::FromCLDR->new( 'ja-Kana-JP', calendar => 'japanese' ) ||
        die( DateTime::Locale::FromCLDR->error );
    my $str = $locale->calendar; # japanese
    $locale->calendar( 'gregorian' );

Sets or gets the L<calendar ID|Locale::Unicode::Data/calendar> used to perform queries along with the given C<locale>

=head2 code

    my $obj = $locale->code;

Returns the L<Locale::Unicode> object either received or created upon object instantiation.

=head2 date_at_time_format_full

    my $str = $locale->date_at_time_format_full;

Returns the full L<date at time pattern|https://unicode.org/reports/tr35/tr35-dates.html#dateTimeFormats>

For example:

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    say $locale->date_at_time_format_full;
    # EEEE, MMMM d, y 'at' h:mm:ss a zzzz
    # Tuesday, July 23, 2024 at 1:26:38 AM UTC

    my $locale = DateTime::Locale::FromCLDR->new( 'fr' );
    say $locale->date_at_time_format_full;
    # EEEE d MMMM y 'à' HH:mm:ss zzzz
    # mardi 23 juillet 2024 à 01:27:11 UTC

=head2 date_at_time_format_long

Same as L<date_at_time_format_full|/date_at_time_format_full>, but returns the long format pattern.

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    say $locale->date_at_time_format_long;
    # MMMM d, y 'at' h:mm:ss a z
    # July 23, 2024 at 1:26:11 AM UTC

=head2 date_at_time_format_medium

Same as L<date_at_time_format_full|/date_at_time_format_full>, but returns the medium format pattern.

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    say $locale->date_at_time_format_medium;
    # MMM d, y 'at' h:mm:ss a
    # Jul 23, 2024 at 1:25:43 AM

=head2 date_at_time_format_short

Same as L<date_at_time_format_full|/date_at_time_format_full>, but returns the short format pattern.

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    say $locale->date_at_time_format_short;
    # M/d/yy 'at' h:mm a
    # 7/23/24 at 1:25 AM

=head2 date_format_default

This is an alias to L<date_format_medium|/date_format_medium>

=head2 date_format_full

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    say $locale->date_format_full;
    # EEEE, MMMM d, y
    # Tuesday, July 23, 2024

Returns the L<full date pattern|https://unicode.org/reports/tr35/tr35-dates.html#dateFormats>

See also L<Locale::Unicode::Data/calendar_format_l10n>

=head2 date_format_long

Same as L<date_format_full|/date_format_full>, but returns the long format pattern.

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    say $locale->date_format_long;
    # MMMM d, y
    # July 23, 2024

=head2 date_format_medium

Same as L<date_format_full|/date_format_full>, but returns the medium format pattern.

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    say $locale->date_format_long;
    # MMM d, y
    # Jul 23, 2024

=head2 date_format_short

Same as L<date_format_full|/date_format_full>, but returns the short format pattern.

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    say $locale->date_format_short;
    # M/d/yy
    # 7/23/24

=head2 date_formats

    my $now = DateTime->now( locale => 'en' );
    my $ref = $locale->date_formats;
    foreach my $type ( sort( keys( %$ref ) ) )
    {
        say $type, ":";
        say $ref->{ $type };
        say $now->format_cldr( $ref->{ $type } ), "\n";
    }

Would produce:

    full:
    EEEE, MMMM d, y
    Tuesday, July 23, 2024

    long:
    MMMM d, y
    July 23, 2024

    medium:
    MMM d, y
    Jul 23, 2024

    short:
    M/d/yy
    7/23/24

Returns an hash reference with the keys being: C<full>, C<long>, C<medium>, C<short> and their value the result of their associated date format methods.

=head2 datetime_format

This is an alias for L<datetime_format_medium|/datetime_format_medium>

=head2 datetime_format_default

This is also an alias for L<datetime_format_medium|/datetime_format_medium>

=head2 datetime_format_full

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    say $locale->datetime_format_full;
    # EEEE, MMMM d, y, h:mm:ss a zzzz
    # Tuesday, July 23, 2024, 1:53:27 AM UTC

Returns the L<full datetime pattern|https://unicode.org/reports/tr35/tr35-dates.html#dateTimeFormats>

See also L<Locale::Unicode::Data/calendar_datetime_format>

=head2 datetime_format_long

Same as L<datetime_format_full|/datetime_format_full>, but returns the long format pattern.

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    say $locale->datetime_format_long;
    # MMMM d, y, h:mm:ss a z
    # July 23, 2024, 1:57:02 AM UTC

=head2 datetime_format_medium

Same as L<datetime_format_full|/datetime_format_full>, but returns the medium format pattern.

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    say $locale->datetime_format_medium;
    # MMM d, y, h:mm:ss a
    # Jul 23, 2024, 2:03:16 AM

=head2 datetime_format_short

Same as L<datetime_format_full|/datetime_format_full>, but returns the short format pattern.

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    say $locale->datetime_format_short;
    # M/d/yy, h:mm a
    # 7/23/24, 2:04 AM

=head2 day_format_abbreviated

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $days = $locale->day_format_abbreviated;
    say @$days;
    # Mon, Tue, Wed, Thu, Fri, Sat, Sun

Returns an array reference of week day names abbreviated format with Monday first and Sunday last.

See also L<Locale::Unicode::Data/calendar_term>

=head2 day_format_narrow

Same as L<day_format_abbreviated|/day_format_abbreviated>, but returns the narrow format days.

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $days = $locale->day_format_abbreviated;
    say @$days;
    # M, T, W, T, F, S, S

=head2 day_format_short

Same as L<day_format_abbreviated|/day_format_abbreviated>, but returns the short format days.

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $days = $locale->day_format_short;
    say @$days;
    # Mo, Tu, We, Th, Fr, Sa, Su

=head2 day_format_wide

Same as L<day_format_abbreviated|/day_format_abbreviated>, but returns the wide format days.

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $days = $locale->day_format_wide;
    say @$days;
    # Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday

=head2 day_period_format_abbreviated

    my $dt = DateTime->new( year => 2024, hour => 7 );
    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    say $locale->day_period_format_abbreviated( $dt );
    # in the morning

    my $dt = DateTime->new( year => 2024, hour => 13 );
    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    say $locale->day_period_format_abbreviated( $dt );
    # in the afternoon

    my $dt = DateTime->new( year => 2024, hour => 7 );
    my $locale = DateTime::Locale::FromCLDR->new( 'ja-Kana-JP' );
    say $locale->day_period_format_abbreviated( $dt );
    # 朝
    # which means "morning" in Japanese

    my $dt = DateTime->new( year => 2024, hour => 13 );
    my $locale = DateTime::Locale::FromCLDR->new( 'fr' );
    say $locale->day_period_format_abbreviated( $dt );
    # après-midi

Returns a string representing the localised expression of the period of day the L<DateTime> object provided is.

If nothing relevant could be found somehow, this will return an empty string. C<undef> is returned only if an error occurred.

This is used to provide the relevant value for the token C<B> or C<b> in the L<Unicode LDML format patterns|Locale::Unicode::Data/"Format Patterns">

See also L<Locale::Unicode::Data/calendar_term>, L<Locale::Unicode::Data/day_period> and L<DateTime::Format::Unicode>

=head2 day_period_format_narrow

Same as L<day_period_format_abbreviated|/day_period_format_abbreviated>, but returns the narrow format of day period.

    my $dt = DateTime->new( year => 2024, hour => 7 );
    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    say $locale->day_period_format_narrow( $dt );
    # in the morning

=head2 day_period_format_wide

Same as L<day_period_format_abbreviated|/day_period_format_abbreviated>, but returns the wide format of day period.

    my $dt = DateTime->new( year => 2024, hour => 7 );
    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    say $locale->day_period_format_wide( $dt );
    # in the morning

=head2 day_period_stand_alone_abbreviated

    my $dt = DateTime->new( year => 2024, hour => 7 );
    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    say $locale->day_period_stand_alone_abbreviated( $dt );
    # morning

    my $dt = DateTime->new( year => 2024, hour => 13 );
    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    say $locale->day_period_stand_alone_abbreviated( $dt );
    # afternoon

    my $dt = DateTime->new( year => 2024, hour => 7 );
    my $locale = DateTime::Locale::FromCLDR->new( 'ja-Kana-JP' );
    say $locale->day_period_stand_alone_abbreviated( $dt );
    # ""

The previous example would yield nothing, and as per L<the LDML specifications|https://unicode.org/reports/tr35/tr35-dates.html#dfst-period>, you would need to use the localised AM/PM instead.

    my $dt = DateTime->new( year => 2024, hour => 13 );
    my $locale = DateTime::Locale::FromCLDR->new( 'fr' );
    say $locale->day_period_stand_alone_abbreviated( $dt );
    # ap.m.

Returns a string representing the localised expression of the period of day the L<DateTime> object provided is.

If nothing relevant could be found somehow, this will return an empty string. C<undef> is returned only if an error occurred.

This is used to provide a stand-alone word that can be used as a title, or in a different context.

See also L<Locale::Unicode::Data/calendar_term>, L<Locale::Unicode::Data/day_period> and L<DateTime::Format::Unicode>

=head2 day_period_stand_alone_narrow

Same as L<day_period_stand_alone_abbreviated|/day_period_stand_alone_abbreviated>, but returns the narrow stand-alone version of the day period.

    my $dt = DateTime->new( year => 2024, hour => 13 );
    my $locale = DateTime::Locale::FromCLDR->new( 'fr' );
    say $locale->day_period_stand_alone_narrow( $dt );
    # ap.m.

=head2 day_period_stand_alone_wide

Same as L<day_period_stand_alone_abbreviated|/day_period_stand_alone_abbreviated>, but returns the wide stand-alone version of the day period.

    my $dt = DateTime->new( year => 2024, hour => 13 );
    my $locale = DateTime::Locale::FromCLDR->new( 'fr' );
    say $locale->day_period_stand_alone_wide( $dt );
    # après-midi

=head2 day_periods

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $hash = $locale->day_periods;
    # Would return an hash reference like:
    {
        midnight => ["00:00", "00:00"],
        morning1 => ["06:00", "12:00"],
        noon => ["12:00", "12:00"],
        afternoon1 => ["12:00", "18:00"],
        evening1 => ["18:00", "21:00"],
        night1 => ["21:00", "06:00"],
    }

Returns an hash reference of day period token and values of 2-elements array (start time and end time in hours and minutes)

=head2 day_stand_alone_abbreviated

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $days = $locale->day_stand_alone_abbreviated;
    say @$days;
    # Mon, Tue, Wed, Thu, Fri, Sat, Sun

Returns an array reference of week day names in abbreviated format with Monday first and Sunday last.

This is often identical to the C<format> type.

See the L<LDML specifications|https://unicode.org/reports/tr35/tr35-dates.html#months_days_quarters_eras> for more information on the difference between the C<format> and C<stand-alone> types.

=head2 day_stand_alone_narrow

Same as L<day_stand_alone_abbreviated|/day_stand_alone_abbreviated>, but returns the narrow format days.

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $days = $locale->day_stand_alone_narrow;
    say @$days;
    # M, T, W, T, F, S, S

=head2 day_stand_alone_short

Same as L<day_stand_alone_abbreviated|/day_stand_alone_abbreviated>, but returns the short format days.

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $days = $locale->day_stand_alone_short;
    say @$days;
    # Mo, Tu, We, Th, Fr, Sa, Su

=head2 day_stand_alone_wide

Same as L<day_stand_alone_abbreviated|/day_stand_alone_abbreviated>, but returns the wide format days.

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $days = $locale->day_stand_alone_wide;
    say @$days;
    # Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday

=head2 default_date_format_length

This returns the string C<medium>

=head2 default_time_format_length

This returns the string C<medium>

=head2 era_abbreviated

    my $array = $locale->era_abbreviated;
    say @$array;
    # BC, AD

Returns an array reference of era names in abbreviated format.

See also L<Locale::Unicode::Data/calendar_eras_l10n>

=head2 era_narrow

Same as L<era_abbreviated|/era_abbreviated>, but returns the narrow format eras.

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $array = $locale->era_narrow;
    say @$array;
    # B, A

=head2 era_wide

Same as L<era_abbreviated|/era_abbreviated>, but returns the wide format eras.

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $array = $locale->era_wide;
    say @$array;
    # Before Christ, Anno Domini

=head2 error

Used as a mutator, this sets an L<exception object|DateTime::Locale::FromCLDR::Exception> and returns an C<DateTime::Locale::FromCLDR::NullObject> in object context (such as when chaining), or C<undef> in scalar context, or an empty list in list context.

The C<DateTime::Locale::FromCLDR::NullObject> class prevents the perl error of C<Can't call method "%s" on an undefined value> (see L<perldiag>). Upon the last method chained, C<undef> is returned in scalar context or an empty list in list context.

=head2 first_day_of_week

    my $integer = $locale->first_day_of_week;

Returns an integer ranging from 1 to 7 where 1 means Monday and 7 means Sunday.

This represents what is the first day of the week for this C<locale>

Since the information on the first day of the week pertains to a C<territory>, if the C<locale> you provided does not have such information, this method will find out the L<likely subtag|Locale::Unicode::Data/likely_subtag> to get the C<locale>'s rightful C<territory>

See the L<LDML specifications about likely subtags|https://unicode.org/reports/tr35/tr35.html#Likely_Subtags> for more information.

For example:

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );

Since there is no C<territory> associated, this will look up the likely subtag to find the target C<locale> is C<en-Latn-US>, and thus the C<territory> for C<en> is C<US> and first day of the week is C<7>

Another example:

    my $locale = DateTime::Locale::FromCLDR->new( 'fr-Latn' );

This will ultimately get the territory C<FR> and first day of the week is C<1>

    # Okinawan as spoken in the Japanese Southern islands
    my $locale = DateTime::Locale::FromCLDR->new( 'ryu' );

This will become C<ryu-Kana-JP> and thus the C<territory> would be C<JP> and first day of the week is C<7>

This information is cached in the current object, like for all the other methods in this API.

=head2 format_for

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $pattern = $locale->format_for( 'Bhm' );

Provided with the format ID of an L<available format|/available_formats> and this will return the localised C<CLDR> pattern.

Keep in mind that the C<CLDR> formatting method of L<DateTime|DateTime/format_cldr> does not recognise all the C<CLDR> pattern tokens. Thus, for example, if you chose the standard available pattern C<Bhm>, this method would return the localised pattern C<h:mm B>. However, L<DateTime> does not understand the token C<B>

    my $now = DateTime->now( locale => "en", time_zone => "Asia/Tokyo" );
    # Assuming $now = 2024-07-23T21:39:39
    say $now->format_cldr( 'h:mm B' );
    # 9:39 B

But C<B> is the day period, which can be looked up with L<Locale::Unicode::Data/day_period>, which provides us with the day period token C<night1>, which itself can be looked up with L<Locale::Unicode::Data/calendar_term> and gives us the localised string C<at night>. Thus the proper C<CLDR> formatting really should be C<9:39 at night>

You can use L<DateTime::Format::Unicode> instead of the default L<DateTime> C<CLDR> formatting if you want to get better support for all L<CLDR pattern tokens|Locale::Unicode::Data/"Format Patterns">.

With Japanese:

    my $locale = DateTime::Locale::FromCLDR->new( 'ja' );
    my $pattern = $locale->format_for( 'Bhm' );
    # BK:mm
    my $now = DateTime->now( locale => "ja", time_zone => "Asia/Tokyo" );
    say $now->format_cldr( 'BK:mm' );
    # B9:54

But, this should have yielded: C<夜9:54> instead.

=head2 format_gmt

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    # Get the offset in seconds from the UTC
    my $offset = $dt->offset;
    my $str = $locale->gmt_format( $offset );
    # The 'width' is 'long' by default
    my $str = $locale->gmt_format( $offset, width => 'short' );

This returns a localised and formatted GMT timezone given an offset in seconds of the datetime from UTC.

For example:

=over 4

=item * C<GMT>

=item * C<UTC>

=item * C<Гринуич>

=back

Optionally, you can provide the C<width> option that may have the value C<long> (default), or C<short>

If the offset is C<0>, meaning this is the GMT time, then the localised representation of C<GMT> is returned using L<timezone_format_gmt_zero|/timezone_format_gmt_zero>, otherwise it will use the GMT format provided by L<timezone_format_gmt|/timezone_format_gmt> and L<timezone_format_hour|/timezone_format_hour> for the formatting of the C<hours>, C<minutes> and possibly C<seconds>.

Also, if the option C<width> is provided with a value C<short>, then the GMT hours, minutes, seconds formatting will not be zero padded.

For example:

=over 4

=item * C<GMT+03:30>

Long

=item * C<GMT+3:30>

Short

=item * C<UTC-03.00>

Long

=item * C<UTC-3>

Short

=item * C<Гринуич+03:30>

Long

=back

See the L<LDML specifications|https://unicode.org/reports/tr35/tr35-dates.html#Using_Time_Zone_Names> for more information.

=head2 format_timezone_location

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $str = $locale->format_timezone_location( timezone => 'Europe/Rome' );
    # "Italy Time"
    my $str = $locale->format_timezone_location( timezone => 'America/Buenos_Aires' );
    # "Buenos Aires Time"

Returns a properly formatted C<timezone> based on the C<locale> and the given C<timezone> provided in an hash or hash reference.

Note that, if the given C<timezone> is, what is called by the C<LDML> specifications, a "Golden Time Zone", then it represents a territory, and the localised territory name is used instead of the localised exemplar city for that C<timezone>. For example:

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $str = $locale->format_timezone_location( timezone => 'Asia/Taipei' );

would yield C<Taiwan Time>, because C<Asia/Taipei> is the primary C<timezone> for Taiwan.

=head2 format_timezone_non_location

    my $locale = DateTime::Locale::FromCLDR->new( 'ja' );
    my $str = $locale->format_timezone_non_location(
        timezone => 'America/Los_Angeles',
        type => 'standard',
    );
    # アメリカ太平洋標準時
    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $str = $locale->format_timezone_non_location(
        timezone => 'America/Vancouver',
        type => 'standard',
    );
    # Pacific Time (Canada)
    my $str = $locale->format_timezone_non_location(
        timezone => 'America/Phoenix',
        type => 'standard',
    );
    # Mountain Time (Phoenix)
    my $str = $locale->format_timezone_non_location(
        timezone => 'America/Whitehorse',
        type => 'standard',
    );
    # Pacific Time (Whitehorse)

Returns a properly formatted C<timezone> based on the C<locale>, the given C<timezone> and the C<type> provided in an hash or hash reference.

This is using a complexe algorithm defined by the L<LDML specifications|https://unicode.org/reports/tr35/tr35-dates.html#Using_Time_Zone_Names>

The C<type> can only be C<generic>, C<standard>, or C<daylight>:

=over 4

=item * C<generic>

Quoting from the L<LDML specifications|https://unicode.org/reports/tr35/tr35-dates.html#Time_Zone_Names>, "[t]he generic time is so-called wall-time; what clocks use when they are correctly switched from standard to daylight time at the mandated time of the year.". See L<here|https://unicode.org/reports/tr35/tr35-dates.html#Using_Time_Zone_Names> too.

Quoting from the L<LDML specifications|https://unicode.org/reports/tr35/tr35-dates.html#Time_Zone_Format_Terminology>:

=over 8

=item * B<Generic non-location format>

Reflects "wall time" (what is on a clock on the wall): used for recurring events, meetings, or anywhere people do not want to be overly specific. For example, C<10 am Pacific Time> will be GMT-8 in the winter, and GMT-7 in the summer.

For example:

=over 12

=item * C<Pacific Time> (long)

=item * C<PT> (short)

=back

=item * B<Generic partial location format>

Reflects "wall time": used as a fallback format when the generic non-location format is not specific enough.

For example:

=over 12

=item * C<Pacific Time (Canada)> (long)

=item * C<PT (Whitehorse)> (short)

=back

=item * B<Generic location format>

Reflects "wall time": a primary function of this format type is to represent a time zone in a list or menu for user selection of time zone. It is also a fallback format when there is no translation for the generic non-location format. Times can also be organized hierarchically by country for easier lookup.

For example:

=over 12

=item * France Time

=item * Italy Time

=item * Japan Time

=item * United States

=over 16

=item * Chicago Time

=item * Denver Time

=item * Los Angeles Time

=item * New York Time

=back

=item * United Kingdom Time

=back

=back

Note that "[a] generic location format is constructed by a part of time zone ID representing an exemplar city name or its country as the final fallback."

See also the L<LDML specifications|https://unicode.org/reports/tr35/tr35-dates.html#Time_Zone_Format_Terminology>

=item * C<standard> or C<daylight>

"Reflects a specific standard or daylight time, which may or may not be the wall time. For example, C<10 am Pacific Standard Time> will be GMT-8 in the winter and in the summer."

For example:

=over 4

=item * C<Pacific Standard Time> (long)

=item * C<PST> (short)

=item * C<Pacific Daylight Time> (long)

=item * C<PDT> (short)

=back

=back

=head2 has_dst

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $bool = $locale->has_dst( 'Asia/Tokyo' );
    # 0
    my $bool = $locale->has_dst( 'America/Los_Angeles' );
    # 1

Returns true if the given C<timezone> is using daylight saving time, and false otherwise.

The result is cached to ensure repeating calls for the same C<timezone> are returned even faster.

If an error occurred, this will set an L<exception object|DateTime::Locale::FromCLDR::Exception>, and returns C<undef> in scalar context, or an empty list in list context.

How does it work? Very simply, this generates a L<DateTime> object based on the current year and given C<timezone> both for January 1st and July 1st, and get the C<timezone> offset for each. If they do not match, the C<timezone> has daylight saving time.

=head2 id

This is an alias for L<locale|/locale>

=head2 interval_format

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $array = $locale->interval_format( GyMEd => 'G' );
    # ["E, M/d/y G", " – ", "E, M/d/y G", "E, M/d/y G – E, M/d/y G"]
    my $array = $locale->interval_format( GyMEd => 'M' );
    # ["E, M/d/y", " – ", "E, M/d/y G", "E, M/d/y – E, M/d/y G"]
    my $array = $locale->interval_format( GyMEd => 'd' );
    # ["E, M/d/y", " – ", "E, M/d/y G", "E, M/d/y – E, M/d/y G"]
    my $array = $locale->interval_format( GyMEd => 'y' );
    # ["E, M/d/y", " – ", "E, M/d/y G", "E, M/d/y – E, M/d/y G"]

Provided with a format ID and a L<greatest difference token|/interval_greatest_diff>, and this will return an array reference composed of the following 4 elements:

=over 4

=item 1. the first part

=item 2. the separator

=item 3. the second part

=item 4. the L<full interval pattern|https://unicode.org/reports/tr35/tr35-dates.html#intervalFormats>

=back

If nothing is found for the given format ID and greatest difference token, an empty array reference will be returned.

If an error occurred, this will set an L<error object|DateTime::Locale::FromCLDR::Exception> and return C<undef> in scalar context and an empty list.

With L<DateTime::Format::Unicode>, you can do something like:

    my $fmt = DateTime::Format::Unicode->new(
        pattern => 'GyMEd',
        locale  => 'en',
    );
    my $str = $fmt->format_interval( $dt1, $dt2 );

This will use this method L<interval_format|/interval_format>

If nothing is found, you can use the fallback pattern, which is something like this (varies from C<locale> to C<locale>): C<{0} - {1}>

    my $array = $locale->interval_format( default => 'default' );
    # ["{0}", " - ", "{1}", "{0} - {1}"]

However, note that not all locales have a fallback pattern, so even the query above may return an empty array.

For example, as of version C<45.0> (2024) of the C<CLDR> data:

    # German:
    my $locale = DateTime::Locale::FromCLDR->new( 'de' );
    my $array = $locale->interval_format( default => 'default' );
    # []

    # French:
    my $locale = DateTime::Locale::FromCLDR->new( 'fr' );
    my $array = $locale->interval_format( default => 'default' );
    # []

    # Italian:
    my $locale = DateTime::Locale::FromCLDR->new( 'it' );
    my $array = $locale->interval_format( default => 'default' );
    # []

=head2 interval_formats

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $ref = $locale->interval_formats;

This would return something like:

    {
        Bh => [qw( B h )],
        Bhm => [qw( B h m )],
        d => ["d"],
        default => ["default"],
        Gy => [qw( G y )],
        GyM => [qw( G M y )],
        GyMd => [qw( d G M y )],
        GyMEd => [qw( d G M y )],
        GyMMM => [qw( G M y )],
        GyMMMd => [qw( d G M y )],
        GyMMMEd => [qw( d G M y )],
        H => ["H"],
        h => [qw( a h )],
        hm => [qw( a h m )],
        Hm => [qw( H m )],
        hmv => [qw( a h m )],
        Hmv => [qw( H m )],
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

Returns an hash reference of all available interval format IDs and their associated L<greatest difference token|https://unicode.org/reports/tr35/tr35-dates.html#intervalFormats>

The C<default> interval format pattern is something like C<{0} – {1}>, but this changes depending on the C<locale> and is not always available.

C<{0}> is the placeholder for the first datetime and C<{1}> is the placeholder for the second one.

See L<Locale::Unicode::Data/interval_formats>

=head2 interval_greatest_diff

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $diff = $locale->interval_greatest_diff( $dt1, $dt2 );

Provided with 2 L<DateTime objects|DateTime>, and this will compute the L<greatest difference|https://unicode.org/reports/tr35/tr35-dates.html#intervalFormats>.

Quoting from the L<LDML specifications|https://unicode.org/reports/tr35/tr35-dates.html#intervalFormats>:

"The data supplied in CLDR requires the software to determine the calendar field with the greatest difference before using the format pattern. For example, the greatest difference in "Jan 10-12, 2008" is the day field, while the greatest difference in "Jan 10 - Feb 12, 2008" is the month field. This is used to pick the exact pattern."

If both C<DateTime> objects are identical, this will return an empty string.

If an error occurred, an L<exception object|DateTime::Locale::FromCLDR> is set and C<undef> is returned in scalar context, and an empty list in list context.

=head2 is_dst

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $dt = DateTime->new( year => 2024, month => 7, day => 1, time_zone => 'Asia/Tokyo' );
    my $bool = $locale->is_dst( $dt );
    # 0
    my $dt = DateTime->new( year => 2024, month => 7, day => 1, time_zone => 'America/Los_Angeles' );
    my $bool = $locale->is_dst( $dt );
    # 1

Returns true if the given C<timezone> is using daylight saving time, and false otherwise.

The result is cached to ensure repeating calls for the same C<timezone> are returned even faster.

If an error occurred, this will set an L<exception object|DateTime::Locale::FromCLDR::Exception>, and returns C<undef> in scalar context, or an empty list in list context.

How does it work? Very simply, this generates a L<DateTime> object based on the current year and given C<timezone> both for January 1st and July 1st, and get the C<timezone> offset for each. If they do not match, the C<timezone> has daylight saving time.

=head2 is_ltr

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $bool = $locale->is_ltr;
    # 1

    # Hebrew:
    my $locale = DateTime::Locale::FromCLDR->new( 'he' );
    my $bool = $locale->is_ltr;
    # 0

Returns true if the C<locale> is written left-to-right, or false otherwise.

=head2 is_rtl

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $bool = $locale->is_ltr;
    # 0

    # Hebrew:
    my $locale = DateTime::Locale::FromCLDR->new( 'he' );
    my $bool = $locale->is_ltr;
    # 1

Returns true if the C<locale> is written right-to-left, or false otherwise.

=head2 language

    my $locale = DateTime::Locale::FromCLDR->new( 'ja' );
    my $str = $locale->language;
    # Japanese

Returns the name of the C<locale> in English

=head2 language_code

    my $locale = DateTime::Locale::FromCLDR->new( 'ja-Kana-JP' );
    my $str = $locale->language_code;
    # ja
    my $locale = DateTime::Locale::FromCLDR->new( 'ryu-JP' );
    my $str = $locale->language_code;
    # ryu

Returns the C<language> ID part of the C<locale>

=head2 language_id

This is an alias for L<language_code|/language_code>

=head2 locale

Returns the current L<Locale::Unicode> object used in the current object.

=head2 locale_number_system

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $array = $locale->locale_number_system;
    # ["latn", ["0","1","2","3","4","5","6","7","8","9"]]
    my $locale = DateTime::Locale::FromCLDR->new( 'ar' );
    my $array = $locale->locale_number_system;
    # ["arab", ["٠","١","٢","٣","٤","٥","٦","٧","٨","٩"]]

This returns array reference containing 2 elements for the C<locale>, crawling along the inheritance tree until it finds a proper match:

=over 4

=item 0. the numbering system

For example: C<latn>

=item 1. an array reference of digits, starting from 0, in the C<locale>'s own writing.

For example: C<["0","1","2","3","4","5","6","7","8","9"]>

=back

=head2 metazone_daylight_long

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $str = $locale->metazone_daylight_long( metazone => 'Atlantic' );
    # Atlantic Daylight Time
    # America/Guadeloupe

    my $locale = DateTime::Locale::FromCLDR->new( 'fr' );
    my $str = $locale->metazone_daylight_long( metazone => 'Atlantic' );
    # heure d’été de l’Atlantique

This returns the localised metazone name for the C<daylight> saving time mode and C<long> format for the given C<metazone> ID.

If nothing can be found, an empty string is returned.

If an error occurred, an L<exception object|DateTime::Format::FromCLDR::Exception> is set, and C<undef> is returned in scalar context, or an empty list in list context.

=head2 metazone_daylight_short

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $str = $locale->metazone_daylight_short( metazone => 'Atlantic' );
    # ADT

    my $locale = DateTime::Locale::FromCLDR->new( 'fr' );
    my $str = $locale->metazone_daylight_short( metazone => 'Atlantic' );
    # HEA

This returns the localised metazone name for the C<daylight> saving time mode and C<short> format for the given C<metazone> ID.

If nothing can be found, an empty string is returned.

If an error occurred, an L<exception object|DateTime::Format::FromCLDR::Exception> is set, and C<undef> is returned in scalar context, or an empty list in list context.

=head2 metazone_generic_long

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $str = $locale->metazone_generic_long( metazone => 'Atlantic' );
    # Atlantic Time

    my $locale = DateTime::Locale::FromCLDR->new( 'fr' );
    my $str = $locale->metazone_generic_long( metazone => 'Atlantic' );
    # heure de l’Atlantique

This returns the localised metazone name for the C<generic> time and C<long> format for the given C<metazone> ID.

If nothing can be found, an empty string is returned.

If an error occurred, an L<exception object|DateTime::Format::FromCLDR::Exception> is set, and C<undef> is returned in scalar context, or an empty list in list context.

=head2 metazone_generic_short

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $str = $locale->metazone_generic_short( metazone => 'Atlantic' );
    # AT

    my $locale = DateTime::Locale::FromCLDR->new( 'fr' );
    my $str = $locale->metazone_generic_short( metazone => 'Atlantic' );
    # HA

This returns the localised metazone name for the C<generic> time and C<short> format for the given C<metazone> ID.

If nothing can be found, an empty string is returned.

If an error occurred, an L<exception object|DateTime::Format::FromCLDR::Exception> is set, and C<undef> is returned in scalar context, or an empty list in list context.

=head2 metazone_standard_long

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $str = $locale->metazone_standard_long( metazone => 'Atlantic' );
    # Atlantic Standard Time

    my $locale = DateTime::Locale::FromCLDR->new( 'fr' );
    my $str = $locale->metazone_standard_long( metazone => 'Atlantic' );
    # heure normale de l’Atlantique

This returns the localised metazone name for the C<standard> time and C<long> format for the given C<metazone> ID.

If nothing can be found, an empty string is returned.

If an error occurred, an L<exception object|DateTime::Format::FromCLDR::Exception> is set, and C<undef> is returned in scalar context, or an empty list in list context.

=head2 metazone_standard_short

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $str = $locale->metazone_standard_short( metazone => 'Atlantic' );
    # AST

    my $locale = DateTime::Locale::FromCLDR->new( 'fr' );
    my $str = $locale->metazone_standard_short( metazone => 'Atlantic' );
    # HNA

This returns the localised metazone name for the C<standard> time and C<short> format for the given C<metazone> ID.

If nothing can be found, an empty string is returned.

If an error occurred, an L<exception object|DateTime::Format::FromCLDR::Exception> is set, and C<undef> is returned in scalar context, or an empty list in list context.

=head2 month_format_abbreviated

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $array = $locale->month_format_abbreviated;
    say @$array;
    # Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec

Returns an array reference of month names in abbreviated format from January to December.

See also L<Locale::Unicode::Data/calendar_term>

=head2 month_format_narrow

Same as L<month_format_abbreviated|/month_format_abbreviated>, but returns the months in narrow format.

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $array = $locale->month_format_narrow;
    say @$array;
    # J, F, M, A, M, J, J, A, S, O, N, D

=head2 month_format_wide

Same as L<month_format_abbreviated|/month_format_abbreviated>, but returns the months in wide format.

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $array = $locale->month_format_wide;
    say @$array;
    # January, February, March, April, May, June, July, August, September, October, November, December

=head2 month_stand_alone_abbreviated

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $array = $locale->month_stand_alone_abbreviated;
    say @$array;
    # Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec

Returns an array reference of month names in abbreviated stand-alone format from January to December.

See also L<Locale::Unicode::Data/calendar_term>

Note that there is often little difference between the C<format> and C<stand-alone> format types.

See the L<LDML specifications|https://unicode.org/reports/tr35/tr35-dates.html#months_days_quarters_eras> for more information on the difference between the C<format> and C<stand-alone> types.

=head2 month_stand_alone_narrow

Same as L<month_stand_alone_abbreviated|/month_stand_alone_abbreviated>, but returns the months in narrow format.

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $array = $locale->month_stand_alone_narrow;
    say @$array;
    # J, F, M, A, M, J, J, A, S, O, N, D

=head2 month_stand_alone_wide

Same as L<month_format_abbreviated|/month_format_abbreviated>, but returns the months in wide format.

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $array = $locale->month_stand_alone_wide;
    say @$array;
    # January, February, March, April, May, June, July, August, September, October, November, December

=head2 name

    my $locale = DateTime::Locale::FromCLDR->new( 'fr' );
    say $locale->name; # French

    my $locale = DateTime::Locale::FromCLDR->new( 'fr-CH' );
    say $locale->name; # Swiss French

The C<locale>'s name in English.

See also L<native_name|/native_name>

=head2 native_language

    my $locale = DateTime::Locale::FromCLDR->new( 'fr-CH' );
    say $locale->native_language; # français

Returns the C<locale>'s C<language> name as written in the C<locale> own language.

If nothing can be found, it will return an empty string.

=head2 native_name

    my $locale = DateTime::Locale::FromCLDR->new( 'fr-CH' );
    say $locale->native_name; # français suisse

Returns the C<locale>'s name as written in the C<locale> own language.

If nothing can be found, it will return an empty string.

=head2 native_script

    my $locale = DateTime::Locale::FromCLDR->new( 'fr-Latn-CH' );
    say $locale->native_script; # latin

    my $locale = DateTime::Locale::FromCLDR->new( 'fr' );
    say $locale->native_script; # undef

Returns the C<locale>'s C<script> name as written in the C<locale> own language.

If there is no C<script> specified in the C<locale>, it will return C<undef>

If there is a C<script> in the C<locale>, but, somehow, it cannot be found in the C<locale>'s own L<language tree|Locale::Unicode::Data/make_inheritance_tree>, it will return an empty string.

=head2 native_territory

    my $locale = DateTime::Locale::FromCLDR->new( 'fr-CH' );
    say $locale->native_territory; # Suisse

    my $locale = DateTime::Locale::FromCLDR->new( 'fr' );
    say $locale->native_territory; # undef

    my $locale = DateTime::Locale::FromCLDR->new( 'en-Latn-003' );
    say $locale->native_territory; # North America

    my $locale = DateTime::Locale::FromCLDR->new( 'en-XX' );
    say $locale->native_territory; # ''

Returns the C<locale>'s C<territory> name as written in the C<locale> own language.

If there is no C<territory> specified in the C<locale>, it will return C<undef>

If there is a C<territory> in the C<locale>, but, somehow, it cannot be found in the C<locale>'s own L<language tree|Locale::Unicode::Data/make_inheritance_tree>, it will return an empty string.

=head2 native_variant

    my $locale = DateTime::Locale::FromCLDR->new( 'es-valencia' );
    say $locale->native_variant; # Valenciano

    my $locale = DateTime::Locale::FromCLDR->new( 'es' );
    say $locale->native_variant; # undef

    my $locale = DateTime::Locale::FromCLDR->new( 'en-Latn-005' );
    say $locale->native_variant; # undef

Returns the C<locale>'s C<variant> name as written in the C<locale> own language.

If there is no C<variant> specified in the C<locale>, it will return C<undef>, and if there is more than one C<variant> it will return the value for the first one only. To get the values for all variants, use L<native_variants|/native_variants>

If there is a C<variant> in the C<locale>, but, somehow, it cannot be found in the C<locale>'s own L<language tree|Locale::Unicode::Data/make_inheritance_tree>, it will return an empty string.

=head2 native_variants

    my $locale = DateTime::Locale::FromCLDR->new( 'ja-Latn-fonipa-hepburn-heploc' );
    say $locale->native_variants;
    # ["IPA Phonetics", "Hepburn romanization", ""]

Here, C<heploc> is an empty string in the array, because it is a deprecated C<variant>, and as such there is no localised name value for it in the C<CLDR> data.

    my $locale = DateTime::Locale::FromCLDR->new( 'es' );
    say $locale->native_variants; # []

Returns an array reference of each of the C<locale>'s C<variant> subtag name as written in the C<locale> own language.

If there is no C<variant> specified in the C<locale>, it will return an empty array.

If a C<variant> subtag cannot be found in the C<locale>'s own L<language tree|Locale::Unicode::Data/make_inheritance_tree>, then an empty string will be set in the array instead.

Either way, the size of the array will always be equal to the number of variants in the C<locale>

=head2 prefers_24_hour_time

This checks whether the C<locale> prefers the 24H format or the 12H one and returns true (C<1>) if it prefers the 24 hours format or false (C<0>) otherwise.

=head2 quarter_format_abbreviated

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $array = $locale->quarter_format_abbreviated;
    say @$array;
    # Q1, Q2, Q3, Q4

Returns an array reference of quarter names in abbreviated format.

See also L<Locale::Unicode::Data/calendar_term>

=head2 quarter_format_narrow

Same as L<quarter_format_abbreviated|/quarter_format_abbreviated>, but returns the quarters in narrow format.

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $array = $locale->quarter_format_narrow;
    say @$array;
    # 1, 2, 3, 4

=head2 quarter_format_wide

Same as L<quarter_format_abbreviated|/quarter_format_abbreviated>, but returns the quarters in wide format.

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $array = $locale->quarter_format_wide;
    say @$array;
    # 1st quarter, 2nd quarter, 3rd quarter, 4th quarter

=head2 quarter_stand_alone_abbreviated

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $array = $locale->quarter_stand_alone_abbreviated;
    say @$array;
    # Q1, Q2, Q3, Q4

Returns an array reference of quarter names in abbreviated format.

See also L<Locale::Unicode::Data/calendar_term>

Note that there is often little difference between the C<format> and C<stand-alone> format types.

See the L<LDML specifications|https://unicode.org/reports/tr35/tr35-dates.html#months_days_quarters_eras> for more information on the difference between the C<format> and C<stand-alone> types.

=head2 quarter_stand_alone_narrow

Same as L<quarter_stand_alone_abbreviated|/quarter_stand_alone_abbreviated>, but returns the quarters in narrow format.

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $array = $locale->quarter_stand_alone_narrow;
    say @$array;
    # 1, 2, 3, 4

=head2 quarter_stand_alone_wide

Same as L<quarter_stand_alone_abbreviated|/quarter_stand_alone_abbreviated>, but returns the quarters in wide format.

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $array = $locale->quarter_stand_alone_wide;
    say @$array;
    # 1st quarter, 2nd quarter, 3rd quarter, 4th quarter

=head2 script

    my $locale = DateTime::Locale::FromCLDR->new( 'ja-Kana-JP' );
    my $str = $locale->script;
    # Katakana

Returns the name of the C<locale>'s C<script> in English.

If there is no C<script> specified in the C<locale>, it will return C<undef>

If there is a C<script> in the C<locale>, but, somehow, it cannot be found in the C<en> C<locale>'s L<language tree|Locale::Unicode::Data/make_inheritance_tree>, it will return an empty string.

=head2 script_code

    my $locale = DateTime::Locale::FromCLDR->new( 'ja-Kana-JP' );
    my $script = $locale->script_code;
    # Kana

    my $locale = DateTime::Locale::FromCLDR->new( 'ja-JP' );
    my $script = $locale->script_code;
    # undef

Returns the C<locale>'s C<script> ID, or C<undef> if there is none.

=head2 script_id

This is an alias for L<script_code|/script_code>

=head2 territory

    my $locale = DateTime::Locale::FromCLDR->new( 'ja-JP' );
    my $script = $locale->territory;
    # Japan

    my $locale = DateTime::Locale::FromCLDR->new( 'zh-034' );
    my $script = $locale->territory;
    # Southern Asia

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $script = $locale->territory;
    # undef

    my $locale = DateTime::Locale::FromCLDR->new( 'en-XX' );
    my $script = $locale->territory;
    # ''

Returns the name of the C<locale>'s C<territory> in English.

If there is no C<territory> specified in the C<locale>, it will return C<undef>

If there is a C<territory> in the C<locale>, but, somehow, it cannot be found in the C<en> C<locale>'s L<language tree|Locale::Unicode::Data/make_inheritance_tree>, it will return an empty string.

=head2 territory_code

    my $locale = DateTime::Locale::FromCLDR->new( 'ja-JP' );
    my $script = $locale->territory_code;
    # JP

    my $locale = DateTime::Locale::FromCLDR->new( 'ja-Kana' );
    my $script = $locale->territory_code;
    # undef

Returns the C<locale>'s C<territory> ID, or C<undef> if there is none.

=head2 territory_id

This is an alias for L<territory_code|/territory_code>

=head2 time_format_allowed

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $array = $locale->time_format_allowed;

Returns an array reference of L<allowed time patterns|https://unicode.org/reports/tr35/tr35-dates.html#Time_Data> for the C<locale>'s associated territory. If the locale has no C<territory> associated with, it will check the L<likely subtag|Locale::Unicode::Data/likely_subtags> to derive the C<territory> for that C<locale>

=head2 time_format_default

This is an alias for L<time_format_medium|/time_format_medium>

=head2 time_format_full

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    say $locale->time_format_full;
    # h:mm:ss a zzzz
    # 10:44:07 PM UTC

Returns the L<full date pattern|https://unicode.org/reports/tr35/tr35-dates.html#dateFormats>

See also L<Locale::Unicode::Data/calendar_format_l10n>

=head2 time_format_long

Same as L<time_format_full|/time_format_full>, but returns the long format pattern.

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    say $locale->time_format_long;
    # h:mm:ss a z
    # 10:44:07 PM UTC

=head2 time_format_medium

Same as L<time_format_full|/time_format_full>, but returns the medium format pattern.

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    say $locale->time_format_medium;
    # h:mm:ss a
    # 10:44:07 PM

=head2 time_format_preferred

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $str = $locale->time_format_preferred;

Returns a string representing the L<time preferred pattern|https://unicode.org/reports/tr35/tr35-dates.html#Time_Data> for the C<locale>'s associated territory. If the locale has no C<territory> associated with, it will check the L<likely subtag|Locale::Unicode::Data/likely_subtags> to derive the C<territory> for that C<locale>

=head2 time_format_short

Same as L<time_format_full|/time_format_full>, but returns the short format pattern.

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    say $locale->time_format_short;
    # h:mm a
    # 10:44 PM

=head2 time_formats

    my $now = DateTime->now( locale => 'en' );
    my $ref = $locale->time_formats;
    foreach my $type ( sort( keys( %$ref ) ) )
    {
        say $type, ":";
        say $ref->{ $type };
        say $now->format_cldr( $ref->{ $type } ), "\n";
    }

Would produce:

    full:
    h:mm:ss a zzzz
    10:44:07 PM UTC

    long:
    h:mm:ss a z
    10:44:07 PM UTC

    medium:
    h:mm:ss a
    10:44:07 PM

    short:
    h:mm a
    10:44 PM

Returns an hash reference with the keys being: C<full>, C<long>, C<medium>, C<short> and their value the result of their associated time format methods.

=head2 timezone_canonical

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $str = $locale->timezone_canonical( timezone => 'America/Atka' );
    # America/Adak

Returns the canonical version of the given C<timezone>.

The C<CLDR> keeps all timezones, even outdated ones for reliability and consistency, so this method helps switch a given C<timezone> for its canonical counterpart.

If the given C<timezone> is already the canonical one, then it is simply returned.

If none could be found somehow, an empty string would be returned.

=head2 timezone_city

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $str = $locale->timezone_city( timezone => 'America/St_Barthelemy' );
    # St. Barthélemy

    my $locale = DateTime::Locale::FromCLDR->new( 'fr' );
    my $str = $locale->timezone_city( timezone => 'America/St_Barthelemy' );
    # Saint-Barthélemy

    my $locale = DateTime::Locale::FromCLDR->new( 'ja' );
    my $str = $locale->timezone_city( timezone => 'America/St_Barthelemy' );
    # サン・バルテルミー

Returns a string representing the localised version of the exemplar city for a given C<timezone>

If nothing can be found, an empty string is returned.

If an error occurred, an L<exception object|DateTime::Format::FromCLDR::Exception> is set, and C<undef> is returned in scalar context, or an empty list in list context.

=head2 timezone_format_fallback

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $str = $locale->timezone_format_fallback;
    # {1} ({0})

    my $locale = DateTime::Locale::FromCLDR->new( 'ja' );
    my $str = $locale->timezone_format_fallback;
    # {1}（{0}）

Returns the L<fallback|https://unicode.org/reports/tr35/tr35-dates.html#fallbackFormat> C<timezone> localised format "where {1} is the metazone, and {0} is the country or city." (quoting from the L<LDML specifications|https://unicode.org/reports/tr35/tr35-dates.html#fallbackFormat>)

Do not assume you can simply use parenthesis to format it yourself, since the format would change depending on the C<locale> used, and even the parenthesis itself varies as shown in the example above with the Japanese language (here a double byte parenthesis).

If nothing can be found, an empty string is returned.

If an error occurred, an L<exception object|DateTime::Format::FromCLDR::Exception> is set, and C<undef> is returned in scalar context, or an empty list in list context.

See the L<LDML specifications|https://unicode.org/reports/tr35/tr35-dates.html#timeZoneNames_Elements_Used_for_Fallback> for more information.

=head2 timezone_format_gmt

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $str = $locale->timezone_format_gmt;
    # GMT{0}

    my $locale = DateTime::Locale::FromCLDR->new( 'fr' );
    my $str = $locale->timezone_format_gmt;
    # UTC{0}

Returns the GMT localised format.

This needs to be used in conjonction with the L<timezone_format_hour|/timezone_format_hour> to form a complete localised GMt formatted C<timezone>.

For example:

=over 4

=item * C<GMT+03:30>

Long

=item * C<GMT+3:30>

Short

=item * C<UTC-03.00>

Long

=item * C<UTC-3>

Short

=item * C<Гринуич+03:30>

Long

=back

If nothing can be found, an empty string is returned.

If an error occurred, an L<exception object|DateTime::Format::FromCLDR::Exception> is set, and C<undef> is returned in scalar context, or an empty list in list context.

See the L<LDML specifications|https://unicode.org/reports/tr35/tr35-dates.html#Using_Time_Zone_Names> for more information.

=head2 timezone_format_gmt_zero

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $str = $locale->timezone_format_gmt_zero;
    # GMT

    my $locale = DateTime::Locale::FromCLDR->new( 'fr' );
    my $str = $locale->timezone_format_gmt_zero;
    # UTC

Returns the GMT localised format for when the offset is C<0>, i.e. when this is a GMT time.

For example:

=over 4

=item * C<GMT>

=item * C<UTC>

=item * C<Гринуич>

=back

If nothing can be found, an empty string is returned.

If an error occurred, an L<exception object|DateTime::Format::FromCLDR::Exception> is set, and C<undef> is returned in scalar context, or an empty list in list context.

See the L<LDML specifications|https://unicode.org/reports/tr35/tr35-dates.html#Using_Time_Zone_Names> for more information.

=head2 timezone_format_hour

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $str = $locale->timezone_format_hour;
    # ["+HH:mm", "-HH:mm"]

Returns the GMT format for hour, minute and possibly seconds, as an array reference containing 2 elements:

=over 4

=item 0. format for positive offset; and

=item 1. format for negative offset.

=back

If nothing can be found, an empty array reference is returned.

If an error occurred, an L<exception object|DateTime::Format::FromCLDR::Exception> is set, and C<undef> is returned in scalar context, or an empty list in list context.

See the L<LDML specifications|https://unicode.org/reports/tr35/tr35-dates.html#timeZoneNames_Elements_Used_for_Fallback> for more information.

=head2 timezone_format_region

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $str = $locale->timezone_format_region;
    # {0} Time

    my $locale = DateTime::Locale::FromCLDR->new( 'ja' );
    my $str = $locale->timezone_format_region;
    # {0}時間

    my $locale = DateTime::Locale::FromCLDR->new( 'es' );
    my $str = $locale->timezone_format_region;
    # hora de {0}

Returns a string representing the C<timezone> localised regional format, "where {0} is the country or city." (quoting from the L<LDML specifications|https://unicode.org/reports/tr35/tr35-dates.html#Using_Time_Zone_Names>)

For example, once formatted, this would yield:

=over 4

=item * C<Japan Time>

=item * C<日本時間>

=item * C<Hora de Japón>

=back

If nothing can be found, an empty string is returned.

If an error occurred, an L<exception object|DateTime::Format::FromCLDR::Exception> is set, and C<undef> is returned in scalar context, or an empty list in list context.

=head2 timezone_format_region_daylight

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $str = $locale->timezone_format_region_daylight;
    # {0} Daylight Time

    my $locale = DateTime::Locale::FromCLDR->new( 'ja' );
    my $str = $locale->timezone_format_region_daylight;
    # {0}夏時間

Same as L<timezone_format_region|/timezone_format_region>, but uses the C<daylight> saving time format.

=head2 timezone_format_region_standard

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $str = $locale->timezone_format_region_standard;
    # {0} Standard Time

    my $locale = DateTime::Locale::FromCLDR->new( 'ja' );
    my $str = $locale->timezone_format_region_standard;
    # {0}標準時

Same as L<timezone_format_region|/timezone_format_region>, but uses the C<daylight> saving time format.

=head2 timezone_daylight_long

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $str = $locale->timezone_daylight_long( timezone => 'Europe/London' );
    # British Summer Time

Returns a string of a localised representation of a given C<timezone>, for the C<daylight> saving time in C<long> format.

If none exists for the given C<timezone>, which may often be the case, you need to use the C<timezone> format methods instead (L<timezone_format_fallback|/timezone_format_fallback>, L<timezone_format_gmt|/timezone_format_gmt>, L<timezone_format_gmt_zero|/timezone_format_gmt_zero>, L<timezone_format_hour|/timezone_format_hour>, L<timezone_format_hour|/timezone_format_hour>, L<timezone_format_region|/timezone_format_region>, L<timezone_format_region_daylight|/timezone_format_region_daylight>, and L<timezone_format_region_standard|/timezone_format_region_standard>)

If nothing can be found, an empty string is returned.

If an error occurred, an L<exception object|DateTime::Format::FromCLDR::Exception> is set, and C<undef> is returned in scalar context, or an empty list in list context.

See the L<LDML specifications|https://unicode.org/reports/tr35/tr35-dates.html#Using_Time_Zone_Names> for more information.

=head2 timezone_daylight_short

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $str = $locale->timezone_daylight_short( timezone => 'Europe/London' );
    # ""

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $str = $locale->timezone_daylight_short( timezone => 'Pacific/Honolulu' );
    # HDT

Same as L<timezone_daylight_long|/timezone_daylight_long>, but for the C<daylight> saving time C<short> format.

=head2 timezone_generic_long

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $str = $locale->timezone_generic_long( timezone => 'Europe/London' );
    # ""

Same as L<timezone_daylight_long|/timezone_daylight_long>, but for the C<generic> C<long> format.

=head2 timezone_generic_short

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $str = $locale->timezone_generic_short( timezone => 'Europe/London' );
    # ""

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $str = $locale->timezone_generic_short( timezone => 'Pacific/Honolulu' );
    # HST

Same as L<timezone_daylight_long|/timezone_daylight_long>, but for the C<generic> C<short> format.

=head2 timezone_standard_long

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $str = $locale->timezone_standard_long( timezone => 'Europe/London' );
    # ""

Same as L<timezone_daylight_long|/timezone_daylight_long>, but for the C<standard> C<long> format.

=head2 timezone_standard_short

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $str = $locale->timezone_standard_short( timezone => 'Europe/London' );
    # ""

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $str = $locale->timezone_standard_short( timezone => 'Pacific/Honolulu' );
    # HST

Same as L<timezone_daylight_long|/timezone_daylight_long>, but for the C<standard> C<short> format.

=head2 variant

    my $locale = DateTime::Locale::FromCLDR->new( 'es-valencia' );
    my $script = $locale->variant;
    # Valencian

    my $locale = DateTime::Locale::FromCLDR->new( 'es' );
    my $script = $locale->variant;
    # undef

    # No such thing as variant 'klingon'. Language 'tlh' exists though :)
    my $locale = DateTime::Locale::FromCLDR->new( 'en-klingon' );
    my $script = $locale->variant;
    # ''

Returns the name of the C<locale>'s C<variant> in English.

If there is no C<variant> specified in the C<locale>, it will return C<undef>

If there is a C<variant> in the C<locale>, but, somehow, it cannot be found in the C<en> C<locale>'s L<language tree|Locale::Unicode::Data/make_inheritance_tree>, it will return an empty string.

=head2 variant_code

    my $locale = DateTime::Locale::FromCLDR->new( 'es-valencia' );
    my $script = $locale->variant_code;
    # valencia

    my $locale = DateTime::Locale::FromCLDR->new( 'es-ES' );
    my $script = $locale->variant_code;
    # undef

Returns the C<locale>'s C<variant> ID, or C<undef> if there is none.

=head2 variant_id

This is an alias for L<variant_code|/variant_code>

=head2 variants

    my $locale = DateTime::Locale::FromCLDR->new( 'es-valencia' );
    my $array = $locale->variants;
    # ["valencia"]

    my $locale = DateTime::Locale::FromCLDR->new( 'ja-Latn-fonipa-hepburn-heploc' );
    my $array = $locale->variants;
    # ["fonipa", "hepburn", "heploc"]

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    my $array = $locale->variants;
    # []

This returns an array reference of C<variant> subtags for this C<locale>, even if there is no variant.

=head2 version

    my $locale = DateTime::Locale::FromCLDR->new( 'en' );
    say $locale->version; # 45.0

Returns the Unicode C<CLDR> data version number.

=head1 SERIALISATION

C<Locale::Unicode> supports L<Storable::Improved>, L<Storable>, L<Sereal> and L<CBOR|CBOR::XS> serialisation, by implementing the methods C<FREEZE>, C<THAW>, C<STORABLE_freeze>, C<STORABLE_thaw>

For serialisation with L<Sereal>, make sure to instantiate the L<Sereal encoder|Sereal::Encoder> with the C<freeze_callbacks> option set to true, otherwise, C<Sereal> will not use the C<FREEZE> and C<THAW> methods.

See L<Sereal::Encoder/"FREEZE/THAW CALLBACK MECHANISM"> for more information.

For L<CBOR|CBOR::XS>, it is recommended to use the option C<allow_sharing> to enable the reuse of references, such as:

    my $cbor = CBOR::XS->new->allow_sharing;

Also, if you use the option C<allow_tags> with L<JSON>, then all of those modules will work too, since this option enables support for the C<FREEZE> and C<THAW> methods.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Locale::Unicode>, L<Locale::Unicode::Data>, L<DateTime::Format::Unicode>

L<DateTime::Locale>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2024 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
