##----------------------------------------------------------------------------
## Lightweight DateTime Alternative - ~/lib/DateTime/Lite/TimeZone.pm
## Version v0.5.2
## Copyright(c) 2026 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2026/04/03
## Modified 2026/04/19
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package DateTime::Lite::TimeZone;
BEGIN
{
    use v5.10.1;
    use strict;
    use warnings;
    if( $] < 5.013 )
    {
        no strict 'refs';
        unless( defined( &warnings::register_categories ) )
        {
            *warnings::_mkMask = sub
            {
                my $bit  = shift( @_ );
                my $mask = "";
                vec( $mask, $bit, 1 ) = 1;
                return( $mask );
            };

            *warnings::register_categories = sub
            {
                my @names = @_;
                foreach my $name ( @names )
                {
                    if( !defined( $warnings::Bits{ $name } ) )
                    {
                        $warnings::Offsets{ $name }  = $warnings::LAST_BIT;
                        $warnings::Bits{ $name }     = warnings::_mkMask( $warnings::LAST_BIT++ );
                        $warnings::DeadBits{ $name } = warnings::_mkMask( $warnings::LAST_BIT++ );
                        if( length( $warnings::Bits{ $name } ) > length( $warnings::Bits{all} ) )
                        {
                            $warnings::Bits{all}     .= "\x55";
                            $warnings::DeadBits{all} .= "\xaa";
                        }
                    }
                }
            };
        }
    }
    warnings::register_categories( 'DateTime::Lite' );
    use vars qw(
        $VERSION $ERROR $DEBUG $FATAL_EXCEPTIONS
        $DB_FILE $DBH $STHS
        $FALLBACK_TO_DT_TZ
        $HAS_CONSTANTS
        $MISSING_AUTO_UTF8_DECODING
        $SQLITE_HAS_MATH_FUNCTIONS
        $USE_MEM_CACHE $_CACHE
    );
    use overload (
        '""'     => \&name,
        bool     => sub{1},
        fallback => 1,
    );
    use version ();
    use Cwd ();
    use File::Spec ();
    use Scalar::Util ();
    use Wanted;

    # Seconds between the Unix epoch (1970-01-01T00:00:00 UTC) and the Rata Die
    # epoch (0001-01-01T00:00:00) used internally by DateTime::Lite.
    #
    # The tz.sqlite3 database stores transition times as raw Unix seconds
    # (as they come from the TZif binary files). All lookups subtract this
    # constant from $dt->utc_rd_as_seconds before querying the database.
    #
    # Verified:
    # DateTime::Lite->new(
    #     year  => 1970,
    #     month => 1,
    #     day   => 1,
    #     time_zone => 'UTC',
    # )->utc_rd_as_seconds == 62_135_683_200
    use constant UNIX_TO_RD => 62_135_683_200;
    our $VERSION = 'v0.5.2';
    our $DEBUG   = 0;
    our $DBH     = {};
    # Cached prepared statements, keyed by db file path then by statement ID:
    # $STHS->{ $db_file }->{ $statement_id } = $sth
    our $STHS    = {};
    # Package-level memory cache: canonical_name -> blessed object.
    # Populated when use_cache_mem => 1 is passed to new(), or when
    # enable_mem_cache() has been called at the class level.
    # Keys are canonical zone names after alias resolution.
    our $_CACHE  = {};
    # $SQLITE_HAS_MATH_FUNCTIONS is not defined on purpose
    # Its definedness is checked in _dbh_add_user_defined_functions()

    # The bundled database lives next to this file
    {
        my( $vol, $parent, $file ) = File::Spec->splitpath( __FILE__ );
        $DB_FILE = File::Spec->catpath( $vol, $parent, 'tz.sqlite3' );
        $DB_FILE = File::Spec->rel2abs( $DB_FILE )
            unless( File::Spec->file_name_is_absolute( $DB_FILE ) );
    }

    # Detect whether DBD::SQLite is available. If not, we fall back to
    # DateTime::TimeZone transparently.
    $FALLBACK_TO_DT_TZ = 0;
    local $@;
    eval
    {
        require DBI;
        require DBD::SQLite;
    };
    if( $@ )
    {
        warn( "DateTime::Lite::TimeZone: DBD::SQLite not available, falling back to DateTime::TimeZone. Install DBD::SQLite for a lighter footprint." ) if( warnings::enabled( 'DateTime::Lite' ) );
        $FALLBACK_TO_DT_TZ = 1;
    }
    elsif( !-e( $DB_FILE ) )
    {
        warn( "DateTime::Lite::TimeZone: bundled database $DB_FILE not found, falling back to DateTime::TimeZone." ) if( warnings::enabled( 'DateTime::Lite' ) );
        $FALLBACK_TO_DT_TZ = 1;
    }

    if( !$FALLBACK_TO_DT_TZ && -l( $DB_FILE ) )
    {
        my $real_path = Cwd::realpath( $DB_FILE );
        if( !-e( $real_path ) )
        {
            warn( "DateTime::Lite::TimeZone: bundled database $DB_FILE is a symbolic link pointing to $real_path, but it could not be found, falling back to DateTime::TimeZone." ) if( warnings::enabled( 'DateTime::Lite' ) );
            $FALLBACK_TO_DT_TZ = 1;
        }
        else
        {
            $DB_FILE = $real_path;
        }
    }

    if( !$FALLBACK_TO_DT_TZ && -z( $DB_FILE ) )
    {
        warn( "DateTime::Lite::TimeZone: bundled database $DB_FILE is an empty file (zero byte)." ) if( warnings::enabled( 'DateTime::Lite' ) );
        $FALLBACK_TO_DT_TZ = 1;
    }

    if( $FALLBACK_TO_DT_TZ )
    {
        local $@;
        # Lazy loading of DateTime::TimeZone
        # We do not want to make it a dependency of our module.
        eval
        {
            require DateTime::TimeZone;
        };
        if( $@ )
        {
            die( "Neither SQLite nor DateTime::TimeZone are installed on your system. You need at least one of them to use this module." );
        }
    }
    else
    {
        # DBD::SQLite::Constants available since 1.48
        # Foreign key constraints since SQLite v3.6.19 (2009-10-14)
        # DBD::SQLite 1.27 (2009-11-23)
        # utf8 auto decoding from version 1.68 (2021-07-22)
        $HAS_CONSTANTS = ( version->parse( $DBD::SQLite::VERSION ) >= version->parse( '1.48' ) ) ? 1 : 0;
        # Native UTF-8 string mode available since 1.68
        $MISSING_AUTO_UTF8_DECODING = ( version->parse( $DBD::SQLite::VERSION ) < version->parse( '1.68' ) ) ? 1 : 0;
    }
};

use strict;
use warnings;

# NOTE: Constructor
sub new
{
    my $this  = shift( @_ );
    my $class = ref( $this ) || $this;
    my %args;

    if( @_ == 1 && !ref( $_[0] ) )
    {
        $args{name} = shift( @_ );
    }
    else
    {
        %args = @_;
    }

    my $name        = delete( $args{name} );
    my $use_cache   = delete( $args{use_cache_mem} ) // $USE_MEM_CACHE // 0;
    my $latitude    = delete( $args{latitude} )  // delete( $args{lat} );
    my $longitude   = delete( $args{longitude} ) // delete( $args{lon} );

    # If latitude and longitude are provided instead of a name, resolve the
    # nearest IANA timezone using the coordinates stored in the zones table.
    if( !defined( $name ) || !length( $name ) )
    {
        if( defined( $latitude ) && defined( $longitude ) )
        {
            $name = $class->_nearest_zone( $latitude, $longitude ) ||
                return( $class->pass_error );
        }
        else
        {
            return( $class->error( "Parameter 'name' is required (or provide 'latitude' and 'longitude')." ) );
        }
    }

    # Package-level memory cache: return immediately if the canonical name
    # is already cached. The cache is keyed BEFORE alias resolution so
    # that both the alias ("US/Eastern") and the canonical name
    # ("America/New_York") are stored and looked up by their original form.
    if( $use_cache && exists( $_CACHE->{ $name } ) )
    {
        return( $_CACHE->{ $name } );
    }

    # Delegate entirely to DateTime::TimeZone if fallback mode is active
    if( $FALLBACK_TO_DT_TZ )
    {
        local $@;
        my $tz = eval{ DateTime::TimeZone->new( name => $name ) };
        return( $class->error( "Invalid time zone name '$name': $@" ) ) if( $@ );
        return( $tz );
    }

    $args{fatal} //= ( $FATAL_EXCEPTIONS // 0 );

    # Special cases: floating, UTC, and local never need a DB lookup
    if( $name eq 'local' )
    {
        # Resolve the local timezone name from the environment or OS.
        # We try the following methods in order, all using only core modules:
        #   1. $ENV{TZ} if set, valid, and not 'local' (to avoid infinite loop)
        #   2. /etc/localtime symlink target (most Linux and macOS systems)
        #   3. /etc/timezone plain text file (Debian/Ubuntu)
        #   4. /etc/TIMEZONE with TZ= line (Solaris)
        #   5. /etc/sysconfig/clock with ZONE= or TIMEZONE= line (RedHat)
        #   6. /etc/default/init with TZ= line (older Unix)
        my $local_name = $class->_resolve_local_tz_name ||
            return( $class->error( "Cannot determine local time zone. Please set \$ENV{TZ}." ) );
        # Recurse with the resolved name
        return( $class->new( name => $local_name, %args ) );
    }

    if( $name eq 'floating' )
    {
        return( bless(
        {
            name        => 'floating',
            is_floating => 1,
            is_utc      => 0,
            is_olson    => 0,
            has_dst     => 0,
            fatal       => $args{fatal},
        }, $class ) );
    }

    if( $name eq 'UTC' || $name eq 'Z' || $name eq '+0000' || $name eq '-0000' )
    {
        return( bless(
        {
            name        => 'UTC',
            is_floating => 0,
            is_utc      => 1,
            is_olson    => 0,
            has_dst     => 0,
            fatal       => $args{fatal},
        }, $class ) );
    }

    # Fixed-offset zones like "+09:00" or "-05:00" or "+0900"
    if( $name =~ /\A([+-])(\d{2}):?(\d{2})\z/ )
    {
        my $sign    = $1 eq '+' ? 1 : -1;
        my $offset  = $sign * ( $2 * 3600 + $3 * 60 );
        return( bless(
        {
            name         => $name,
            is_floating  => 0,
            is_utc       => ( $offset == 0 ? 1 : 0 ),
            is_olson     => 0,
            has_dst      => 0,
            fixed_offset => $offset,
            fatal        => $args{fatal},
        }, $class ) );
    }

    my $self = bless(
    {
        name        => $name,
        is_floating => 0,
        is_utc      => 0,
        is_olson    => 1,
        has_dst     => 0,
        _zone_id    => undef,
        fatal       => $args{fatal},
    }, $class );

    # Resolve aliases (such as "US/Eastern" -> "America/New_York")
    my $canonical = $self->_resolve_alias( $name ) ||
        return( $self->pass_error );

    $self->{_is_canonical} = ( $canonical eq $name ? 1 : 0 );
    if( !$self->{_is_canonical} )
    {
        $self->{name}      = $canonical;
        $self->{_alias_of} = $name;
    }

    my $ref = $self->_get_zone_info( $self->{name} );
    return( $self->pass_error ) if( !defined( $ref ) && $self->error );

    return( $self->error( "Unknown time zone '$name'." ) ) unless( $ref );

    $self->{_zone_id}         = $ref->{zone_id};
    $self->{has_dst}          = $ref->{has_dst}   ? 1 : 0;
    $self->{is_olson}         = $ref->{canonical} ? 1 : 0;
    my @keys = qw( countries coordinates comment latitude longitude tzif_version footer_tz_string transition_count type_count leap_count isstd_count designation_charcount );
    @$self{ @keys } = @$ref{ @keys };

    # Store in process-level cache if requested.
    # Cache under both the input name (which may be an alias) and the
    # canonical name so that either form hits the cache on the next call.
    # Also initialise the per-object span cache so that _lookup_span
    # avoids SQLite queries for repeated timestamps in the same span.
    if( $use_cache )
    {
        $self->{_span_cache}             = {};
        $self->{_span_cache_local}       = {};
        $self->{_footer_cache_key}       = undef;
        $self->{_footer_cache_val}       = undef;
        $self->{_footer_local_cache_key} = undef;
        $self->{_footer_local_cache_val} = undef;
        $_CACHE->{ $name }               = $self;
        $_CACHE->{ $self->{name} }       = $self if( $self->{name} ne $name );
    }

    return( $self );
}

sub aliases
{
    # Can be called as class method, instance method, or plain function.
    my $class_or_self = shift( @_ );
    local $@;
    my $sth;
    unless( $sth = $class_or_self->_get_cached_statement( 'all_aliases' ) )
    {
        my $dbh = $class_or_self->_dbh || return( $class_or_self->pass_error );
        my $query = q{SELECT alias_name, zone_name FROM v_zone_aliases ORDER BY alias_name};
        $sth = eval
        {
            $dbh->prepare( $query );
        } || return( $class_or_self->error( "Error preparing the query to get all timezone aliases: ", ( $@ || $dbh->errstr ), "\nSQL query was $query" ) );
        $class_or_self->_set_cached_statement( all_aliases => $sth );
    }

    my $rv = eval{ $sth->execute };
    if( $@ )
    {
        $sth->finish;
        return( $class_or_self->error( "Error executing the query to get all timezone aliases: $@", "\nSQL query was ", $sth->{Statement} ) );
    }
    elsif( !defined( $rv ) )
    {
        $sth->finish;
        return( $class_or_self->error( "Error executing the query to get all timezone aliases: ", $sth->errstr, "\nSQL query was ", $sth->{Statement} ) );
    }

    my $all = eval{ $sth->fetchall_arrayref([0,1]) };
    if( $@ )
    {
        $sth->finish;
        return( $class_or_self->error( "Error retrieving all timezone aliases: $@", "\nSQL query was ", $sth->{Statement} ) );
    }
    # We check for definedness, which means an error in DBI
    elsif( !defined( $all ) && $sth->errstr )
    {
        $sth->finish;
        return( $class_or_self->error( "Error retrieving all timezone aliases: ", $sth->errstr, "\nSQL query was ", $sth->{Statement} ) );
    }
    $sth->finish;
    my $aliases = +{map{ $_->[0] => $_->[1] } @$all};
    return( wantarray() ? %$aliases : $aliases );
}

{
    no warnings 'once';
    *links = \&aliases;
}

sub all_names
{
    # Can be called as class method, instance method, or plain function.
    my $class_or_self = shift( @_ );
    local $@;
    my $sth;
    unless( $sth = $class_or_self->_get_cached_statement( 'all_names' ) )
    {
        my $dbh = $class_or_self->_dbh || return( $class_or_self->pass_error );
        # We handle each step of building the query, so we can report on any error with better accuracy.
        my $query = q{SELECT name FROM zones ORDER BY name};
        $sth = eval
        {
            $dbh->prepare( $query );
        } || return( $class_or_self->error( "Error preparing the query to get all timezone names: ", ( $@ || $dbh->errstr ), "\nSQL query was $query" ) );
        $class_or_self->_set_cached_statement( all_names => $sth );
    }

    my $rv = eval{ $sth->execute };
    if( $@ )
    {
        $sth->finish;
        return( $class_or_self->error( "Error executing the query to get all timezone names: $@\nSQL query was ", $sth->{Statement} ) );
    }
    elsif( !defined( $rv ) )
    {
        $sth->finish;
        return( $class_or_self->error( "Error executing the query to get all timezone names: ", $sth->errstr, "\nSQL query was ", $sth->{Statement} ) );
    }

    my $all = eval{ $sth->fetchall_arrayref([0]) };
    if( $@ )
    {
        $sth->finish;
        return( $class_or_self->error( "Error retrieving all timezone names: $@", "\nSQL query was ", $sth->{Statement} ) );
    }
    # We check for definedness, which means an error in DBI
    elsif( !defined( $all ) && $sth->errstr )
    {
        $sth->finish;
        return( $class_or_self->error( "Error retrieving all timezone names: ", $sth->errstr, "\nSQL query was ", $sth->{Statement} ) );
    }
    $sth->finish;
    my $zones = [map{ $_->[0] } @$all];
    return( wantarray() ? @$zones : $zones );
}

sub categories
{
    # Can be called as class method, instance method, or plain function.
    my $class_or_self = shift( @_ );
    local $@;
    my $sth;
    unless( $sth = $class_or_self->_get_cached_statement( 'categories' ) )
    {
        my $dbh = $class_or_self->_dbh || return( $class_or_self->pass_error );
        my $query = q{SELECT DISTINCT(category) FROM zones WHERE category IS NOT NULL ORDER BY category};
        $sth = eval
        {
            $dbh->prepare( $query );
        } || return( $class_or_self->error( "Error preparing the query to get all timezone categories: ", ( $@ || $dbh->errstr ), "\nSQL query was $query" ) );
        $class_or_self->_set_cached_statement( categories => $sth );
    }

    my $rv = eval{ $sth->execute };
    if( $@ )
    {
        $sth->finish;
        return( $class_or_self->error( "Error executing the query to get all timezone categories: $@", "\nSQL query was ", $sth->{Statement} ) );
    }
    elsif( !defined( $rv ) )
    {
        $sth->finish;
        return( $class_or_self->error( "Error executing the query to get all timezone categories: ", $sth->errstr, "\nSQL query was ", $sth->{Statement} ) );
    }

    my $all = eval{ $sth->fetchall_arrayref([0]) };
    if( $@ )
    {
        $sth->finish;
        return( $class_or_self->error( "Error retrieving all timezone categories: $@", "\nSQL query was ", $sth->{Statement} ) );
    }
    # We check for definedness, which means an error in DBI
    elsif( !defined( $all ) && $sth->errstr )
    {
        $sth->finish;
        return( $class_or_self->error( "Error retrieving all timezone categories: ", $sth->errstr, "\nSQL query was ", $sth->{Statement} ) );
    }
    $sth->finish;
    my $categories = [map{ $_->[0] } @$all];
    return( wantarray() ? @$categories : $categories );
}

# Returns the first part of the timezone, such as 'Asia' in 'Asia/Tokyo'
sub category
{
    my $self = shift( @_ );
    unless( defined( $self ) && ref( $self ) )
    {
        return( $self->error( "category() must be called on a class instance." ) );
    }
    return if( index( $self->{name}, '/' ) == -1 );
    return( [split( /\//, $self->{name}, 2 )]->[0] );
}

# clear_mem_cache()
# Class method. Removes all entries from the package-level cache without
# disabling it. Useful when zone data may have changed, such as after replacing
# tz.sqlite3 at runtime, which is an unusual operation.
sub clear_mem_cache
{
    my $class = shift( @_ );
    $_CACHE = {};
    return( $class );
}

# Returns the optional zone comment from zone1970.tab
sub comment     { return( $_[0]->{comment} ) }

# Returns the compact coordinate string from zone1970.tab, such as "+3518+13942"
sub coordinates { return( $_[0]->{coordinates} ) }

# Returns an arrayref of ISO 3166-1 alpha-2 country codes associated with
# this timezone, such as ["JP"] or ["US","CA"].
# Returns an empty array for UTC, floating, and fixed-offset zones.
sub country_codes
{
    my $self = shift( @_ );
    unless( defined( $self ) && ref( $self ) )
    {
        return( $self->error( "country_codes() must be called on a class instance." ) );
    }
    return unless( defined( $self->{countries} ) );
    # We need to cache it
    unless( ref( $self->{countries} ) eq 'ARRAY' )
    {
        $self->{countries} = $self->_decode_sql_array( $self->{countries} );
    }
    return( $self->{countries} );
}

sub countries
{
    # Can be called as class method, instance method, or plain function.
    my $class_or_self = shift( @_ );
    local $@;
    my $sth;
    unless( $sth = $class_or_self->_get_cached_statement( 'countries' ) )
    {
        my $dbh = $class_or_self->_dbh || return( $class_or_self->pass_error );
        my $query = q{SELECT LOWER(code) FROM countries ORDER BY code};
        $sth = eval
        {
            $dbh->prepare( $query );
        } || return( $class_or_self->error( "Error preparing the query to get all country codes: ", ( $@ || $dbh->errstr ), "\nSQL query was $query" ) );
        $class_or_self->_set_cached_statement( countries => $sth );
    }

    my $rv = eval{ $sth->execute };
    if( $@ )
    {
        $sth->finish;
        return( $class_or_self->error( "Error executing the query to get all country codes: $@", "\nSQL query was ", $sth->{Statement} ) );
    }
    elsif( !defined( $rv ) )
    {
        $sth->finish;
        return( $class_or_self->error( "Error executing the query to get all country codes: ", $sth->errstr, "\nSQL query was ", $sth->{Statement} ) );
    }

    my $all = eval{ $sth->fetchall_arrayref([0]) };
    if( $@ )
    {
        $sth->finish;
        return( $class_or_self->error( "Error retrieving all country codes: $@", "\nSQL query was ", $sth->{Statement} ) );
    }
    # We check for definedness, which means an error in DBI
    elsif( !defined( $all ) && $sth->errstr )
    {
        $sth->finish;
        return( $class_or_self->error( "Error retrieving all country codes: ", $sth->errstr, "\nSQL query was ", $sth->{Statement} ) );
    }
    $sth->finish;
    my $codes = [map{ $_->[0] } @$all];
    return( wantarray() ? @$codes : $codes );
}

# Returns the path to the bundled tz.sqlite3 database
sub datafile { return( $DB_FILE ) }

sub designation_charcount { return( $_[0]->{designation_charcount} ) }

# disable_mem_cache()
# Class method. Disables the package-level cache and clears all cached entries.
sub disable_mem_cache
{
    my $class = shift( @_ );
    $USE_MEM_CACHE = 0;
    $_CACHE = {};
    return( $class );
}

# enable_mem_cache( [$bool] )
# Class method. Enables or disables the package-level memory cache for all
# subsequent TimeZone->new() calls. When enabled, constructed objects are
# stored in a process-global hash keyed by canonical zone name; repeated
# calls for the same name return the cached object without a DB query.
#
# Equivalent to passing use_cache_mem => 1 on every new() call.
sub enable_mem_cache
{
    my( $class, $bool ) = @_;
    $bool //= 1;
    $USE_MEM_CACHE = $bool ? 1 : 0;
    return( $class );
}

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
            warn( $msg ) if( warnings::enabled( 'DateTime::Lite') );
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
            warn( "Cannot call fatal in mutator mode as a class method." ) if( warnings::enabled( 'DateTime::Lite' ) );
        }
    }
    return( ref( $this ) ? $this->_set_get_prop( 'fatal' ) : $FATAL_EXCEPTIONS );
}

sub footer_tz_string { return( $_[0]->{footer_tz_string} ); }

{
    no warnings 'once';
    *has_dst = \&has_dst_changes;
}

# Returns true if this timezone observes DST transitions
sub has_dst_changes
{
    my $self = shift( @_ );
    unless( defined( $self ) && ref( $self ) )
    {
        return( $self->error( "has_dst_changes() must be called on a class instance." ) );
    }
    return( $self->{has_dst} ? 1 : 0 );
}

sub is_canonical { return( $_[0]->{_is_canonical} ? 1 : 0 ); }

sub is_dst_for_datetime
{
    my $self = shift( @_ );
    my $dt   = shift( @_ );
    unless( defined( $self ) && ref( $self ) )
    {
        return( $self->error( "is_dst_for_datetime() must be called on a class instance." ) );
    }
    return(0) if( $self->{is_floating} || $self->{is_utc} );
    return(0) if( exists( $self->{fixed_offset} ) );
    if( !defined( $dt ) )
    {
        return( $self->error( "No DateTime::Lite or DateTime object was provided." ) );
    }
    elsif( !Scalar::Util::blessed( $dt ) )
    {
        return( $self->error( "The object provided (", overload::StrVal( $dt ), ") is not an object." ) );
    }
    elsif( !$dt->can( 'utc_rd_as_seconds' ) )
    {
        return( $self->error( "The object provided (", overload::StrVal( $dt ), ") does not support the method 'utc_rd_as_seconds'." ) );
    }
    my $span = $self->_lookup_span( $dt->utc_rd_as_seconds ) || return(0);
    return( $span->{is_dst} ? 1 : 0 );
}

sub is_floating { return( $_[0]->{is_floating} ? 1 : 0 ) }

sub is_olson    { return( $_[0]->{is_olson} ? 1 : 0 ) }

sub is_utc      { return( $_[0]->{is_utc} ? 1 : 0 ) }

sub is_valid_name
{
    # Can be called as class method, instance method, or plain function.
    my $class_or_self = shift( @_ );
    my $name = shift( @_ ) ||
        return( $class_or_self->error( "No timezone name was provided." ) );
    my $canon = $class_or_self->_resolve_alias( $name );
    return( $class_or_self->pass_error ) if( !defined( $canon ) && $class_or_self->error );
    my $orig;
    if( defined( $canon ) && $name ne $canon )
    {
        $orig = $name;
        $name = $canon;
    }
    my $ref = $class_or_self->_get_zone_info( $name ) || return(0);
    return(1);
}

sub isstd_count { return( $_[0]->{isstd_count} ); }

sub isut_count  { return( $_[0]->{isut_count} ); }

sub latitude    { return( $_[0]->{latitude} ) }

sub leap_count  { return( $_[0]->{leap_count} ); }

sub longitude   { return( $_[0]->{longitude} ) }

sub name        { return( $_[0]->{name} ) }

sub names_in_category
{
    # Can be called as class method, instance method, or plain function.
    my $class_or_self = shift( @_ );
    my $cat = shift( @_ ) ||
        return( $class_or_self->error( "No timezone category was provided." ) );
    local $@;
    my $sth;
    unless( $sth = $class_or_self->_get_cached_statement( 'names_in_category' ) )
    {
        my $dbh = $class_or_self->_dbh || return( $class_or_self->pass_error );
        my $query = <<'SQL';
SELECT DISTINCT
    CASE
        WHEN subregion IS NOT NULL
        THEN subregion || '/' || location
        ELSE location
    END AS name
FROM zones
WHERE category = ?
ORDER BY name
SQL
        $sth = eval
        {
            $dbh->prepare( $query );
        } || return( $class_or_self->error( "Error preparing the query to get all local names for a category: ", ( $@ || $dbh->errstr ), "\nSQL query was $query" ) );
        $class_or_self->_set_cached_statement( names_in_category => $sth );
    }

    my $rv = eval{ $sth->execute( $cat ) };
    if( $@ )
    {
        $sth->finish;
        return( $class_or_self->error( "Error executing the query to get all local names for the category $cat: $@", "\nSQL query was ", $sth->{Statement} ) );
    }
    elsif( !defined( $rv ) )
    {
        $sth->finish;
        return( $class_or_self->error( "Error executing the query to get all local names for the category $cat: ", $sth->errstr, "\nSQL query was ", $sth->{Statement} ) );
    }

    my $all = eval{ $sth->fetchall_arrayref([0]) };
    if( $@ )
    {
        $sth->finish;
        return( $class_or_self->error( "Error retrieving all local names for the category $cat: $@", "\nSQL query was ", $sth->{Statement} ) );
    }
    # We check for definedness, which means an error in DBI
    elsif( !defined( $all ) && $sth->errstr )
    {
        $sth->finish;
        return( $class_or_self->error( "Error retrieving all local names for the category $cat: ", $sth->errstr, "\nSQL query was ", $sth->{Statement} ) );
    }
    $sth->finish;
    my $names = [map{ $_->[0] } @$all];
    return( wantarray() ? @$names : $names );
}

sub names_in_country
{
    # Can be called as class method, instance method, or plain function.
    my $class_or_self = shift( @_ );
    my $code = shift( @_ ) ||
        return( $class_or_self->error( "No country code was provided." ) );
    # Because the country codes are stored in upper case, and there is no need to have SQL change the case when we can do it.
    $code = uc( $code );
    local $@;
    my $sth;
    unless( $sth = $class_or_self->_get_cached_statement( 'names_in_country' ) )
    {
        my $dbh = $class_or_self->_dbh || return( $class_or_self->pass_error );
        my $query = <<'SQL';
SELECT DISTINCT
     z.name
FROM zones z
JOIN json_each( z.countries ) j
  ON 1 = 1
WHERE j.value = ?
ORDER BY z.name
SQL
        $sth = eval
        {
            $dbh->prepare( $query );
        } || return( $class_or_self->error( "Error preparing the query to get all zone names for a given country code: ", ( $@ || $dbh->errstr ), "\nSQL query was $query" ) );
        $class_or_self->_set_cached_statement( names_in_country => $sth );
    }

    my $rv = eval{ $sth->execute( $code ) };
    if( $@ )
    {
        $sth->finish;
        return( $class_or_self->error( "Error executing the query to get all zone names for the country code $code: $@", "\nSQL query was ", $sth->{Statement} ) );
    }
    elsif( !defined( $rv ) )
    {
        $sth->finish;
        return( $class_or_self->error( "Error executing the query to get all zone names for the country code $code: ", $sth->errstr, "\nSQL query was ", $sth->{Statement} ) );
    }

    my $all = eval{ $sth->fetchall_arrayref([0]) };
    if( $@ )
    {
        $sth->finish;
        return( $class_or_self->error( "Error retrieving all zone names for the country code $code: $@" ) );
    }
    # We check for definedness, which means an error in DBI
    elsif( !defined( $all ) && $sth->errstr )
    {
        $sth->finish;
        return( $class_or_self->error( "Error retrieving all zone names for the country code $code: ", $sth->errstr, "\nSQL query was ", $sth->{Statement} ) );
    }
    $sth->finish;
    my $names = [map{ $_->[0] } @$all];
    return( wantarray() ? @$names : $names );
}

sub offset_as_seconds
{
    # Can be called as class method, instance method, or plain function.
    my $class_or_self = shift( @_ );
    my $offset = shift( @_ );

    return( $class_or_self->error( "No offset was provided." ) ) unless( defined( $offset ) );
    return(0) if( $offset eq '0' );

    my( $sign, $hours, $minutes, $seconds );
    # Colon form: [+-]H:MM[:SS] or [+-]HH:MM[:SS]
    if( $offset =~ /\A([+-])?(\d{1,2}):(\d{2})(?::(\d{2}))?\z/ )
    {
        ( $sign, $hours, $minutes, $seconds ) = ( $1, $2, $3, $4 );
    }
    # Compact form: [+-]HHMM[SS]
    elsif( $offset =~ /\A([+-])?(\d{2})(\d{2})(\d{2})?\z/ )
    {
        ( $sign, $hours, $minutes, $seconds ) = ( $1, $2, $3, $4 );
    }
    else
    {
        # Will return undef in scalar context, and an empty list in list context.
        return( $class_or_self->error( "Unsupported offset format '$offset'" ) );
    }

    $sign //= '+';
    unless( $hours >= 0 && $hours <= 99 )
    {
        return( $class_or_self->error( "Unsupported hours ($hours). It must be greater or equal to 0 and lower or equal to 99." ) );
    }
    unless( $minutes >= 0 && $minutes <= 59 )
    {
        return( $class_or_self->error( "Unsupported minutes ($minutes). It must be greater or equal to 0 and lower or equal to 59." ) );
    }
    if( defined( $seconds ) && ( $seconds < 0 || $seconds > 59 ) )
    {
        return( $class_or_self->error( "Unsupported seconds ($seconds). It must be greater or equal to 0 and lower or equal to 59." ) );
    }

    my $total = $hours * 3600 + $minutes * 60;
    $total   += $seconds if( defined( $seconds ) );
    $total   *= -1 if( $sign eq '-' );

    return( $total );
}

# Class or instance method: convert an offset in seconds to a formatted string.
# With no separator: "+0900"; with ':' as separator: "+09:00"
# Drop-in compatible with DateTime::TimeZone->offset_as_string.
sub offset_as_string
{
    # Can be called as class method, instance method, or plain function.
    # Second arg is the offset in seconds; third (optional) is a separator
    # (':' gives '+09:00' style, default gives '+0900').
    my $class_or_self = shift( @_ );
    my $offset        = shift( @_ );
    my $sep           = shift( @_ ) // '';
    unless( defined( $offset ) && length( $offset // '' ) )
    {
        return( $class_or_self->error( "No offset was provided." ) );
    }
    unless( $offset >= -359999 && $offset <= 359999 )
    {
        return( $class_or_self->error( "Offset must be comprised between -359999 and 359999" ) );
    }

    my $sign  = $offset < 0 ? '-' : '+';
    my $abs   = abs( $offset );
    my $hours = int( $abs / 3600 );
    my $mins  = int( ( $abs % 3600 ) / 60 );
    my $secs  = $abs % 60;

    if( $secs )
    {
        return( sprintf( "%s%02d%s%02d%s%02d", $sign, $hours, $sep, $mins, $sep, $secs ) );
    }
    return( sprintf( "%s%02d%s%02d", $sign, $hours, $sep, $mins ) );
}

sub offset_for_datetime
{
    my $self = shift( @_ );
    my $dt   = shift( @_ );
    unless( defined( $self ) && ref( $self ) )
    {
        return( $self->error( "offset_for_datetime() must be called on a class instance." ) );
    }
    return(0) if( $self->{is_floating} || $self->{is_utc} );
    return( $self->{fixed_offset} ) if( exists( $self->{fixed_offset} ) );
    if( !defined( $dt ) )
    {
        return( $self->error( "No DateTime::Lite or DateTime object was provided." ) );
    }
    elsif( !Scalar::Util::blessed( $dt ) )
    {
        return( $self->error( "The object provided (", overload::StrVal( $dt ), ") is not an object." ) );
    }
    elsif( !$dt->can( 'utc_rd_as_seconds' ) )
    {
        return( $self->error( "The object provided (", overload::StrVal( $dt ), ") does not support the method 'utc_rd_as_seconds'." ) );
    }
    my $span = $self->_lookup_span( $dt->utc_rd_as_seconds ) || return(0);
    return( $span->{offset} + 0 );
}

sub offset_for_local_datetime
{
    my $self = shift( @_ );
    my $dt   = shift( @_ );
    unless( defined( $self ) && ref( $self ) )
    {
        return( $self->error( "offset_for_local_datetime() must be called on a class instance." ) );
    }
    return(0) if( $self->{is_floating} || $self->{is_utc} );
    return( $self->{fixed_offset} ) if( exists( $self->{fixed_offset} ) );
    if( !defined( $dt ) )
    {
        return( $self->error( "No DateTime::Lite or DateTime object was provided." ) );
    }
    elsif( !Scalar::Util::blessed( $dt ) )
    {
        return( $self->error( "The object provided (", overload::StrVal( $dt ), ") is not an object." ) );
    }
    elsif( !$dt->can( 'local_rd_as_seconds' ) )
    {
        return( $self->error( "The object provided (", overload::StrVal( $dt ), ") does not support the method 'local_rd_as_seconds'." ) );
    }
    my $span = $self->_lookup_span_local( $dt->local_rd_as_seconds ) || return(0);
    return( $span->{offset} + 0 );
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

sub resolve_abbreviation
{
    my $self = shift( @_ );
    my $abbr = shift( @_ ) ||
        return( $self->error( "No timezone abbreviation was provided." ) );
    my %opts = @_;

    local $@;
    my $sth;
    my $has_offset = (
        defined( $opts{utc_offset} ) &&
        Scalar::Util::looks_like_number( $opts{utc_offset} )
    ) ? 1 : 0;
    my $extended = $opts{extended} ? 1 : 0;

    # Build the dynamic WHERE skeleton for the IANA types query.
    # Based on Locale::Unicode::Data::_fetch_all(): each filter value may be prefixed
    # with a comparison operator (<, <=, >, >=, =, !=).
    # When period is an array ref, each element adds one AND condition on
    # MAX(tr.trans_time). When period is the special string 'current', the query
    # is restricted to the zone's last transition (MAX = most recent) and requires
    # that last transition to be in the past, effectively returning only zones that
    # still use the abbreviation today.
    my $op_map = { '=' => 'IS', '!=' => 'IS NOT' };

    # Conditions on MAX(tr.trans_time) built from the 'period' option.
    # Each element of @period_skels is a HAVING clause fragment.
    # @period_key_parts accumulates tokens for the cache key; they must distinguish
    # ISO date strings from raw epoch integers since each uses a different SQL
    # placeholder form ('e' = epoch, 'd' = ISO date).
    my @period_skels     = ();
    my @period_values    = ();
    my @period_key_parts = ();
    my $current_special  = 0;

    if( defined( $opts{period} ) )
    {
        my @period_items = ref( $opts{period} ) eq 'ARRAY'
            ? @{$opts{period}}
            : ( $opts{period} );

        foreach my $item ( @period_items )
        {
            if( !defined( $item ) || !length( $item ) )
            {
                return( $self->error( "Empty value in 'period' option for resolve_abbreviation." ) );
            }

            # Special value 'current': return only zones whose most recent transition
            # for this abbreviation is in the past and whose next transition has not yet
            # occurred. Handled via LEFT JOIN below.
            if( $item eq 'current' )
            {
                $current_special = 1;
                push( @period_key_parts, 'current' );
                next;
            }

            my $op  = '>';
            my $val = $item;
            # Strip leading operator prefix, e.g. '>1950-01-01' -> op='>', val='1950-01-01'
            if( $val =~ s/^[[:blank:]\h]*(?<op>\<|\<=|\>|\>=|=|\!=)[[:blank:]\h]*(?<val>.+?)$/$+{val}/ )
            {
                $op = $+{op};
            }
            $op = $op_map->{ $op } if( exists( $op_map->{ $op } ) );
            # Dates are stored as Unix epoch integers; convert ISO date string via
            # SQLite strftime('%s', ...) so the user can pass '1950-01-01'.
            # Numeric values are used as-is (already epoch seconds).
            # IMPORTANT: the two paths generate different SQL, so the cache key must
            # distinguish them via 'e' (epoch int) vs 'd' (ISO date string).
            if( Scalar::Util::looks_like_number( $val ) )
            {
                # Use CAST(? AS INTEGER) rather than a bare ? to ensure SQLite
                # treats the bind value as an integer regardless of how DBD::SQLite
                # represents the Perl scalar internally (string vs numeric).
                push( @period_skels,     "MAX(tr.trans_time) ${op} CAST(? AS INTEGER)" );
                push( @period_values,    $val + 0 );
                push( @period_key_parts, "${op}e" );
            }
            else
            {
                push( @period_skels,     "MAX(tr.trans_time) ${op} CAST(strftime('%s', ?) AS INTEGER)" );
                push( @period_values,    $val );
                push( @period_key_parts, "${op}d" );
            }
        }
    }

    # The HAVING clause combines the utc_offset filter and any period conditions.
    # Because we GROUP BY zone to obtain MAX(trans_time) for ordering and period
    # filtering, utc_offset is also moved into HAVING (it is functionally constant
    # per (zone, abbreviation) pair so this is semantically equivalent).
    my @having_skels  = ();
    my @having_values = ();

    if( $has_offset )
    {
        push( @having_skels,  "t.utc_offset = ?" );
        push( @having_values, $opts{utc_offset} );
    }
    push( @having_skels,  @period_skels );
    push( @having_values, @period_values );

    # Build the HAVING clause first so we can derive the cache key from the actual SQL
    # string, which is provably collision-free.
    # 'current' restricts to zones where the matched abbreviation type's most recent
    # transition IS the zone's overall most recent transition, meaning the abbreviation
    # is still active right now. The conditions are added directly to @having_skels so
    # that the HAVING keyword is always emitted when needed, avoiding any
    # GROUP BY / HAVING confusion.
    # A correlated subquery referencing the outer MAX() is not supported by SQLite in
    # HAVING; we use an independent scalar subquery instead.
    if( $current_special )
    {
        push( @having_skels, <<'SQL' );
MAX(tr.trans_time) <= CAST(strftime('%s', 'now') AS INTEGER)
SQL
        push( @having_skels, <<'SQL' );
MAX(tr.trans_time) = (
    SELECT MAX(tr2.trans_time)
    FROM   transition tr2
    WHERE  tr2.zone_id = t.zone_id
)
SQL
    }
    # Build the HAVING clause from all accumulated conditions.
    # Conditions are joined with AND; the HAVING keyword is only emitted when at least
    # one condition exists, keeping the SQL clean.
    my @having_parts = ();
    foreach my $skel ( @having_skels )
    {
        chomp( my $s = $skel );
        push( @having_parts, $s );
    }
    my $having_sql = scalar( @having_parts )
        ? "\nHAVING " . join( "\n   AND ", @having_parts )
        : "";
    # We JOIN transition to get MAX(trans_time) per zone for:
    #   1. Default sort order: most-recently-used first (DESC).
    #   2. Period filtering via HAVING on MAX(trans_time).
    # DISTINCT is replaced by GROUP BY zone since we aggregate.
    my $query = <<"SQL_IANA";
SELECT z.name AS zone_name, t.utc_offset, t.is_dst,
       MAX(tr.trans_time) AS last_trans_time
FROM types t
JOIN zones z       ON z.zone_id  = t.zone_id
JOIN transition tr ON tr.zone_id = t.zone_id AND tr.type_id = t.type_id
WHERE z.canonical = 1
  AND t.abbreviation = ?
GROUP BY z.name, t.utc_offset, t.is_dst${having_sql}
ORDER BY last_trans_time DESC
SQL_IANA
    # Use the SQL string itself as the cache key - provably collision-free
    # regardless of any subtlety in the period_key_parts logic.
    my $cache_id = 'resolve_abbreviation_sql_' . $query;
    unless( $sth = $self->_get_cached_statement( $cache_id ) )
    {
        my $dbh  = $self->_dbh || return( $self->pass_error );
        $sth = eval
        {
            $dbh->prepare( $query );
        } || return( $self->error( "Error preparing the abbreviation resolution query: ", ( $@ || $dbh->errstr ), "\nSQL query was: $query" ) );
        $self->_set_cached_statement( $cache_id => $sth );
    }

    my $rv = eval
    {
        $sth->execute( $abbr, @having_values );
    };
    if( $@ )
    {
        $sth->finish;
        return( $self->error( "Error executing the abbreviation resolution query for '$abbr': $@\nSQL query was: ", $sth->{Statement} ) );
    }
    elsif( !defined( $rv ) )
    {
        $sth->finish;
        return( $self->error( "Error executing the abbreviation resolution query for '$abbr': ", $sth->errstr, "\nSQL query was: ", $sth->{Statement} ) );
    }

    my $all = eval{ $sth->fetchall_arrayref( {} ) };
    if( $@ )
    {
        $sth->finish;
        return( $self->error( "Error retrieving abbreviation resolution results for '$abbr': $@\nSQL query was: ", $sth->{Statement} ) );
    }
    elsif( !defined( $all ) && $sth->errstr )
    {
        $sth->finish;
        return( $self->error( "Error retrieving abbreviation resolution results for '$abbr': ", $sth->errstr, "\nSQL query was: ", $sth->{Statement} ) );
    }
    $sth->finish;

    # IANA types table returned results: use them directly.
    if( @$all )
    {
        # Determine whether all candidates share the same UTC offset.
        # If they do, the abbreviation is unambiguous in terms of wall-clock meaning,
        # even if multiple zone names match (such as JST covering several Asian zones
        # all at +09:00). Genuinely ambiguous abbreviations such as IST or CST map to
        # different offsets and get ambiguous => 1.
        my %offsets = map{ $_->{utc_offset} => 1 } @$all;
        my $ambiguous = scalar( keys( %offsets ) ) > 1 ? 1 : 0;
        return([
            map
            {
                {
                    zone_name       => $_->{zone_name},
                    utc_offset      => $_->{utc_offset},
                    is_dst          => $_->{is_dst} ? 1 : 0,
                    ambiguous       => $ambiguous,
                    extended        => 0,
                    last_trans_time => $_->{last_trans_time},
                }
            }
            @$all
        ]);
    }

    # No results in the IANA types table.
    # If extended mode is not requested, fail with the standard message.
    unless( $extended )
    {
        return( $self->error( "No timezone found for abbreviation '$abbr'." ) );
    }

    # Extended mode: fall back to the extended_aliases table.
    # Covers real-world abbreviations (such as BDT, CEST, JST) that are not stored as
    # type abbreviations in the IANA TZif data but map to known zones.
    # Note: extended aliases carry no utc_offset or is_dst data; those fields are
    # undef in the result. The caller must resolve offset from the zone itself if
    # needed.
    # Period filtering does not apply to extended aliases (no trans_time data).
    my $ext_sth;
    unless( $ext_sth = $self->_get_cached_statement( 'resolve_abbreviation_extended' ) )
    {
        my $dbh = $self->_dbh || return( $self->pass_error );
        my $query = <<'SQL_EXTENDED';
SELECT ea.abbreviation, z.name AS zone_name, ea.is_primary
FROM extended_aliases ea
JOIN zones z ON z.zone_id = ea.zone_id
WHERE ea.abbreviation = ?
ORDER BY ea.is_primary DESC, z.name
SQL_EXTENDED
        $ext_sth = eval
        {
            $dbh->prepare( $query );
        } || return( $self->error( "Error preparing the extended alias resolution query: ", ( $@ || $dbh->errstr ), "\nSQL query was: $query" ) );
        $self->_set_cached_statement( resolve_abbreviation_extended => $ext_sth );
    }

    my $ext_rv = eval{ $ext_sth->execute( $abbr ) };
    if( $@ )
    {
        $ext_sth->finish;
        return( $self->error( "Error executing the extended alias resolution query for '$abbr': $@\nSQL query was: ", $ext_sth->{Statement} ) );
    }
    elsif( !defined( $ext_rv ) )
    {
        $ext_sth->finish;
        return( $self->error( "Error executing the extended alias resolution query for '$abbr': ", $ext_sth->errstr, "\nSQL query was: ", $ext_sth->{Statement} ) );
    }

    my $ext_all = eval{ $ext_sth->fetchall_arrayref( {} ) };
    if( $@ )
    {
        $ext_sth->finish;
        return( $self->error( "Error retrieving extended alias results for '$abbr': $@\nSQL query was: ", $ext_sth->{Statement} ) );
    }
    elsif( !defined( $ext_all ) && $ext_sth->errstr )
    {
        $ext_sth->finish;
        return( $self->error( "Error retrieving extended alias results for '$abbr': ", $ext_sth->errstr, "\nSQL query was: ", $ext_sth->{Statement} ) );
    }
    $ext_sth->finish;

    unless( @$ext_all )
    {
        return( $self->error( "No timezone found for abbreviation '$abbr' (including extended aliases)." ) );
    }

    # Ambiguity for extended aliases: more than one candidate with no single
    # is_primary designating the canonical choice.
    my $n_primary = scalar( grep{ $_->{is_primary} } @$ext_all );
    my $n_total   = scalar( @$ext_all );
    my $ambiguous = ( $n_total > 1 && $n_primary != 1 ) ? 1 : 0;

    return([
        map
        {
            {
                zone_name  => $_->{zone_name},
                # Extended aliases carry no offset data.
                utc_offset => undef,
                is_dst     => undef,
                ambiguous  => $ambiguous,
                is_primary => $_->{is_primary} ? 1 : 0,
                extended   => 1,
            }
        }
        @$ext_all
    ]);
}

sub short_name_for_datetime
{
    my $self = shift( @_ );
    my $dt   = shift( @_ );
    unless( defined( $self ) && ref( $self ) )
    {
        return( $self->error( "short_name_for_datetime() must be called on a class instance." ) );
    }
    return( 'floating' ) if( $self->{is_floating} );
    return( 'UTC' )      if( $self->{is_utc} );
    if( exists( $self->{fixed_offset} ) )
    {
        return( $self->offset_as_string( $self->{fixed_offset} ) );
    }

    if( !defined( $dt ) )
    {
        return( $self->error( "No DateTime::Lite or DateTime object was provided." ) );
    }
    elsif( !Scalar::Util::blessed( $dt ) )
    {
        return( $self->error( "The object provided (", overload::StrVal( $dt ), ") is not an object." ) );
    }
    elsif( !$dt->can( 'utc_rd_as_seconds' ) )
    {
        return( $self->error( "The object provided (", overload::StrVal( $dt ), ") does not support the method 'utc_rd_as_seconds'." ) );
    }
    my $span = $self->_lookup_span( $dt->utc_rd_as_seconds ) ||
        return( $self->{name} );
    return( $span->{short_name} );
}

sub transition_count { return( $_[0]->{transition_count} ); }

sub type_count { return( $_[0]->{type_count} ); }

# Returns the tzdata version string from the database metadata, such as "2026a"
sub tz_version
{
    my $self = shift( @_ );
    local $@;
    my $sth;
    unless( $sth = $self->_get_cached_statement( 'tz_version' ) )
    {
        my $dbh = $self->_dbh || return( $self->pass_error );
        my $query = "SELECT value FROM metadata WHERE key = 'tz_version'";
        local $@;
        $sth = eval
        {
            $dbh->prepare( $query )
        } || return( $self->error( "Cannot prepare tz_version query: ", ( $@ || $dbh->errstr ), "\nSQL query was $query" ) );
        $self->_set_cached_statement( tz_version => $sth );
    }

    my $rv = eval{ $sth->execute };
    if( $@ )
    {
        $sth->finish;
        return( $self->error( "Error executing the query to get the tz_version: $@", "\nSQL query was ", $sth->{Statement} ) );
    }
    elsif( !defined( $rv ) )
    {
        $sth->finish;
        return( $self->error( "Error executing the query to get the tz_version: ", $sth->errstr, "\nSQL query was ", $sth->{Statement} ) );
    }
    my $row = eval{ $sth->fetchrow_arrayref };
    if( $@ )
    {
        $sth->finish;
        return( $self->error( "Error retrieving the tz_version: $@", "\nSQL query was ", $sth->{Statement} ) );
    }
    # We check for definedness, which means an error in DBI
    elsif( !defined( $row ) && $sth->errstr )
    {
        $sth->finish;
        return( $self->error( "Error retrieving the tz_version: ", $sth->errstr, "\nSQL query was ", $sth->{Statement} ) );
    }
    $sth->finish;
    return( $row ? $row->[0] : undef );
}

sub tzif_version
{
    my $self = shift( @_ );
    unless( defined( $self ) && ref( $self ) )
    {
        return( $self->error( "tzif_version() must be called on a class instance." ) );
    }
    return( $self->{tzif_version} );
}

# NOTE: Windows timezone name -> IANA mapping
# Source: DateTime::TimeZone::Local::Win32 by Dave Rolsky and David Pinkowitz.
# Built lazily via state in _local_tz_mswin32; consumes no memory on non-Windows
# platforms.
sub _build_win_to_iana
{
    return(
    {
    'Afghanistan'                     => 'Asia/Kabul',
    'Afghanistan Standard Time'       => 'Asia/Kabul',
    'Alaskan'                         => 'America/Anchorage',
    'Alaskan Standard Time'           => 'America/Anchorage',
    'Aleutian Standard Time'          => 'America/Adak',
    'Altai Standard Time'             => 'Asia/Barnaul',
    'Arab'                            => 'Asia/Riyadh',
    'Arab Standard Time'              => 'Asia/Riyadh',
    'Arabian'                         => 'Asia/Muscat',
    'Arabian Standard Time'           => 'Asia/Muscat',
    'Arabic Standard Time'            => 'Asia/Baghdad',
    'Argentina Standard Time'         => 'America/Argentina/Buenos_Aires',
    'Armenian Standard Time'          => 'Asia/Yerevan',
    'Astrakhan Standard Time'         => 'Europe/Astrakhan',
    'Atlantic'                        => 'America/Halifax',
    'Atlantic Standard Time'          => 'America/Halifax',
    'AUS Central'                     => 'Australia/Darwin',
    'AUS Central Standard Time'       => 'Australia/Darwin',
    'Aus Central W. Standard Time'    => 'Australia/Eucla',
    'AUS Eastern'                     => 'Australia/Sydney',
    'AUS Eastern Standard Time'       => 'Australia/Sydney',
    'Azerbaijan Standard Time'        => 'Asia/Baku',
    'Azores'                          => 'Atlantic/Azores',
    'Azores Standard Time'            => 'Atlantic/Azores',
    'Bahia Standard Time'             => 'America/Bahia',
    'Bangkok'                         => 'Asia/Bangkok',
    'Bangkok Standard Time'           => 'Asia/Bangkok',
    'Bangladesh Standard Time'        => 'Asia/Dhaka',
    'Beijing'                         => 'Asia/Shanghai',
    'Belarus Standard Time'           => 'Europe/Minsk',
    'Bougainville Standard Time'      => 'Pacific/Bougainville',
    'Canada Central'                  => 'America/Regina',
    'Canada Central Standard Time'    => 'America/Regina',
    'Cape Verde Standard Time'        => 'Atlantic/Cape_Verde',
    'Caucasus'                        => 'Asia/Yerevan',
    'Caucasus Standard Time'          => 'Asia/Yerevan',
    'Cen. Australia'                  => 'Australia/Adelaide',
    'Cen. Australia Standard Time'    => 'Australia/Adelaide',
    'Central'                         => 'America/Chicago',
    'Central America Standard Time'   => 'America/Tegucigalpa',
    'Central Asia'                    => 'Asia/Almaty',
    'Central Asia Standard Time'      => 'Asia/Almaty',
    'Central Brazilian Standard Time' => 'America/Cuiaba',
    'Central Europe'                  => 'Europe/Prague',
    'Central Europe Standard Time'    => 'Europe/Prague',
    'Central European'                => 'Europe/Belgrade',
    'Central European Standard Time'  => 'Europe/Warsaw',
    'Central Pacific'                 => 'Pacific/Guadalcanal',
    'Central Pacific Standard Time'   => 'Pacific/Guadalcanal',
    'Central Standard Time'           => 'America/Chicago',
    'Central Standard Time (Mexico)'  => 'America/Mexico_City',
    'Chatham Islands Standard Time'   => 'Pacific/Chatham',
    'China'                           => 'Asia/Shanghai',
    'China Standard Time'             => 'Asia/Shanghai',
    'Cuba Standard Time'              => 'America/Havana',
    'Dateline'                        => '-1200',
    'Dateline Standard Time'          => 'Etc/GMT+12',
    'E. Africa'                       => 'Africa/Nairobi',
    'E. Africa Standard Time'         => 'Africa/Nairobi',
    'E. Australia'                    => 'Australia/Brisbane',
    'E. Australia Standard Time'      => 'Australia/Brisbane',
    'E. Europe'                       => 'Europe/Helsinki',
    'E. Europe Standard Time'         => 'Europe/Chisinau',
    'E. South America'                => 'America/Sao_Paulo',
    'E. South America Standard Time'  => 'America/Sao_Paulo',
    'Easter Island Standard Time'     => 'Pacific/Easter',
    'Eastern'                         => 'America/New_York',
    'Eastern Standard Time'           => 'America/New_York',
    'Eastern Standard Time (Mexico)'  => 'America/Cancun',
    'Egypt'                           => 'Africa/Cairo',
    'Egypt Standard Time'             => 'Africa/Cairo',
    'Ekaterinburg'                    => 'Asia/Yekaterinburg',
    'Ekaterinburg Standard Time'      => 'Asia/Yekaterinburg',
    'Fiji'                            => 'Pacific/Fiji',
    'Fiji Standard Time'              => 'Pacific/Fiji',
    'FLE'                             => 'Europe/Helsinki',
    'FLE Standard Time'               => 'Europe/Helsinki',
    'Georgian Standard Time'          => 'Asia/Tbilisi',
    'GFT'                             => 'Europe/Athens',
    'GFT Standard Time'               => 'Europe/Athens',
    'GMT'                             => 'Europe/London',
    'GMT Standard Time'               => 'Europe/London',
    'Greenland Standard Time'         => 'America/Godthab',
    'Greenwich'                       => 'GMT',
    'Greenwich Standard Time'         => 'GMT',
    'GTB'                             => 'Europe/Athens',
    'GTB Standard Time'               => 'Europe/Athens',
    'Haiti Standard Time'             => 'America/Port-au-Prince',
    'Hawaiian'                        => 'Pacific/Honolulu',
    'Hawaiian Standard Time'          => 'Pacific/Honolulu',
    'India'                           => 'Asia/Kolkata',
    'India Standard Time'             => 'Asia/Kolkata',
    'Iran'                            => 'Asia/Tehran',
    'Iran Standard Time'              => 'Asia/Tehran',
    'Israel'                          => 'Asia/Jerusalem',
    'Israel Standard Time'            => 'Asia/Jerusalem',
    'Jordan Standard Time'            => 'Asia/Amman',
    'Kaliningrad Standard Time'       => 'Europe/Kaliningrad',
    'Kamchatka Standard Time'         => 'Asia/Kamchatka',
    'Korea'                           => 'Asia/Seoul',
    'Korea Standard Time'             => 'Asia/Seoul',
    'Libya Standard Time'             => 'Africa/Tripoli',
    'Line Islands Standard Time'      => 'Pacific/Kiritimati',
    'Lord Howe Standard Time'         => 'Australia/Lord_Howe',
    'Magadan Standard Time'           => 'Asia/Magadan',
    'Magallanes Standard Time'        => 'America/Punta_Arenas',
    'Marquesas Standard Time'         => 'Pacific/Marquesas',
    'Mauritius Standard Time'         => 'Indian/Mauritius',
    'Mexico'                          => 'America/Mexico_City',
    'Mexico Standard Time'            => 'America/Mexico_City',
    'Mexico Standard Time 2'          => 'America/Chihuahua',
    'Mid-Atlantic'                    => 'Atlantic/South_Georgia',
    'Mid-Atlantic Standard Time'      => 'Atlantic/South_Georgia',
    'Middle East Standard Time'       => 'Asia/Beirut',
    'Montevideo Standard Time'        => 'America/Montevideo',
    'Morocco Standard Time'           => 'Africa/Casablanca',
    'Mountain'                        => 'America/Denver',
    'Mountain Standard Time'          => 'America/Denver',
    'Mountain Standard Time (Mexico)' => 'America/Mazatlan',
    'Myanmar Standard Time'           => 'Asia/Rangoon',
    'N. Central Asia Standard Time'   => 'Asia/Novosibirsk',
    'Namibia Standard Time'           => 'Africa/Windhoek',
    'Nepal Standard Time'             => 'Asia/Katmandu',
    'New Zealand'                     => 'Pacific/Auckland',
    'New Zealand Standard Time'       => 'Pacific/Auckland',
    'Newfoundland'                    => 'America/St_Johns',
    'Newfoundland Standard Time'      => 'America/St_Johns',
    'Norfolk Standard Time'           => 'Pacific/Norfolk',
    'North Asia East Standard Time'   => 'Asia/Irkutsk',
    'North Asia Standard Time'        => 'Asia/Krasnoyarsk',
    'North Korea Standard Time'       => 'Asia/Pyongyang',
    'Omsk Standard Time'              => 'Asia/Omsk',
    'Pacific'                         => 'America/Los_Angeles',
    'Pacific SA'                      => 'America/Santiago',
    'Pacific SA Standard Time'        => 'America/Santiago',
    'Pacific Standard Time'           => 'America/Los_Angeles',
    'Pacific Standard Time (Mexico)'  => 'America/Tijuana',
    'Pakistan Standard Time'          => 'Asia/Karachi',
    'Paraguay Standard Time'          => 'America/Asuncion',
    'Prague Bratislava'               => 'Europe/Prague',
    'Qyzylorda Standard Time'         => 'Asia/Qyzylorda',
    'Romance'                         => 'Europe/Paris',
    'Romance Standard Time'           => 'Europe/Paris',
    'Russia Time Zone 10'             => 'Asia/Srednekolymsk',
    'Russia Time Zone 11'             => 'Asia/Anadyr',
    'Russia Time Zone 3'              => 'Europe/Samara',
    'Russian'                         => 'Europe/Moscow',
    'Russian Standard Time'           => 'Europe/Moscow',
    'SA Eastern'                      => 'America/Cayenne',
    'SA Eastern Standard Time'        => 'America/Cayenne',
    'SA Pacific'                      => 'America/Bogota',
    'SA Pacific Standard Time'        => 'America/Bogota',
    'SA Western'                      => 'America/Guyana',
    'SA Western Standard Time'        => 'America/Guyana',
    'Saint Pierre Standard Time'      => 'America/Miquelon',
    'Sakhalin Standard Time'          => 'Asia/Sakhalin',
    'Samoa'                           => 'Pacific/Apia',
    'Samoa Standard Time'             => 'Pacific/Apia',
    'Sao Tome Standard Time'          => 'Africa/Sao_Tome',
    'Saratov Standard Time'           => 'Europe/Saratov',
    'Saudi Arabia'                    => 'Asia/Riyadh',
    'Saudi Arabia Standard Time'      => 'Asia/Riyadh',
    'SE Asia'                         => 'Asia/Bangkok',
    'SE Asia Standard Time'           => 'Asia/Bangkok',
    'Singapore'                       => 'Asia/Singapore',
    'Singapore Standard Time'         => 'Asia/Singapore',
    'South Africa'                    => 'Africa/Harare',
    'South Africa Standard Time'      => 'Africa/Harare',
    'South Sudan Standard Time'       => 'Africa/Juba',
    'Sri Lanka'                       => 'Asia/Colombo',
    'Sri Lanka Standard Time'         => 'Asia/Colombo',
    'Sudan Standard Time'             => 'Africa/Khartoum',
    'Syria Standard Time'             => 'Asia/Damascus',
    'Sydney Standard Time'            => 'Australia/Sydney',
    'Taipei'                          => 'Asia/Taipei',
    'Taipei Standard Time'            => 'Asia/Taipei',
    'Tasmania'                        => 'Australia/Hobart',
    'Tasmania Standard Time'          => 'Australia/Hobart',
    'Tocantins Standard Time'         => 'America/Araguaina',
    'Tokyo'                           => 'Asia/Tokyo',
    'Tokyo Standard Time'             => 'Asia/Tokyo',
    'Tomsk Standard Time'             => 'Asia/Tomsk',
    'Tonga Standard Time'             => 'Pacific/Tongatapu',
    'Transbaikal Standard Time'       => 'Asia/Chita',
    'Turkey Standard Time'            => 'Europe/Istanbul',
    'Turks And Caicos Standard Time'  => 'America/Grand_Turk',
    'Ulaanbaatar Standard Time'       => 'Asia/Ulaanbaatar',
    'US Eastern'                      => 'America/Indianapolis',
    'US Eastern Standard Time'        => 'America/Indianapolis',
    'US Mountain'                     => 'America/Phoenix',
    'US Mountain Standard Time'       => 'America/Phoenix',
    'UTC'                             => 'UTC',
    'UTC+13'                          => 'Etc/GMT-13',
    'UTC+12'                          => 'Etc/GMT-12',
    'UTC-02'                          => 'America/Noronha',
    'UTC-08'                          => 'Etc/GMT+8',
    'UTC-09'                          => 'Etc/GMT+9',
    'UTC-11'                          => 'Etc/GMT+11',
    'Venezuela Standard Time'         => 'America/Caracas',
    'Vladivostok'                     => 'Asia/Vladivostok',
    'Vladivostok Standard Time'       => 'Asia/Vladivostok',
    'Volgograd Standard Time'         => 'Europe/Volgograd',
    'W. Australia'                    => 'Australia/Perth',
    'W. Australia Standard Time'      => 'Australia/Perth',
    'W. Central Africa Standard Time' => 'Africa/Luanda',
    'W. Europe'                       => 'Europe/Berlin',
    'W. Europe Standard Time'         => 'Europe/Berlin',
    'W. Mongolia Standard Time'       => 'Asia/Hovd',
    'Warsaw'                          => 'Europe/Warsaw',
    'West Asia'                       => 'Asia/Karachi',
    'West Asia Standard Time'         => 'Asia/Tashkent',
    'West Bank Standard Time'         => 'Asia/Gaza',
    'West Pacific'                    => 'Pacific/Guam',
    'West Pacific Standard Time'      => 'Pacific/Guam',
    'Western Brazilian Standard Time' => 'America/Rio_Branco',
    'Yakutsk'                         => 'Asia/Yakutsk',
    'Yakutsk Standard Time'           => 'Asia/Yakutsk',
    'Yukon Standard Time'             => 'America/Whitehorse',
    });
}

sub _dbh
{
    my $self = shift( @_ );
    my $file = $DB_FILE;

    if( $DBH &&
        ref( $DBH ) eq 'HASH' &&
        exists( $DBH->{ $file } ) &&
        $DBH->{ $file } &&
        Scalar::Util::blessed( $DBH->{ $file } ) &&
        $DBH->{ $file }->isa( 'DBI::db' ) &&
        $DBH->{ $file }->ping )
    {
        return( $DBH->{ $file } );
    }

    return( $self->error( "Timezone database file '$file' does not exist." ) )
        unless( -e( $file ) );
    return( $self->error( "Timezone database file '$file' is not a regular file." ) )
        unless( -f( $file ) );
    return( $self->error( "Timezone database file '$file' is empty." ) )
        if( -z( $file ) );
    return( $self->error( "Timezone database file '$file' is not readable by uid $>." ) )
        unless( -r( $file ) );

    # Require SQLite >= 3.6.19 for foreign key support (DBD::SQLite >= 1.27)
    if( version->parse( $DBD::SQLite::sqlite_version ) < version->parse( '3.6.19' ) )
    {
        return( $self->error( "SQLite version 3.6.19 or higher is required. You have $DBD::SQLite::sqlite_version" ) );
    }

    my $params = {};
    if( $HAS_CONSTANTS )
    {
        require DBD::SQLite::Constants;
        $params->{sqlite_open_flags} = DBD::SQLite::Constants::SQLITE_OPEN_READONLY();
    }

    my $dbh = DBI->connect(
        "dbi:SQLite:dbname=$file", '', '',
        {
            %$params,
            RaiseError     => 0,
            PrintError     => 0,
            AutoCommit     => 1,
            sqlite_unicode => 1,
        }
    ) || return( $self->error( "Cannot connect to timezone database '$file': $DBI::errstr" ) );

    $dbh->do( "PRAGMA foreign_keys = ON" );
    $dbh->do( "PRAGMA query_only   = ON" );

    # Native UTF-8 string mode available since DBD::SQLite 1.68
    if( !$MISSING_AUTO_UTF8_DECODING )
    {
        $dbh->{sqlite_string_mode} = DBD::SQLite::Constants::DBD_SQLITE_STRING_MODE_UNICODE_FALLBACK();
    }
    return( $DBH->{ $file } = $dbh );
}

sub _dbh_add_user_defined_functions
{
    my( $this, $dbh ) = @_;
    if( defined( $SQLITE_HAS_MATH_FUNCTIONS ) )
    {
        return( $SQLITE_HAS_MATH_FUNCTIONS );
    }
    elsif( !$dbh )
    {
        return( $this->error( "No database handle was provided." ) );
    }
    # Determine whether SQLite's built-in math functions are available.
    #
    # Detection strategy based on SQLite version:
    #
    #   >= 3.35.0 (2021-03-12): built-in math functions may be available, but only if
    #     compiled with -DSQLITE_ENABLE_MATH_FUNCTIONS (which DBD::SQLite enables by
    #     default since ~1.72). Query pragma_function_list for 'sqrt' to confirm. Since
    #     this check runs before any UDF is registered, a hit is guaranteed native.
    #
    #   >= 3.16.0 (2017-01-02) and < 3.35.0: pragma_function_list exists but the math
    #     functions do not, so querying it would be pointless.
    #     Register Perl UDFs directly.
    #
    #   < 3.16.0 (2017-01-02): pragma_function_list is not available as a table-valued
    #     function. Register Perl UDFs directly.
    #
    # UDFs via sqlite_create_function() are available on all SQLite >= 3.0.0.
    # <https://sqlite.org/lang_mathfunc.html>
    # <https://sqlite.org/pragma.html#pragfunc>
    my $sqlite_ver = version->parse( $DBD::SQLite::sqlite_version );
    my $has_math   = 0;
    # The virtual table pragma_function_list is available, so we query it to check if the math functions have been compiled with the macro 'SQLITE_ENABLE_MATH_FUNCTIONS'
    if( $sqlite_ver >= version->parse( '3.35.0' ) )
    {
        my $query = "SELECT name FROM pragma_function_list WHERE name = 'sqrt'";
        local $@;
        my $sth = eval
        {
            $dbh->prepare( $query );
        } || return( $this->error( "Error preparing the query to check if SQLite has math functions: ", ( $@ || $dbh->errstr ), "\nSQL query was $query" ) );
        my $rv = eval{ $sth->execute };
        if( $@ )
        {
            $sth->finish;
            return( $this->error( "Error executing the query to check if SQLite has math functions: $@", "\nSQL query was ", $sth->{Statement} ) );
        }
        elsif( !defined( $rv ) )
        {
            $sth->finish;
            return( $this->error( "Error executing the query to check if SQLite has math functions: ", $sth->errstr, "\nSQL query was ", $sth->{Statement} ) );
        }
        my $row = eval{ $sth->fetchrow_arrayref };
        if( $@ )
        {
            $sth->finish;
            return( $this->error( "Error retrieving the value to check if SQLite has math functions: $@", "\nSQL query was ", $sth->{Statement} ) );
        }
        # We check for definedness, which means an error in DBI
        elsif( !defined( $row ) && $sth->errstr )
        {
            $sth->finish;
            return( $this->error( "Error retrieving the value to check if SQLite has math functions: ", $sth->errstr, "\nSQL query was ", $sth->{Statement} ) );
        }
        $sth->finish;
        # Don't assume anything.
        if( $row && ref( $row ) eq 'ARRAY' && $row->[0] )
        {
            $has_math = 1;
        }
    }

    if( $has_math )
    {
        # <https://sqlite.org/lang_mathfunc.html>
        $SQLITE_HAS_MATH_FUNCTIONS = 1;
    }
    else
    {
        # Native math functions are absent or unconfirmed; register Perl UDFs.
        require POSIX;
        $dbh->sqlite_create_function( 'sqrt', 1, sub{ CORE::sqrt( $_[0] ) } );
        $dbh->sqlite_create_function( 'sin',  1, sub{ CORE::sin(  $_[0] ) } );
        $dbh->sqlite_create_function( 'cos',  1, sub{ CORE::cos(  $_[0] ) } );
        $dbh->sqlite_create_function( 'asin', 1, sub{ POSIX::asin( $_[0] ) } );
        $SQLITE_HAS_MATH_FUNCTIONS = 0;
    }
    return(1);
}

# _decode_sql_array() decode the JSON array and returns an array reference. 
sub _decode_sql_array
{
    my $self = shift( @_ );
    die( "\$cldr->_decode_sql_array( \$data )" ) if( @_ != 1 );
    my $data = shift( @_ );
    # No data was provided
    if( !defined( $data ) )
    {
        return;
    }
    # Should not be a reference, but a plain string
    elsif( ref( $data ) )
    {
        die( "\$cldr->_decode_sql_array( \$data )" );
    }

    require JSON;
    my $j = JSON->new->relaxed;
    local $@;
    my $decoded = eval
    {
        $j->decode( $data );
    };
    if( $@ )
    {
        warn( "Warning only: error attempting to decode JSON array: $@" );
        $decoded = [];
    }
    return( $decoded );
}

# _decode_sql_arrays() takes an hash reference, or an array of hash reference,
# and decode the array fields of those tuples
sub _decode_sql_arrays
{
    my $self = shift( @_ );
    die( "\$cldr->_decode_sql_arrays( \$array_ref_of_array_fields, \$data )" ) if( @_ != 2 );
    my( $where, $ref ) = @_;
    if( ref( $where ) ne 'ARRAY' )
    {
        die( "\$cldr->_decode_sql_arrays( \$array_ref_of_array_fields, \$data )" );
    }
    # No data was provided
    elsif( !defined( $ref ) )
    {
        return;
    }
    elsif( ref( $ref // '' ) ne 'HASH' && Scalar::Util::reftype( $ref // '' ) ne 'ARRAY' )
    {
        die( "\$cldr->_decode_sql_arrays( \$array_ref_of_array_fields, \$data )" );
    }

    require JSON;
    my $j = JSON->new->relaxed;
    local $@;
    if( ref( $ref ) eq 'HASH' )
    {
        foreach my $field ( @$where )
        {
            if( exists( $ref->{ $field } ) &&
                defined( $ref->{ $field } ) &&
                length( $ref->{ $field } ) )
            {
                my $decoded = eval
                {
                    $j->decode( $ref->{ $field } );
                };
                if( $@ )
                {
                    warn( "Warning only: error attempting to decode JSON array in field \"${field}\" for value '", $ref->{ $field }, "': $@" );
                    $ref->{ $field } = [];
                }
                else
                {
                    $ref->{ $field } = $decoded;
                }
            }
        }
    }
    elsif( Scalar::Util::reftype( $ref ) eq 'ARRAY' )
    {
        for( my $i = 0; $i < scalar( @$ref ); $i++ )
        {
            if( ref( $ref->[$i] ) ne 'HASH' )
            {
                warn( "SQL data at offset ${i} is not an HASH reference." );
                next;
            }
            $self->_decode_sql_arrays( $where, $ref->[$i] );
        }
    }
    return( $ref );
}

# Retrieve a cached prepared statement by ID.
# Keyed by db file path so statements survive interpreter-level reuse.
sub _get_cached_statement
{
    my $self = shift( @_ );
    my $id   = shift( @_ );
    die( "No statement ID provided." ) unless( defined( $id ) && length( $id ) );
    my $file = $DB_FILE;
    $STHS->{ $file } //= {};
    my $sth = $STHS->{ $file }->{ $id };
    if( defined( $sth ) &&
        Scalar::Util::blessed( $sth ) &&
        $sth->isa( 'DBI::st' ) )
    {
        return( $sth );
    }
    return;
}

# DateTime::Lite::TimeZone->_get_zone_info( $name );
# $tz->_get_zone_info( $name );
sub _get_zone_info
{
    my $self = shift( @_ );
    my $name = shift( @_ );
    local $@;
    # Verify the zone exists and cache its metadata
    my $sth;
    unless( $sth = $self->_get_cached_statement( 'get_zone_info' ) )
    {
        my $dbh = $self->_dbh || return( $self->pass_error );
        # We handle each step of building the query, so we can report on any error with better accuracy.
        my $query = q{SELECT * FROM zones WHERE name = ?};
        $sth = eval
        {
            $dbh->prepare( $query );
        } || return( $self->error( "Error preparing the query to get the timezone information: ", ( $@ || $dbh->errstr ), "\nSQL query was $query" ) );
        $self->_set_cached_statement( get_zone_info => $sth );
    }

    my $rv = eval{ $sth->execute( $name ) };
    if( $@ )
    {
        $sth->finish;
        return( $self->error( "Error executing the query to get the timezone information for $name: $@", "\nSQL query was ", $sth->{Statement} ) );
    }
    elsif( !defined( $rv ) )
    {
        $sth->finish;
        return( $self->error( "Error executing the query to get the timezone information for $name: ", $sth->errstr, "\nSQL query was ", $sth->{Statement} ) );
    }

    my $row = eval{ $sth->fetchrow_hashref };
    if( $@ )
    {
        $sth->finish;
        return( $self->error( "Error retrieving the timezone information for $name: $@", "\nSQL query was ", $sth->{Statement} ) );
    }
    # We check for definedness, which means an error in DBI
    elsif( !defined( $row ) && $sth->errstr )
    {
        $sth->finish;
        return( $self->error( "Error retrieving the timezone information for $name: ", $sth->errstr, "\nSQL query was ", $sth->{Statement} ) );
    }
    $sth->finish;
    $self->_decode_sql_arrays( [qw( countries )], $row ) if( defined( $row ) );
    return( $row );
}

sub _local_tz_android
{
    my $class = shift( @_ );

    # Method 1: $ENV{TZ}
    my $name = $class->_local_tz_env( 'TZ' );
    return( $name ) if( defined( $name ) );

    # Method 2: getprop persist.sys.timezone (Android system property)
    {
        local $@;
        my $n = eval
        {
            my $r = `getprop persist.sys.timezone 2>/dev/null`;
            chomp( $r );
            return( $r );
        };
        if( !$@ &&
            defined( $n ) &&
            length( $n ) &&
            $class->is_valid_name( $n ) )
        {
            return( $n );
        }
    }

    # Android always defaults to UTC if nothing else is found
    return( 'UTC' );
}

sub _local_tz_env
{
    my $class = shift( @_ );
    my @vars  = @_;
    foreach my $var ( @vars )
    {
        if( defined( $ENV{ $var } ) &&
            length( $ENV{ $var } ) &&
            $ENV{ $var } ne 'local' &&
            $ENV{ $var } =~ m{^[\w/+\-]+$} )
        {
            return( $ENV{ $var } );
        }
    }
    return;
}

sub _local_tz_env_only
{
    my $class = shift( @_ );
    # Platforms with no filesystem or registry to query: check $ENV{TZ} only
    return( $class->_local_tz_env( 'TZ' ) );
}

my $win_map;
sub _local_tz_mswin32
{
    my $class = shift( @_ );

    # Method 1: $ENV{TZ}
    my $name = $class->_local_tz_env( 'TZ' );
    return( $name ) if( defined( $name ) );

    # Method 2: Windows Registry via Win32::TieRegistry (non-core, optional)
    # The Windows->IANA mapping is built lazily via state so it consumes no
    # memory on non-Windows platforms.
    {
        local $@;
        eval{ require Win32::TieRegistry };
        if( !$@ )
        {
            my $win_name = $class->_win32_tz_from_registry;
            if( defined( $win_name ) )
            {
                $win_map = $class->_build_win_to_iana unless( defined( $win_map ) );
                my $iana   = $win_map->{ $win_name };
                if( defined( $iana ) &&
                    $class->is_valid_name( $iana ) )
                {
                    return( $iana );
                }
            }
        }
    }

    return;
}

sub _local_tz_unix
{
    my $class = shift( @_ );

    # Method 1: $ENV{TZ}
    my $name = $class->_local_tz_env( 'TZ' );
    return( $name ) if( defined( $name ) );

    # Method 2: /etc/localtime symlink or binary match against /usr/share/zoneinfo
    {
        require File::Spec;  # Core module
        my $lt = File::Spec->catfile( '/etc', 'localtime' );
        if( -r( $lt ) && -s( $lt ) )
        {
            my $real;
            if( -l( $lt ) )
            {
                # Will resolve the link
                $real = Cwd::abs_path( $lt );
            }
            $real ||= $class->_match_zoneinfo_file( $lt );
            if( defined( $real ) )
            {
                my( undef, $dirs, $file ) = File::Spec->splitpath( $real );
                my @parts = grep{ defined && length } File::Spec->splitdir( $dirs ), $file;
                foreach my $x ( reverse( 0 .. $#parts ) )
                {
                    my $tzname = $x < $#parts
                        ? join( '/', @parts[ $x .. $#parts ] )
                        : $parts[$x];
                    return( $tzname ) if( $class->is_valid_name( $tzname ) );
                }
            }
        }
    }

    # Method 3: /etc/timezone plain text file (Debian/Ubuntu)
    {
        my $f = '/etc/timezone';
        if( -f( $f ) && -r( $f ) )
        {
            if( open( my $fh, '<', $f ) )
            {
                my $n = <$fh>;
                chomp( $n );
                close( $fh );
                $n =~ s/^\s+|\s+$//g;
                return( $n ) if( $n && $class->is_valid_name( $n ) );
            }
        }
    }

    # Method 4: /etc/TIMEZONE with TZ= line (Solaris, HP-UX)
    {
        my $f = '/etc/TIMEZONE';
        if( -f( $f ) && -r( $f ) )
        {
            if( open( my $fh, '<', $f ) )
            {
                while( <$fh> )
                {
                    if( /^\s*TZ\s*=\s*(\S+)/ &&
                        $class->is_valid_name( $1 ) )
                    {
                        return( $1 );
                    }
                }
                close( $fh );
            }
        }
    }

    # Method 5: /etc/sysconfig/clock with ZONE= or TIMEZONE= line (RedHat/CentOS)
    {
        my $f = '/etc/sysconfig/clock';
        if( -f( $f ) && -r( $f ) )
        {
            if( open( my $fh, '<', $f ) )
            {
                while( <$fh> )
                {
                    if( /^(?:TIME)?ZONE="([^"]+)"/ &&
                        $class->is_valid_name( $1 ) )
                    {
                        return( $1 );
                    }
                }
                close( $fh );
            }
        }
    }

    # Method 6: /etc/default/init with TZ= line (older Unix)
    {
        my $f = '/etc/default/init';
        if( -f( $f ) && -r( $f ) )
        {
            if( open( my $fh, '<', $f ) )
            {
                while( <$fh> )
                {
                    if( /^TZ=(\S+)/ &&
                        $class->is_valid_name( $1 ) )
                    {
                        return( $1 );
                    }
                }
                close( $fh );
            }
        }
    }

    return;
}

sub _local_tz_vms
{
    my $class = shift( @_ );
    # VMS uses several environment variables for timezone
    return( $class->_local_tz_env(
        qw( TZ SYS$TIMEZONE_RULE SYS$TIMEZONE_NAME UCX$TZ TCPIP$TZ )
    ) );
}

# NOTE: OS aliases
{
    no warnings 'once';
    # Unix-like: use the full Unix detection chain
    # NOTE: _local_tz_aix -> _local_tz_unix
    *_local_tz_aix     = \&_local_tz_unix;
    # NOTE: _local_tz_cygwin -> _local_tz_unix
    *_local_tz_cygwin  = \&_local_tz_unix;   # Cygwin on Windows
    # NOTE: _local_tz_darwin -> _local_tz_unix
    *_local_tz_darwin  = \&_local_tz_unix;   # macOS ($^O eq 'darwin')
    # NOTE: _local_tz_freebsd -> _local_tz_unix
    *_local_tz_freebsd = \&_local_tz_unix;
    # NOTE: _local_tz_hpux -> _local_tz_unix
    *_local_tz_hpux    = \&_local_tz_unix;   # HPUX IANA names; HP-UX-proprietary names require $ENV{TZ}
    # NOTE: _local_tz_netbsd -> _local_tz_unix
    *_local_tz_netbsd  = \&_local_tz_unix;
    # NOTE: _local_tz_openbsd -> _local_tz_unix
    *_local_tz_openbsd = \&_local_tz_unix;
    # NOTE: _local_tz_os2 -> _local_tz_unix
    *_local_tz_os2     = \&_local_tz_unix;   # OS/2 has a /etc filesystem
    # NOTE: _local_tz_solaris -> _local_tz_unix
    *_local_tz_solaris = \&_local_tz_unix;
    # Win32 variants
    # NOTE: _local_tz_netware -> _local_tz_mswin32
    *_local_tz_netware = \&_local_tz_mswin32;
    # Env-only platforms: no filesystem or registry to query
    # NOTE: _local_tz_symbian -> _local_tz_env_only (Symbian OS is not Win32)
    *_local_tz_symbian = \&_local_tz_env_only;
    # NOTE: _local_tz_epoc -> _local_tz_env_only
    *_local_tz_epoc    = \&_local_tz_env_only;  # EPOC (Symbian predecessor)
    # NOTE: _local_tz_dos -> _local_tz_env_only
    *_local_tz_dos     = \&_local_tz_env_only;  # MS-DOS
    # NOTE: _local_tz_macos -> _local_tz_env_only
    *_local_tz_macos   = \&_local_tz_env_only;  # Mac OS 9 and earlier (not macOS/darwin)
}

# Look up a span by UTC time (the common case).
# $utc_rd_secs is in Rata Die seconds (as returned by $dt->utc_rd_as_seconds).
# The database stores Unix seconds, so UNIX_TO_RD is subtracted before querying.
# NULL utc_start means "before all recorded transitions" (effectively -Inf).
# NULL utc_end means "after all recorded transitions" (effectively +Inf).
sub _lookup_span
{
    my( $self, $utc_rd_secs ) = @_;
    unless( defined( $self ) && ref( $self ) )
    {
        # We die, because this is not a user bad call, but an internal design error that should not happen.
        die( "_lookup_span() must be called on a class instance." );
    }
    my $zone_id = $self->{_zone_id} ||
        return( $self->error( "No zone_id cached for '$self->{name}'." ) );

    # Per-object span cache (populated when use_cache_mem is active or
    # when _span_cache is explicitly used). Stores the last matched span's
    # boundaries so that repeated calls with timestamps in the same span
    # skip the SQLite query entirely. The slot is undef when caching is
    # disabled; an empty hashref {} means caching is enabled but no span
    # has been fetched yet.
    if( defined( $self->{_span_cache} ) && exists( $self->{_span_cache}->{offset} ) )
    {
        my $c    = $self->{_span_cache};
        my $unix = $utc_rd_secs - UNIX_TO_RD;
        my $s    = $c->{utc_start};
        my $e    = $c->{utc_end};
        # Range check: [utc_start, utc_end) — both bounds may be undef (open span)
        if( ( !defined( $s ) || $unix >= $s ) &&
            ( !defined( $e ) || $unix <  $e ) )
        {
            return( $c );
        }
        # Timestamp outside cached span — fall through to DB
    }

    # Footer result cache: keyed by day (unix_secs / 86400).
    # Checked before the SQL query to skip the DB entirely for zones
    # whose current dates are governed by a POSIX footer rule.
    if( defined( $self->{_footer_cache_key} ) &&
        defined( $self->{footer_tz_string} ) &&
        length( $self->{footer_tz_string} ) )
    {
        my $unix_pre  = $utc_rd_secs - UNIX_TO_RD;
        my $day_pre   = int( $unix_pre / 86400 );
        if( $self->{_footer_cache_key} == $day_pre )
        {
            return( $self->{_footer_cache_val} );
        }
    }

    local $@;
    my $sth;
    unless( $sth = $self->_get_cached_statement( 'span_by_utc' ) )
    {
        my $query = <<'SQL';
SELECT s.offset, s.is_dst, s.short_name, s.utc_start, s.utc_end
FROM spans s
WHERE s.zone_id = ?
  AND ( s.utc_start IS NULL OR s.utc_start <= ? )
  AND ( s.utc_end   IS NULL OR s.utc_end   >  ? )
LIMIT 1
SQL
        my $dbh = $self->_dbh || return( $self->pass_error );
        $sth = eval
        {
            $dbh->prepare( $query );
        } || return( $self->error( "Cannot prepare span_by_utc: ", ( $@ || $dbh->errstr ), "\nSQL query was $query" ) );
        $self->_set_cached_statement( span_by_utc => $sth );
    }

    my $unix_secs = $utc_rd_secs - UNIX_TO_RD;
    my $rv = eval{ $sth->execute( $zone_id, $unix_secs, $unix_secs ) };
    if( $@ )
    {
        $sth->finish;
        return( $self->error( "Error executing the query to get the timezone spans information for $self->{name} and zone ID $zone_id: $@", "\nSQL query was ", $sth->{Statement} ) );
    }
    elsif( !defined( $rv ) )
    {
        $sth->finish;
        return( $self->error( "Error executing the query to get the timezone spans information for $self->{name} and zone ID $zone_id: ", $sth->errstr, "\nSQL query was ", $sth->{Statement} ) );
    }

    my $row = eval{ $sth->fetchrow_hashref };
    if( $@ )
    {
        $sth->finish;
        return( $self->error( "Error retrieving the timezone spans information for $self->{name} and zone ID $zone_id: $@", "\nSQL query was ", $sth->{Statement} ) );
    }
    # We check for definedness, which means an error in DBI
    elsif( !defined( $row ) && $sth->errstr )
    {
        $sth->finish;
        return( $self->error( "Error retrieving the timezone spans information for $self->{name} and zone ID $zone_id: ", $sth->errstr, "\nSQL query was ", $sth->{Statement} ) );
    }
    $sth->finish;

    # If the matching span has an open end (utc_end IS NULL) and this zone has
    # a POSIX footer TZ string, the DB transitions may be incomplete for future
    # dates. The footer encodes the recurring DST rule for all dates beyond the
    # last stored transition, per RFC 9636 section 3.3.
    if( defined( $row ) &&
        defined( $self->{footer_tz_string} ) &&
        length( $self->{footer_tz_string} ) )
    {
        # Fetch the utc_start of this span to check whether the timestamp is actually
        # beyond the last recorded transition.
        my $footer_row = $self->_posix_tz_lookup( $unix_secs, $self->{footer_tz_string} );
        if( defined( $footer_row ) )
        {
            # Cache the footer result keyed by day (unix_secs rounded down
            # to midnight). DST transitions are rare (twice a year); on all
            # other days the same footer result applies for the whole day.
            if( defined( $self->{_span_cache} ) )
            {
                my $day_key = int( $unix_secs / 86400 );
                if( defined( $self->{_footer_cache_key} ) &&
                    $self->{_footer_cache_key} == $day_key )
                {
                    return( $self->{_footer_cache_val} );
                }
                $self->{_footer_cache_key} = $day_key;
                $self->{_footer_cache_val} = $footer_row;
            }
            return( $footer_row );
        }
    }

    # Store matched span in the per-object cache for future range checks.
    # We cache only when the object already has a _span_cache slot (i.e.
    # the cache was enabled by use_cache_mem or enable_mem_cache) to avoid
    # allocating memory for callers that never requested caching.
    if( defined( $self->{_span_cache} ) && defined( $row ) )
    {
        $self->{_span_cache} = $row;
    }

    return( $row );
}

# Look up a span by local (wall-clock) time.
# Used by offset_for_local_datetime.
# $local_rd_secs is in Rata Die seconds (as returned by $dt->local_rd_as_seconds).
sub _lookup_span_local
{
    my( $self, $local_rd_secs ) = @_;
    my $zone_id = $self->{_zone_id} ||
        return( $self->error( "No zone_id cached for '$self->{name}'." ) );

    # Per-object span cache for local lookups (same logic as _lookup_span).
    if( defined( $self->{_span_cache_local} ) &&
        exists( $self->{_span_cache_local}->{offset} ) )
    {
        my $c    = $self->{_span_cache_local};
        my $unix = $local_rd_secs - UNIX_TO_RD;
        my $s    = $c->{local_start};
        my $e    = $c->{local_end};
        if( ( !defined( $s ) || $unix >= $s ) &&
            ( !defined( $e ) || $unix <  $e ) )
        {
            return( $c );
        }
    }

    # Footer result cache for local lookups.
    if( defined( $self->{_footer_local_cache_key} ) &&
        defined( $self->{footer_tz_string} ) &&
        length( $self->{footer_tz_string} ) )
    {
        my $day_pre = int( ( $local_rd_secs - UNIX_TO_RD ) / 86400 );
        if( $self->{_footer_local_cache_key} == $day_pre )
        {
            return( $self->{_footer_local_cache_val} );
        }
    }

    local $@;
    my $sth;
    unless( $sth = $self->_get_cached_statement( 'span_by_local' ) )
    {
        my $query = <<'SQL';
SELECT s.offset, s.is_dst, s.short_name, s.local_start, s.local_end
FROM spans s
WHERE s.zone_id = ?
  AND ( s.local_start IS NULL OR s.local_start <= ? )
  AND ( s.local_end   IS NULL OR s.local_end   >  ? )
LIMIT 1
SQL
        my $dbh = $self->_dbh || return( $self->pass_error );
        local $@;
        $sth = eval
        {
            $dbh->prepare( $query );
        } || return( $self->error( "Cannot prepare span_by_local: ", ( $@ || $dbh->errstr ), "\nSQL query was $query" ) );
        $self->_set_cached_statement( span_by_local => $sth );
    }

    my $unix_local = $local_rd_secs - UNIX_TO_RD;
    my $rv = eval{ $sth->execute( $zone_id, $unix_local, $unix_local ) };
    if( $@ )
    {
        $sth->finish;
        return( $self->error( "Error executing the query to get all the spans for the zone ID $zone_id: $@", "\nSQL query was ", $sth->{Statement} ) );
    }
    elsif( !defined( $rv ) )
    {
        $sth->finish;
        return( $self->error( "Error executing the query to get all the spans for the zone ID $zone_id: ", $sth->errstr, "\nSQL query was ", $sth->{Statement} ) );
    }

    my $row = eval{ $sth->fetchrow_hashref };
    if( $@ )
    {
        $sth->finish;
        return( $self->error( "Error retrieving all the spans for the zone ID $zone_id: $@", "\nSQL query was ", $sth->{Statement} ) );
    }
    # We check for definedness, which means an error in DBI
    elsif( !defined( $row ) && $sth->errstr )
    {
        $sth->finish;
        return( $self->error( "Error retrieving all the spans for the zone ID $zone_id: ", $sth->errstr, "\nSQL query was ", $sth->{Statement} ) );
    }
    $sth->finish;

    # If the matching span has an open end (local_end IS NULL) and this zone has
    # a POSIX footer TZ string, the DB transitions may be incomplete for future
    # dates. Convert the local timestamp to approximate UTC using both the standard
    # and DST offsets from the footer, then pick the self-consistent result. Decision
    # tree (std_ok = r_std is std, dst_ok = r_dst is DST):
    #   std only       -> standard time
    #   dst only       -> DST
    #   both (overlap) -> prefer standard (fall-back convention)
    #   neither (gap)  -> r_std carries the post-gap DST info
    if( defined( $row ) &&
        defined( $self->{footer_tz_string} ) &&
        length( $self->{footer_tz_string} ) )
    {
        my $footer = $self->{footer_tz_string};

        # Quick-parse std and dst offsets from the footer string.
        # POSIX convention: positive offset = WEST; we negate to get UTC east.
        # We only need the two offsets to build the two UTC guesses for disambiguation;
        # full parsing is done inside _posix_tz_lookup().
        my( $std_offset, $dst_offset );
        {
            my $s = $footer;
            $s =~ s/\A(?:<[^>]+>|[A-Za-z]{3,})//;  # strip std name
            if( $s =~ /\A([+-]?\d{1,3}(?::\d{2}(?::\d{2})?)?)/ )
            {
                # Negate POSIX sign convention to get seconds east of UTC
                my $raw = $1;
                my $sign = ( $raw =~ s/^-// ) ? 1 : -1;
                $raw =~ s/^\+//;
                my( $h, $m, $sec ) = split( /:/, $raw );
                $std_offset = $sign * ( ( $h // 0 ) * 3600
                                      + ( $m // 0 ) * 60
                                      + ( $sec // 0 ) );
                $s = $';
                $s =~ s/\A(?:<[^>]+>|[A-Za-z]{3,})//;  # strip dst name
                if( $s =~ /\A([+-]?\d{1,3}(?::\d{2}(?::\d{2})?)?)/ )
                {
                    my $raw2 = $1;
                    my $sign2 = ( $raw2 =~ s/^-// ) ? 1 : -1;
                    $raw2 =~ s/^\+//;
                    my( $h2, $m2, $s2 ) = split( /:/, $raw2 );
                    $dst_offset = $sign2 * ( ( $h2 // 0 ) * 3600
                                           + ( $m2 // 0 ) * 60
                                           + ( $s2 // 0 ) );
                }
                else
                {
                    $dst_offset = $std_offset + 3600;
                }
            }
        }

        if( defined( $std_offset ) )
        {
            my $r_std = $self->_posix_tz_lookup( $unix_local - $std_offset, $footer );
            my $r_dst = $self->_posix_tz_lookup( $unix_local - $dst_offset, $footer );

            if( defined( $r_std ) && defined( $r_dst ) )
            {
                my $std_ok = !$r_std->{is_dst} && $r_std->{offset} == $std_offset;
                my $dst_ok =  $r_dst->{is_dst} && $r_dst->{offset} == $dst_offset;

                # Unambiguous DST: only DST assumption is self-consistent
                # Unambiguous DST: only DST assumption is self-consistent
                if( !$std_ok && $dst_ok && defined( $r_dst ) )
                {
                    if( defined( $self->{_span_cache_local} ) )
                    {
                        $self->{_footer_local_cache_key} =
                            int( ( $local_rd_secs - UNIX_TO_RD ) / 86400 );
                        $self->{_footer_local_cache_val} = $r_dst;
                    }
                    return( $r_dst );
                }
                # All other cases (unambiguous std, overlap, gap): return r_std
                # For gap: r_std contains the post-gap DST state, which is correct
                my $footer_result = $r_std || $row;
                if( defined( $self->{_span_cache_local} ) && defined( $footer_result ) )
                {
                    $self->{_footer_local_cache_key} =
                        int( ( $local_rd_secs - UNIX_TO_RD ) / 86400 );
                    $self->{_footer_local_cache_val} = $footer_result;
                }
                return( $footer_result );
            }
        }
    }

    # Store in local span cache.
    if( defined( $self->{_span_cache_local} ) && defined( $row ) )
    {
        $self->{_span_cache_local} = $row;
    }

    return( $row );
}

sub _match_zoneinfo_file
{
    my( $class, $file_to_match ) = @_;
    my $zoneinfo_dir = '/usr/share/zoneinfo';
    my $this_dir = Cwd::realpath( $zoneinfo_dir );
    if( !defined( $this_dir ) )
    {
        return( $class->error( "Failed to resolve the zoneinfo directory location '$zoneinfo_dir'." ) );
    }
    elsif( !-e( $this_dir ) )
    {
        return( $class->error( "The resolved directory for '$zoneinfo_dir' points to $this_dir, which does not exist." ) );
    }
    elsif( !-x( $this_dir ) || !-r( $this_dir ) )
    {
        return( $class->error( "The resolved directory '$this_dir' does not have the necessary read/execute permissions." ) );
    }
    $zoneinfo_dir = $this_dir;

    require File::Basename;
    require File::Compare;
    require File::Find;

    my $size = -s( $file_to_match );
    my $real_name;
    local $@;
    eval
    {
        local $SIG{__DIE__};
        File::Find::find(
        {
            wanted => sub
            {
                if( !defined( $real_name ) &&
                    -f( $_ ) &&
                    !-l( $_ ) &&
                    $size == -s( $_ ) &&
                    File::Basename::basename( $_ ) ne 'posixrules' &&
                    File::Compare::compare( $_, $file_to_match ) == 0 )
                {
                    $real_name = $_;
                    # Bail out of File::Find early using die with a sentinel
                    die({ found => 1 });
                }
            },
            no_chdir => 1,
        },
        $zoneinfo_dir );
    };
    if( $@ )
    {
        # Re-raise anything that is not our own sentinel
        unless( ref( $@ ) eq 'HASH' && $@->{found} )
        {
            return( $class->error( "Error while searching zoneinfo directory: $@" ) );
        }
    }
    return( $real_name );
}

sub _nearest_zone
{
    my( $class, $latitude, $longitude ) = @_;

    return( $class->error( "Parameter 'latitude' must be a number." ) )
        unless( defined( $latitude ) && Scalar::Util::looks_like_number( $latitude ) );
    return( $class->error( "Parameter 'longitude' must be a number." ) )
        unless( defined( $longitude ) && Scalar::Util::looks_like_number( $longitude ) );
    return( $class->error( "Latitude must be between -90 and 90." ) )
        unless( $latitude >= -90 && $latitude <= 90 );
    return( $class->error( "Longitude must be between -180 and 180." ) )
        unless( $longitude >= -180 && $longitude <= 180 );

    my $sth;
    unless( $sth = $class->_get_cached_statement( 'nearest_zone' ) )
    {
        my $dbh = $class->_dbh || return( $class->pass_error );
        $class->_dbh_add_user_defined_functions( $dbh ) ||
            return( $class->pass_error );
        # Use the haversine formula entirely within SQLite to find the nearest zone.
        # Only canonical zones with coordinates are considered.
        # haversine(lat1, lon1, lat2, lon2):
        #   a = sin((lat2-lat1)/2)^2 + cos(lat1)*cos(lat2)*sin((lon2-lon1)/2)^2
        #   distance = 2 * asin(sqrt(a))
        # in radians; no need for Earth radius since we are only ranking, not computing
        # actual distance.
        my $query = <<'SQL';
SELECT
    name,
    (
        2.0 * asin( sqrt(
            ( sin( ( (latitude  - ?) * 0.017453292519943 ) / 2.0 ) *
              sin( ( (latitude  - ?) * 0.017453292519943 ) / 2.0 ) )
            +
            cos( ? * 0.017453292519943 ) *
            cos( latitude * 0.017453292519943 ) *
            ( sin( ( (longitude - ?) * 0.017453292519943 ) / 2.0 ) *
              sin( ( (longitude - ?) * 0.017453292519943 ) / 2.0 ) )
        ) )
    ) AS distance
FROM zones
WHERE canonical = 1
  AND latitude  IS NOT NULL
  AND longitude IS NOT NULL
ORDER BY distance ASC
LIMIT 1
SQL
        local $@;
        $sth = eval
        {
            $dbh->prepare( $query );
        } || return( $class->error( "Cannot prepare nearest_zone: ", ( $@ || $dbh->errstr ), "\nQuery was: $query" ) );
        $class->_set_cached_statement( nearest_zone => $sth );
    }

    my $rv = eval{ $sth->execute( $latitude, $latitude, $latitude, $longitude, $longitude ) };
    if( $@ )
    {
        $sth->finish;
        return( $class->error( "Error executing the query to get the nearest zone for latitude $latitude and longitude $longitude: $@", "\nSQL query was ", $sth->{Statement} ) );
    }
    elsif( !defined( $rv ) )
    {
        $sth->finish;
        return( $class->error( "Error executing the query to get the nearest zone for latitude $latitude and longitude $longitude: ", $sth->errstr, "\nSQL query was ", $sth->{Statement} ) );
    }

    my $row = eval{ $sth->fetchrow_hashref };
    if( $@ )
    {
        $sth->finish;
        return( $class->error( "Error retrieving the nearest zone information for latitude $latitude and longitude $longitude: $@", "\nSQL query was ", $sth->{Statement} ) );
    }
    # We check for definedness, which means an error in DBI
    elsif( !defined( $row ) && $sth->errstr )
    {
        $sth->finish;
        return( $class->error( "Error retrieving the nearest zone information for latitude $latitude and longitude $longitude: ", $sth->errstr, "\nSQL query was ", $sth->{Statement} ) );
    }
    $sth->finish;
    unless( defined( $row ) && defined( $row->{name} ) )
    {
        return( $class->error( "No timezone found for coordinates ($latitude, $longitude)." ) );
    }
    return( $row->{name} );
}

# _posix_tz_lookup( $unix_secs, $footer_tz_string )
#
# Thin wrapper around the XS function DateTime::Lite::posix_tz_lookup(), which
# is implemented in dtl_posix.h using IANA tzcode (public domain).
# Returns { offset, is_dst, short_name } or undef on parse error.
#
# The three pure-Perl helpers that this replaces
# (_posix_offset_to_utc, _posix_rule_to_unix, _posix_tz_lookup) have been
# removed; the XS implementation covers all their functionality and also handles
# the Jn and n rule forms that the Perl code did not.
sub _posix_tz_lookup
{
    my( $self, $unix_secs, $tz_string ) = @_;
    return( DateTime::Lite::posix_tz_lookup( $self, $unix_secs, $tz_string ) );
}

# Resolve an alias (such as "US/Eastern") to its canonical zone name.
# Queries aliases JOIN zones so the canonical name is returned directly.
#
# DateTime::Lite::TimeZone->_resolve_alias( $name );
# $tz->_resolve_alias( $name );
sub _resolve_alias
{
    my $self = shift( @_ );
    my $name = shift( @_ ) ||
        return( $self->error( "No timezone alias was provided." ) );
    local $@;
    my $sth;
    unless( $sth = $self->_get_cached_statement( 'resolve_alias' ) )
    {
        my $query = <<'SQL';
SELECT z.name
FROM aliases a
JOIN zones z ON z.zone_id = a.zone_id
WHERE a.alias = ?
SQL
        my $dbh = $self->_dbh || return( $self->pass_error );
        local $@;
        $sth = eval
        {
            $dbh->prepare( $query );
        } || return( $self->error( "Cannot prepare resolve_alias: ", ( $@ || $dbh->errstr ), "\nSQL query was $query" ) );
        $self->_set_cached_statement( resolve_alias => $sth );
    }

    my $rv = eval{ $sth->execute( $name ) };
    if( $@ )
    {
        $sth->finish;
        return( $self->error( "Error executing the query to get the canonical zone name for alias '$name': $@", "\nSQL query was ", $sth->{Statement} ) );
    }
    elsif( !defined( $rv ) )
    {
        $sth->finish;
        return( $self->error( "Error executing the query to get the canonical zone name for alias '$name': ", $sth->errstr, "\nSQL query was ", $sth->{Statement} ) );
    }

    my $row = eval{ $sth->fetchrow_arrayref };
    if( $@ )
    {
        $sth->finish;
        return( $self->error( "Error retrieving the canonical zone name for alias '$name': $@", "\nSQL query was ", $sth->{Statement} ) );
    }
    # We check for definedness, which means an error in DBI
    elsif( !defined( $row ) && $sth->errstr )
    {
        $sth->finish;
        return( $self->error( "Error retrieving the canonical zone name for alias '$name': ", $sth->errstr, "\nSQL query was ", $sth->{Statement} ) );
    }
    $sth->finish;
    # Not found in aliases: the name is assumed to be a canonical zone name
    return( $row ? $row->[0] : $name );
}

sub _resolve_local_tz_name
{
    my $class = shift( @_ );
    # Dispatch to an OS-specific method if one exists, otherwise fall back
    # to the Unix implementation (covers Linux, macOS via alias, BSDs, etc.)
    # However, we do not support macOS since this means any version of MacOS 9 and earlier.
    # MacOSX is $^O code with 'darwin'
    my $meth = '_local_tz_' . lc( $^O );
    if( my $code = $class->can( $meth ) )
    {
        return( $code->( $class ) );
    }
    return( $class->_local_tz_unix );
}

# DateTime::Lite::TimeZone->_set_cached_statement( $id => $sth );
# $tz->_set_cached_statement( $id => $sth );
sub _set_cached_statement
{
    my $self = shift( @_ );
    my $id   = shift( @_ ) ||
        return( $self->error( "No statement cache ID was provided." ) );
    my $sth  = shift( @_ ) ||
        return( $self->error( "No statement object was provided." ) );
    unless( Scalar::Util::blessed( $sth ) && $sth->isa( 'DBI::st' ) )
    {
        return( $self->error( "Statement object provided (", overload::StrVal( $sth ), ") is not a DBI statement object." ) );
    }
        ;
    my $file = $DB_FILE;
    $STHS->{ $file } //= {};
    $STHS->{ $file }->{ $id } = $sth;
    return( $sth );
}

sub _set_get_prop
{
    my $self = shift( @_ );
    my $prop = shift( @_ ) || die( "No object property was provided." );
    unless( defined( $self ) && ref( $self ) )
    {
        die( "_set_get_prop() must be called on a class instance." );
    }
    $self->{ $prop } = shift( @_ ) if( @_ );
    return( $self->{ $prop } );
}

sub _win32_tz_from_registry
{
    my $class = shift( @_ );
    local $@;
    my $reg = eval
    {
        no warnings 'once';
        Win32::TieRegistry->import( 'KEY_READ', Delimiter => '/' );
        my $lm = $Win32::TieRegistry::Registry->Open(
            'LMachine/', { Access => Win32::TieRegistry::KEY_READ() }
        );
        $lm;
    };
    return if( $@ || !defined( $reg ) );

    if( ref( $reg ) ne 'HASH' )
    {
        return( $class->error( "I was expecting an hash reference to be returned from Win32::TieRegistry::Registry->Open, but instead I got '", overload::StrVal( $reg ), "'" ) );
    }

    my $tzi = $reg->{'SYSTEM/CurrentControlSet/Control/TimeZoneInformation/'};
    return unless( defined( $tzi ) );

    # Windows Vista and newer
    if( defined( $tzi->{'/TimeZoneKeyName'} ) &&
        $tzi->{'/TimeZoneKeyName'} ne '' )
    {
        my $n = $tzi->{'/TimeZoneKeyName'};
        # Strip trailing null garbage (Windows 2008 Server)
        $n =~ s/\0.*$//s;
        return( $n );
    }

    # Windows NT/2000/XP/2003: match StandardName against zone sub-keys
    foreach my $key (
        'SOFTWARE/Microsoft/Windows NT/CurrentVersion/Time Zones/',
        'SOFTWARE/Microsoft/Windows/CurrentVersion/Time Zones/',
    )
    {
        my $zones = $reg->{ $key };
        next unless( defined( $zones ) );
        my $std = $tzi->{'/StandardName'};
        next unless( defined( $std ) );
        for my $zone ( $zones->SubKeyNames )
        {
            if( defined( $zones->{ $zone . '/Std' } ) &&
                $zones->{ $zone . '/Std' } eq $std )
            {
                return( $zone );
            }
        }
    }

    return;
}

# NOTE: END
# Cleanup of the DBI handles upon end of process
END
{
    CORE::local( $., $@, $!, $^E, $? );
    # Finish all cached statement handles first
    if( ref( $STHS ) eq 'HASH' )
    {
        for my $file ( keys( %$STHS ) )
        {
            for my $id ( keys( %{ $STHS->{ $file } } ) )
            {
                my $sth = $STHS->{ $file }->{ $id };
                eval{ $sth->finish } if( ref( $sth ) );
            }
        }
    }
    # Then disconnect all database handles
    if( ref( $DBH ) eq 'HASH' )
    {
        for my $file ( keys( %$DBH ) )
        {
            my $dbh = $DBH->{ $file };
            eval{ $dbh->disconnect } if( ref( $dbh ) );
        }
    }
    $STHS = {};
    $DBH  = {};
}

sub DESTROY
{
    # See https://perldoc.perl.org/perlobj#Destructors
    CORE::local( $., $@, $!, $^E, $? );
    CORE::return if( defined( ${^GLOBAL_PHASE} ) && ${^GLOBAL_PHASE} eq 'DESTRUCT' );
}

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

DateTime::Lite::TimeZone - Lightweight timezone support for DateTime::Lite

=head1 SYNOPSIS

    use DateTime::Lite::TimeZone;

    my $tz = DateTime::Lite::TimeZone->new( name => 'Asia/Tokyo' ) ||
        die( DateTime::Lite::TimeZone->error );

    my $dt = DateTime::Lite->now( time_zone => $tz );

    # Alias
    my $tz2 = DateTime::Lite::TimeZone->new( name => 'US/Eastern' );

    # Fixed offset
    my $tz3 = DateTime::Lite::TimeZone->new( name => '+09:00' );

    # Special zones
    my $utc  = DateTime::Lite::TimeZone->new( name => 'UTC' );
    my $flt  = DateTime::Lite::TimeZone->new( name => 'floating' );

    # Single-argument shorthand
    my $tz4 = DateTime::Lite::TimeZone->new( 'Europe/Paris' );

    # Using latitude and longitude
    my $tz = DateTime::Lite::TimeZone->new(
        latitude  => 35.658558,
        longitude => 139.745504,
    ) || die( "Could not find a timezone: ", DateTime::Lite::TimeZone->error );

    # You can also use 'lat' and 'lon'
    my $tz = DateTime::Lite::TimeZone->new(
        lat => 35.658558,
        lon => 139.745504,
    ) || die( "Could not find a timezone: ", DateTime::Lite::TimeZone->error );
    say $tz->name;  # Asia/Tokyo

    # Memory cache (three-layer: object + span + POSIX footer)
    # Enable once at application start-up for best performance:
    DateTime::Lite::TimeZone->enable_mem_cache;

    # Or per-call:
    my $tz5 = DateTime::Lite::TimeZone->new(
        name          => 'America/New_York',
        use_cache_mem => 1,
    );

    DateTime::Lite::TimeZone->disable_mem_cache;  # disables and clears
    DateTime::Lite::TimeZone->clear_mem_cache;    # clears without disabling

    # Offset and DST queries
    use DateTime::Lite;
    my $dt = DateTime::Lite->now( time_zone => $tz );

    my $offset_secs = $tz->offset_for_datetime( $dt );        # e.g. -18000
    my $local_off   = $tz->offset_for_local_datetime( $dt );  # from wall-clock time
    my $is_dst      = $tz->is_dst_for_datetime( $dt );        # 1 or 0
    my $abbr        = $tz->short_name_for_datetime( $dt );    # e.g. "EDT"

    printf "%s", $tz->offset_as_string( $offset_secs );       # "-0500"
    printf "%s", $tz->offset_as_string( $offset_secs, ':' );  # "-05:00"

    # Parse an offset string to seconds:
    my $secs = DateTime::Lite::TimeZone->offset_as_seconds( '-05:00' );  # -18000

    # Zone metadata
    $tz->name;             # canonical name, e.g. "America/New_York"
    $tz->is_olson;         # 1 if an IANA named zone
    $tz->is_utc;           # 1 if UTC
    $tz->is_floating;      # 1 if floating
    $tz->has_dst;          # 1 if zone ever observes DST
    $tz->country_codes;    # arrayref of ISO 3166-1 alpha-2 codes, e.g. ['US']
    $tz->countries;        # arrayref of hashrefs with full country data
    $tz->coordinates;      # e.g. "+404251-0740023"
    $tz->comment;          # free-text annotation from IANA data
    $tz->latitude;
    $tz->longitude;
    $tz->tz_version;       # IANA release string, e.g. "2026a"
    $tz->tzif_version;     # TZif binary format version (1, 2, 3, or 4)
    $tz->footer_tz_string; # POSIX TZ string for recurring DST rules
    $tz->transition_count;
    $tz->type_count;
    $tz->leap_count;

    # Zone discovery
    my $all      = DateTime::Lite::TimeZone->all_names;  # array reference
    my @all      = DateTime::Lite::TimeZone->all_names;
    my $cats     = DateTime::Lite::TimeZone->categories; # array reference
    my @cats     = DateTime::Lite::TimeZone->categories;
    my $in_cat   = DateTime::Lite::TimeZone->names_in_category('America');  # array reference
    my @in_cat   = DateTime::Lite::TimeZone->names_in_category('America');
    my $in_cc    = DateTime::Lite::TimeZone->names_in_country('JP');        # array reference
    my @in_cc    = DateTime::Lite::TimeZone->names_in_country('JP');
    my $is_valid = DateTime::Lite::TimeZone->is_valid_name('Asia/Tokyo');  # 1

    my $aliases  = DateTime::Lite::TimeZone->aliases;   # hashref alias => canonical
    my %aliases  = DateTime::Lite::TimeZone->aliases;   # hash    alias => canonical
    my $links    = $tz->links;                          # arrayref of alias names

    # Resolve a timezone abbreviation against the IANA types table
    my $results = DateTime::Lite::TimeZone->resolve_abbreviation( 'JST' );
    # $results = [
    #     {
    #         ambiguous       => 0,
    #         extended        => 0,
    #         is_dst          => 0,
    #         last_trans_time => -577962000,
    #         utc_offset      => 32400,
    #         zone_name       => "Asia/Tokyo",
    #     },
    #     {
    #         ambiguous       => 0,
    #         extended        => 0,
    #         is_dst          => 0,
    #         last_trans_time => -880016400,
    #         utc_offset      => 32400,
    #         zone_name       => "Asia/Manila",
    #     },
    #     # etc...
    # ]

    # Narrow by co-parsed numeric offset
    my $pst = DateTime::Lite::TimeZone->resolve_abbreviation( 'PST',
        utc_offset => -28800
    );

    # Period filter: zones that still used JST after 1950
    my $modern = DateTime::Lite::TimeZone->resolve_abbreviation( 'JST',
        period => '>1950-01-01'
    );

    # Period filter with two ISO date bounds
    my $wartime = DateTime::Lite::TimeZone->resolve_abbreviation( 'JST',
        period => ['>1941-01-01', '<1946-01-01']
    );

    # Period filter with a raw epoch integer (post-1970 value, safe on all platforms)
    my $epoch_2010 = 1262304000;  # 2010-01-01 00:00:00 UTC
    my $recent = DateTime::Lite::TimeZone->resolve_abbreviation( 'EST',
        period => ">$epoch_2010"
    );

    # Period filter: only zones currently on this abbreviation
    my $current = DateTime::Lite::TimeZone->resolve_abbreviation( 'JST',
        period => 'current'
    );

    # Extended mode: fall back to extended_aliases if not in IANA types
    # (covers real-world abbreviations such as AFT, AMST, CEST, HAEC, ...)
    my $aft = DateTime::Lite::TimeZone->resolve_abbreviation( 'AFT',
        extended => 1
    );
    # $aft = [
    #     {
    #         ambiguous  => 0,
    #         extended   => 1,
    #         is_dst     => undef,
    #         is_primary => 1,
    #         utc_offset => undef,
    #         zone_name  => "Asia/Kabul",
    #     },
    # ]

    # Database access (low-level)
    my $path = DateTime::Lite::TimeZone->datafile;  # path to tz.sqlite3
    # Raw SQLite queries via public view methods (return DBI statement handles):
    #   $tz->zones, $tz->spans, $tz->transition, $tz->types,
    #   $tz->aliases, $tz->countries, $tz->leap_second, $tz->metadata

    # Error handling
    my $bad = DateTime::Lite::TimeZone->new( name => 'Mars/Olympus' );
    if( !defined( $bad ) )
    {
        warn DateTime::Lite::TimeZone->error;  # "Unknown time zone 'Mars/Olympus'"
    }
    $tz->fatal(1);  # make errors die instead of warn+return undef

    # Object context is detected even in errors, but allows the chain to unfold until the end to avoid the typical: "Can't call method "%s" on an undefined value"
    # See https://perldoc.perl.org/perldiag#Can't-call-method-%22%25s%22-on-an-undefined-value
    my $bad = DateTime::Lite::TimeZone->new( name => 'Mars/Olympus' )->name;

=head1 VERSION

    v0.5.2

=head1 DESCRIPTION

C<DateTime::Lite::TimeZone> is a drop-in replacement for L<DateTime::TimeZone> designed to eliminate its heavy dependency and memory footprint.

L<DateTime::TimeZone> loads 85 modules at startup, including the entire L<Specio>, L<Params::ValidationCompiler>, and L<Exception::Class> stacks, simply to validate constructor arguments. C<DateTime::Lite::TimeZone> replaces all of that with a single L<DBD::SQLite> query against a compact bundled database (C<tz.sqlite3>).

You may also be interested in the Unicode CLDR (Common Locale Data Repository) with the module L<Locale::Unicode::Data>, which provides richer timezone information, such as C<metazones>, C<regions>, and historical timezone data.

For example:

    my $cldr = Locale::Unicode::Data->new;
    my $ref  = $cldr->timezone( timezone => 'Asia/Tokyo' );

This would return an hash reference with the following information:

    {
       timezone_id => 281,
       timezone    => 'Asia/Tokyo',
       territory   => 'JP',
       region      => 'Asia',
       tzid        => 'japa',
       metazone    => 'Japan',
       tz_bcpid    => 'jptyo',
       is_golden   => 1,
       is_primary  => 0,
       is_preferred => 0,
       is_canonical => 0,
    }

You can also returns all the timezones for a country code:

    my $array_ref = $cldr->timezones( territory => 'US' );

Would return 55 results, such as:

    {
        alias => [qw( America/Atka US/Aleutian )],
        is_canonical => 1,
        is_golden => 1,
        is_preferred => 0,
        is_primary => 0,
        metazone => "Hawaii_Aleutian",
        region => "America",
        territory => "US",
        timezone => "America/Adak",
        timezone_id => 55,
        tz_bcpid => "usadk",
        tzid => "haal",
    }

You can also get the localised city name for a time zone:

    my $ref = $cldr->timezone_city(
        locale   => 'de',
        timezone => 'Asia/Tokyo',
    );

which would return:

    {
       tz_city_id  => 7486,
       locale      => 'de',
       timezone    => 'Asia/Tokyo',
       city        => 'Tokio',
       alt         => undef,
    }

And if you want to access historical information:

    my $ref = $cldr->timezone_info(
        timezone    => 'Europe/Simferopol',
        start       => '1994-04-30T21:00:00',
    );

which would return:

    {
       tzinfo_id   => 594,
       timezone    => 'Europe/Simferopol',
       metazone    => 'Moscow',
       start       => '1994-04-30T21:00:00',
       until       => '1997-03-30T01:00:00',
    }

or, maybe:

    my $ref = $cldr->timezone_info(
        timezone    => 'Europe/Simferopol',
        start       => ['>1992-01-01', '<1995-01-01'],
    );

This is handy if you do not know the exact date, and want to provide a range instead.

=head2 Database schema

The bundled C<tz.sqlite3> uses the following main tables:

=over 4

=item C<aliases>

Alias-to-zone_id FK mappings (such as C<US/Eastern> to C<America/New_York>)

=item C<metadata>

Key/value pairs including the tzdata version

=item C<spans>

Pre-computed time spans derived from transitions and types, indexed for fast range lookup

=item C<types>

Local time type records from the TZif files

=item C<zones>

Canonical IANA zone names with country codes and coordinates

=back

=head2 Fallback mode

If L<DBD::SQLite> is not available, or the bundled C<tz.sqlite3> cannot be found, C<DateTime::Lite::TimeZone> falls back transparently to L<DateTime::TimeZone> and emits a one-time warning, if warning is permitted.

If L<DateTime::TimeZone> is not available, then it dies.

=head1 CONSTRUCTOR

=head2 new

    my $zone = DateTime::Lite::TimeZone->new( 'Asia/Tokyo' );
    my $zone = DateTime::Lite::TimeZone->new(
        name  => 'Asia/Tokyo',
        fatal => 1, # Makes all error fatal
    );

    # Using latitude and longitude
    my $tz = DateTime::Lite::TimeZone->new(
        latitude  => 35.658558,
        longitude => 139.745504,
    ) || die( "Could not find a timezone: ", DateTime::Lite::TimeZone->error );

    # You can also use 'lat' and 'lon'
    my $tz = DateTime::Lite::TimeZone->new(
        lat => 35.658558,
        lon => 139.745504,
    ) || die( "Could not find a timezone: ", DateTime::Lite::TimeZone->error );
    say $tz->name;  # Asia/Tokyo

A new C<DateTime::Lite::TimeZone> object can be instantiated by either passing the timezone as a single argument, or as an hash, such as C<< name => 'Asia/Tokyo' >>

Recognised forms:

=over 4

=item Named IANA timezones such as C<America/New_York>, C<Europe/Paris>.

=item Aliases such as C<US/Eastern>, C<Japan>.

=item Fixed-offset strings such as C<+09:00>, C<-0500>.

=item The special names C<UTC>, C<floating>, and C<local>.

The C<local> name instructs C<DateTime::Lite::TimeZone> to determine the system's local timezone automatically, without requiring any external modules. The detection strategy is OS-specific, relying on L<$^O|perlvar/"$^O">:

=over 8

=item B<Linux, macOS (darwin), FreeBSD, OpenBSD, NetBSD, Solaris, AIX, HP-UX, OS/2, Cygwin>

Tries, in order:

=over 12

=item * C<$ENV{TZ}>

=item * the C</etc/localtime> symlink target or a binary match against C</usr/share/zoneinfo>

=item * C</etc/timezone> (Debian/Ubuntu)

=item * C</etc/TIMEZONE> with a C<TZ=> line (Solaris, HP-UX)

=item * C</etc/sysconfig/clock> with a C<ZONE=> or C<TIMEZONE=> line (RedHat/CentOS)

=item * C</etc/default/init> with a C<TZ=> line (older Unix)

=back

=item B<Windows (MSWin32, NetWare)>

Tries C<$ENV{TZ}> first, then reads the timezone name from the Windows Registry (C<SYSTEM/CurrentControlSet/Control/TimeZoneInformation>) and maps it to an IANA name using the CLDR C<windowsZones.xml> table.
Requires C<Win32::TieRegistry> (available on CPAN; not a hard dependency).

=item B<Android>

Tries C<$ENV{TZ}>, then C<getprop persist.sys.timezone>, then falls back to C<UTC>.

=item B<VMS>

Checks the environment variables C<TZ>, C<SYS$TIMEZONE_RULE>, C<SYS$TIMEZONE_NAME>, C<UCX$TZ>, and C<TCPIP$TZ>.

=item B<Symbian, EPOC, MS-DOS, Mac OS 9 and earlier>

Checks C<$ENV{TZ}> only.

=back

If the local timezone cannot be determined, an error is set and C<undef> is returned in scalar context, or an empty list in list context. In chaining (object context), it returns a dummy object (C<DateTime::Lite::Null>) to avoid the typical C<Can't call method '%s' on an undefined value>.

=item Coordinates via C<latitude> and C<longitude> arguments.

As an alternative to a C<name>, you can pass decimal-degree coordinates to have C<DateTime::Lite::TimeZone> resolve the nearest IANA timezone automatically:

    my $tz = DateTime::Lite::TimeZone->new(
        latitude  => 35.658558,
        longitude => 139.745504,
    );
    say $tz->name;  # Asia/Tokyo

The resolution uses the reference coordinates stored in the IANA C<zone1970.tab> file (one representative point per canonical zone) and finds the nearest zone by the L<haversine great-circle distance|https://en.wikipedia.org/wiki/Haversine_formula>. This is an B<approximation>: it is accurate for most locations, but may give incorrect results near timezone boundaries, in disputed territories, or for enclaves such as Kaliningrad. If you need boundary-precise resolution, consider L<Geo::Location::TimeZoneFinder> instead.

C<latitude> must be in the range C<-90> to C<90>; C<longitude> in C<-180> to C<180>. An L<error object|DateTime::Lite::Exception> is set and C<undef> is returned in scalar context, or an empty list in list context, if the values are out of range or if no zone with coordinates is found in the database.

The haversine formula is computed in SQLite when the database was compiled with C<-DSQLITE_ENABLE_MATH_FUNCTIONS> (SQLite version E<gt>= 3.35.0, L<released on March 2021|https://sqlite.org/changes.html>).

On older systems or builds where the math functions are absent, the required functions (C<sqrt>, C<sin>, C<cos>, C<asin>) are registered automatically as Perl UDFs (User Defined Functions) via L<DBD::SQLite/sqlite_create_function> on first use, so coordinate resolution works transparently on all supported SQLite versions.

Detection is version-aware. Thus:

=over 8

=item * on SQLite with version E<gt>= 3.35.0, the special système table C<pragma_function_list> is queried for C<sqrt> before any UDF is registered, to ensure a native function is used in priority.

=item * on SQLite with version E<lt> 3.35.0, where the math functions did not yet exist, UDFs are registered directly without querying C<pragma_function_list>.

=item * on SQLite version E<lt> 3.16.0, C<pragma_function_list> is not available as a table-valued function, so UDFs are registered directly.

=back

UDFs are available on all SQLite version E<gt>= 3.0.0.


On older systems that ships SQLite 3.31.1, the required functions (C<sqrt>, C<sin>, C<cos>, C<asin>) are registered automatically as Perl UDFs (User Defined Functions) via L<DBD::SQLite/sqlite_create_function> on first use, so coordinate resolution works transparently on all supported SQLite versions.

=back

A boolean option C<use_cache_mem> set to a true value activates the process-level memory cache for this call. When set, subsequent calls with the same zone name (or its alias) return the cached object without a database query. See L</MEMORY CACHE> for details and for the class-level L</enable_mem_cache> alternative.

    # Each of these hits the cache after the first construction:
    my $tz = DateTime::Lite::TimeZone->new(
        name          => 'America/New_York',
        use_cache_mem => 1,
    );

Returns the new object on success. On error, sets the L<exception object|DateTime::Lite::Exception> with C<error()> and returns C<undef> in scalar context, or an empty list in list context. In method-chaining (object) context, returns a C<DateTime::Lite::NullObject> to avoid the error C<Can't call method '%s' on an undefined value>. At the end of the chain, C<undef> or an empty list will still be returned though.

=head1 MEMORY CACHE

By default, each call to L</new> constructs a fresh object with a SQLite query. For applications that construct C<DateTime::Lite::TimeZone> objects repeatedly with the same zone name, a three-layer cache is available.

B<Layer 1 - Object cache>: When enabled, the second and subsequent calls for the same zone name return the original object directly from a hash, bypassing the database entirely.

B<Layer 2 - Span cache>: Each cached TimeZone object stores the last matched UTC and local time span. Calls to C<offset_for_datetime> and C<offset_for_local_datetime> skip the SQLite query when the timestamp falls within the cached span's C<[utc_start, utc_end)> or C<[local_start, local_end)> range.

B<Layer 3 - POSIX footer cache>: For zones where current dates are governed by a recurring DST rule (POSIX TZ footer string), the result of the footer calculation is cached by calendar day. DST transitions happen twice a year; on all other days the cached result is returned without re-evaluating the rule.

Together these three layers reduce the per-call cost of C<< DateTime::Lite->new( time_zone => 'America/New_York' ) >> from ~430 µs to ~25 µs, putting it on par with C<DateTime>.

Cache entries are keyed by the name passed to L</new>, plus the canonical name (after alias resolution). Both C<US/Eastern> and C<America/New_York> therefore map to the same cached object.

Cached objects are immutable in normal use. All public accessors are read-only, so sharing an object across callers is safe.

=head2 enable_mem_cache

Class method. Activates the memory cache for all subsequent L</new> calls.

    DateTime::Lite::TimeZone->enable_mem_cache;

    # Every new() call now hits the cache after the first construction:
    my $tz = DateTime::Lite::TimeZone->new( name => 'America/New_York' );
    my $tz2 = DateTime::Lite::TimeZone->new( name => 'America/New_York' );
    # $tz and $tz2 are the same object

Equivalent to passing C<< use_cache_mem => 1 >> on every L</new> call, but more convenient when you want the cache active for the lifetime of the process. Returns the class name to allow chaining.

=head2 disable_mem_cache

Class method. Disables the memory cache and clears all cached entries. Subsequent L</new> calls will construct fresh objects.

    DateTime::Lite::TimeZone->disable_mem_cache;

Returns the class name.

=head2 clear_mem_cache

Class method. Empties the cache without disabling it. The next L</new> call for any zone name will re-query the database and re-populate the cache.

Useful if the C<tz.sqlite3> database has been replaced at runtime (an unusual operation):

    DateTime::Lite::TimeZone->clear_mem_cache;

Returns the class name.

=head1 METHODS

=head2 aliases

    # Checking for errors too
    my $aliases  = DateTime::Lite::TimeZone->aliases ||
        die( DateTime::Lite::TimeZone->error );
    my( %aliases ) = DateTime::Lite::TimeZone->aliases ||
        die( DateTime::Lite::TimeZone->error );
    my $aliases    = $zone->aliases ||
        die( $zone->error );
    my( %aliases ) = $zone->aliases ||
        die( $zone->error );

This can be called as an instance method, or as a class function.

This returns a hash of all the zones aliases (the old, deprecated names) to their corresponding canonical names.

For example:

    Japan -> Asia/Tokyo

In scalar context, it returns an hash reference, and in list context, it returns an hash.

If an error occurred, this sets an L<exception object|DateTime::Lite::Exception>, and returns C<undef> in scalar context, and an empty list in list context. The exception object can then be retrieved with L</error>

=head2 all_names

    # Checking for errors too
    my $names    = DateTime::Lite::TimeZone->all_names ||
        die( DateTime::Lite::TimeZone->error );
    my( @names ) = DateTime::Lite::TimeZone->all_names ||
        die( DateTime::Lite::TimeZone->error );
    my $names    = $zone->all_names ||
        die( $zone->error );
    my( @names ) = $zone->all_names ||
        die( $zone->error );

This can be called as an instance method, or as a class function.

This returns a list of all the time zone names sorted alphabetically.
This list does not include zone alias (a.k.a. "links").

In scalar context, it returns an array reference, and in list context, it returns an array.

If an error occurred, this sets an L<exception object|DateTime::Lite::Exception>, and returns C<undef> in scalar context, and an empty list in list context. The exception object can then be retrieved with L</error>

=head2 categories

    # Checking for errors too
    my $categories    = DateTime::Lite::TimeZone->categories ||
        die( DateTime::Lite::TimeZone->error );
    my( @categories ) = DateTime::Lite::TimeZone->categories ||
        die( DateTime::Lite::TimeZone->error );
    my $categories    = $zone->categories ||
        die( $zone->error );
    my( @categories ) = $zone->categories ||
        die( $zone->error );

This can be called as an instance method, or as a class function.

This returns a list of all time zone categories. A C<category> is the part, if any, that precedes the forward slash of a zone name. For example, in C<Asia/Tokyo>, the category would be C<Asia>. However, with the special zone C<Factory>, there would not be any category.

In scalar context, it returns an array reference, and in list context, it returns an array.

If an error occurred, this sets an L<exception object|DateTime::Lite::Exception>, and returns C<undef> in scalar context, and an empty list in list context. The exception object can then be retrieved with L</error>

=head2 category

    my $zone = DateTime::Lite::TimeZone->new( name => "Asia/Tokyo" );
    say $zone->category; # Asia
    my $zone = DateTime::Lite::TimeZone->new( name => "UTC" );
    say $zone->category; # undef

Returns the part of the time zone name before the first slash, such as C<Asia> in C<Asia/Tokyo>

=head2 comment

Returns the optional zone comment from C<zone1970.tab>, such as C<"Mountain Time - south Idaho and east Oregon">.

Returns C<undef> in scalar context, or an empty list in list context if no comment is recorded.

=head2 coordinates

Returns the compact coordinate string from C<zone1970.tab>, such as C<+3518+13942> for Tokyo.
Returns C<undef> in scalar context, or an empty list in list context when there are no coordinates, such as C<UTC>, C<floating>, and fixed-offset zones.

=head2 country_codes

Returns an arrayref of ISO 3166-1 alpha-2 country codes associated with this timezone, such as C<["JP"]> or C<["US","CA"]>.

Returns C<undef> in scalar context, or an empty list in list context when the timezone has no countries associated, such as C<UTC>, C<floating>, and fixed-offset zones.

=head2 countries

    # Checking for errors too
    my $countries    = DateTime::Lite::TimeZone->countries ||
        die( DateTime::Lite::TimeZone->error );
    my( @countries ) = DateTime::Lite::TimeZone->countries ||
        die( DateTime::Lite::TimeZone->error );
    my $countries    = $zone->countries ||
        die( $zone->error );
    my( @countries ) = $zone->countries ||
        die( $zone->error );

This can be called as an instance method, or as a class function.

This returns a list of all the ISO 3166 2-letters country codes sorted alphabetically, and in lower-case. Those codes can be used to call L</names_in_country>.

In scalar context, it returns an array reference, and in list context, it returns an array.

If an error occurred, this sets an L<exception object|DateTime::Lite::Exception>, and returns C<undef> in scalar context, and an empty list in list context. The exception object can then be retrieved with L</error>

If you want to convert a country to its locale name, you can use the L<Unicode CLDR database|Locale::Unicode::Data> designed specifically for this.

For example, using the C<locale> C<en>:

    use Locale::Unicode::Data;
    my $cldr = Locale::Unicode::Data->new;
    my $ref  = $cldr->territory_l10n( locale => 'en', territory => 'JP', alt => undef );

# Returns an hash reference like this:

    {
       terr_l10n_id    => 13385,
       locale          => 'en',
       territory       => 'JP',
       locale_name     => 'Japan',
       alt             => undef,
    }

And, if you want to look up the ISO3166 code based on the locale country name, you could do something like this. Here we search for the country code matching C<アメリカ>, which is C<America> in Japanese:

    use strict;
    use warnings;
    use utf8;
    use open ':std' => ':utf8';
    use Data::Pretty qw( dump );
    use Locale::Unicode::Data;
    my $cldr = Locale::Unicode::Data->new;
    my $all = $cldr->territories_l10n( locale => 'ja' );
    foreach my $ref ( @$all )
    {
        if( $ref->{locale_name} =~ /アメリカ/ &&
            $ref->{territory} =~ /^[A-Z]{2}$/ ) # Because a territory, in Unicode CLDR, can also be a 3-digits code
        {
            say dump( $ref );
        }
    }

which would produce something like this:

    {
        alt => undef,
        locale => "ja",
        locale_name => "アメリカ合衆国",
        terr_l10n_id => 26334,
        territory => "US",
    }

=head2 datafile

Returns the absolute path to the bundled C<tz.sqlite3> database file.

=head2 designation_charcount

Returns the total size of abbreviation string table (in bytes).

This is equivalent to TZif header field C<charcnt>, including trailing NUL bytes.

See L<rfc9636, section 3.1|https://www.rfc-editor.org/rfc/rfc9636.html#name-tzif-header>

=head2 error

    my $ex = $zone->error;

Returns the last L<exception object|DateTime::Lite::Exception>, if any.

=head2 fatal

Sets or gets the C<fatal> property for this object.

When enabled, any error will trigger a fatal exception and call L<perlfunc/die>

=head2 footer_tz_string

Returns the footer portion of the timezone.

See L<rfc9636, section 3.3|https://www.rfc-editor.org/rfc/rfc9636.html#name-tzif-footer>

=head2 has_dst

This is an alias for L</has_dst_changes>

=head2 has_dst_changes

Returns true if the timezone observes daylight saving time transitions.

=head2 is_canonical

    my $zone = DateTime::Lite::TimeZone->new( 'Japan' );
    say $zone->is_canonical; # false
    my $zone = DateTime::Lite::TimeZone->new( 'Asia/Tokyo' );
    say $zone->is_canonical; # true

Returns true if the timezone name provided is a canonical one, false otherwise.

=head2 is_dst_for_datetime( $dt )

Returns true if C<$dt> falls within a DST period for this timezone.

=head2 is_floating

Returns true for the special C<floating> timezone.

=head2 is_olson

Returns true for IANA/Olson-sourced timezones.

=head2 is_utc

Returns true for the C<UTC> timezone and for fixed-offset C<+0000>.

=head2 is_valid_name

    say DateTime::Lite::TimeZone->is_valid_name( 'Singapore' );  # true
    say $zone->is_valid_name( 'Singapore' );                     # true
    say DateTime::Lite::TimeZone->is_valid_name( 'Paris' );      # false
    say $zone->is_valid_name( 'Paris' );                         # false
    say DateTime::Lite::TimeZone->is_valid_name( 'Asia/Seoul' ); # true
    say $zone->is_valid_name( 'Asia/Seoul' );                    # true

This takes a canonical timezone or a timezone alias, and returns true if the value provided is valid, or false otherwise.

This sets an L<exception object|DateTime::Lite::Exception>, an returns an error only if no value was provided, so you may want to check if the value returned is defined.

Contrary to C<DateTime::TimeZone>, passin a L<DateTime::TimeZone::Alias> does not make that zone valid. This class, adhere strictly to the IANA time zones.

=head2 isstd_count

Returns the number of C<standard time> (a.k.a "standard/wall") indicators.

This "must either be zero or equal to "L<typecnt|/type_count>".

See L<rfc9636, section 3.1|https://www.rfc-editor.org/rfc/rfc9636.html#name-tzif-header>

=head2 isut_count

Returns the number of C<UT/local time> indicators.

This "must either be zero or equal to "L<typecnt|/type_count>".

See L<rfc9636, section 3.1|https://www.rfc-editor.org/rfc/rfc9636.html#name-tzif-header>

=head2 latitude

Returns the latitude for this zone, as a real number, if any.

=head2 links

This is an alias for L</aliases>

=head2 longitude

Returns the longitude for this zone, as a real number, if any.

=head2 name

    my $zone = DateTime::Lite::TimeZone->new( name => 'Japan' );
    say $zone->name; # Asia/Tokyo

Returns the canonical timezone name, such as C<Asia/Tokyo>.

This means that if you provide an alias upon instantiation, it will be resolved, and accessible with this method.

=head2 names_in_category

    # Checking for errors too
    my $names    = DateTime::Lite::TimeZone->names_in_category( 'Asia' ) ||
        die( DateTime::Lite::TimeZone->error );
    my( @names ) = DateTime::Lite::TimeZone->names_in_category( 'Asia' ) ||
        die( DateTime::Lite::TimeZone->error );
    my $names    = $zone->names_in_category( 'America' ) ||
        die( $zone->error );
    my( @names ) = $zone->names_in_category( 'America' ) ||
        die( $zone->error );

This takes a C<category>, which under this class means the left-hand side of the zone name, separated by a forward slash. So, with the example of C<Asia/Seoul>, the C<category> would be C<Asia>.

With this C<category> provided, this returns a list of the name on the left-hand side of the first forward slash.

For example:

For C<Asia/Taipei>, the category would be C<Asia>, and the list would return among the 74 results, the name C<Taipei>.

For the category C<America>, there would be 121 results, and of which C<Indiana/Vincennes> whose full timezone is C<America/Indiana/Vincennes>, would also be returned.

In scalar context, it returns an array reference, and in list context, it returns an array.

If an error occurred, this sets an L<exception object|DateTime::Lite::Exception>, and returns C<undef> in scalar context, and an empty list in list context. The exception object can then be retrieved with L</error>

=head2 names_in_country

    # Checking for errors too
    my $names    = DateTime::Lite::TimeZone->names_in_country( 'US' ) ||
        die( DateTime::Lite::TimeZone->error );
    my( @names ) = DateTime::Lite::TimeZone->names_in_country( 'US' ) ||
        die( DateTime::Lite::TimeZone->error );
    my $names    = $zone->names_in_country( 'US' ) ||
        die( $zone->error );
    my( @names ) = $zone->names_in_country( 'US' ) ||
        die( $zone->error );

This takes a 2-letter ISO3166 country code, and returns a list of all the time zones associated with it.

This is case insensitive, so a country code provided, such as C<US> or C<us> would be treated equally.

In scalar context, it returns an array reference, and in list context, it returns an array.

If an error occurred, this sets an L<exception object|DateTime::Lite::Exception>, and returns C<undef> in scalar context, and an empty list in list context. The exception object can then be retrieved with L</error>

The order of the time zones returned is the same ones as set by IANA database.

=head2 offset_as_seconds

This takes an offset as a string, such as C<+09:00>, and this returns the number of seconds represented by that offset either as a signed integer.

If no value was provided, or if that value is not comprised in the range C<-99:59:59> to C<+99:59:59>, or, if the offset string provided does not match any of the following 2 patterns, then this sets an L<error object|DateTime::Lite::Exception>, and returns C<undef> in scalar context or an empty list in list context.

The supported offset patterns are (sign defaults to C<+> if absent):

=over 4

=item Colon form: C<[+-]H:MM>, C<[+-]HH:MM>, C<[+-]HH:MM:SS>

The regular expression is: C<\A([+-])?(\d{1,2}):(\d{2})(?::(\d{2}))?\z>

Examples: C<+09:00>, C<-02:00>, C<9:0:0>

=item Compact form: C<[+-]HHMM>, C<[+-]HHMMSS>

The regular expression is: C</\A([+-])?(\d{2})(\d{2})(\d{2})?\z/>

Examples: C<+0900>, C<-0200>, C<0900>, C<+090000>, C<090000>

=item The special string C<"0"> (returns C<0>).

=back

=head2 offset_as_string

    say DateTime::Lite::TimeZone->offset_as_string(32400);       # +0900
    say DateTime::Lite::TimeZone->offset_as_string(32400, ':' ); # +09:00
    say $zone->offset_as_string(32400);                          # +0900
    say $zone->offset_as_string(32400, ':');                     # +09:00

Class or instance method. This converts a numeric UTC offset in seconds to a formatted string such as C<+0900> (default) or C<+09:00> (with C<':'> as separator).

Drop-in compatible with L<DateTime::TimeZone/offset_as_string>.

=head2 offset_for_datetime

    my $offset = $zone->offset_for_datetime( $dt );

This takes a L<DateTime::Lite> object, and returns the UTC offset in seconds applicable to that object.

Upon error, then this sets an L<error object|DateTime::Lite::Exception>, and returns C<undef> in scalar context or an empty list in list context.

=head2 offset_for_local_datetime

    my $offset = $zone->offset_for_local_datetime( $dt );

This takes a L<DateTime::Lite> object, and returns the UTC offset in seconds given a local (wall-clock) time.

Used internally during timezone conversion.

Upon error, then this sets an L<error object|DateTime::Lite::Exception>, and returns C<undef> in scalar context or an empty list in list context.

=for Pod::Coverage pass_error

=head2 resolve_abbreviation

    # Unambiguous: JST maps to a single UTC offset
    # Results sorted by most-recently-used first (last_trans_time DESC).
    my $results = DateTime::Lite::TimeZone->resolve_abbreviation( 'JST' );
    # $results = [
    #     {
    #         ambiguous       => 0,
    #         extended        => 0,
    #         is_dst          => 0,
    #         last_trans_time => -577962000,
    #         utc_offset      => 32400,
    #         zone_name       => "Asia/Tokyo",
    #     },
    #     {
    #         ambiguous       => 0,
    #         extended        => 0,
    #         is_dst          => 0,
    #         last_trans_time => -880016400,
    #         utc_offset      => 32400,
    #         zone_name       => "Asia/Manila",
    #     },
    #     # etc...
    # ]

    # Truly ambiguous: CST has different offsets in Asia and America
    my $cst = DateTime::Lite::TimeZone->resolve_abbreviation( 'CST' );
    # $cst->[0]{ambiguous} == 1

    # Narrow by offset when already known (such as from a co-parsed %z token)
    my $filtered = DateTime::Lite::TimeZone->resolve_abbreviation(
        'PST', utc_offset => -28800
    );

    # Period filter: only zones that used JST after 1950
    my $modern = DateTime::Lite::TimeZone->resolve_abbreviation(
        'JST', period => '>1950-01-01'
    );

    # Period filter with two bounds: zones that used JST during WWII
    my $wartime = DateTime::Lite::TimeZone->resolve_abbreviation(
        'JST', period => ['>1941-01-01', '<1946-01-01']
    );

    # Period filter: only zones currently on this abbreviation
    my $current = DateTime::Lite::TimeZone->resolve_abbreviation(
        'JST', period => 'current'
    );

    # Extended mode: fall back to extended_aliases if not in IANA types
    my $aft = DateTime::Lite::TimeZone->resolve_abbreviation(
        'AFT', extended => 1
    );
    # $aft = [
    #   { zone_name => 'Asia/Kabul', utc_offset => undef, is_dst => undef,
    #     ambiguous => 0, is_primary => 1, extended => 1 },
    # ]

    # extended => 1 is a no-op for abbreviations already in IANA types (such as IST, CST):
    # the IANA result is returned and the extended_aliases table is not consulted.

Class or instance method. Resolves a timezone abbreviation such as C<JST> or C<EST> against the IANA data in the bundled C<tz.sqlite3> database, returning all canonical zones that have ever used that abbreviation.

Results are sorted by the most recent transition using the abbreviation (C<last_trans_time> descending), so the currently-active or most-recently-active zone appears first.

The single required argument is the abbreviation string. The following optional keyword arguments are accepted:

=over 4

=item C<extended>

Boolean. When true and the abbreviation is not found in the IANA types table, the method falls back to querying the C<extended_aliases> table. This covers real-world abbreviations (such as C<AFT>, C<AMST>, or C<HAEC>) that appear in date strings but are not stored as TZif type abbreviations in the IANA database.

When an extended result is returned, C<utc_offset> and C<is_dst> are C<undef> since the extended alias table maps abbreviations to zone names only. If you need the offset, instantiate a C<DateTime::Lite::TimeZone> object from the returned C<zone_name>.

=item C<period>

Restricts results to zones whose most recent matching transition (C<MAX(trans_time)>) falls within a given time window. Accepts either a single string or an array reference of strings for multiple conditions.

Each value may be prefixed with a comparison operator:

=over 4

=item C<< > >> (default when no operator is given)

Greater than. The most common operator: zones whose last use of the abbreviation is more recent than the given date.

=item C<< >= >>

Greater than or equal.

=item C<< < >>

Less than. Returns zones whose last use is older than the given date.

=item C<< <= >>

Less than or equal.

=back

The operators C<=> and C<!=> are accepted but map to SQL C<IS> and C<IS NOT>. They have no practical use for timestamp comparisons and are not recommended.

B<Value types>: ISO date strings such as C<1950-01-01> are converted to Unix epoch via SQLite C<strftime('%s', ...)>. Plain integers are treated as epoch seconds and passed as C<CAST(? AS INTEGER)> to ensure correct numeric comparison regardless of how the Perl scalar is internally represented. For portability, use post-1970 epoch values when passing raw integers; pre-1970 negatives may behave unexpectedly on some platforms.

The special value C<current> returns only zones whose most recent use of the abbreviation is in the past and whose next scheduled transition has not yet occurred, which means zones that are on this abbreviation right now.

    period => '>1950-01-01'                   # last used after 1950 (ISO date)
    period => ['>1941-01-01', '<1946-01-01']  # last used within WWII window
    period => '>1262304000'                   # last used after 2010-01-01 (epoch int)
    period => 'current'                       # currently active only

Period filtering does not apply to extended alias results.

=item C<utc_offset>

Integer seconds east of UTC. Narrows the results to candidates with a matching offset, which is useful when the numeric offset has already been parsed from the same string (such as from a co-parsed C<%z> token). Only applies to the IANA types lookup; not used for the extended aliases fallback.

=back

Returns an array reference of hashrefs on success, each with the following keys:

=over 4

=item C<zone_name>

The canonical IANA zone name, such as C<Asia/Tokyo>.

=item C<utc_offset>

The UTC offset in seconds east of UTC for this abbreviation in this zone. C<undef> for extended alias results.

=item C<is_dst>

C<1> if this abbreviation represents a DST period, C<0> otherwise. C<undef> for extended alias results.

=item C<ambiguous>

For IANA results: C<1> if the abbreviation maps to multiple distinct UTC offsets (a genuine ambiguity such as C<IST> or C<CST>); C<0> if all candidates share the same UTC offset.

For extended alias results: C<1> if there are multiple candidates and none or more than one is marked C<is_primary>; C<0> if exactly one candidate has C<is_primary = 1>.

=item C<extended>

C<1> if this result came from the C<extended_aliases> table; C<0> if it came from the IANA types table.

=item C<is_primary>

Only present in extended alias results (C<extended =E<gt> 1>). C<1> marks the preferred zone for this abbreviation when multiple candidates exist. Absent from IANA results.

=item C<last_trans_time>

Unix epoch of the most recent transition in this zone using the abbreviation. Absent from extended alias results. Useful for understanding how recently a zone was last on this abbreviation.

=back

If an error occurred, this sets an L<exception object|DateTime::Lite::Exception>, and returns C<undef> in scalar context, and an empty list in list context. The exception object can then be retrieved with L</error>.

Note that many abbreviations such as C<EST> or C<PST> match multiple zone names that all share the same UTC offset. These are not genuinely ambiguous for the purpose of parsing a datetime string; the C<ambiguous> flag will be C<0> in those cases. Genuinely ambiguous abbreviations such as C<IST> (Irish Summer Time, Indian Standard Time, or Israel Standard Time) will have C<ambiguous =E<gt> 1>.

=head2 short_name_for_datetime

    say $zone->short_name_for_datetime( $dt );

This takes a L<DateTime::Lite> object, and returns the abbreviated timezone name applicable, such as C<JST> or C<EDT>.

=head2 transition_count

Returns the number of transitions record for this timezone.

Equivalent to TZif header field C<timecnt>

See L<rfc9636, section 3.1|https://www.rfc-editor.org/rfc/rfc9636.html#name-tzif-header>

=head2 type_count

Returns the number of types for this timezone.

See L<rfc9636, section 3.1|https://www.rfc-editor.org/rfc/rfc9636.html#name-tzif-header>

=head2 tz_version

Returns the IANA tzdata version string from the database C<metadata> table, such as C<2026a>.

=head2 tzif_version

Returns the timezone version string from the timezone data.

The possible values are C<1>, C<2>, C<3> or C<4>

See L<rfc9636, section 3.1|https://www.rfc-editor.org/rfc/rfc9636.html#name-tzif-header>

=head1 ERROR HANDLING

Upon error, this class methods sets an L<exception object|DateTime::Lite::Exception>, and return C<undef> in scalar context, and an empty list in list context. The exception is accessible via:

    my $err = DateTime::Lite::TimeZone->error;   # class method
    my $err = $tz->error;                        # instance method

The exception stringifies to a human-readable message including the source file and line number.

If the instance option L<fatal|/fatal> has been enabled, then any error triggered will be fatal.

=head1 EPOCH CONVENTION

The C<tz.sqlite3> database stores span boundaries as Unix seconds (seconds since 1970-01-01T00:00:00 UTC), matching the raw values from the TZif binary files. L<DateTime::Lite> uses Rata Die seconds (seconds since 0001-01-01T00:00:00).

The conversion constant is:

    UNIX_TO_RD = 62_135_683_200

All lookup methods subtract C<UNIX_TO_RD> from C<< $dt->utc_rd_as_seconds >> before querying the database. C<NULL> span boundaries represent ±infinity (before the first recorded transition, and after the last).

=head1 BUILDING THE DATABASE

The bundled C<tz.sqlite3> is generated by running:

    perl scripts/build_tz_database.pl [--verbose, --debug 3]

This fetches the latest C<tzcode> and C<tzdata> release from IANA, verifies the GPG signature, compiles it with C<zic(1)>, and populates the database. Run this script once per tzdata release, then commit the updated C<lib/DateTime/Lite/tz.sqlite3>.

=head1 SQL SCHEMA

The SQLite SQL schema is available in the file C<scripts/cldr-schema.sql>

The data are populated into the SQLite database using the script located in C<scripts/build_tz_database.pl> and the data accessible from L<https://ftp.iana.org/tz/releases>

The SQL schema used to create the SQLite database is available in the C<scripts> directory of this distribution in the file C<tz_schema.sql>

The tables used are as follows, in alphabetical order:

=head2 aliases

=over 4

=item * C<alias>

A string field, case insensitive.

=item * C<zone_id>

An integer field.

=back

=head2 countries

=over 4

=item * C<code>

A string field, case insensitive.

=item * C<name>

A string field, case insensitive.

=back

=head2 extended_aliases

=over 4

=item * C<abbr_id>

An integer field.

=item * C<abbreviation>

A string field, case insensitive.

=item * C<zone_id>

An integer field.

=item * C<is_primary>

A boolean field.

Defaults to false

=item * C<comment>

A string field.

=back

=head2 leap_second

=over 4

=item * C<leap_sec_id>

An integer field.

=item * C<zone_id>

An integer field.

=item * C<leap_index>

An integer field.

=item * C<occurrence_time>

An integer field.

=item * C<correction>

An integer field.

=item * C<is_expiration>

A boolean field.

Defaults to false

=back

=head2 metadata

=over 4

=item * C<key>

A string field.

=item * C<value>

A string field.

=back

=head2 spans

=over 4

=item * C<span_id>

An integer field.

=item * C<zone_id>

An integer field.

=item * C<type_id>

An integer field.

=item * C<span_index>

An integer field.

=item * C<utc_start>

An integer field.

=item * C<utc_end>

An integer field.

=item * C<local_start>

An integer field.

=item * C<local_end>

An integer field.

=item * C<offset>

An integer field.

=item * C<is_dst>

A boolean field.

Defaults to false

=item * C<short_name>

A string field, case insensitive.

=back

=head2 transition

=over 4

=item * C<trans_id>

An integer field.

=item * C<zone_id>

An integer field.

=item * C<trans_index>

An integer field.

=item * C<trans_time>

An integer field.

=item * C<type_id>

An integer field.

=back

=head2 types

=over 4

=item * C<type_id>

An integer field.

=item * C<zone_id>

An integer field.

=item * C<type_index>

An integer field.

=item * C<utc_offset>

An integer field.

=item * C<is_dst>

A boolean field.

=item * C<abbreviation>

A string field, case insensitive.

=item * C<designation_index>

An integer field.

=item * C<is_standard_time>

A boolean field.

=item * C<is_ut_time>

A boolean field.

=item * C<is_placeholder>

A boolean field.

Defaults to false

=back

=head2 zones

=over 4

=item * C<zone_id>

An integer field.

=item * C<name>

A string field, case insensitive.

=item * C<canonical>

A boolean field.

Defaults to true

=item * C<has_dst>

A boolean field.

Defaults to false

=item * C<countries>

A string array field.

=item * C<coordinates>

A string field.

=item * C<latitude>

A real field.

=item * C<longitude>

A real field.

=item * C<comment>

A string field.

=item * C<tzif_version>

An integer field.

=item * C<footer_tz_string>

A string field.

=item * C<transition_count>

An integer field.

=item * C<type_count>

An integer field.

=item * C<leap_count>

An integer field.

=item * C<isstd_count>

An integer field.

=item * C<isut_count>

An integer field.

=item * C<designation_charcount>

An integer field.

=item * C<category>

A string field, case insensitive.

=item * C<subregion>

A string field, case insensitive.

=item * C<location>

A string field, case insensitive.

=back

=head1 SEE ALSO

L<DateTime::Lite>, L<DateTime::TimeZone>, L<Locale::Unicode::Data>

RFC 9636 (The Time Zone Information Format (TZif)) L<https://www.rfc-editor.org/rfc/rfc9636>

L<Locale::Unicode::Data> for historical data of time zones, metazones, and BCP47 time zones data.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
