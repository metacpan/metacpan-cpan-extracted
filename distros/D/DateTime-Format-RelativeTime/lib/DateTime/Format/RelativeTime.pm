##----------------------------------------------------------------------------
## DateTime Format Relative Time - ~/lib/DateTime/Format/RelativeTime.pm
## Version v0.2.0
## Copyright(c) 2025 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2024/12/30
## Modified 2025/10/16
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package DateTime::Format::RelativeTime;
BEGIN
{
    use v5.10.1;
    use strict;
    use warnings;
    use warnings::register;
    use vars qw(
        $VERSION $DEBUG $ERROR $FATAL_EXCEPTIONS
    );
    use DateTime;
    use DateTime::Locale::FromCLDR;
    use Locale::Intl;
    use Locale::Unicode::Data v1.3.2;
    use Scalar::Util ();
    use Wanted;
    our $VERSION = 'v0.2.0';
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
            my $all = $cldr->time_relatives_l10n(
                locale => $l,
            );
            return( $self->pass_error( $cldr->error ) ) if( !defined( $all ) && $cldr->error );
            if( $all && scalar( @$all ) )
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
    $self->{locale} = $locale;
    my $unicode = $self->{_unicode} = DateTime::Locale::FromCLDR->new( $locale ) ||
        return( $self->pass_error( DateTime::Locale::FromCLDR->error ) );

    my @component_options = qw( numberingSystem style numeric );
    my @core_options = grep{ exists( $opts->{ $_ } ) } @component_options;
    # RangeError: invalid value "plop" for option month
    my %valid_options = 
    (
        localeMatcher           => ['lookup', 'best fit'],
        # numberingSystem is processed separately
        numberingSystem         => qr/[a-zA-Z][a-zA-Z0-9]+/,
        style                   => [qw( long narrow short )],
        numeric                 => [qw( always auto )],
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
                return( $self->error({
                    type => 'RangeError',
                    message => "Invalid value \"${value}\" for option ${key}. Expected one of: " . @{$valid_options{ $key }},
                }) );
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

    my $resolved = 
    {
        locale => $locale,
    };
    @$resolved{ @core_options } = @$opts{ @core_options };
    my $num_sys = $opts->{numberingSystem};

    my $systems = $unicode->number_systems;
    my $ns_default = $unicode->number_system;
    # To contain the locale's number system's digits
    my $ns_digits;
    my $ns_default_def = $cldr->number_system( number_system => $ns_default ) ||
        return( $self->pass_error( $cldr->error ) );
    undef( $ns_default ) unless( $ns_default_def->{type} eq 'numeric' );
    # NOTE: number system check
    # The user has provided a number system as the option 'numberingSystem', let's check it
    if( $num_sys )
    {
        my $num_sys_def = $cldr->number_system( number_system => $num_sys );
        return( $self->pass_error( $cldr->error ) ) if( !defined( $num_sys_def ) && $cldr->error );
        if( $num_sys_def && scalar( keys( %$num_sys_def ) ) )
        {
            # 'latn' is always supported by all locale as per the LDML specifications
            # We reject the specified if it is not among the locale's default, and if it is not 'numeric' (e.g. if it is algorithmic)
            if( $num_sys eq 'latn' || 
                (
                    scalar( grep( ( $systems->{ $_ } // '' ) eq $num_sys, qw( number_system native ) ) ) && 
                    $num_sys_def->{type} eq 'numeric'
                ) )
            {
                $ns_digits = $num_sys_def->{digits};
            }
            elsif( $num_sys_def->{type} eq 'numeric' )
            {
                warn( "Warning only: this requested numbering system \"${num_sys}\" is not natural for this locale \"${locale}\"." );
            }
            else
            {
                warn( "Warning only: unsupported numbering system provided \"${num_sys}\" for locale \"${locale}\"." ) if( warnings::enabled() );
                undef( $num_sys );
            }
        }
        # The proper behaviour is to ignore bad value and fall back to 'latn'
        else
        {
            warn( "Warning only: invalid numbering system provided \"${num_sys}\"." ) if( warnings::enabled() );
            undef( $num_sys );
        }
    }

    # Check if a valid numbering system was provided as an attribute to the locale.
    if( !defined( $num_sys ) && ( my $locale_num_sys = $locale->number ) )
    {
        my $num_sys_def = $cldr->number_system( number_system => $locale_num_sys );
        return( $self->pass_error( $cldr->error ) ) if( !defined( $num_sys_def ) && $cldr->error );
        $num_sys_def ||= {};
        if( $locale_num_sys eq 'latn' || ( scalar( grep( ( $systems->{ $_ } // '' ) eq $locale_num_sys, qw( number_system native ) ) ) && $num_sys_def->{type} ne 'numeric' ) )
        {
            $num_sys = $locale_num_sys;
        }
        else
        {
            warn( "Warning only: unsupported numbering system provided (${locale_num_sys}) via the locale \"nu\" extension (${locale})." ) if( warnings::enabled() );
        }
    }

    # If no number system was provided, or if it was maybe invalid, we check the locale's default number system, and before that we make sure to expand the locale if necessary so that, for example, 'en' becomes 'en-Latn-US', or 'ar' becomes 'ar-Arab-EG'
    # If the locale already has a country code / region associated, it is specific enough
    if( !defined( $num_sys ) && !( my $cc = $locale->country_code ) )
    {
        my $tree = $cldr->make_inheritance_tree( $locale ) ||
            return( $self->pass_error( $cldr->error ) );
        LOCALE: foreach my $loc ( @$tree )
        {
            my $ref = $cldr->likely_subtag( locale => $loc );
            # Ok, we found an expanded locale, now let's get its number system
            if( $ref && $ref->{target} )
            {
                my $expanded_locale = Locale::Unicode->new( $ref->{target} ) ||
                    return( $self->pass_error( Locale::Unicode->error ) );
                # Get the locale number systems
                my $expanded_locale_tree = $cldr->make_inheritance_tree( $expanded_locale );
                return( $self->pass_error( $cldr->error ) ) if( !defined( $expanded_locale_tree ) && $cldr->error );

                my $locale_ns_def;
                LOCALE_NS_SEARCH: foreach my $l ( @$expanded_locale_tree )
                {
                    my $this = $cldr->locale_number_system( locale => $l );
                    return( $self->pass_error( $cldr->error ) ) if( !defined( $this ) && $cldr->error );
                    if( $this && scalar( keys( %$this ) ) )
                    {
                        $locale_ns_def = $this;
                        last LOCALE_NS_SEARCH;
                    }
                }
                return( $self->error( "Unable to find any numbering system for any locale in the inheritance tree @$expanded_locale_tree" ) ) if( !defined( $locale_ns_def ) );

                foreach my $ns_type ( qw( number_system native traditional finance ) )
                {
                    # It may not be defined for that locale, and in this case, we skip to the next one.
                    next if( !length( $locale_ns_def->{ $ns_type } // '' ) );
                    my $ns_def = $cldr->number_system( number_system => $locale_ns_def->{ $ns_type } );
                    return( $self->pass_error( $cldr->error ) ) if( !defined( $ns_def ) && $cldr->error );
                    # It needs to be 'numeric', as opposed to 'algorithmic', or else we cannot use it
                    if( $ns_def->{type} eq 'numeric' &&
                        defined( $ns_def->{digits} ) &&
                        ref( $ns_def->{digits} ) eq 'ARRAY' &&
                        scalar( @{$ns_def->{digits}} ) )
                    {
                        $ns_digits = $ns_def->{digits};
                        $num_sys = $locale_ns_def->{ $ns_type };
                        last LOCALE;
                    }
                }
            }
        }
    }
    
    # Still have not found anything
    if( !length( $num_sys // '' ) )
    {
        $num_sys //= $ns_default || 'latn';
    }
    $resolved->{numberingSystem} = $num_sys;

    unless( $resolved->{style} )
    {
        $resolved->{style} = 'long';
    }

    unless( $resolved->{numeric} )
    {
        $resolved->{numeric} = 'always';
    }

    $self->{resolvedOptions} = $resolved;
    unless( defined( $ns_digits ) )
    {
        my $ns_def = $cldr->number_system( number_system => $num_sys );
        return( $self->pass_error( $cldr->error ) ) if( !defined( $ns_def ) && $cldr->error );
        unless( exists( $ns_def->{digits} ) &&
                defined( $ns_def->{digits} ) &&
                ref( $ns_def->{digits} ) eq 'ARRAY' &&
                scalar( @{$ns_def->{digits}} ) )
        {
            return( $self->error( "Unable to find digits for the numbering system '${num_sys}'" ) );
        }
        $ns_digits = $ns_def->{digits};
    }
    $self->{_ns_digits} = $ns_digits;
    return( $self );
}

sub error
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $def = {};
        if( @_ == 1 &&
            defined( $_[0] ) &&
            ref( $_[0] ) eq 'HASH' &&
            exists( $_[0]->{message} ) )
        {
            $def = shift( @_ );
        }
        else
        {
            $def->{message} = join( '', map( ( ref( $_ ) eq 'CODE' ) ? $_->() : $_, @_ ) );
        }
        $def->{skip_frames} = 1 unless( exists( $def->{skip_frames} ) );
        $self->{error} = $ERROR = DateTime::Format::RelativeTime::Exception->new( $def );
        if( $self->fatal )
        {
            die( $self->{error} );
        }
        else
        {
            warn( $def->{message}  ) if( warnings::enabled() );
            if( want( 'ARRAY' ) )
            {
                rreturn( [] );
            }
            elsif( want( 'OBJECT' ) )
            {
                rreturn( DateTime::Format::RelativeTime::NullObject->new );
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
    my $parts = $self->format_to_parts( @_ ) || return( $self->pass_error );
    if( !scalar( @$parts ) )
    {
        return( $self->error( "Error formatting to parts. No data received!" ) );
    }

    my $str = join( '', map( $_->{value}, @$parts ) );
    return( $str );
}

# $self->format_to_parts( 1, 'day' );
# $self->format_to_parts( -2, 'days' );
# Or, let's find out automatically
# $self->format_to_parts( $dt );
sub format_to_parts
{
    my $self = shift( @_ );
    return( $self->error( "format_to_parts() must be called with an object, and not as a class function." ) ) if( !ref( $self ) );
    my $cldr = $self->{_cldr} ||
        die( "Our Locale::Unicode::Data object is gone!" );
    my $unicode = $self->{_unicode} ||
        die( "Our DateTime::Locale::FromCLDR object is gone!" );
    my $locale = $self->{locale} || die( "Our Locale::Unicode object is gone!" );
    my( $num, $unit );

    if( @_ >= 1 && 
        defined( $_[0] ) &&
        Scalar::Util::blessed( $_[0] ) &&
        $_[0]->isa( 'DateTime' ) )
    {
        my( $dt, $now );
        if( @_ > 2 )
        {
            return( $self->error({
                type => 'RangeError',
                message => "format_to_parts() accepts only 1 or 2 DateTime objects."
            }) );
        }
        elsif( @_ == 2 )
        {
            if( defined( $_[1] ) &&
                Scalar::Util::blessed( $_[1] ) &&
                $_[1]->isa( 'DateTime' ) )
            {
                ( $dt, $now ) = @_;
            }
            else
            {
                return( $self->error({
                    type => 'RangeError',
                    message => "format_to_parts() requires the second DateTime to be provided if you provide 2 arguments."
                }) );
            }
        }
        else
        {
            $dt = shift( @_ );
            $now = DateTime->now( time_zone => $dt->time_zone );
        }
        my( $diff_val, $diff_unit ) = $self->_greatest_interval( $dt => $now );
        return( $self->pass_error ) if( !defined( $diff_val ) );
        if( length( $diff_unit ) )
        {
            ( $num, $unit ) = ( $diff_val, $diff_unit );
        }
        else
        {
            $num = 0;
            $unit = 'second';
        }
    }
    elsif( @_ == 2 )
    {
        ( $num, $unit ) = @_;
        # This regular expression should support numbers like: 1, 1.5, 0.5 or even .5, but
        # it will yield an error on numbers like: 01.5, or 1,500.3
        if( $num !~ /^-?(?:(0|[1-9]\d*)(\.\d+)?|(?:\d*\.)?\d+)$/ )
        {
            return( $self->error({
                type => 'RangeError',
                message => "format_to_parts() must be called with a valid integer or decimal number, and a unit."
            }) );
        }
        elsif( $unit !~ /^(?:year|quarter|month|week|day|hour|minute|second)s?$/i )
        {
            return( $self->error({
                type => 'RangeError',
                message => "Supported unit value must be one of: 'year', 'quarter', 'month', 'week', 'day', 'hour', 'minute', 'second'"
            }) );
        }
        $unit = lc( $unit );
        # Remove the 's' at the end if there is one
        $unit = substr( $unit, 0, -1 ) if( substr( $unit, -1, 1 ) eq 's' );
        # $num could be 0.0, and this edge case would disrupt formatting, so we need to transform it to a simple 0
        # Using sprintf also ensures .5 becomes 0.5, or -.5 becomes -0.5
        $num = sprintf( '%.15g', $num );
    }
    else
    {
        return( $self->error({
            type => 'RangeError',
            message => "format_to_parts() requires either a numerical value and a unit, or a DateTime object."
        }) );
    }
    my $opts = $self->resolvedOptions;
    my $pattern;
    my $algo = lc( $opts->{numeric} || 'always' );
    my $style = lc( $opts->{style} || 'long' );
    # This should already be defined, and if it is not anymore, then something is wrong
    my $num_sys = lc( $opts->{numberingSystem} || 'latn' );
    # This is because Locale::Unicode::Data stored this format as 'standard', but the Web API defines it as 'long'
    my $cldr_style = ( $style eq 'long' ? 'standard' : $style );
    my $tree = $cldr->make_inheritance_tree( $locale ) ||
        return( $self->pass_error( $cldr->error ) );
    # We set an array of possible styles to try to find the most appropriate, while putting the user preferred one first
    my @styles = ( $cldr_style, ( grep{ $_ ne $style } qw( standard short narrow ) ) );
    # If the algorithm is set to auto, we check if we can find a relative value -1, 0 or 1 for our unit type
    # If not, we fall back to the numeric pattern
    if( $algo eq 'auto' && 
        ( $num >= -1 && $num <= 1 ) )
    {
        LOCALE: foreach my $loc ( @$tree )
        {
            foreach my $this_style ( @styles )
            {
                my $ref = $cldr->date_field_l10n(
                    locale => $loc,
                    field_type => $unit,
                    field_length => $this_style,
                    relative => $num,
                );
                return( $self->pass_error( $cldr->error ) ) if( !defined( $ref ) && $cldr->error );
                if( $ref && scalar( keys( %$ref ) ) )
                {
                    $pattern = $ref->{locale_name};
                    last LOCALE;
                }
            }
        }
    }
    # Either the algorithm is not set to 'auto', or our 'auto' attempt has failed, and we fallback to the numeric pattern
    # And, if so, we then have only two choices: past (-1) or future (1), which also includes the present (0),
    # so, we need to change $num to 1 if it is greater or equal to 0, or -1 if it is lower than 0
    if( !defined( $pattern ) )
    {
        my $count = $cldr->plural_count( abs( $num ), $locale );
        my $cldr_num = ( $num < 0 ? -1 : 1 );
        my @best = ();
        LOCALE: foreach my $loc ( @$tree )
        {
            foreach my $this_style ( @styles )
            {
                # As a safe fallback, we add 'other'
                foreach my $cnt ( $count, ( $count ne 'other' ? ( 'other' ) : () ) )
                {
                    my $ref = $cldr->time_relative_l10n(
                        locale => $loc,
                        field_type => $unit,
                        field_length => $this_style,
                        relative => $cldr_num,
                        count => $cnt,
                    );
                    return( $self->pass_error( $cldr->error ) ) if( !defined( $ref ) && $cldr->error );
                    if( $ref && scalar( keys( %$ref ) ) )
                    {
                        # If this style matches exactly that of user preferred one, we stop here, otherwise, we add it with a score so we can take the best pick after.
                        if( $this_style eq $cldr_style )
                        {
                            $pattern = $ref->{format_pattern};
                            last LOCALE;
                        }
                        else
                        {
                            push( @best, { style => $this_style, pattern => $pattern });
                        }
                    }
                }
            }
        }
        if( !defined( $pattern ) && scalar( @best ) )
        {
            $pattern = $best[0];
        }
    }
    return( $self->error( "No suitable pattern could be found. Something is wrong with the Locale::Unicode::Data database." ) ) if( !defined( $pattern ) );

    my $decimal;
    # If the number used has a decimal point, then we get the localised value of it.
    if( index( $num, '.' ) != -1 )
    {
        LOCALE: foreach my $loc ( @$tree )
        {
            my $ref = $cldr->number_symbol_l10n(
                locale => $loc,
                number_system => $num_sys,
                property => 'decimal',
            );
            return( $self->pass_error( $cldr->error ) ) if( !defined( $ref ) && $cldr->error );
            if( $ref && scalar( keys( %$ref ) ) && length( $ref->{value} // '' ) )
            {
                $decimal = $ref->{value};
                last LOCALE;
            }
        }
    }

    my $parts = $self->_format_to_parts(
        pattern => $pattern,
        unit => $unit,
        value => $num,
        ( defined( $decimal ) ? ( decimal => $decimal ) : () ),
    ) || return( $self->pass_error );
    return( $parts );
}

sub formatToParts { return( shift->format_to_parts( @_ ) ); }

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
        rreturn( DateTime::Format::RelativeTime::NullObject->new );
    }
    return;
}

sub resolvedOptions { return( shift->_set_get_prop( 'resolvedOptions', @_ ) ); }

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
            my $all = $cldr->time_relatives_l10n(
                locale => $loc,
            );
            if( $all && ref( $all ) eq 'ARRAY' && scalar( @$all ) )
            {
                push( @$res, $loc );
                next LOCALE;
            }
        }
    }
    return( $res );
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

# Takes a pattern, break it down into pieces of information as an hash reference and return an array of those hash references
sub _format_to_parts
{
    my $self = shift( @_ );
    my $args = $self->_get_args_as_hash( @_ );
    my $pat = $args->{pattern} || die( "No pattern was provided." );
    my $val = $args->{value};
    die( "No value was provided." ) if( !length( $val // '' ) );
    my $unit = $args->{unit} || die( "No unit was provided." );
    my $decimal = $args->{decimal};

    my $locale = $self->{locale} || die( "Our Locale::Unicode object is gone!" );
    my $digits = $self->{_ns_digits};
    unless( defined( $digits ) &&
            ref( $digits ) eq 'ARRAY' &&
            scalar( @$digits ) )
    {
        die( "Our numbering system digits are gone!" );
    }
    my $opts = $self->resolvedOptions;
    my $num_sys = $opts->{numberingSystem};

    my $parts = [];
    if( index( $pat, '{0}' ) == -1 )
    {
        return([
            {
                type => 'literal',
                value => $pat,
            }
        ]);
    }

    my @chunks = grep( length( $_ // '' ), split( /(\{0\})/, $pat ) );
    for my $i ( 0 .. $#chunks )
    {
        if( $chunks[$i] eq '{0}' )
        {
            # $val could be an integer, or a decimal
            # if it is a decimal such as 3.5, then we need to create an hash entry for '3', '.' and '5'
            my( $int, $fraction ) = split( /\./, abs( $val ), 2 );
            push( @$parts, {
                type => 'integer',
                value => join( '', map( $digits->[ $_ ], split( //, $int ) ) ),
                unit => $unit,
            });
            if( defined( $fraction ) && length( $fraction ) )
            {
                push( @$parts, {
                    type => 'decimal',
                    value => $decimal,
                    unit => $unit,
                });
                push( @$parts, {
                    type => 'fraction',
                    value => join( '', map( $digits->[ $_ ], split( //, $fraction ) ) ),
                    unit => $unit,
                });
            }
        }
        else
        {
            push( @$parts, {
                type => 'literal',
                value => $chunks[$i],
            });
        }
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

sub _greatest_interval
{
    my( $self, $dt1, $dt2 ) = @_;
    unless( defined( $dt1 ) &&
            Scalar::Util::blessed( $dt1 ) &&
            $dt1->isa( 'DateTime' ) )
    {
        return( $self->error( "The first argument provided is not a DateTime object." ) );
    }
    unless( defined( $dt2 ) &&
            Scalar::Util::blessed( $dt2 ) &&
            $dt2->isa( 'DateTime' ) )
    {
        return( $self->error( "The second argument provided is not a DateTime object." ) );
    }

    # Factor for direction of time
    my $time_orientation_factor = 1;
    # Check if dt2 precedes dt1 and adjust reverse factor
    if( $dt2 < $dt1 )
    {
        ( $dt1, $dt2 ) = ( $dt2, $dt1 );
        # Reverse direction
        $time_orientation_factor = -1;
    }
    my $duration = $dt2 - $dt1;

    my %intervals = 
    (
        year    => $duration->in_units( 'years' ),
        quarter => 0,
        month   => $duration->in_units( 'months' ),
        week    => $duration->in_units( 'weeks' ),
        day     => $duration->in_units( 'days' ),
        hour    => $duration->in_units( 'hours' ),
        minute  => $duration->in_units( 'minutes' ),
        second  => $duration->in_units( 'seconds' ),
    );

    # DateTime::Duration does not support quarters, so we check ourself if the difference spans across quarters
    my $start_quarter = int( ( $dt1->month - 1 ) / 3 ) + 1;
    my $end_quarter   = int( ( $dt2->month - 1 ) / 3 ) + 1;
    my $quarter_diff  = ( $dt2->year - $dt1->year ) * 4 + ( $end_quarter - $start_quarter );
    $intervals{quarter} = $quarter_diff if( $quarter_diff > 0 );
    # $intervals{quarter} = abs( $quarter_diff ) if( $quarter_diff );

    # Find the greatest interval unit by considering the hierarchy of units
    my @units_order = qw( year quarter month week day hour minute second );
    foreach my $unit ( @units_order )
    {
        if( $intervals{ $unit } > 0 )
        {
            return( wantarray ? ( ( $intervals{ $unit } * $time_orientation_factor ), $unit ) : $unit );
        }
    }
    return( wantarray ? () : '' );
}

sub _locale_object
{
    my $self = shift( @_ );
    my $locale = shift( @_ ) ||
        return( $self->error( "No locale provided to ensure a Locale::Unicode." ) );
    unless( Scalar::Util::blessed( $locale ) &&
            $locale->isa( 'Locale::Unicode' ) )
    {
        $locale = Locale::Unicode->new( $locale ) ||
            return( $self->pass_error( Locale::Unicode->error ) );
    }
    return( $locale );
}

sub _set_get_prop
{
    my $self = shift( @_ );
    my $prop = shift( @_ ) || die( "No object property was provided." );
    $self->{ $prop } = shift( @_ ) if( @_ );
    return( $self->{ $prop } );
}

# NOTE: DateTime::Format::RelativeTime::Exception class
package DateTime::Format::RelativeTime::Exception;
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
        elsif( ref( $_[0] ) && $_[0]->isa( 'DateTime::Format::RelativeTime::Exception' ) )
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
    # NOTE: DateTime::Format::RelativeTime::NullObject class
    package
        DateTime::Format::RelativeTime::NullObject;
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

=encoding utf-8

=head1 NAME

DateTime::Format::RelativeTime - A Web Intl.RelativeTimeFormat Class Implementation

=head1 SYNOPSIS

    use DateTime;
    use DateTime::Format::RelativeTime;
    my $fmt = DateTime::Format::RelativeTime->new(
        # You can use en-GB (Unicode / web-style) or en_GB (system-style), it does not matter.
        'en_GB', {
            localeMatcher => 'best fit',
            # see getNumberingSystems() in Locale::Intl for the supported number systems
            numberingSystem => 'latn',
            # Possible values are: long, short or narrow
            style => 'short',
            # Possible values are: always or auto
            numeric => 'always',
        },
    ) || die( DateTime::Format::RelativeTime->error );

    # Format relative time using negative value (-1).
    $fmt->format( -1, 'day' ); # "1 day ago"

    # Format relative time using positive value (1).
    $fmt->format( 1, 'day' ); # "in 1 day"

You can also pass one or two L<DateTime> objects, and let this interface find out the greatest difference between the two objects. If you pass only one L<DateTime> object, this will instantiate another L<DateTime> object, using the method L<now|DateTime/now> with the C<time_zone> value from the first object.

    my $dt = DateTime->new(
        year => 2024,
        month => 8,
        day => 15,
    );
    $fmt->format( $dt );
    # Assuming today is 2024-12-31, this would return: "1 qtr. ago"

or, with 2 L<DateTime> objects:

    my $dt = DateTime->new(
        year => 2024,
        month => 8,
        day => 15,
    );
    my $dt2 = DateTime->new(
        year => 2022,
        month => 2,
        day => 22,
    );
    $fmt->format( $dt => $dt2 ); # "2 yr. ago"

Using the auto option

If C<numeric> option is set to C<auto>, it will produce the string C<yesterday> or C<tomorrow> instead of C<1 day ago> or C<in 1 day>. This allows to not always have to use numeric values in the output.

    # Create a relative time formatter in your locale with numeric option set to 'auto'.
    my $fmt = DateTime::Format::RelativeTime->new( 'en', { numeric => 'auto' });

    # Format relative time using negative value (-1).
    $fmt->format( -1, 'day' ); # "yesterday"

    # Format relative time using positive day unit (1).
    $fmt->format( 1, 'day' ); # "tomorrow"

In basic use without specifying a locale, C<DateTime::Format::RelativeTime> uses the default locale and default options.

A word about precision:

When formatting numbers for display, this module uses up to 15 significant digits. This decision balances between providing high precision for calculations and maintaining readability for the user. If numbers with more than 15 significant digits are provided, they will be formatted to this limit, which should suffice for most practical applications:

    my $num = 0.123456789123456789;
    my $formatted = sprintf("%.15g", $num);
    # $formatted would be "0.123456789123457"

For users requiring exact decimal representation beyond this precision, consider using modules like L<Math::BigFloat>.

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This module provides the equivalent of the JavaScript implementation of L<Intl.RelativeTimeFormat|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/RelativeTimeFormat>

It relies on L<Locale::Unicode::Data>, which provides access to all the L<Unicode CLDR (Common Locale Data Repository)|https://cldr.unicode.org/>, and L<Locale::Intl> to achieve similar results. It requires perl v5.10.1 minimum to run.

The algorithm provides the same result you would get with a web browser.

Because, just like its JavaScript equivalent, C<DateTime::Format::Intl> does quite a bit of look-ups and sensible guessing upon object instantiation, you want to create an object for a specific format, cache it and re-use it rather than creating a new one for each date formatting.

=head1 CONSTRUCTOR

=head2 new

    # Create a relative time formatter in your locale
    # with default values explicitly passed in.
    my $fmt = DateTime::Format::RelativeTime->new( 'en', {
        localeMatcher => 'best fit', # other values: 'lookup'
        numeric => 'always', # other values: 'auto'
        style => 'long', # other values: 'short' or 'narrow'
    }) || die( DateTime::Format::RelativeTime->error );

    # Format relative time using negative value (-1).
    $fmt->format( -1, 'day' ); # "1 day ago"

    # Format relative time using positive value (1).
    $fmt->format( 1, 'day' ); # "in 1 day"

This takes a C<locale> (a.k.a. language C<code> compliant with L<ISO 15924|https://en.wikipedia.org/wiki/ISO_15924> as defined by L<IETF|https://en.wikipedia.org/wiki/IETF_language_tag#Syntax_of_language_tags>) and an hash or hash reference of options and will return a new L<DateTime::Format::RelativeTime> object, or upon failure C<undef> in scalar context and an empty list in list context.

Each option can also be accessed or changed using their corresponding method of the same name.

See the L<CLDR (Unicode Common Locale Data Repository) page|https://cldr.unicode.org/translation/date-time/date-time-patterns> for more on the format patterns used.

Supported options are:

=head3 Locale options

=over 4

=item * C<localeMatcher>

The locale matching algorithm to use. Possible values are C<lookup> and C<best fit>; the default is C<best fit>. For information about this option, see L<Locale identification and negotiation|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl#locale_identification_and_negotiation>.

Whatever value you provide, does not actually have any influence on the algorithm used. C<best fit> will always be the one used.

=item * C<numberingSystem>

The numbering system to use for number formatting, such as C<fullwide>, C<hant>, C<mathsans>, and so on. For a list of supported numbering system types, see L<getNumberingSystems()|Locale::Intl/getNumberingSystems>. This option can also be set through the L<nu|Locale::Unicode/nu> Unicode extension key; if both are provided, this options property takes precedence.

For example, a Japanese locale with the C<latn> number system extension set and with the C<jptyo> time zone:

    my $fmt = DateTime::Format::RelativeTime->new( 'ja-u-nu-latn-tz-jptyo' );

However, note that you can only provide a number system that is supported by the C<locale>, and that is of type C<numeric>, i.e. not C<algorithmic>. For instance, you cannot specify a C<locale> C<ar-SA> (arab as spoken in Saudi Arabia) with a number system of Japan:

    my $fmt = DateTime::Format::RelativeTime->new( 'ar-SA', { numberingSystem => 'japn' } );
    say $fmt->resolvedOptions->{numberingSystem}; # arab

It would reject it, and issue a warning, if warnings are enabled, and fallback to the C<locale>'s default number system, which is, in this case, C<arab>

Additionally, even though the number system C<jpanfin> is supported by the locale C<ja>, it would not be acceptable, because it is not suitable for datetime formatting since it is not of type C<numeric>, or at least this is how it is treated by web browsers (see L<here the web browser engine implementation|https://github.com/v8/v8/blob/main/src/objects/intl-objects.cc> and L<here for the Unicode ICU implementation|https://github.com/unicode-org/icu/blob/main/icu4c/source/i18n/numsys.cpp>). This API could easily make it acceptable, but it was designed to closely mimic the web browser implementation of the JavaScript API C<Intl.DateTimeFormat>. Thus:

    my $fmt = DateTime::Format::RelativeTime->new( 'ja-u-nu-jpanfin-tz-jptyo' );
    say $fmt->resolvedOptions->{numberingSystem}; # latn

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/Locale/getNumberingSystems>, and also the perl module L<Locale::Intl>

=item * C<style>

The style of the formatted relative time. Possible values are:

=over 8

=item * C<long>

This is the default. For example: C<in 1 month>

=item * C<short>

For example: C<in 1 mo.>

=item * C<narrow>

For example: C<in 1 mo.>. The C<narrow> style could be similar to the C<short> style for some locales.

=back

=item * C<numeric>

Whether to use numeric values in the output. Possible values are C<always> and C<auto>; the default is C<always>. When set to C<auto>, the output may use more idiomatic phrasing such as C<yesterday> instead of C<1 day ago>.

=back

=head1 METHODS

=head2 format

    my $fmt = DateTime::Format::RelativeTime->new( 'en', { style => 'short' });

    say $fmt->format( 3, 'quarter' );
    # Expected output: "in 3 qtrs."

    say $fmt->format( -1, 'day' );
    # Expected output: "1 day ago"

    say $fmt->format( 10, 'seconds' );
    # Expected output: "in 10 sec."

Alternatively, you can pass two L<DateTime> objects, and C<format> will calculate the greatest time difference between the two. If you provide only one L<DateTime>, C<format> will instantiate a new L<DateTime> object using the C<time_zone> value from the first L<DateTime> object.

    my $dt = DateTime->new(
        year => 2024,
        month => 8,
        day => 15,
    );
    $fmt->format( $dt );
    # Assuming today is 2024-12-31, this would return: "1 qtr. ago"

or, with 2 L<DateTime> objects:

    my $dt = DateTime->new(
        year => 2024,
        month => 8,
        day => 15,
    );
    my $dt2 = DateTime->new(
        year => 2022,
        month => 2,
        day => 22,
    );
    $fmt->format( $dt => $dt2 ); # "2 yr. ago"

The C<format()> method of C<DateTime::Format::RelativeTime> instances formats a value and unit according to the C<locale> and formatting C<options> of this C<DateTime::Format::RelativeTime> object.

It returns a string representing the given value and unit formatted according to the locale and formatting options of this C<DateTime::Format::RelativeTime> object.

Supported parameters are:

=over 4

=item C<value>

Numeric value to use in the internationalized relative time message.

If the value is negative, the result will be formatted in the past.

=item C<unit>

Unit to use in the relative time internationalized message.

Possible values are: C<year>, C<quarter>, C<month>, C<week>, C<day>, C<hour>, C<minute>, C<second>.
Plural forms are also permitted.

=back

B<Note>: Most of the time, the formatting returned by C<format()> is consistent. However, the output may vary between implementations, even within the same C<locale> — output variations are by design and allowed by the specification. It may also not be what you expect. For example, the string may use non-breaking spaces or be surrounded by bidirectional control characters. You should I<not> compare the results of C<format()> to hardcoded constants.

=head2 formatToParts

    my $fmt = DateTime::Format::RelativeTime->new( 'en', { numeric => 'auto' });
    my $parts = $fmt->formatToParts( 10, 'seconds' );

    say $parts->[0]->{value};
    # Expected output: "in "

    say $parts->[1]->{value};
    # Expected output: "10"

    say $parts->[2]->{value};
    # Expected output: " seconds"

    my $fmt = DateTime::Format::RelativeTime->new( 'en', { numeric => 'auto' });

    # Format relative time using the day unit
    $fmt->formatToParts( -1, 'day' );
    # [{ type: 'literal', value: 'yesterday' }]

    $fmt->formatToParts( 100, 'day' );
    # [
    #     { type => 'literal', value => 'in ' },
    #     { type => 'integer', value => 100, unit => 'day' },
    #     { type => 'literal', value => ' days' }
    # ]

Just like for L<format|/format>, you can alternatively provide one or two L<DateTime> objects.

The C<formatToParts()> method of C<DateTime::Format::RelativeTime> instances returns an array reference of hash reference representing the relative time format in parts that can be used for custom locale-aware formatting.

The C<DateTime::Format::RelativeTime->formatToParts> method is a version of the L<format|/format> method that returns an array reference of hash reference which represents C<parts> of the object, separating the formatted number into its constituent parts and separating it from other surrounding text. These hash reference have two or three properties:

=over 4

=item * C<type> a string

=item * C<value>, a string representing the component of the output.

=item * C<unit>

The unit value for the number value, when the type is C<integer>

=back

Supported parameters are:

=over 4

=item * C<value>

Numeric value to use in the internationalized relative time message.

If the value is negative, the result will be formatted in the past.

=item * C<unit>

Unit to use in the relative time internationalized message.

Possible values are: C<year>, C<quarter>, C<month>, C<week>, C<day>, C<hour>, C<minute>, C<second>.
Plural forms are also permitted.

=back

=for Pod::Coverage format_to_parts

=head2 resolvedOptions

    my $fmt = DateTime::Format::RelativeTime->new('en', { style => 'narrow' });
    my $options1 = $fmt->resolvedOptions();
    
    my $fmt2 = DateTime::Format::RelativeTime->new('es', { numeric => 'auto' });
    my $options2 = $fmt2->resolvedOptions();
    
    say "$options1->{locale}, $options1->{style}, $options1->{numeric}";
    # Expected output: "en, narrow, always"
    
    say "$options2->{locale}, $options2->{style}, $options2->{numeric}";
    # Expected output: "es, long, auto"

The C<resolvedOptions()> method of C<DateTime::Format::RelativeTime> instances returns a new hash reference with properties reflecting the options computed during initialisation of this C<DateTime::Format::RelativeTime> object.

For the details of the properties retured, see the L<new|/new> instantiation method.

=head1 CLASS METHODS

=head2 supportedLocalesOf

    my $locales1 = ['ban', 'id-u-co-pinyin', 'de-ID'];
    my $options1 = { localeMatcher: 'lookup' };

    say DateTime::Format::RelativeTime->supportedLocalesOf( $locales1, $options1 );
    # Expected output: ['id-u-co-pinyin', 'de-ID']

The C<DateTime::Format::RelativeTime->supportedLocalesOf> class method returns an array containing those of the provided locales that are supported in relative time formatting without having to fall back to the runtime's default locale.

Supported parameters are:

=over 4

=item * C<locale>

A string with a BCP 47 language tag, or an array of such strings. For the general form and interpretation of the C<locales> argument, see the parameter description on the L<Locale::Intl> documentation.

=item * C<options>

An hash reference that may have the following property:

=over 8

=item * C<localeMatcher>

The locale matching algorithm to use. Possible values are C<lookup> and C<best fit>; the default is C<best fit>. For information about this option, see the L<DateTime::Format::Intl> documentation.

In reality, it does not matter what value you set, because this module only support the C<best fit> option.

=back

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

=for Pod::Coverage pass_error

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Locale::Unicode::Data>, L<Locale::Unicode>, L<Locale::Intl>, L<DateTime::Format::Intl>, L<DateTime::Locale::FromCLDR>

L<DateTime::Format::Natural>, L<DateTimeX::Format::Ago>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2024-2025 DEGUEST Pte. Ltd.

All rights reserved
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
