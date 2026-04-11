##----------------------------------------------------------------------------
## Lightweight DateTime Alternative - ~/lib/DateTime/Lite/TimeZone.pm
## Version v0.1.0
## Copyright(c) 2026 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2026/04/03
## Modified 2026/04/10
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
        $VERSION $ERROR $DEBUG
        $DB_FILE $DBH $STHS
        $FALLBACK_TO_DT_TZ
        $HAS_CONSTANTS
        $MISSING_AUTO_UTF8_DECODING
        $USE_MEM_CACHE
    );
    # Package-level memory cache: canonical_name -> blessed object.
    # Populated when use_cache_mem => 1 is passed to new(), or when
    # enable_mem_cache() has been called at the class level.
    # Keys are canonical zone names after alias resolution.
    my %_CACHE;
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
    our $VERSION = 'v0.1.0';
    our $DEBUG   = 0;
    our $DBH     = {};
    # Cached prepared statements, keyed by db file path then by statement ID:
    # $STHS->{ $db_file }->{ $statement_id } = $sth
    our $STHS    = {};

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

    my $name        = $args{name};
    my $use_cache   = delete( $args{use_cache_mem} ) // $USE_MEM_CACHE // 0;
    return( $class->error( "Parameter 'name' is required." ) )
        unless( defined( $name ) && length( $name ) );

    # Package-level memory cache: return immediately if the canonical name
    # is already cached. The cache is keyed BEFORE alias resolution so
    # that both the alias ("US/Eastern") and the canonical name
    # ("America/New_York") are stored and looked up by their original form.
    if( $use_cache && exists( $_CACHE{ $name } ) )
    {
        return( $_CACHE{ $name } );
    }

    # Delegate entirely to DateTime::TimeZone if fallback mode is active
    if( $FALLBACK_TO_DT_TZ )
    {
        local $@;
        my $tz = eval{ DateTime::TimeZone->new( name => $name ) };
        return( $class->error( "Invalid time zone name '$name': $@" ) ) if( $@ );
        return( $tz );
    }

    $args{fatal} //= 0;

    # Special cases: floating and UTC never need a DB lookup
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
        $_CACHE{ $name }                 = $self;
        $_CACHE{ $self->{name} }         = $self if( $self->{name} ne $name );
    }

    return( $self );
}

sub aliases
{
    # Can be called as class method, instance method, or plain function.
    my $class_or_self = shift( @_ );
    local $@;
    my $sth;
    unless( $sth = $self->_get_cached_statement( 'all_aliases' ) )
    {
        my $dbh = $self->_dbh || return( $self->pass_error );
        my $query = q{SELECT alias_name, zone_name FROM v_zone_aliases ORDER BY alias_name};
        $sth = eval
        {
            $dbh->prepare( $query );
        } || return( $self->error( "Error preparing the query to get all timezone aliases: ", ( $@ || $dbh->errstr ) ) );
        $self->_set_cached_statement( all_aliases => $sth );
    }

    my $rv = eval{ $sth->execute };
    if( $@ )
    {
        $sth->finish;
        return( $self->error( "Error executing the query to get all timezone aliases: $@" ) );
    }
    elsif( !defined( $rv ) )
    {
        $sth->finish;
        return( $self->error( "Error executing the query to get all timezone aliases: ", $sth->errstr ) );
    }

    my $all = eval{ $sth->fetchall_arrayref([0,1]) };
    if( $@ )
    {
        $sth->finish;
        return( $self->error( "Error retrieving all timezone aliases: $@" ) );
    }
    # We check for definedness, which means an error in DBI
    elsif( !defined( $row ) && $sth->errstr )
    {
        $sth->finish;
        return( $self->error( "Error retrieving all timezone aliases: ", $sth->errstr ) );
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
    unless( $sth = $self->_get_cached_statement( 'all_names' ) )
    {
        my $dbh = $self->_dbh || return( $self->pass_error );
        # We handle each step of building the query, so we can report on any error with better accuracy.
        my $query = q{SELECT name FROM zones ORDER BY name};
        $sth = eval
        {
            $dbh->prepare( $query );
        } || return( $self->error( "Error preparing the query to get all timezone names: ", ( $@ || $dbh->errstr ) ) );
        $self->_set_cached_statement( all_names => $sth );
    }

    my $rv = eval{ $sth->execute };
    if( $@ )
    {
        $sth->finish;
        return( $self->error( "Error executing the query to get all timezone names: $@" ) );
    }
    elsif( !defined( $rv ) )
    {
        $sth->finish;
        return( $self->error( "Error executing the query to get all timezone names: ", $sth->errstr ) );
    }

    my $all = eval{ $sth->fetchall_arrayref([0]) };
    if( $@ )
    {
        $sth->finish;
        return( $self->error( "Error retrieving all timezone names: $@" ) );
    }
    # We check for definedness, which means an error in DBI
    elsif( !defined( $row ) && $sth->errstr )
    {
        $sth->finish;
        return( $self->error( "Error retrieving all timezone names: ", $sth->errstr ) );
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
    unless( $sth = $self->_get_cached_statement( 'categories' ) )
    {
        my $dbh = $self->_dbh || return( $self->pass_error );
        my $query = q{SELECT DISTINCT(category) FROM zones ORDER BY category};
        $sth = eval
        {
            $dbh->prepare( $query );
        } || return( $self->error( "Error preparing the query to get all timezone categories: ", ( $@ || $dbh->errstr ) ) );
        $self->_set_cached_statement( categories => $sth );
    }

    my $rv = eval{ $sth->execute };
    if( $@ )
    {
        $sth->finish;
        return( $self->error( "Error executing the query to get all timezone categories: $@" ) );
    }
    elsif( !defined( $rv ) )
    {
        $sth->finish;
        return( $self->error( "Error executing the query to get all timezone categories: ", $sth->errstr ) );
    }

    my $all = eval{ $sth->fetchall_arrayref([0]) };
    if( $@ )
    {
        $sth->finish;
        return( $self->error( "Error retrieving all timezone categories: $@" ) );
    }
    # We check for definedness, which means an error in DBI
    elsif( !defined( $row ) && $sth->errstr )
    {
        $sth->finish;
        return( $self->error( "Error retrieving all timezone categories: ", $sth->errstr ) );
    }
    $sth->finish;
    my $categories = [map{ $_->[0] } @$all];
    return( wantarray() ? @$categories : $categories );
}

# Returns the first part of the timezone, such as 'Asia' in 'Asia/Tokyo'
sub category
{
    my $self = shift( @_ );
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
    %_CACHE = ();
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
    unless( $sth = $self->_get_cached_statement( 'countries' ) )
    {
        my $dbh = $self->_dbh || return( $self->pass_error );
        my $query = q{SELECT LOWER(code) FROM countries ORDER BY code};
        $sth = eval
        {
            $dbh->prepare( $query );
        } || return( $self->error( "Error preparing the query to get all country codes: ", ( $@ || $dbh->errstr ) ) );
        $self->_set_cached_statement( countries => $sth );
    }

    my $rv = eval{ $sth->execute };
    if( $@ )
    {
        $sth->finish;
        return( $self->error( "Error executing the query to get all country codes: $@" ) );
    }
    elsif( !defined( $rv ) )
    {
        $sth->finish;
        return( $self->error( "Error executing the query to get all country codes: ", $sth->errstr ) );
    }

    my $all = eval{ $sth->fetchall_arrayref([0]) };
    if( $@ )
    {
        $sth->finish;
        return( $self->error( "Error retrieving all country codes: $@" ) );
    }
    # We check for definedness, which means an error in DBI
    elsif( !defined( $row ) && $sth->errstr )
    {
        $sth->finish;
        return( $self->error( "Error retrieving all country codes: ", $sth->errstr ) );
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
    %_CACHE = ();
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

sub fatal { return( shift->_set_get_prop( 'fatal', @_ ) ); }

sub footer_tz_string { return( $_[0]->{footer_tz_string} ); }

{
    no warnings 'once';
    *has_dst = \&has_dst_changes;
}

# Returns true if this timezone observes DST transitions
sub has_dst_changes
{
    my $self = shift( @_ );
    return( $self->{has_dst} ? 1 : 0 );
}

sub is_canonical { return( $_[0]->{_is_canonical} ? 1 : 0 ); }

sub is_dst_for_datetime
{
    my $self = shift( @_ );
    my $dt   = shift( @_ );
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
        return( $self->error( "No timezone name was provided." ) );
    my $canon = $self->_resolve_alias( $name );
    return( $self->pass_error ) if( !defined( $canon ) && $self->error );
    my $orig;
    if( defined( $canon ) && $name ne $canon )
    {
        $orig = $name;
        $name = $canon;
    }
    my $ref = $self->_get_zone_info( $name ) || return(0);
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
        return( $self->error( "No timezone category was provided." ) );
    local $@;
    my $sth;
    unless( $sth = $self->_get_cached_statement( 'names_in_category' ) )
    {
        my $dbh = $self->_dbh || return( $self->pass_error );
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
        } || return( $self->error( "Error preparing the query to get all local names for a category: ", ( $@ || $dbh->errstr ) ) );
        $self->_set_cached_statement( names_in_category => $sth );
    }

    my $rv = eval{ $sth->execute };
    if( $@ )
    {
        $sth->finish;
        return( $self->error( "Error executing the query to get all local names for the category $cat: $@" ) );
    }
    elsif( !defined( $rv ) )
    {
        $sth->finish;
        return( $self->error( "Error executing the query to get all local names for the category $cat: ", $sth->errstr ) );
    }

    my $all = eval{ $sth->fetchall_arrayref([0]) };
    if( $@ )
    {
        $sth->finish;
        return( $self->error( "Error retrieving all local names for the category $cat: $@" ) );
    }
    # We check for definedness, which means an error in DBI
    elsif( !defined( $row ) && $sth->errstr )
    {
        $sth->finish;
        return( $self->error( "Error retrieving all local names for the category $cat: ", $sth->errstr ) );
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
        return( $self->error( "No country code was provided." ) );
    # Because the country codes are stored in upper case, and there is no need to have SQL change the case when we can do it.
    $code = uc( $code );
    local $@;
    my $sth;
    unless( $sth = $self->_get_cached_statement( 'names_in_category' ) )
    {
        my $dbh = $self->_dbh || return( $self->pass_error );
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
        } || return( $self->error( "Error preparing the query to get all zone names for a given country code: ", ( $@ || $dbh->errstr ) ) );
        $self->_set_cached_statement( names_in_category => $sth );
    }

    my $rv = eval{ $sth->execute };
    if( $@ )
    {
        $sth->finish;
        return( $self->error( "Error executing the query to get all zone names for the country code $cat: $@" ) );
    }
    elsif( !defined( $rv ) )
    {
        $sth->finish;
        return( $self->error( "Error executing the query to get all zone names for the country code $cat: ", $sth->errstr ) );
    }

    my $all = eval{ $sth->fetchall_arrayref([0]) };
    if( $@ )
    {
        $sth->finish;
        return( $self->error( "Error retrieving all zone names for the country code $cat: $@" ) );
    }
    # We check for definedness, which means an error in DBI
    elsif( !defined( $row ) && $sth->errstr )
    {
        $sth->finish;
        return( $self->error( "Error retrieving all zone names for the country code $cat: ", $sth->errstr ) );
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
        return( $self->error( "Unsupported offset format '$offset'" ) );
    }

    $sign //= '+';
    unless( $hours >= 0 && $hours <= 99 )
    {
        return( $self->error( "Unsupported hours ($hours). It must be greater or equal to 0 and lower or equal to 99." ) );
    }
    unless( $minutes >= 0 && $minutes <= 59 )
    {
        return( $self->error( "Unsupported minutes ($minutes). It must be greater or equal to 0 and lower or equal to 59." ) );
    }
    if( defined( $seconds ) && ( $seconds < 0 || $seconds > 59 ) )
    {
        return( $self->error( "Unsupported seconds ($seconds). It must be greater or equal to 0 and lower or equal to 59." ) );
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

sub short_name_for_datetime
{
    my $self = shift( @_ );
    my $dt   = shift( @_ );
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
        local $@;
        $sth = eval
        {
            $dbh->prepare( "SELECT value FROM metadata WHERE key = 'tz_version'" )
        } || return( $self->error( "Cannot prepare tz_version query: ", ( $@ || $dbh->errstr ) ) );
        $self->_set_cached_statement( tz_version => $sth );
    }

    my $rv = eval{ $sth->execute };
    if( $@ )
    {
        $sth->finish;
        return( $self->error( "Error executing the query to get the tz_version: $@" ) );
    }
    elsif( !defined( $rv ) )
    {
        $sth->finish;
        return( $self->error( "Error executing the query to get the tz_version: ", $sth->errstr ) );
    }
    my $row = eval{ $sth->fetchrow_arrayref };
    if( $@ )
    {
        $sth->finish;
        return( $self->error( "Error retrieving the tz_version: $@" ) );
    }
    # We check for definedness, which means an error in DBI
    elsif( !defined( $row ) && $sth->errstr )
    {
        $sth->finish;
        return( $self->error( "Error retrieving the tz_version: ", $sth->errstr ) );
    }
    $sth->finish;
    return( $row ? $row->[0] : undef );
}

sub tzif_version { return( $_[0]->{tzif_version} ); }

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
        return( $self->error(
            "SQLite version 3.6.19 or higher is required. You have $DBD::SQLite::sqlite_version"
        ) );
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
    return( $sth )
        if( defined( $sth ) &&
            Scalar::Util::blessed( $sth ) &&
            $sth->isa( 'DBI::st' ) );
    return;
}

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
        } || return( $self->error( "Error preparing the query to get the timezone information for $self->{name}: ", ( $@ || $dbh->errstr ) ) );
        $self->_set_cached_statement( get_zone_info => $sth );
    }

    my $rv = eval{ $sth->execute( $self->{name} ) };
    if( $@ )
    {
        $sth->finish;
        return( $self->error( "Error executing the query to get the timezone information for $self->{name}: $@" ) );
    }
    elsif( !defined( $rv ) )
    {
        $sth->finish;
        return( $self->error( "Error executing the query to get the timezone information for $self->{name}: ", $sth->errstr ) );
    }

    my $row = eval{ $sth->fetchrow_hashref };
    if( $@ )
    {
        $sth->finish;
        return( $self->error( "Error retrieving the timezone information for $self->{name}: $@" ) );
    }
    # We check for definedness, which means an error in DBI
    elsif( !defined( $row ) && $sth->errstr )
    {
        $sth->finish;
        return( $self->error( "Error retrieving the timezone information for $self->{name}: ", $sth->errstr ) );
    }
    $sth->finish;
    $self->_decode_sql_arrays( [qw( countries )], $row ) if( defined( $row ) );
    return( $row );
}

# Look up a span by UTC time (the common case).
# $utc_rd_secs is in Rata Die seconds (as returned by $dt->utc_rd_as_seconds).
# The database stores Unix seconds, so UNIX_TO_RD is subtracted before querying.
# NULL utc_start means "before all recorded transitions" (effectively -Inf).
# NULL utc_end means "after all recorded transitions" (effectively +Inf).
sub _lookup_span
{
    my( $self, $utc_rd_secs ) = @_;
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
        my $dbh = $self->_dbh || return( $self->pass_error );
        $sth = eval
        {
            $dbh->prepare( <<'SQL' )
SELECT s.offset, s.is_dst, s.short_name, s.utc_start, s.utc_end
FROM spans s
WHERE s.zone_id = ?
  AND ( s.utc_start IS NULL OR s.utc_start <= ? )
  AND ( s.utc_end   IS NULL OR s.utc_end   >  ? )
LIMIT 1
SQL
        } || return( $self->error( "Cannot prepare span_by_utc: ", ( $@ || $dbh->errstr ) ) );
        $self->_set_cached_statement( span_by_utc => $sth );
    }

    my $unix_secs = $utc_rd_secs - UNIX_TO_RD;
    my $rv = eval{ $sth->execute( $zone_id, $unix_secs, $unix_secs ) };
    if( $@ )
    {
        $sth->finish;
        return( $self->error( "Error executing the query to get the timezone spans information for $self->{name} and zone ID $zone_id: $@" ) );
    }
    elsif( !defined( $rv ) )
    {
        $sth->finish;
        return( $self->error( "Error executing the query to get the timezone spans information for $self->{name} and zone ID $zone_id: ", $sth->errstr ) );
    }

    my $row = eval{ $sth->fetchrow_hashref };
    if( $@ )
    {
        $sth->finish;
        return( $self->error( "Error retrieving the timezone spans information for $self->{name} and zone ID $zone_id: $@" ) );
    }
    # We check for definedness, which means an error in DBI
    elsif( !defined( $row ) && $sth->errstr )
    {
        $sth->finish;
        return( $self->error( "Error retrieving the timezone spans information for $self->{name} and zone ID $zone_id: ", $sth->errstr ) );
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
        exists( $self->{_span_cache_local}{offset} ) )
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
        my $dbh = $self->_dbh || return( $self->pass_error );
        local $@;
        $sth = eval
        {
            $dbh->prepare( <<'SQL' )
SELECT s.offset, s.is_dst, s.short_name, s.local_start, s.local_end
FROM spans s
WHERE s.zone_id = ?
  AND ( s.local_start IS NULL OR s.local_start <= ? )
  AND ( s.local_end   IS NULL OR s.local_end   >  ? )
LIMIT 1
SQL
        } || return( $self->error( "Cannot prepare span_by_local: ", ( $@ || $dbh->errstr ) ) );
        $self->_set_cached_statement( span_by_local => $sth );
    }

    my $unix_local = $local_rd_secs - UNIX_TO_RD;
    my $rv = eval{ $sth->execute( $zone_id, $unix_local, $unix_local ) };
    if( $@ )
    {
        $sth->finish;
        return( $self->error( "Error executing the query to get all the spans for the zone ID $zone_id: $@" ) );
    }
    elsif( !defined( $rv ) )
    {
        $sth->finish;
        return( $self->error( "Error executing the query to get all the spans for the zone ID $zone_id: ", $sth->errstr ) );
    }

    my $row = eval{ $sth->fetchrow_hashref };
    if( $@ )
    {
        $sth->finish;
        return( $self->error( "Error retrieving all the spans for the zone ID $zone_id: $@" ) );
    }
    # We check for definedness, which means an error in DBI
    elsif( !defined( $row ) && $sth->errstr )
    {
        $sth->finish;
        return( $self->error( "Error retrieving all the spans for the zone ID $zone_id: ", $sth->errstr ) );
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
sub _resolve_alias
{
    my $self = shift( @_ );
    my $name = shift( @_ ) ||
        return( $self->error( "No timezone alias was provided." ) );
    local $@;
    my $sth;
    unless( $sth = $self->_get_cached_statement( 'resolve_alias' ) )
    {
        my $dbh = $self->_dbh || return( $self->pass_error );
        local $@;
        $sth = eval
        {
            $dbh->prepare( <<'SQL' )
SELECT z.name
FROM aliases a
JOIN zones z ON z.zone_id = a.zone_id
WHERE a.alias = ?
SQL
        } || return( $self->error( "Cannot prepare resolve_alias: ", ( $@ || $dbh->errstr ) ) );
        $self->_set_cached_statement( resolve_alias => $sth );
    }

    my $rv = eval{ $sth->execute( $name ) };
    if( $@ )
    {
        $sth->finish;
        return( $self->error( "Error executing the query to get the canonical zone name for alias '$name': $@" ) );
    }
    elsif( !defined( $rv ) )
    {
        $sth->finish;
        return( $self->error( "Error executing the query to get the canonical zone name for alias '$name': ", $sth->errstr ) );
    }

    my $row = eval{ $sth->fetchrow_arrayref };
    if( $@ )
    {
        $sth->finish;
        return( $self->error( "Error retrieving the canonical zone name for alias '$name': $@" ) );
    }
    # We check for definedness, which means an error in DBI
    elsif( !defined( $row ) && $sth->errstr )
    {
        $sth->finish;
        return( $self->error( "Error retrieving the canonical zone name for alias '$name': ", $sth->errstr ) );
    }
    $sth->finish;
    # Not found in aliases: the name is assumed to be a canonical zone name
    return( $row ? $row->[0] : $name );
}

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
    $self->{ $prop } = shift( @_ ) if( @_ );
    return( $self->{ $prop } );
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

A new C<DateTime::Lite::TimeZone> object can be instantiated by either passing the timezone as a single argument, or as an hash, such as C<< name => 'Asia/Tokyo' >>

Recognised forms:

=over 4

=item Named IANA timezones such as C<America/New_York>, C<Europe/Paris>.

=item Aliases such as C<US/Eastern>, C<Japan>.

=item Fixed-offset strings such as C<+09:00>, C<-0500>.

=item The special names C<UTC> and C<floating>.

=back

An optional C<use_cache_mem =E<gt> 1> argument activates the process-level memory cache for this call. When set, subsequent calls with the same zone name (or its alias) return the cached object without a database query. See L</MEMORY CACHE> for details and for the class-level L</enable_mem_cache> alternative.

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
