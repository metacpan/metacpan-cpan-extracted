##----------------------------------------------------------------------------
## DateTime Format Lite - ~/lib/DateTime/Format/Lite.pm
## Version v0.1.3
## Copyright(c) 2026 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2026/04/14
## Modified 2026/04/23
## All rights reserved.
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package DateTime::Format::Lite;
BEGIN
{
    use v5.10.1;
    use strict;
    use warnings;
    use warnings::register;
    use vars qw(
        $VERSION $ERROR $FATAL_EXCEPTIONS $IsPurePerl
    );
    use DateTime::Lite ();
    use DateTime::Lite::TimeZone ();
    use DateTime::Locale::FromCLDR ();
    use Exporter qw( import );
    use Locale::Unicode ();
    use POSIX ();
    use Scalar::Util ();
    use Wanted;
    our $VERSION    = 'v0.1.3';
    our @EXPORT_OK  = qw( strptime strftime );
    our $IsPurePerl;
};

use strict;
use warnings;

# NOTE: Load XS; fall back to pure-Perl implementations if unavailable.
{
    my $loaded = 0;
    unless( $ENV{PERL_DATETIME_FORMAT_LITE_PP} )
    {
        local $SIG{__WARN__} = sub{};
        local $@;
        eval
        {
            no warnings 'redefine';
            require XSLoader;
            XSLoader::load(
                __PACKAGE__,
                exists( $DateTime::Format::Lite::{VERSION} ) && ${ $DateTime::Format::Lite::{VERSION} }
                    ? ${ $DateTime::Format::Lite::{VERSION} }
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
        require DateTime::Format::Lite::PP;
        $IsPurePerl = 1;
    }
}

# Fields captured during parsing that cannot be passed directly to DateTime::Lite
# constructors, so they require munging in _munge_args first.
my @NON_DT_KEYS = qw(
    am_pm
    century
    day_name
    day_of_week
    day_of_week_sun_0
    hour_12
    iso_week_year
    iso_week_year_100
    month_name
    time_zone_abbreviation
    time_zone_name
    time_zone_offset
    week_mon_1
    week_sun_0
    year_100
);

# Locale-independent token table. Locale-dependent tokens (%a/%A, %b/%B/%h, %p/%P)
# are built per-object in _parser_pieces() since they depend on the locale's day
# and month names.
my $DIGIT             = qr/(?:[0-9])/;
my $ONE_OR_TWO_DIGITS = qr/[0-9 ]?$DIGIT/;

my %UNIVERSAL_PATTERNS =
(
    '%' => { regex => qr/%/                                                  },
    C   => { regex => $ONE_OR_TWO_DIGITS,       field => 'century'           },
    d   => { regex => $ONE_OR_TWO_DIGITS,       field => 'day'               },
    e   => { regex => $ONE_OR_TWO_DIGITS,       field => 'day'               },
    g   => { regex => $ONE_OR_TWO_DIGITS,       field => 'iso_week_year_100' },
    G   => { regex => qr/$DIGIT{4}/,            field => 'iso_week_year'     },
    H   => { regex => $ONE_OR_TWO_DIGITS,       field => 'hour'              },
    I   => { regex => $ONE_OR_TWO_DIGITS,       field => 'hour_12'           },
    k   => { regex => $ONE_OR_TWO_DIGITS,       field => 'hour'              },
    l   => { regex => $ONE_OR_TWO_DIGITS,       field => 'hour_12'           },
    j   => { regex => qr/$DIGIT{1,3}/,          field => 'day_of_year'       },
    m   => { regex => $ONE_OR_TWO_DIGITS,       field => 'month'             },
    M   => { regex => $ONE_OR_TWO_DIGITS,       field => 'minute'            },
    n   => { regex => qr/\s+/                                                },
    t   => { regex => qr/\s+/                                                },
    O   => { regex => qr{[a-zA-Z_]+(?:/[a-zA-Z_]+(?:/[a-zA-Z_]+)?)?},
             field => 'time_zone_name'                                       },
    s   => { regex => qr/-?$DIGIT+/,            field => 'epoch'             },
    S   => { regex => $ONE_OR_TWO_DIGITS,       field => 'second'            },
    U   => { regex => $ONE_OR_TWO_DIGITS,       field => 'week_sun_0'        },
    u   => { regex => $ONE_OR_TWO_DIGITS,       field => 'day_of_week'       },
    w   => { regex => $ONE_OR_TWO_DIGITS,       field => 'day_of_week_sun_0' },
    W   => { regex => $ONE_OR_TWO_DIGITS,       field => 'week_mon_1'        },
    y   => { regex => $ONE_OR_TWO_DIGITS,       field => 'year_100'          },
    Y   => { regex => qr/$DIGIT{4}/,            field => 'year'              },
    z   => { regex => qr/(?:Z|[+-]$DIGIT{2}(?:[:]?$DIGIT{2})?)/,
             field => 'time_zone_offset'                                     },
    Z   => { regex => qr{[a-zA-Z]{1,6}(?:/[a-zA-Z_]+(?:/[a-zA-Z_]+)?)?|[\-\+]$DIGIT{2}},
             field => 'time_zone_abbreviation'                               },
);

# Compound tokens expanded before the main token pass (up to 2 rounds)
my %UNIVERSAL_REPLACEMENTS =
(
    D => '%m/%d/%y',
    F => '%Y-%m-%d',
    r => '%I:%M:%S %p',
    R => '%H:%M',
    T => '%H:%M:%S',
);

# NOTE: subroutine pre-declaration
# for sub in `perl -ln -E 'say "$1" if( /^sub (\w+)[[:blank:]\v]*(?:\{|\Z|[[:blank:]\v]*:[[:blank:]\v]*lvalue)/ )' ./lib/DateTime/Format/Lite.pm | LC_COLLATE=C sort -uV`; do echo "sub $sub;"; done
sub FREEZE;
sub STORABLE_freeze;
sub STORABLE_thaw;
sub THAW;
sub TO_JSON;
sub debug;
sub error;
sub fatal;
sub format_datetime;
sub format_duration;
sub locale;
sub new;
sub on_error;
sub parse_datetime;
sub parse_duration;
sub pass_error;
sub pattern;
sub strftime;
sub strict;
sub strptime;
sub time_zone;
sub zone_map;
sub _build_parser;
sub _check_dt;
sub _locale_days;
sub _locale_months;
sub _munge_args;
sub _on_error;
sub _parser;
sub _parser_pieces;
sub _restore_state;
sub _serialise_state;
sub _set_get_prop;
sub _token_re_for;

sub new
{
    my $this  = shift( @_ );
    my $class = ref( $this ) || $this;
    my %p     = @_;

    unless( defined( $p{pattern} ) && length( $p{pattern} ) )
    {
        return( $class->error( "Parameter 'pattern' is required for ", __PACKAGE__, "::new()." ) );
    }

    my $self = bless(
    {
        debug          => $ENV{DATETIME_FORMAT_LITE_DEBUG} // 0,
        locale         => undef,
        on_error       => 'undef',
        pattern        => undef,
        strict         => 0,
        time_zone      => undef,
        zone_map       => {},
        # Internal caches
        _parser        => undef,
        _locale_days   => undef,
        _locale_months => undef,
    }, $class );

    # Process each parameter through its accessor for validation and coercion
    foreach my $param ( qw( debug locale on_error pattern strict time_zone zone_map ) )
    {
        next unless( exists( $p{ $param } ) );
        $self->$param( $p{ $param } ) //
            return( $class->pass_error( $self->error ) );
    }

    # Force compilation at construction time to catch invalid patterns early
    $self->_parser ||
        return( $class->pass_error( $self->error ) );

    return( $self );
}

sub debug
{
    my $self = shift( @_ );
    if( @_ )
    {
        $self->{debug} = $_[0] ? 1 : 0;
        if( $self->{debug} )
        {
            # Ensure STDERR handles UTF-8 when debug output is enabled
            binmode( STDERR, ':encoding(UTF-8)' );
        }
    }
    return( $self->{debug} );
}

# NOTE: Error handling
sub error
{
    my $self = shift( @_ );
    if( @_ )
    {
        require DateTime::Format::Lite::Exception;
        my $msg = join( '', map( ( ref( $_ ) eq 'CODE' ) ? $_->() : $_, @_ ) );
        my $e = DateTime::Format::Lite::Exception->new({
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
            rreturn( DateTime::Format::Lite::NullObject->new ) if( want( 'OBJECT' ) );
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

sub format_datetime
{
    my $self = shift( @_ );
    my $dt   = shift( @_ );

    unless( defined( $dt ) &&
            Scalar::Util::blessed( $dt ) &&
            $dt->isa( 'DateTime::Lite' ) )
    {
        return( $self->error( "A DateTime::Lite object is required for format_datetime()." ) );
    }

    # XS path: delegates to strftime without clone()
    unless( $IsPurePerl )
    {
        return( DateTime::Format::Lite::format_datetime( $self, $dt ) );
    }

    # Pure-Perl fallback: strftime is already XS-accelerated in DateTime::Lite
    return( $dt->strftime( $self->{pattern} ) );
}

sub format_duration
{
    my $self = shift( @_ );
    my $dur  = shift( @_ );

    unless( defined( $dur ) &&
            Scalar::Util::blessed( $dur ) &&
            $dur->isa( 'DateTime::Lite::Duration' ) )
    {
        return( $self->error( "A DateTime::Lite::Duration object is required for format_duration()." ) );
    }

    my $str = 'P';
    $str .= $dur->years    . 'Y' if( $dur->years   );
    $str .= $dur->months   . 'M' if( $dur->months  );
    $str .= $dur->days     . 'D' if( $dur->days    );
    my $time = '';
    $time .= $dur->hours   . 'H' if( $dur->hours   );
    $time .= $dur->minutes . 'M' if( $dur->minutes );
    $time .= $dur->seconds . 'S' if( $dur->seconds );
    $str .= 'T' . $time if( length( $time ) );
    # Edge case: zero duration -> PT0S
    $str = 'PT0S' if( $str eq 'P' );
    return( $str );
}

sub locale
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $locale = shift( @_ );
        if( !defined( $locale ) )
        {
            # Default to English
            $self->{locale} = DateTime::Locale::FromCLDR->new( 'en' ) ||
                return( $self->pass_error( DateTime::Locale::FromCLDR->error ) );
        }
        elsif( Scalar::Util::blessed( $locale ) )
        {
            unless( $locale->isa( 'DateTime::Locale::FromCLDR' ) ||
                    $locale->isa( 'Locale::Unicode' ) )
            {
                return( $self->error( "Locale object must be a DateTime::Locale::FromCLDR or Locale::Unicode instance, got: ", ref( $locale ) ) );
            }
            $self->{locale} = $locale;
        }
        elsif( ref( $locale ) )
        {
            return( $self->error( "locale must be a string or object, got an unblessed reference: ", ref( $locale ) ) );
        }
        else
        {
            $self->{locale} = DateTime::Locale::FromCLDR->new( $locale ) ||
                return( $self->pass_error( DateTime::Locale::FromCLDR->error ) );
        }
        # Invalidate locale-dependent caches
        $self->{_parser}        = undef;
        $self->{_locale_days}   = undef;
        $self->{_locale_months} = undef;
    }
    # Initialise lazily on first access
    unless( defined( $self->{locale} ) )
    {
        $self->{locale} = DateTime::Locale::FromCLDR->new( 'en' ) ||
            return( $self->pass_error( DateTime::Locale::FromCLDR->error ) );
    }
    return( $self->{locale} );
}

sub on_error
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $val = shift( @_ );
        if( ref( $val ) eq 'CODE' )
        {
            $self->{on_error} = $val;
        }
        elsif( defined( $val ) && ( $val eq 'croak' || $val eq 'die' || $val eq 'undef' ) )
        {
            $self->{on_error} = $val;
        }
        else
        {
            return( $self->error( "on_error must be 'croak', 'die', 'undef', or a code reference." ) );
        }
    }
    return( $self->{on_error} );
}

sub parse_datetime
{
    my $self   = shift( @_ );
    my $string = shift( @_ );

    if( !defined( $string ) || ( defined( $string ) && !length( $string // '' ) ) )
    {
        return( $self->error( "A string to parse is required for parse_datetime()." ) );
    }

    my $parser = $self->_parser ||
        return( $self->pass_error );

    if( $self->{debug} )
    {
        warn( "Regex for $self->{pattern}: $parser->{regex}\nFields: @{$parser->{fields}}\n" );
    }

    my %args;
    if( $IsPurePerl )
    {
        my @matches = ( $string =~ $parser->{regex} );
        unless( @matches )
        {
            return( $self->_on_error(
                'Your datetime does not match your pattern'
                . ( $self->{debug}
                    ? qq{ - string="$string" regex=$parser->{regex}}
                    : '' )
                . '.'
            ) );
        }
        my $i = 0;
        foreach my $f ( @{$parser->{fields}} )
        {
            $args{ $f } = $matches[ $i++ ];
        }
    }
    else
    {
        # XS _match_and_extract returns a hashref or undef on no match
        my $extracted = DateTime::Format::Lite::_match_and_extract(
            $self,
            $parser->{regex},
            $parser->{fields},
            $string,
        );
        unless( defined( $extracted ) )
        {
            return( $self->_on_error(
                'Your datetime does not match your pattern'
                . ( $self->{debug}
                    ? qq{ - string="$string" regex=$parser->{regex}}
                    : '' )
                . '.'
            ) );
        }
        %args = %$extracted;
    }

    # _munge_args modifies a copy of %args; pass a copy to preserve original
    my( $constructor, $args, $post_construct ) = $self->_munge_args( {%args} );
    return( $self->pass_error ) unless( $constructor && $args );

    local $@;
    my $dt = eval{ DateTime::Lite->$constructor( %$args ) };
    if( $@ || !$dt )
    {
        return( $self->_on_error( 'Parsed values did not produce a valid datetime.' ) );
    }

    $post_construct->( $dt ) if( $post_construct );

    return( $self->pass_error ) unless( $self->_check_dt( $dt, \%args ) );

    $dt->set_time_zone( $self->{time_zone} ) if( $self->{time_zone} );

    return( $dt );
}

sub parse_duration
{
    my $self   = shift( @_ );
    my $string = shift( @_ );

    if( !defined( $string ) || ( defined( $string ) && !length( $string // '' ) ) )
    {
        return( $self->error( "A string to parse is required for parse_duration()." ) );
    }

    # ISO 8601 duration: PnYnMnDTnHnMnS (decimal fractions allowed)
    unless( $string =~ /\A
        P
        (?:(\d+(?:[.,]\d+)?)Y)?
        (?:(\d+(?:[.,]\d+)?)M)?
        (?:(\d+(?:[.,]\d+)?)W)?
        (?:(\d+(?:[.,]\d+)?)D)?
        (?:T
            (?:(\d+(?:[.,]\d+)?)H)?
            (?:(\d+(?:[.,]\d+)?)M)?
            (?:(\d+(?:[.,]\d+)?)S)?
        )?
    \z/x )
    {
        return( $self->_on_error( "String '$string' does not match the ISO 8601 duration format." ) );
    }

    my( $years, $months, $weeks, $days, $hours, $minutes, $seconds ) =
        map{ defined( $_ ) ? do{ ( my $v = $_ ) =~ s/,/./; $v + 0 } : 0 }
        ( $1, $2, $3, $4, $5, $6, $7 );

    # Fold weeks into days (ISO 8601 weeks are always exactly 7 days)
    $days += $weeks * 7;

    return( DateTime::Lite::Duration->new(
        years   => $years,
        months  => $months,
        days    => $days,
        hours   => $hours,
        minutes => $minutes,
        seconds => $seconds,
    ) );
}

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

        # Use $pack (always defined) not $class (only set when explicitly provided)
        # to check for FATAL_EXCEPTIONS, to avoid "uninitialized value" warnings.
        my $check_class = $class // $pack;
        if( $self->{fatal} || ( defined( ${"${check_class}::FATAL_EXCEPTIONS"} ) && ${"${check_class}::FATAL_EXCEPTIONS"} ) )
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
        rreturn( DateTime::Format::Lite::NullObject->new );
    }
    return;
}

sub pattern
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $pat = shift( @_ );
        unless( defined( $pat ) && length( $pat ) )
        {
            return( $self->error( "pattern must be a non-empty string." ) );
        }
        $self->{pattern} = $pat;
        # Invalidate cached parser
        $self->{_parser} = undef;
    }
    return( $self->{pattern} );
}

sub strict
{
    my $self = shift( @_ );
    $self->{strict} = $_[0] ? 1 : 0 if( @_ );
    return( $self->{strict} );
}

# NOTE: strftime() -> Exportable convenience function
sub strftime
{
    my( $pattern, $dt ) = @_;
    my $fmt = __PACKAGE__->new( pattern => $pattern ) ||
        die( __PACKAGE__->error );
    return( $fmt->format_datetime( $dt ) );
}

# NOTE: strptime() -> Exportable convenience function
sub strptime
{
    my( $pattern, $string ) = @_;
    my $fmt = __PACKAGE__->new( pattern => $pattern ) ||
        die( __PACKAGE__->error );
    return( $fmt->parse_datetime( $string ) );
}

sub time_zone
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $tz = shift( @_ );
        if( !defined( $tz ) )
        {
            $self->{time_zone} = undef;
        }
        elsif( Scalar::Util::blessed( $tz ) )
        {
            unless( $tz->isa( 'DateTime::Lite::TimeZone' ) )
            {
                return( $self->error( "time_zone object must be a DateTime::Lite::TimeZone instance, got: ", ref( $tz ) ) );
            }
            $self->{time_zone} = $tz;
        }
        elsif( ref( $tz ) )
        {
            return( $self->error( "time_zone must be a string or a DateTime::Lite::TimeZone object." ) );
        }
        else
        {
            $self->{time_zone} = DateTime::Lite::TimeZone->new( name => $tz, extended => 1 ) ||
                return( $self->pass_error( DateTime::Lite::TimeZone->error ) );
        }
    }
    return( $self->{time_zone} );
}

sub zone_map
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $map = shift( @_ );
        unless( ref( $map ) eq 'HASH' )
        {
            return( $self->error( "zone_map must be a hash reference." ) );
        }
        $self->{zone_map} = $map;
    }
    return( $self->{zone_map} //= {} );
}

# NOTE: Serialisation
# FREEZE / THAW (Sereal >= 4, CBOR::XS)
sub FREEZE
{
    my $self       = CORE::shift( @_ );
    my $serialiser = CORE::shift( @_ ) // '';
    my $class      = CORE::ref( $self );
    my $state      = $self->_serialise_state || CORE::return;
    # Sereal <= 4.023 requires an arrayref; later versions and CBOR accept a list
    if( $serialiser eq 'Sereal' &&
        defined( &Sereal::Encoder::VERSION ) &&
        Sereal::Encoder->VERSION <= version->parse( '4.023' ) )
    {
        CORE::return( [$class, $state] );
    }
    CORE::return( $class, $state );
}

sub THAW
{
    my( $self, $serialiser, @args ) = @_;
    my $ref   = ( CORE::scalar( @args ) == 1 &&
                  CORE::ref( $args[0] ) eq 'ARRAY' )
        ? CORE::shift( @args )
        : \@args;
    my $class = ( CORE::ref( $ref ) eq 'ARRAY' &&
                  CORE::scalar( @$ref ) > 1 )
        ? CORE::shift( @$ref )
        : ( CORE::ref( $self ) || $self );
    my $state = CORE::ref( $ref ) eq 'ARRAY' ? CORE::shift( @$ref ) : {};

    if( CORE::ref( $self ) )
    {
        # Storable pattern: modify the existing object in place
        $self->_restore_state( $state ) || CORE::return;
        CORE::return( $self );
    }
    else
    {
        my $new = CORE::bless( {}, $class );
        $new->_restore_state( $state ) || CORE::return;
        CORE::return( $new );
    }
}

# STORABLE_freeze / STORABLE_thaw (Storable)
sub STORABLE_freeze
{
    my $self     = shift( @_ );
    my $cloning  = shift( @_ );
    my $state    = $self->_serialise_state || CORE::return;
    if( !defined( $state ) || ( defined( $state ) && ref( $state ) ne 'HASH' ) )
    {
        warn( "state returned by _serialise_state() is not an hash reference." ) if( warnings::enabled() );
        CORE::return;
    }
    # Encode the state as a compact key:value string, with the zone_map
    # JSON-encoded since it may contain arbitrary string values.
    my $zone_map_json = '';
    if( defined( $state->{zone_map} ) && scalar( keys( %{$state->{zone_map}} ) ) )
    {
        require JSON;
        $zone_map_json = JSON::encode_json( $state->{zone_map} );
    }
    my $serialised = join( '|',
        'pattern:'  . ( $state->{pattern}   // '' ),
        'locale:'   . ( $state->{locale}    // 'en' ),
        'on_error:' . ( $state->{on_error}  // 'undef' ),
        'strict:'   . ( $state->{strict}    // 0 ),
        'debug:'    . ( $state->{debug}     // 0 ),
        'zone_map:' . $zone_map_json,
    );
    # time_zone is passed as a separate object for Storable reference tracking
    return( $serialised, \( $state->{time_zone} // '' ) );
}

sub STORABLE_thaw
{
    my $self       = shift( @_ );
    my $cloning    = shift( @_ );
    my $serialised = shift( @_ );
    my $tz_ref     = shift( @_ );

    my %s;
    foreach my $pair ( split( /\|/, $serialised ) )
    {
        my( $k, $v ) = split( /:/, $pair, 2 );
        $s{ $k } = $v // '';
    }

    my %state = (
        pattern  => $s{pattern},
        locale   => $s{locale}   || 'en',
        on_error => $s{on_error} || 'undef',
        strict   => $s{strict}   // 0,
        debug    => $s{debug}    // 0,
    );

    if( defined( $s{zone_map} ) && length( $s{zone_map} ) )
    {
        require JSON;
        local $@;
        $state{zone_map} = eval{ JSON::decode_json( $s{zone_map} ) };
        if( $@ )
        {
            die( "Error serialising DateTime::Format::Lite object: $@" );
        }
    }

    if( defined( $tz_ref ) &&
        ref( $tz_ref ) &&
        defined( $$tz_ref ) &&
        length( $$tz_ref ) )
    {
        $state{time_zone} = $$tz_ref;
    }

    $self->_restore_state( \%state ) ||
        die( ref( $self )->error || "STORABLE_thaw: failed to restore state" );
    return( $self );
}

sub TO_JSON
{
    my $self = shift( @_ );
    return( $self->_serialise_state );
}

sub _build_parser
{
    my $self = shift( @_ );

    my @pieces = $self->_parser_pieces;
    return( $self->pass_error ) unless( @pieces );
    my( $replacement_tokens_re, $replacements, $pattern_tokens_re, $patterns ) = @pieces;

    my $pattern = $self->{pattern};

    # Two expansion passes: the first may turn %c into %H:%M:%S etc., the
    # second resolves any tokens introduced by that first expansion.
    $pattern =~ s/%($replacement_tokens_re)/$replacements->{$1}/g for( 1..2 );

    if( $self->{debug} && $pattern ne $self->{pattern} )
    {
        warn( "Pattern after replacement substitution: $pattern\n" );
    }

    my $regex  = q{};
    my @fields;

    while( $pattern =~ /
        \G
        %($pattern_tokens_re)       # named token
        |
        %([1-9]?)(N)                # %N or %nN nanoseconds
        |
        (%[0-9]*[a-zA-Z])           # unrecognised token
        |
        ([^%]+)                     # literal text
    /xg )
    {
        if( defined( $1 ) )
        {
            my $p = $patterns->{ $1 }
                or return( $self->error( qq{Unidentified token "%$1" in pattern: $self->{pattern}} ) );
            if( $p->{field} )
            {
                $regex .= qr/($p->{regex})/;
                push( @fields, $p->{field} );
            }
            else
            {
                $regex .= qr/$p->{regex}/;
            }
        }
        elsif( defined( $3 ) )
        {
            # %N captures all digits; %nN captures exactly n digits
            $regex .= $2 ? qr/([0-9]{$2})/ : qr/([0-9]+)/;
            push( @fields, 'nanosecond' );
        }
        elsif( defined( $4 ) )
        {
            return( $self->error( qq{Pattern contained an unrecognised strptime token, "$4"} ) );
        }
        else
        {
            # Literal text - escape for regex
            $regex .= qr/\Q$5/;
        }
    }

    return({
        regex  => ( $self->{strict}
            ? qr/(?:\A|\b)$regex(?:\b|\Z)/
            : qr/$regex/ ),
        fields => \@fields,
    });
}

sub _check_dt
{
    my $self = shift( @_ );
    my $dt   = shift( @_ ) ||
        return( $self->_on_error( "No DateTime::Lite or DateTime object was provided." ) );
    my $args = shift( @_ ) || {};
    if( defined( $args ) && ref( $args ) ne 'HASH' )
    {
        return( $self->_on_error( "Arguments hash provided (", overload::StrVal( $args ), ") is not an hash reference." ) );
    }

    my $locale = $self->locale || return( $self->pass_error );

    my $is_am = defined( $args->{am_pm} ) && lc( $args->{am_pm} ) eq lc( $locale->am_pm_abbreviated->[0] );

    if( defined( $args->{hour} ) && defined( $args->{hour_12} ) )
    {
        unless( ( $args->{hour} % 12 ) == $args->{hour_12} )
        {
            return( $self->_on_error(
                'Parsed an input with 24-hour and 12-hour time values that do not match'
                . qq{ - "$args->{hour}" versus "$args->{hour_12}"}
            ) );
        }
    }

    if( defined( $args->{hour} ) && defined( $args->{am_pm} ) )
    {
        if( ( $is_am && $args->{hour} >= 12 ) ||
            ( !$is_am && $args->{hour} < 12 ) )
        {
            return( $self->_on_error(
                'Parsed an input with 24-hour and AM/PM values that do not match'
                . qq{ - "$args->{hour}" versus "$args->{am_pm}"}
            ) );
        }
    }

    if( defined( $args->{year} ) && defined( $args->{century} ) )
    {
        unless( int( $args->{year} / 100 ) == $args->{century} )
        {
            return( $self->_on_error(
                'Parsed an input with year and century values that do not match'
                . qq{ - "$args->{year}" versus "$args->{century}"}
            ) );
        }
    }

    if( defined( $args->{year} ) && defined( $args->{year_100} ) )
    {
        unless( ( $args->{year} % 100 ) == $args->{year_100} )
        {
            return( $self->_on_error(
                'Parsed an input with year and year-within-century values that do not match'
                . qq{ - "$args->{year}" versus "$args->{year_100}"}
            ) );
        }
    }

    if( defined( $args->{time_zone_abbreviation} ) &&
        defined( $args->{time_zone_offset} ) &&
        exists( $self->zone_map->{ $args->{time_zone_abbreviation} } ) )
    {
        # Only cross-check when the abbreviation was explicitly mapped via zone_map.
        # When resolved via the DB (not in zone_map), _munge_args already used the
        # co-parsed offset as a filter, so there is no conflict to detect here.
        my $mapped = $self->zone_map->{ $args->{time_zone_abbreviation} };
        unless( defined( $mapped ) && $mapped eq $args->{time_zone_offset} )
        {
            return( $self->_on_error(
                'Parsed an input with time zone abbreviation and offset values that do not match'
                . qq{ - "$args->{time_zone_abbreviation}" versus "$args->{time_zone_offset}"}
            ) );
        }
    }

    if( defined( $args->{epoch} ) )
    {
        foreach my $key ( qw( year month day hour minute second hour_12 day_of_year ) )
        {
            if( defined( $args->{ $key } ) && $dt->$key != $args->{ $key } )
            {
                my $label =
                    $key eq 'hour_12'     ? 'hour (1-12)'  :
                    $key eq 'day_of_year' ? 'day of year'  : $key;
                return( $self->_on_error(
                    "Parsed an input with epoch and $label values that do not match"
                    . qq{ - "$args->{epoch}" versus "$args->{$key}"}
                ) );
            }
        }
    }

    if( defined( $args->{month} ) && defined( $args->{day_of_year} ) )
    {
        unless( $dt->month == $args->{month} )
        {
            return( $self->_on_error(
                'Parsed an input with month and day of year values that do not match'
                . qq{ - "$args->{month}" versus "$args->{day_of_year}"}
            ) );
        }
    }

    if( defined( $args->{day_name} ) )
    {
        my $dow = $self->_locale_days->{ lc( $args->{day_name} ) };
        defined( $dow ) or return( $self->error(
            "We somehow parsed a day name ($args->{day_name})"
            . ' that does not correspond to any day in this locale!'
        ) );
        unless( $dt->day_of_week_0 == $dow )
        {
            return( $self->_on_error(
                'Parsed an input where the day name does not match the date'
                . qq{ - "$args->{day_name}" versus "} . $dt->ymd . q{"}
            ) );
        }
    }

    return(1);
}

sub _locale_days
{
    my $self = shift( @_ );
    return( $self->{_locale_days} ) if( defined( $self->{_locale_days} ) );
    my $locale = $self->locale || return( $self->pass_error );
    my %days;
    my @wide = @{$locale->day_format_wide};
    my @abbr = @{$locale->day_format_abbreviated};
    # In DateTime::Lite: day_of_week_0 is 0=Monday .. 6=Sunday
    for my $i ( 0..6 )
    {
        $days{ lc( $wide[ $i ] ) } = $i if( defined( $wide[ $i ] ) );
        $days{ lc( $abbr[ $i ] ) } = $i if( defined( $abbr[ $i ] ) );
    }
    return( $self->{_locale_days} = \%days );
}

sub _locale_months
{
    my $self = shift( @_ );
    return( $self->{_locale_months} ) if( defined( $self->{_locale_months} ) );
    my $locale = $self->locale || return( $self->pass_error );
    my %months;
    my @wide = @{$locale->month_format_wide};
    my @abbr = @{$locale->month_format_abbreviated};
    for my $i ( 0..11 )
    {
        $months{ lc( $wide[ $i ] ) } = $i + 1 if( defined( $wide[ $i ] ) );
        $months{ lc( $abbr[ $i ] ) } = $i + 1 if( defined( $abbr[ $i ] ) );
    }
    return( $self->{_locale_months} = \%months );
}

sub _munge_args
{
    my $self = shift( @_ );
    my $args = shift( @_ ) || {};
    if( defined( $args ) && ref( $args ) ne 'HASH' )
    {
        return( $self->_on_error( "Arguments hash provided (", overload::StrVal( $args ), ") is not an hash reference." ) );
    }

    # Resolve month name -> month number
    if( defined( $args->{month_name} ) )
    {
        my $num = $self->_locale_months->{ lc( $args->{month_name} ) } or
            return( $self->error( "We somehow parsed a month name ($args->{month_name}) that does not correspond to any month in this locale!" ) );
        $args->{month} = $num;
    }

    # Resolve 12-hour clock + AM/PM -> 24-hour
    if( defined( $args->{am_pm} ) && defined( $args->{hour_12} ) )
    {
        my $locale = $self->locale || return( $self->pass_error );
        my( $am, $pm ) = @{$locale->am_pm_abbreviated};
        $args->{hour} = $args->{hour_12};
        if( lc( $args->{am_pm} ) eq lc( $am ) )
        {
            $args->{hour} = 0 if( $args->{hour} == 12 );
        }
        else
        {
            $args->{hour} += 12 unless( $args->{hour} == 12 );
        }
    }
    elsif( defined( $args->{hour_12} ) )
    {
        return( $self->_on_error( qq{Parsed a 12-hour based hour, "$args->{hour_12}", but the pattern does not include an AM/PM specifier.} ) );
    }

    # Resolve 2-digit year with optional century
    if( defined( $args->{year_100} ) )
    {
        if( defined( $args->{century} ) )
        {
            $args->{year} = $args->{year_100} + ( $args->{century} * 100 );
        }
        else
        {
            $args->{year} = $args->{year_100} + ( $args->{year_100} >= 69 ? 1900 : 2000 );
        }
    }

    # Resolve numeric timezone offset string -> DateTime::Lite::TimeZone object
    if( defined( $args->{time_zone_offset} ) )
    {
        my $offset = $args->{time_zone_offset};
        $offset = '+0000' if( $offset eq 'Z' );
        $offset .= '00'   if( $offset =~ /^[+-][0-9]{2}$/ );
        my $tz = DateTime::Lite::TimeZone->new( name => $offset );
        unless( $tz )
        {
            return( $self->_on_error( qq{The time zone offset "$args->{time_zone_offset}" does not appear to be valid.} ) );
        }
        $args->{time_zone} = $tz;
    }

    # Resolve timezone abbreviation via zone_map then IANA SQLite DB.
    # When %z was also parsed, args->{time_zone} is already a fixed-offset
    # timezone built from the explicit offset - the abbreviation is then
    # purely informational and we skip DB resolution entirely.
    if( defined( $args->{time_zone_abbreviation} ) &&
        !defined( $args->{time_zone} ) )
    {
        my $abbr = $args->{time_zone_abbreviation};
        my $tz;

        # 1. Check caller-supplied zone_map first (explicit overrides)
        if( exists( $self->{zone_map}->{ $abbr } ) )
        {
            if( !defined( $self->{zone_map}->{ $abbr } ) )
            {
                return( $self->_on_error( qq{The time zone abbreviation "$abbr" is marked ambiguous in zone_map.} ) );
            }
            $tz = DateTime::Lite::TimeZone->new( name => $self->{zone_map}->{ $abbr } );
        }
        # Short-circuit for canonical zone names that also show up as %Z.
        # UTC, GMT, and Z (Zulu) are all IANA zone names, not abbreviations in the
        # types table, so resolve_abbreviation() would fail. Any string with a '/' is
        # an IANA zone name and never an abbreviation.
        elsif( $abbr eq 'UTC' ||
               $abbr eq 'GMT' ||
               $abbr eq 'Z' ||
               $abbr eq 'floating' ||
               index( $abbr, '/' ) >= 0 )
        {
            $tz = DateTime::Lite::TimeZone->new( name => $abbr );
            if( !defined( $tz ) )
            {
                return( $self->_on_error( qq{Cannot construct timezone "$abbr": } . DateTime::Lite::TimeZone->error ) );
            }
        }
        else
        {
            # 2. Query the IANA DB, optionally narrowing by co-parsed offset.
            # time_zone_offset is a parsed string like "-0800" or "+0900";
            # resolve_abbreviation expects integer seconds east of UTC.
            my @resolve_args;
            if( defined( $args->{time_zone_offset} ) )
            {
                my $off_str = $args->{time_zone_offset};
                $off_str = '+0000' if( $off_str eq 'Z' );
                $off_str .= '00' if( $off_str =~ /^[+-][0-9]{2}$/ );
                my( $sign, $hh, $mm ) = ( $off_str =~ /^([+-])([0-9]{2})([0-9]{2})$/ );
                if( defined( $sign ) )
                {
                    my $secs = ( $hh * 3600 + $mm * 60 );
                    $secs *= -1 if( $sign eq '-' );
                    @resolve_args = ( $abbr, utc_offset => $secs );
                }
                else
                {
                    @resolve_args = ( $abbr );
                }
            }
            else
            {
                @resolve_args = ( $abbr );
            }
            my $candidates = DateTime::Lite::TimeZone->resolve_abbreviation( @resolve_args, extended => 1 );
            if( !defined( $candidates ) )
            {
                return( $self->_on_error( qq{Error resolving timezone abbreviation "$abbr": } . DateTime::Lite::TimeZone->error ) );
            }
            if( $candidates->[0]->{ambiguous} )
            {
                return( $self->_on_error( qq{The time zone abbreviation "$abbr" is ambiguous (maps to multiple UTC offsets). Use zone_map to specify which timezone is intended.} ) );
            }
            # When a co-parsed %z offset was used to filter candidates, all
            # results already have the correct offset - just take the first.
            # When no offset filter was applied (e.g. bare %Z without %z), we pick
            # the first zone whose CURRENT offset matches the abbreviation's offset,
            # to avoid zones that only used the abbreviation historically
            # (such as Asia/Hong_Kong for JST, which is now HKT +08:00).
            my $chosen_zone;
            if( @resolve_args > 1 )
            {
                # utc_offset filter was applied: all candidates are already correct
                $chosen_zone = DateTime::Lite::TimeZone->new(
                    name => $candidates->[0]->{zone_name}
                );
            }
            else
            {
                foreach my $candidate ( @$candidates )
                {
                    my $tz_candidate = DateTime::Lite::TimeZone->new(
                        name => $candidate->{zone_name}
                    );
                    next unless( $tz_candidate );
                    # Check the offset at the present moment
                    my $current_offset;
                    {
                        local $@;
                        eval { $current_offset = $tz_candidate->offset_for_datetime(
                            DateTime::Lite->from_epoch( epoch => time() )
                        ) };
                    }
                    if( defined( $current_offset ) &&
                        $current_offset == $candidate->{utc_offset} )
                    {
                        $chosen_zone = $tz_candidate;
                        last;
                    }
                    # Fallback: keep first candidate even if current offset differs
                    $chosen_zone //= $tz_candidate;
                }
            }
            $tz = $chosen_zone;
        }

        unless( $tz )
        {
            return( $self->_on_error( qq{Could not build a timezone object for abbreviation "$abbr".} ) );
        }
        $args->{time_zone} = $tz;
    }
    else
    {
        $args->{time_zone} ||= 'floating';
    }

    # Resolve Olson/IANA timezone name (%O token)
    if( defined( $args->{time_zone_name} ) )
    {
        my $name = $args->{time_zone_name};
        # Normalise capitalisation unconditionally before lookup, because
        # DateTime::Lite::TimeZone->new may accept incorrect case and store it verbatim,
        # which would cause time_zone_long_name to return the un-normalised string.
        # e.g. 'asia/tokyo' or 'ASIA/TOKYO' -> 'Asia/Tokyo'
        if( index( $name, '/' ) != -1 )
        {
            $name = lc( $name );
            $name =~ s{ (^|[/_]) (.) }{ $1 . uc($2) }xge;
        }
        my $tz = DateTime::Lite::TimeZone->new( name => $name, extended => 1 );
        unless( $tz )
        {
            return( $self->_on_error( qq{The Olson timezone name "$args->{time_zone_name}" does not appear to be valid.} ) );
        }
        $args->{time_zone} = $tz;
    }

    delete( @$args{ @NON_DT_KEYS } );
    $args->{locale} = $self->locale;

    # Strip leading spaces from numeric fields (%e, %k, %l are space-padded)
    foreach my $k ( grep{ defined( $args->{ $_ } ) } qw( month day hour minute second nanosecond ) )
    {
        $args->{ $k } =~ s/^\s+//;
    }

    # Nanosecond scaling: "12345" -> 123450000, "000123456" -> 123456 ns
    if( defined( $args->{nanosecond} ) )
    {
        if( length( $args->{nanosecond} ) != 9 )
        {
            $args->{nanosecond} *= 10 ** ( 9 - length( $args->{nanosecond} ) );
        }
        $args->{nanosecond} += 0;
    }

    # Supply defaults for the three required DateTime::Lite fields
    $args->{ $_ } //= 1 for qw( year month day );

    # Choose the right DateTime::Lite constructor
    if( defined( $args->{epoch} ) )
    {
        my $post_construct;
        if( my $nano = $args->{nanosecond} )
        {
            # epoch is truncated to integer by DateTime::Lite; set nanosecond afterwards
            $post_construct = sub{ $_[0]->set( nanosecond => $nano ) };
        }
        delete( @$args{ qw( day_of_year year month day hour minute second nanosecond ) } );
        return( 'from_epoch', $args, $post_construct );
    }
    elsif( $args->{day_of_year} )
    {
        delete( @$args{ qw( epoch month day ) } );
        return( 'from_day_of_year', $args );
    }

    return( 'new', $args );
}

sub _on_error
{
    my $self = shift( @_ );
    my $msg  = join( '', @_ );
    if( ref( $self->{on_error} ) eq 'CODE' )
    {
        $self->{on_error}->( $self, $msg );
        return;
    }
    elsif( defined( $self->{on_error} ) && ( $self->{on_error} eq 'croak' || $self->{on_error} eq 'die' ) )
    {
        die( $msg );
    }
    # Default 'undef': set the error object and return undef
    return( $self->error( $msg ) );
}

sub _parser
{
    my $self = shift( @_ );
    return( $self->{_parser} //= $self->_build_parser );
}

sub _parser_pieces
{
    my $self = shift( @_ );

    my %replacements = %UNIVERSAL_REPLACEMENTS;
    my $locale = $self->locale || return( $self->pass_error );

    # Locale-dependent compound expansions.
    # DateTime::Locale::FromCLDR is CLDR-based and does not provide glibc-style
    # strptime strings (glibc_datetime_format etc. are explicitly not implemented).
    # We use fixed POSIX C-locale equivalents as a universal fallback.
    # Users who need locale-specific datetime representations should use explicit 
    # patterns instead of %c/%x/%X.
    $replacements{c} = '%a %b %e %T %Y';   # e.g. "Mon Jan  3 15:04:05 2006"
    $replacements{x} = '%m/%d/%y';         # e.g. "01/03/06"
    $replacements{X} = '%T';               # e.g. "15:04:05"

    my %patterns = %UNIVERSAL_PATTERNS;

    # Locale-dependent: day names (%a/%A)
    $patterns{a} = $patterns{A} =
    {
        regex => do
        {
            my $days = join( '|',
                map { quotemeta }
                sort{ ( length( $b ) <=> length( $a ) ) || ( $a cmp $b ) }
                keys( %{ $self->_locale_days || {} } )
            );
            qr/$days/i;
        },
        field => 'day_name',
    };

    # Locale-dependent: month names (%b/%B/%h)
    $patterns{b} = $patterns{B} = $patterns{h} =
    {
        regex => do
        {
            my $months = join( '|',
                map { quotemeta }
                sort{ ( length( $b ) <=> length( $a ) ) || ( $a cmp $b ) }
                keys( %{ $self->_locale_months || {} } )
            );
            qr/$months/i;
        },
        field => 'month_name',
    };

    # Locale-dependent: AM/PM (%p/%P)
    $patterns{p} = $patterns{P} =
    {
        regex => do
        {
            my $am_pm = join( '|',
                map { quotemeta }
                sort{ ( length( $b ) <=> length( $a ) ) || ( $a cmp $b ) }
                @{$locale->am_pm_abbreviated}
            );
            qr/$am_pm/i;
        },
        field => 'am_pm',
    };

    return(
        _token_re_for( keys( %replacements ) ),
        \%replacements,
        _token_re_for( keys( %patterns ) ),
        \%patterns,
    );
}

# _restore_state(): common helper that populates $self from a plain hashref
# previously produced by _serialise_state().
sub _restore_state
{
    my( $self, $state ) = @_;
    if( !defined( $state ) || ref( $state ) ne 'HASH' )
    {
        return( $self->error( "_restore_state: state argument must be a HASH reference." ) );
    }

    foreach my $param ( qw( pattern locale on_error strict debug time_zone zone_map ) )
    {
        unless( exists( $state->{ $param } ) &&
                defined( $state->{ $param } ) )
        {
            next;
        }
        $self->$param( $state->{ $param } ) //
            return( $self->pass_error );
    }
    return( $self );
}

# _serialise_state(): common helper returning a plain hashref of the public object
# state, with objects reduced to their string identifiers.
# Used by all serialisation methods to avoid duplication.
sub _serialise_state
{
    my $self = shift( @_ );
    # on_error may be a coderef, which cannot be serialised.
    # Fall back to 'undef' and warn so the caller is not surprised.
    my $on_error = $self->{on_error};
    if( ref( $on_error ) eq 'CODE' )
    {
        warn( "on_error is a CODE reference and cannot be serialised; storing 'undef' instead." ) if( warnings::enabled( 'DateTime::Format::Lite' ) );
        $on_error = 'undef';
    }
    return({
        pattern   => $self->{pattern},
        # Reduce objects to their string identifiers for portability
        locale    => ( defined( $self->{locale} )
            ? $self->{locale}->as_string
            : 'en' ),
        time_zone => ( defined( $self->{time_zone} )
            ? $self->{time_zone}->name
            : undef ),
        on_error  => $on_error,
        strict    => $self->{strict}  // 0,
        debug     => $self->{debug}   // 0,
        zone_map  => $self->{zone_map} // {},
    });
}

sub _set_get_prop
{
    my $self = shift( @_ );
    my $prop = shift( @_ ) || die( "No object property was provided." );
    $self->{ $prop } = shift( @_ ) if( @_ );
    return( $self->{ $prop } );
}

sub _token_re_for
{
    my $t = join( '|', sort{ ( length( $b ) <=> length( $a ) ) || ( $a cmp $b ) } @_ );
    return( qr/$t/ );
}

{
    # NOTE: DateTime::Format::Lite::NullObject class
    package
        DateTime::Format::Lite::NullObject;
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

# NOTE: POD
1;
__END__

=encoding utf-8

=head1 NAME

DateTime::Format::Lite - Parse and format datetimes with strptime patterns, returning DateTime::Lite objects

=head1 SYNOPSIS

    use DateTime::Format::Lite;

    my $fmt = DateTime::Format::Lite->new(
        pattern   => '%Y-%m-%dT%H:%M:%S',
        locale    => 'ja-JP',
        time_zone => 'Asia/Tokyo',
    ) || die( DateTime::Format::Lite->error );

    my $dt  = $fmt->parse_datetime( '2026-04-14T09:00:00' );
    my $str = $fmt->format_datetime( $dt );

    # Exportable convenience functions
    use DateTime::Format::Lite qw( strptime strftime );
    my $dt2  = strptime( '%Y-%m-%d', '2026-04-14' );
    my $str2 = strftime( '%Y-%m-%d', $dt2 );

=head1 VERSION

    v0.1.3

=head1 DESCRIPTION

L<DateTime::Format::Lite> parses and formats datetime strings using strptime-style patterns, returning L<DateTime::Lite> objects.

It is a replacement for L<DateTime::Format::Strptime> designed for the L<DateTime::Lite> ecosystem, with the following key differences:

=over 4

=item No heavy dependencies

No C<Params::ValidationCompiler>, C<Specio>, or C<Try::Tiny>. Validation follows the same lightweight philosophy as L<DateTime::Lite> itself.

=item Returns L<DateTime::Lite> objects

C<parse_datetime> returns L<DateTime::Lite> objects rather than L<DateTime> objects.

=item Dynamic timezone abbreviation resolution

Rather than a static hardcoded table of ~300 entries, timezone abbreviations are resolved live against the L<IANA data|https://ftp.iana.org/tz/releases/> in the SQLite database bundled with L<DateTime::Lite::TimeZone>, via L<DateTime::Lite::TimeZone/resolve_abbreviation>. The resolution is automatically up to date with each tzdata release.

=item XS-accelerated hot paths

When a C compiler is available at install time, C<_match_and_extract> and C<format_datetime> are implemented in XS for reduced per-call overhead. A pure-Perl fallback is used automatically otherwise.

=item Error handling via C<error()>

Errors set an error object accessible via C<< $fmt->error >> and return C<undef> in scalar context, or an empty list in list context, or a C<DateTime::Format::Lite::NullObject> object in object chaining context detected with L<Wanted>, consistent with L<DateTime::Lite>. Fatal mode is available when the instantiation option C<on_error> is set to C<croak> or C<die>.

=back

=head1 CONSTRUCTORS

=head2 new

    my $fmt = DateTime::Format::Lite->new(
        pattern   => '%Y-%m-%d %H:%M:%S',
        locale    => 'fr-FR',
        time_zone => 'Europe/Paris',
        on_error  => 'undef',
        strict    => 0,
        zone_map  => { BST => 'Europe/London' },
    ) || die( DateTime::Format::Lite->error );

The C<pattern> parameter is required. All others are optional.

=over 4

=item C<pattern>

A strptime-style format string. See L</TOKENS>.

=item C<locale>

A L<BCP47 locale|https://cldr.unicode.org/index/bcp47-extension> string (such as C<fr-FR> or C<ja-JP> or even more complex ones like C<ja-Kana-t-it> or C<es-Latn-001-valencia>), a L<DateTime::Locale::FromCLDR> object, or a L<Locale::Unicode> object. Defaults to C<en>.

=item C<time_zone>

An IANA timezone name string (such as C<Asia/Tokyo>) or a L<DateTime::Lite::TimeZone> object. When provided, it is applied to the parsed object after construction. If omitted, the parsed object uses the floating timezone unless the pattern itself contains C<%z>, C<%Z>, or C<%O>.

=item C<on_error>

Error handling mode: C<undef> (by default, it returns C<undef> on error), C<croak> or C<die> (dies with the error message), or a code reference invoked as C<< $coderef->( $fmt_object, $message ) >>.

=item C<strict>

If true, wraps the compiled regex with word-boundary anchors, requiring the input datetime to be delimited from surrounding text.

=item C<zone_map>

A hash reference of abbreviation overrides. Keys are abbreviation strings; values are IANA timezone names or numeric offset strings. Set a key to C<undef> to mark an abbreviation as explicitly ambiguous (always errors if encountered during parsing).

=back

=head1 METHODS

=head2 format_datetime

    my $string = $fmt->format_datetime( $dt );

Formats a L<DateTime::Lite> object using the configured pattern. Delegates directly to L<DateTime::Lite->strftime|DateTime::Lite/strftime> without cloning.

Returns a string, or C<undef> on error.

=head2 format_duration

    my $string = $fmt->format_duration( $duration );

Formats a L<DateTime::Lite::Duration> object as an ISO 8601 duration string such as C<P1Y2M3DT4H5M6S>. A zero duration returns C<PT0S>.

=head2 parse_datetime

    my $dt = $fmt->parse_datetime( '2026-04-14 09:00:00' );

Parses C<$string> against the configured pattern and returns a L<DateTime::Lite> object on success, or C<undef> on failure (with the error accessible via C<< $fmt->error >>).

=head2 parse_duration

    my $dur = $fmt->parse_duration( 'P1Y2M3DT4H5M6S' );

Parses an ISO 8601 duration string and returns a L<DateTime::Lite::Duration> object.

=head1 ACCESSORS

=head2 debug

Boolean. When set to a true value, emits diagnostic warnings during pattern compilation and timezone resolution.

=head2 error

    my $err = DateTime::Format::Lite->error;   # class-level last error
    my $err = $fmt->error;                     # instance-level last error

Returns the last L<DateTime::Format::Lite::Exception> object set by a failed operation, or C<undef> if no error has occurred. When called as a class method it returns the last error set by any instance or constructor call. When called as an instance method it returns the last error set on that specific object.

=head2 fatal

Boolean. When true, any error calls C<die()> immediately instead of returning C<undef>. Equivalent to setting the instantiation option C<on_error> to C<die>, but applies globally when set as a class method.

=head2 locale

A L<BCP47 locale|https://cldr.unicode.org/index/bcp47-extension> string (such as C<fr-FR> or C<ja-JP> or even more complex ones like C<ja-Kana-t-it> or C<es-Latn-001-valencia>), a L<DateTime::Locale::FromCLDR> object, or a L<Locale::Unicode> object. Defaults to C<en>.

Controls the locale used for parsing and formatting locale-sensitive tokens such as C<%a>, C<%A>, C<%b>, C<%B>, and C<%p>.

=head2 on_error

Error handling mode. One of:

=over 4

=item C<undef> (default)

Returns C<undef> on error and stores the exception in C<< $fmt->error >>.

=item C<croak> or C<die>

Calls C<die()> with the exception object.

=item C<coderef>

Calls C<< $coderef->( $fmt, $message ) >>. The coderef receives the formatter object and the error message string.

=back

=head2 pass_error

    return( $self->pass_error );
    return( $self->pass_error( $other_object ) );

Propagates the last error from C<$self> (or from C<$other_object> if provided) up the call stack. Returns C<undef> in scalar context or an empty list in list context. Used internally to chain error propagation between methods.

=head2 pattern

The strptime pattern string, such as C<%Y-%m-%dT%H:%M:%S>. Required at construction time; may be updated after construction.

=head2 strict

Boolean. When true, the generated regex is anchored with word boundaries (C<\b>) at both ends. This prevents matching a date pattern embedded in a longer string such as C<2016-03-31.log> from matching if the surrounding characters would cause a word-boundary failure.

=head2 time_zone

A timezone name (C<Asia/Tokyo>, C<UTC>, C<floating>) or a L<DateTime::Lite::TimeZone> object. When set, this timezone is applied to every parsed object, overriding any timezone parsed from C<%z>, C<%Z>, or C<%O>.

=head2 zone_map

A hash reference mapping timezone abbreviations to IANA names or numeric offset strings. Useful for resolving ambiguous abbreviations such as C<IST> (which maps to India, Ireland, and Israel):

    zone_map => { IST => 'Asia/Kolkata' }

Setting a key to C<undef> marks the abbreviation as explicitly ambiguous (always an error if encountered during parsing).

=head1 TOKENS

    %Y  Four-digit year
    %y  Two-digit year (69-99 -> 19xx, 00-68 -> 20xx)
    %C  Century (combined with %y)
    %m  Month (01-12)
    %d  Day of month (01-31)
    %e  Day of month, space-padded
    %H  Hour 24h (00-23)
    %k  Hour 24h, space-padded
    %I  Hour 12h (01-12)
    %l  Hour 12h, space-padded
    %M  Minute (00-59)
    %S  Second (00-60)
    %N  Nanoseconds (scaled to 9 digits; %3N -> milliseconds, etc.)
    %p  AM/PM (locale-aware, case-insensitive)
    %P  am/pm (alias for %p)
    %a  Abbreviated weekday name (locale-aware)
    %A  Full weekday name (locale-aware)
    %b  Abbreviated month name (locale-aware)
    %B  Full month name (locale-aware)
    %h  Alias for %b
    %j  Day of year (001-366)
    %s  Unix epoch timestamp (positive or negative; pre-1970 dates use negative values)
    %u  Day of week (1=Mon .. 7=Sun, ISO)
    %w  Day of week (0=Sun .. 6=Sat)
    %U  Week number, Sunday as first day (00-53)
    %W  Week number, Monday as first day (00-53)
    %G  ISO week year (4 digits)
    %g  ISO week year (2 digits)
    %z  Timezone offset: Z, +HH:MM, +HHMM, +HH
    %Z  Timezone abbreviation such as JST or EDT
    %O  Olson/IANA timezone name such as Asia/Tokyo
    %D  Equivalent to %m/%d/%y
    %F  Equivalent to %Y-%m-%d
    %T  Equivalent to %H:%M:%S
    %R  Equivalent to %H:%M
    %r  Equivalent to %I:%M:%S %p
    %c  Locale datetime format (fixed C-locale fallback: "%a %b %e %T %Y")
    %x  Locale date format (fixed C-locale fallback: "%m/%d/%y")
    %X  Locale time format (fixed C-locale fallback: "%T")
    %n  Whitespace
    %t  Whitespace
    %%  Literal percent sign

=head1 EXPORTABLE FUNCTIONS

    use DateTime::Format::Lite qw( strptime strftime );

    my $dt  = strptime( '%Y-%m-%d', '2026-04-14' );
    my $str = strftime( '%Y-%m-%d', $dt );

Both functions dies on error.

=head2 strptime

    my $dt = strptime( $pattern, $string );

Convenience wrapper. Constructs a one-shot L<DateTime::Format::Lite> with C<$pattern> and calls C<parse_datetime( $string )>. Dies on error (constructor or parse failure).

=head2 strftime

    my $str = strftime( $pattern, $dt );

Convenience wrapper. Constructs a one-shot L<DateTime::Format::Lite> with C<$pattern> and calls C<format_datetime( $dt )>. Dies on error.

=head1 ERROR HANDLING

On error, this class methods set an L<exception object|DateTime::Format::Lite::Exception>, and return C<undef> in scalar context, or an empty list in list context. The exception object is accessible via:

    my $err = DateTime::Format::Lite->error;  # class method
    my $err = $dt->error;                     # instance method

The exception object stringifies to a human-readable message including file and line number.

C<error> detects the context is chaining, or object, and thus instead of returning C<undef>, it will return a dummy instance of C<DateTime::Format::Lite::NullObject> to avoid the typical perl error C<Can't call method '%s' on an undefined value>.

So for example:

    $fmt->parse_datetime( %bad_arguments )->iso8601;

If there was an error in C<parse_datetime>, the chain will execute, but the last one, C<iso8601> in this example, will return C<undef>, so you can and even should check the return value:

    $fmt->parse_datetime( %bad_arguments )->iso8601 ||
        die( $fmt->error );

=head1 SERIALISATION

L<DateTime::Format::Lite> supports serialisation via L<Storable>, L<Sereal>, L<CBOR::XS>, and JSON serialisers.

The following methods are implemented:

=over 4

=item C<FREEZE> / C<THAW>

Used by L<Sereal> (v4+) and L<CBOR::XS>. The object is reduced to its public configuration state (C<pattern>, C<locale>, C<time_zone>, C<on_error>, C<strict>, C<debug>, C<zone_map>). Internal caches are not serialised and are rebuilt on demand after thawing.

=item C<STORABLE_freeze> / C<STORABLE_thaw>

Used by L<Storable>. The state is encoded as a compact pipe-delimited string. The C<zone_map> is JSON-encoded when non-empty.

=item C<TO_JSON>

Returns the public configuration state as a plain hash reference, suitable for serialisation by L<JSON::XS>, L<Cpanel::JSON::XS>, or similar. The returned hash reference contains: C<pattern>, C<locale> (BCP47 string), C<time_zone> (IANA name string or C<undef>), C<on_error>, C<strict>, C<debug>, and C<zone_map>.

Note that if C<on_error> was set to a code reference, it cannot be serialised. C<undef> is stored as a fallback and a warning is issued if the L<DateTime::Format::Lite> warning category is enabled.

=back

=head1 SEE ALSO

L<DateTime::Lite>, L<DateTime::Lite::TimeZone>, L<DateTime::Format::Strptime>, L<DateTime::Format::Unicode>, L<DateTime::Locale::FromCLDR>, L<Locale::Unicode>, L<Locale::Unicode::Data>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
