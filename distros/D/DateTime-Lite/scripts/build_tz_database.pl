#!/usr/bin/env perl
##----------------------------------------------------------------------------
## DateTime::Lite::TimeZone - ~/scripts/build_tz_database.pl
## Version v0.4.0
## Copyright(c) 2026 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2026/04/03
## Modified 2026/04/07
## All rights reserved
##
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
# SYNOPSIS
#   # Fetch latest tzdata from IANA, compile, build database:
#   perl scripts/build_tz_database.pl [--verbose|--debug 3]
#
#   # Use a specific version (fetched from IANA if not cached):
#   perl scripts/build_tz_database.pl --tz-version 2026a [--verbose|--debug 3]
#
#   # Use already-downloaded tarball:
#   perl scripts/build_tz_database.pl --tarball /path/to/tzdata2026a.tar.gz
#
#   # Use system zoneinfo directory (no download):
#   perl scripts/build_tz_database.pl --zoneinfo /usr/share/zoneinfo
#
# DESCRIPTION
#   Builds the SQLite timezone database bundled with DateTime::Lite::TimeZone.
#
#   Primary mode: downloads the latest (or specified) tzdata release from
#   IANA (https://ftp.iana.org/tz/releases/), verifies the GPG signature,
#   compiles the Olson source files with zic(1), then reads the resulting
#   TZif binary files (RFC 8536). Downloaded tarballs are cached under
#   ~/.cache/dtl-tzdata/ to avoid redundant downloads.
#
#   Fallback mode (--zoneinfo): reads TZif files from a local zoneinfo
#   directory instead of downloading. Useful when IANA is not reachable.
#
# REQUIREMENTS
#   Always:       zic(1), Perl 5.10.1+, DBD::SQLite >= 1.27, DBI >= 1.611
#   IANA mode:    HTTP::Promise or Net::FTP depending on --proto (default to 'http')
#   Recommended:  gpg(1) for signature verification
#   Optional:     rdfind(1), symlinks(1) for zoneinfo deduplication
#
# SEE ALSO
#   Repository on Github: <https://github.com/eggert/tz>
##----------------------------------------------------------------------------
use v5.10.1;
use strict;
use warnings;
use Config;
use Data::Pretty qw( dump );
use DBI ();
use Encode ();
use File::Which qw( which );
use Getopt::Class;
use JSON;
use Module::Generic::File qw( cwd file stdout stderr tempdir );
use Pod::Usage;
use POSIX qw( strftime );
use Term::ANSIColor::Simple;
our $VERSION   = 'v0.4.0';
our $LOG_LEVEL = 0;
our $DEBUG     = 0;
our $VERBOSE   = 0;

# NOTE: Constants
use constant NEG_INF_SENTINEL =>  -9_223_372_036_854_775_807;
use constant POS_INF_SENTINEL =>   9_223_372_036_854_775_807;

# Seconds from Rata Die epoch (0001-01-01) to Unix epoch (1970-01-01)
# Verified: DateTime->new(year=>1970,month=>1,day=>1,time_zone=>'UTC')->utc_rd_as_seconds
use constant UNIX_TO_RD => 62_135_683_200;

use constant IANA_RELEASES    => 'https://ftp.iana.org/tz/releases';
# We need both code and data to compile the binaries and tzdata.zi
use constant IANA_LATEST_CODE => 'https://ftp.iana.org/tz/tzcode-latest.tar.gz';
use constant IANA_LATEST_DATA => 'https://ftp.iana.org/tz/tzdata-latest.tar.gz';

# Olson source files to compile with zic, in the conventional order
use constant OLSON_FILES => [qw(
    africa
    antarctica
    asia
    australasia
    europe
    northamerica
    southamerica
    etcetera
    factory
    backward
)];

use constant TZINFO_EXTRA_FILES => [qw(
    iso3166.tab
    zone1970.tab
    zonenow.tab
    zone.tab
    tzdata.zi
)];

our $HAS_NATIVE_I64 = 0;
unless( !defined( $Config{ivsize} ) || $Config{ivsize} < 8 )
{
    local $@;
    my $ok = eval
    {
        my $v = unpack( 'q>', pack( 'C8', 0, 0, 0, 0, 0, 0, 0, 1 ) );
        defined( $v ) ? 1 : 0;
    };
    if( !$@ )
    {
        $HAS_NATIVE_I64 = $ok;
    }
}


our $PROG_NAME = file( __FILE__ )->basename( '.pl' );
$SIG{INT} = $SIG{TERM} = \&_signal_handler;
our $out = stdout( binmode => 'utf-8', autoflush => 1 );
our $err = stderr( binmode => 'utf-8', autoflush => 1 );
@ARGV = map( Encode::decode_utf8( $_ ), @ARGV );
my $script_dir  = file(__FILE__)->parent;
my $dist_dir    = $script_dir->parent;
my $default_db  = $dist_dir->child( 'lib/DateTime/Lite/tz.sqlite3' );
my $cache_dir   = $dist_dir->child( 'dev/dtl-tzdata' );
my $cwd         = cwd();
my $iana_host   = 'ftp.iana.org';
my $iana_dir    = '/tz/releases';
my $iana_latest = '/tz/tzdata-latest.tar.gz';

# NOTE: options dictionary
# Tokens use underscores; Getopt::Class automatically exposes them as dashes on the
# For example: skip_verif -> --skip-verif
my $dict =
{
    cache           => { type => 'file', default => $cache_dir },   # Will set this to a Module::Generic::File object
    db              => { type => 'file', default => $default_db },
    # Do we prefer to download via the web or ftp ?
    # If we prefer ftp, we need Net::FTP, otherwise we need HTTP::Promise
    proto           => { type => 'string', re => qr/^(ftp|http)$/, alias => [qw( protocol )], default => 'http' },
    skip_verif      => { type => 'boolean', default => 0 },
    tz_version      => { type => 'string' },
    tarball_code    => { type => 'file' },
    tarball_data    => { type => 'file' },
    zoneinfo        => { type => 'file' },

    # Generic options
    debug       => { type => 'integer', alias => [qw( d )],  default => \$DEBUG },
    help        => { type => 'code',    alias => [qw( h ? )],
                     code => sub{ pod2usage( -exitstatus => 1, -verbose => 99,
                        -sections => [qw( NAME SYNOPSIS DESCRIPTION OPTIONS AUTHOR COPYRIGHT )] ) },
                     action => 1 },
    http_debug  => { type => 'integer', default => 0 },
    log_level   => { type => 'integer', default => \$LOG_LEVEL },
    man         => { type => 'code',
                     code => sub{ pod2usage( -exitstatus => 0, -verbose => 2 ) },
                     action => 1 },
    quiet       => { type => 'boolean', default => 0 },
    verbose     => { type => 'integer', default => \$VERBOSE },
    v           => { type => 'code',
                     code => sub{ $out->print( $VERSION, "\n" ); exit(0) },
                     action => 1 },
};

our $opt = Getopt::Class->new({ dictionary => $dict }) ||
    die( "Error instantiating Getopt::Class object: ", Getopt::Class->error, "\n" );
$opt->usage( sub{ pod2usage(2) } );
our $opts = $opt->exec || die( "An error occurred executing Getopt::Class: ", $opt->error, "\n" );

my @errors = ();
my $opt_errors = $opt->configure_errors;
push( @errors, @$opt_errors ) if( $opt_errors->length );

if( $opts->{quiet} )
{
    $DEBUG = $VERBOSE = 0;
}

# NOTE: SIGDIE
local $SIG{__DIE__} = sub
{
    my $msg = join( '', @_ );
    my $trace = $opt->_get_stack_trace;
    my $stack_trace = join( "\n    ", split( /\n/, $trace->as_string ) );
    $err->print( "Error: ", color( $msg )->red, "\n", $stack_trace );
    &_cleanup_and_exit(1);
};
# NOTE: SIGWARN
local $SIG{__WARN__} = sub
{
    $out->print( "Perl warning only: ", @_, "\n" ) if( $LOG_LEVEL >= 5 );
};

unless( $LOG_LEVEL )
{
    $LOG_LEVEL = 1 if( $VERBOSE );
    $LOG_LEVEL = ( 1 + $DEBUG ) if( $DEBUG );
}

if( @errors )
{
    my $error = join( "\n", map{ "\t* $_" } @errors );
    substr( $error, 0, 0, "\n\tThe following errors were found.\n" );
    unless( $opts->{quiet} )
    {
        $err->print( <<EOT );
$error
Please, use option '-h' or '--help' to get usage information:

$PROG_NAME -h
EOT
    }
    exit(1);
}

# A bit paranoid...
$opts->{db}        //= $default_db;
$opts->{cache_dir} //= $cache_dir;
$cache_dir           = $opts->{cache_dir};
my $zone_db          = $opts->{db};
$cache_dir->mkpath if( !$cache_dir->exists );
my $schema_file      = file(__FILE__)->parent->child( 'tz_schema.sql' );
my $temp_zone_db     = $cache_dir->child( 'tz.sqlite3' );

# NOTE: Determine zoneinfo source
my( $zoneinfo_dir, $tz_version );
# Points to an existing zoneinfo directory
if( $opts->{zoneinfo} )
{
    $zoneinfo_dir = $opts->{zoneinfo};
    die( "Zoneinfo directory '$opts->{zoneinfo}' does not exist.\n" )
        unless( $zoneinfo_dir->exists );
    $tz_version   = _read_tz_version( $zoneinfo_dir );
    _message( 1, "Mode         : local zoneinfo fallback" );
    _message( 1, "Zoneinfo dir : <green>$zoneinfo_dir</>" );
}
# Download the code and data, and compile it.
else
{
    my $tar_code  = _resolve_tarball_code();
    my $tar_data  = _resolve_tarball_data();
    $zoneinfo_dir = _compile_tzdata( $tar_code, $tar_data );
    $tz_version   = _read_tz_version( $zoneinfo_dir );
}
my $iso3166_tab   = $zoneinfo_dir->child( 'iso3166.tab' );
my $zone1970_tab  = $zoneinfo_dir->child( 'zone1970.tab' );

_message( 1, "TZ version   : <green>$tz_version</>" );
_message( 1, "Output DB    : <green>$zone_db</>" );

# NOTE: Read zone names and links from tzdata.zi
my $tzdata_zi = $zoneinfo_dir->child( 'tzdata.zi' );
die( "Cannot find $tzdata_zi . Is tzdata installed properly?\n" )
    unless( $tzdata_zi->exists );

_message( 3, "Reading ISO3166 countries file from <green>$iso3166_tab</>" );
my $countries = _read_iso3166_tab( $iso3166_tab );
_message( 3, "Reading 1970 time zones file from <green>$zone1970_tab</>" );
my $zones_map = _read_zone1970_tab( $zone1970_tab );
_message( 3, "Building time zone name and alias list from <green>$tzdata_zi</>" );
# NOTE: Building time zone name and alias list
my $zi_info   = _read_tzdata_zi( $tzdata_zi );

_message( 1, sprintf( "Canonical zones : <green>%d</> | Links/aliases : <green>%d</>",
    scalar( keys( %{$zi_info->{zones}} ) ), scalar( keys( %{$zi_info->{links}} ) ) ) );

# NOTE: Connecting to the SQLite database
$temp_zone_db->unlink if( $temp_zone_db->exists );
my $dbh = DBI->connect(
    "dbi:SQLite:dbname=$temp_zone_db", '', '',
    { RaiseError => 1, AutoCommit => 1, sqlite_unicode => 1 }
) or die( "Cannot open $temp_zone_db: $DBI::errstr" );

$dbh->do( "PRAGMA foreign_keys = ON" );
$dbh->do( "PRAGMA journal_mode = WAL" );
$dbh->do( "PRAGMA synchronous  = NORMAL" );

# NOTE: Loading the SQLite schema
_message( 1, "Creating SQL schema." );
my $objects = _load_schema( $schema_file );
my $tables  = $objects->{tables};
my $views   = $objects->{views};
_message( 1, "Loaded <green>", scalar( @$tables ), "</> tables and <green>", scalar( @$views ), "</> views schema." );
my $tables_to_query_check = {};
@$tables_to_query_check{ @$tables } = (1) x scalar( @$tables );
# We create it here, because we need it for _build_database() and _to_array();
my $json = JSON->new->utf8->canonical(1);
# NOTE: Build the SQLite database
_build_database();
if( !$temp_zone_db->is_empty )
{
    _message( 2, "Moving temporary database <green>$temp_zone_db</> to <green>$zone_db</>" );
    $temp_zone_db->copy( $zone_db, overwrite => 1 ) ||
        die( "Unable to copy $temp_zone_db to $zone_db: ", $temp_zone_db->error );
}
else
{
    _message( 2, "Something is wrong. The temporary database file <green>$temp_zone_db</> i szero byte." );
}
exit(0);

sub _abbr
{
    my( $d, $i ) = @_;
    my $s = substr( $d, $i );
    $s =~ s/\0.*//s;
    return( $s );
}

sub _build_database
{
    my $imported_at_utc = strftime( '%Y-%m-%dT%H:%M:%SZ', gmtime() );
    # NOTE: Preparing all SQL queries
    _message( 1, "Preparing all SQL queries." );
    my $queries =
    [
        aliases     => "INSERT INTO aliases     (alias, zone_id) VALUES(?, ?)",
        countries   => "INSERT INTO countries   (code, name) VALUES(?, ?)",
        leap_second => "INSERT INTO leap_second (zone_id, leap_index, occurrence_time, correction, is_expiration) VALUES(?, ?, ?, ?, ?)",
        metadata    => "INSERT INTO metadata    (key, value) VALUES(?, ?)",
        spans       => "INSERT INTO spans       (zone_id, type_id, span_index, utc_start, utc_end, local_start, local_end, offset, is_dst, short_name) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
        transition  => "INSERT INTO transition  (zone_id, trans_index, trans_time, type_id) VALUES(?, ?, ?, ?)",
        types       => "INSERT INTO types       (zone_id, type_index, utc_offset, is_dst, abbreviation, designation_index, is_standard_time, is_ut_time, is_placeholder) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?)",
        zones       => "INSERT INTO zones       (name, canonical, has_dst, countries, coordinates, latitude, longitude, comment, tzif_version, footer_tz_string, transition_count, type_count, leap_count, isstd_count, isut_count, designation_charcount, category, subregion, location) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
    ];
    my $sths = {};

    for( my $i = 0; $i < scalar( @$queries ); $i += 2 )
    {
        my $id = $queries->[$i];
        $out->print( "[${id}] " ) if( $LOG_LEVEL );
        my $sql = $queries->[$i + 1];
        # It is listed, but we skip it to make the 'tables_to_query_check' happy
        if( !defined( $sql ) )
        {
            delete( $tables_to_query_check->{ $id } );
            next;
        }
        elsif( exists( $sths->{ $id } ) )
        {
            die( "There is already a statement object for ID '${id}' with SQL: ", $sths->{ $id }->{Statement} );
        }
        my $sth = $dbh->prepare( $sql ) ||
            die( "Error preparing query '", $sql, "': ", $dbh->errstr );
        $sths->{ $id } = $sth;
        $out->print( "ok\n" ) if( $LOG_LEVEL );
        if( exists( $tables_to_query_check->{ $id } ) )
        {
            delete( $tables_to_query_check->{ $id } );
        }
        else
        {
            warn( "Warning only: No table '$id' found in our a tables-to-query map check." );
        }
    }

    if( scalar( keys( %$tables_to_query_check ) ) )
    {
        die( sprintf( "There are %d tables with no statement defined: %s", scalar( keys( %$tables_to_query_check ) ), join( ', ', sort( keys( %$tables_to_query_check ) ) ) ) );
    }
    else
    {
        _message( 1, "All tables have a statement defined." );
    }

    $sths->{resolve_alias} = $dbh->prepare( q{SELECT zone_id FROM zones WHERE name = ?} ) ||
        die( "Error preparing query to resolve zone alias: ", $dbh->errstr );


    $dbh->begin_work;
    my( $total_spans, $total_types, $total_zones, $total_aliases, $errors ) = ( 0, 0, 0, 0, 0 );

    eval
    {
        # _clear_all_data( $dbh );
        # NOTEE: Process countries
        foreach my $code ( sort( keys( %$countries ) ) )
        {
            $sths->{countries}->execute(
                $countries->{ $code }->{code},
                $countries->{ $code }->{name},
            ) || die( "Error adding country code $code with value '", ( $countries->{ $code }->{name} // 'undef' ), "'" );
        }

        # NOTE: Process timezones
        my %all_canonical = %{$zi_info->{zones}};
        # Zone map = 1970 tab data
        foreach my $name ( keys( %$zones_map ) )
        {
            $all_canonical{ $name } = 1;
        }

        foreach my $name ( sort( keys( %all_canonical ) ) )
        {
            my $tzfile = $zoneinfo_dir->child( $name );
            unless( $tzfile->exists && $tzfile->can_read )
            {
                _message( 1, "  SKIP $name: TZif file not found" );
                die( "Compiled zone file $tzfile not found" );
            }

            my $parsed = _parse_tzif( $tzfile );
            my $h      = $parsed->{header};
            my $d      = $parsed->{data};

            my $zone_meta = $zones_map->{ $name } || {};

            # Encode the countries array to JSON
            # If no countries, we get back undef, which translates to NULL
            my $countries_json = _to_array( $zone_meta->{countries} );
            # Convenience
            my $has_dst = 0;
            foreach my $type ( @{$d->{types}} )
            {
                if( $type->{is_dst} )
                {
                    $has_dst++;
                    last;
                }
            }

            my( $category, $subregion, $location );
            my @parts = split( /\//, $name );
            if( scalar( @parts ) == 1 )
            {
                # Example: "Factory"
                $location = $parts[0];
            }
            elsif( scalar( @parts ) == 2 )
            {
                # Example: "Asia/Tokyo"
                ( $category, $location ) = @parts;
            }
            else
            {
                # Example: "America/Indiana/Indianapolis"
                $category  = shift( @parts );
                $location  = pop( @parts );
                $subregion = join( '/', @parts );  # future-proof
            }

            # NOTE: Add zones
            $sths->{zones}->execute(
                $name,                              # name
                1,                                  # canonical
                $has_dst,                           # has_dst
                $countries_json,                    # countries
                $zone_meta->{coordinates},          # coordinates
                $zone_meta->{latitude},             # latitude
                $zone_meta->{longitude},            # longitude
                $zone_meta->{comment},              # comment
                $parsed->{tzif_version},            # tzif_version
                $parsed->{footer_tz},               # footer_tz_string
                scalar( @{$d->{transitions}} ),     # transition_count
                scalar( @{$d->{types}} ),           # type_count
                scalar( @{$d->{leaps}} ),           # leap_count
                $h->{isstdcnt},                     # isstd_count
                $h->{isutcnt},                      # isut_count
                $h->{charcnt},                      # designation_charcount
                $category,                          # category
                $subregion,                         # subregion
                $location,                          # location
            ) || die( "Error adding zone $name data: ", $sths->{zones}->errstr );

            my $zone_id = $dbh->sqlite_last_insert_rowid();

            # NOTE: Add zone types
            my $type_id_by_index  = {};
            my $type_row_by_index = {};
            foreach my $type ( @{$d->{types}} )
            {
                $sths->{types}->execute(
                    $zone_id,
                    $type->{type_index},            # type_index
                    $type->{utc_offset},            # utc_offset
                    $type->{is_dst},                # is_dst
                    $type->{abbreviation},          # abbreviation
                    $type->{designation_index},     # designation_index
                    $type->{is_standard_time},      # is_standard_time
                    $type->{is_ut_time},            # is_ut_time
                    $type->{is_placeholder},        # is_placeholder
                ) || die( "Error adding zone $name type index $type->{type_index}: ", $sths->{types}->errstr );
                $total_types++;
                my $type_id = $dbh->sqlite_last_insert_rowid();

                $type_id_by_index->{ $type->{type_index} }  = $type_id;
                $type_row_by_index->{ $type->{type_index} } =
                {
                    type_id       => $type_id,
                    utc_offset    => $type->{utc_offset},
                    is_dst        => $type->{is_dst},
                    abbreviation  => ( defined( $type->{abbreviation} ) && length( $type->{abbreviation} ) ) ? $type->{abbreviation} : undef,
                };
            }

            # NOTE: Add zone transition
            foreach my $tr ( @{$d->{transitions}} )
            {
                my $type_id = $type_id_by_index->{ $tr->{type_index} };

                unless( defined( $type_id ) )
                {
                    die( "Could not resolve type_id for zone $name (zone_id=$zone_id), and  type_index=$tr->{type_index}" );
                }

                $sths->{transition}->execute(
                    $zone_id,                       # zone_id
                    $tr->{transition_index},        # trans_index
                    $tr->{transition_time},         # trans_time
                    $type_id,                       # type_id
                ) || die( "Error adding zone $name transition with index $tr->{transition_index}: ", $sths->{transition}->errstr );
            }

            # NOTE: Add zone leap seconds
            foreach my $leap ( @{$d->{leaps}} )
            {
                $sths->{leap_second}->execute(
                    $zone_id,                       # zone_id
                    $leap->{leap_index},            # leap_index
                    $leap->{occurrence_time},       # occurrence_time
                    $leap->{correction},            # correction
                    $leap->{is_expiration},         # is_expiration
                ) || die( "Error adding zone $name leap second with leap index $leap->{leap_index}: ", $sths->{leap_second}->errstr );
            }

            # insert_zone_spans( $dbh, $zone_id, $d->{transitions}, $type_id_by_index, $type_row_by_index );
            # my( $dbh, $zone_id, $transitions, $type_id_by_index, $type_row_by_index ) = @_;
            # NOTE: Add spans
            my @ordered = sort
            {
                $a->{transition_index} <=> $b->{transition_index}
            } @{$d->{transitions}};

            my $span_index = 0;
            if( !@ordered )
            {
                my $type0 = $type_row_by_index->{0};

                unless( defined( $type0 ) )
                {
                    die( "Missing type_index 0 for zone $name, with zone_id=$zone_id" );
                }

                $sths->{spans}->execute(
                    $zone_id,                       # zone_id 
                    $type0->{type_id},              # type_id
                    $span_index,                    # span_index
                    undef,                          # utc_start
                    undef,                          # utc_end
                    undef,                          # local_start
                    undef,                          # local_end
                    $type0->{utc_offset},           # offset
                    $type0->{is_dst},               # is_dst
                    $type0->{abbreviation},         # short_name
                ) || die( "Error adding span for zone $name and index $span_index: ", $sths->{spans}->errstr );
            }
            else
            {
                my $type0 = $type_row_by_index->{0};

                unless( defined( $type0 ) )
                {
                    die( "Missing type_index 0 for zone_id=$zone_id" );
                }

                my $first_transition_time = $ordered[0]->{transition_time};

                $sths->{spans}->execute(
                    $zone_id,                       # zone_id
                    $type0->{type_id},              # type_id
                    $span_index++,                  # span_index
                    undef,                          # utc_start
                    $first_transition_time,         # utc_end
                    undef,                          # local_start
                    ( defined( $first_transition_time )
                        ? ( $first_transition_time + $type0->{utc_offset} )
                        : undef ),                  # local_end
                    $type0->{utc_offset},           # offset
                    $type0->{is_dst},               # is_dst
                    $type0->{abbreviation},         # short_name
                ) || die( "Error adding span for zone $name and index $span_index: ", $sths->{spans}->errstr );
                $total_spans++;

                for( my $i = 0; $i < scalar( @ordered ); $i++ )
                {
                    my $current = $ordered[$i];
                    my $next    = ( $i + 1 < scalar( @ordered ) ) ? $ordered[$i + 1] : undef;

                    my $type_index = $current->{type_index};
                    my $type_row   = $type_row_by_index->{ $type_index };

                    unless( defined( $type_row ) )
                    {
                        die( "Missing type row for zone_id=$zone_id, type_index=$type_index" );
                    }

                    my $utc_start   = $current->{transition_time};
                    my $utc_end     = defined( $next )      ? $next->{transition_time} : undef;
                    my $local_start = defined( $utc_start ) ? ( $utc_start + $type_row->{utc_offset} ) : undef;
                    my $local_end   = defined( $utc_end )   ? ( $utc_end   + $type_row->{utc_offset} ) : undef;

                    $sths->{spans}->execute(
                        $zone_id,                   # zone_id
                        $type_row->{type_id},       # type_id
                        $span_index++,              # span_index
                        $utc_start,                 # utc_start
                        $utc_end,                   # utc_end
                        $local_start,               # local_start
                        $local_end,                 # local_end
                        $type_row->{utc_offset},    # offset
                        $type_row->{is_dst},        # is_dst
                        $type_row->{abbreviation},  # short_name
                    ) || die( "Error adding span for zone $name and index $span_index: ", $sths->{spans}->errstr );
                    $total_spans++;
                }
            }

            $total_spans += scalar( @{$d->{types}} );
            $total_zones++;
            _message( 1, sprintf( "  [%3d/%3d] %-40s %3d spans",
                                     $total_zones,
                                     scalar( keys( %{$zi_info->{zones}} ) ),
                                     $name,
                                     scalar( @{$d->{types}} )
            ) );
        }

        # NOTE: Add aliases
        foreach my $alias ( sort( keys( %{$zi_info->{links}} ) ) )
        {
            unless( exists( $zi_info->{zones}->{ $zi_info->{links}->{ $alias } } ) )
            {
                die( "Found an alias $alias whose corresponding zone name '", ( $zi_info->{links}->{ $alias } // 'undef' ), "' does not exist: ", dump( $zi_info->{zones} ) );
            }
            my $target = $zi_info->{links}->{ $alias };

            $sths->{resolve_alias}->execute( $target ) ||
                die( "Error executing query to resolve zone alias '$target': ", $sths->{resolve_alias}->errstr );
            my( $zone_id ) = $sths->{resolve_alias}->fetchrow_array();

            unless( defined( $zone_id ) )
            {
                die( "Alias target zone not found: $alias -> $target" );
            }

            $sths->{aliases}->execute(
                $alias,                         # alias
                $zone_id,                       # zone_id
            ) || die( "Error adding alias $alias for zone_id $zone_id: ", $sths->{aliases}->errstr );
            $total_aliases++;
        }

        $sths->{metadata}->execute( 'tz_version',  $tz_version ) ||
            die( "Error inserting into metadata table tz_version $tz_version: ", $sths->{metadata}->errstr );
        $sths->{metadata}->execute( 'built_by',    "build_tz_database.pl $VERSION" ) ||
            die( "Error inserting into metadata table built_by 'build_tz_database.pl $VERSION': ", $sths->{metadata}->errstr );
        # We use a ISO8601 date format
        $sths->{metadata}->execute( 'built_at',    POSIX::strftime( '%Y-%m-%dT%H:%M:%S+00:00', gmtime() ) ) ||
            die( "Error inserting into metadata table built_at ", scalar( localtime ), ": ", $sths->{metadata}->errstr );
        $sths->{metadata}->execute( 'total_zones', $total_zones ) ||
            die( "Error inserting into metadata table total_zones $total_zones: ", $sths->{metadata}->errstr );
        $sths->{metadata}->execute( 'total_spans', $total_spans ) ||
            die( "Error inserting into metadata table total_spans $total_spans: ", $sths->{metadata}->errstr );
        $sths->{metadata}->execute( 'total_aliases', $total_aliases ) ||
            die( "Error inserting into metadata table total_aliases $total_aliases: ", $sths->{metadata}->errstr );
        1;
    } or do
    {
        my $err = $@ || 'Unknown error';
        eval{ $dbh->rollback; };
        die( $err );
    };

    $dbh->commit;
    $dbh->do( 'VACUUM' );
    $dbh->disconnect;

    my $size_kb = int( $temp_zone_db->size / 1024 );
    _message( 1, '' );
    _message( 1, 'Done.' );
    _message( 1, sprintf( "  TZ version  : <green>%s</>",    $tz_version ) );
    _message( 1, sprintf( "  Zones       : <green>%d</>",    $total_zones ) );
    _message( 1, sprintf( "  Types       : <green>%d</>",    $total_types ) );
    _message( 1, sprintf( "  Spans       : <green>%d</>",    $total_spans ) );
    _message( 1, sprintf( "  Alias       : <green>%d</>",    $total_aliases ) );
    _message( 1, sprintf( "  Errors      : <green>%d</>",    $errors ) );
    _message( 1, sprintf( "  DB size     : <green>%d kB</>", $size_kb ) );
    _message( 1, sprintf( "  Written     : <green>%s</>",    $temp_zone_db ) );
    return( $temp_zone_db );
}

sub _cleanup_and_exit
{
    my $exit = shift( @_ );
    $exit = 0 if( !length( $exit // '' ) || $exit !~ /^\d+$/ );
    exit( $exit );
}

# Called by _parse_compact_coordinates()
sub _compact_coord_to_decimal
{
    my( $raw, $is_latitude ) = @_;

    my $sign   = ( substr( $raw, 0, 1 ) eq '-' ) ? -1 : 1;
    my $digits = substr( $raw, 1 );

    my( $deg, $min, $sec );

    if( $is_latitude )
    {
        if( length( $digits ) == 4 )
        {
            $deg = substr( $digits, 0, 2 );
            $min = substr( $digits, 2, 2 );
            $sec = 0;
        }
        elsif( length( $digits ) == 6 )
        {
            $deg = substr( $digits, 0, 2 );
            $min = substr( $digits, 2, 2 );
            $sec = substr( $digits, 4, 2 );
        }
        else
        {
            die( "Invalid latitude coordinate: $raw" );
        }
    }
    else
    {
        if( length( $digits ) == 5 )
        {
            $deg = substr( $digits, 0, 3 );
            $min = substr( $digits, 3, 2 );
            $sec = 0;
        }
        elsif( length( $digits ) == 7 )
        {
            $deg = substr( $digits, 0, 3 );
            $min = substr( $digits, 3, 2 );
            $sec = substr( $digits, 5, 2 );
        }
        else
        {
            die( "Invalid longitude coordinate: $raw" );
        }
    }

    my $decimal = $deg + ( $min / 60 ) + ( $sec / 3600 );
    return( $sign * $decimal );
}

# _compile_tzdata( $tarball )
# Extracts the tarball, compiles each Olson source file with zic, optionally deduplicates
# with rdfind and fixes symlinks.
# Returns path to the compiled zoneinfo directory.
sub _compile_tzdata
{
    my( $tar_code, $tar_data ) = @_;

    my $cwd = cwd();
    my $tmpdir = tempdir( cleanup => ( $opts->{debug} ? 0 : 1 ) );
    $tmpdir->mkpath || die( $tmpdir->error );
    $tmpdir->chdir;
    _message( 1, "Extracting   : <green>$tar_code</> and <green>$tar_data</> to <green>$tmpdir</>" );
    my $tar = _has_tool( 'tar' ) ||
        die( "tar is not installed on your system." );
    my $make = _has_tool( 'make' ) ||
        die( "make is not installed on your system." );
    _message( 3, "Extracting $tar_code to $tmpdir" );
    system( $tar, '-xzf', "$tar_code", '-C', "$tmpdir" ) == 0 ||
        die( "tar extraction failed for $tar_code: $? (exit ", ( $? >> 8 ), ").\n" );
    _message( 3, "Extracting $tar_data to $tmpdir" );
    system( $tar, '-xzf', "$tar_data", '-C', "$tmpdir" ) == 0 ||
        die( "tar extraction failed for $tar_data: $? (exit ", ( $? >> 8 ), ").\n" );

    # Compile
    # Although usually not necessary, we add the CFLAGS because of an issue introduced in
    # 2017c with the use of snprintf
    system( $make, 'CFLAGS=-DHAVE_SNPRINTF' ) == 0 ||
        die( "Error running $make inside $tmpdir: ", ( $? == -1 ? $! : "exit value " . ( $? >> 8 ) ) );
    # Consequently, we now have the binaries tzselect, zdump, and more importantly 'zic' inside our temporary directory.
    my $zic;
    my $new_zic = $tmpdir->child( 'zic' );
    if( $new_zic->exists && $new_zic->can_exec )
    {
        _message( 3, "Using newly compiled version of zic at $new_zic" );
        $zic = "$new_zic";
    }
    else
    {
        $zic = _has_tool('zic') ||
            die( "zic not found. Install the tzdata or tz-utils package.\n" );
        _message( 3, "Using system version of zic at $zic" );
    }

    my $target = $tmpdir->child( 'zoneinfo' );
    $target->mkpath || die( $target->error );
    _message( 2, "Target directory is <green>$target</>" );

    _message( 1, "Compiling with <green>$zic</>..." );
    foreach my $file ( @{+OLSON_FILES} )
    {
        my $src = $tmpdir->child( $file );
        next unless( $src->exists );
        _message( 3, "$zic -d $target $src" );
        system( $zic, '-d', "$target", "$src" ) == 0 ||
            die( "$zic failed on '$src': $? (exit ", ( $? >> 8 ), ").\n" );
        _message( 1, "  $zic $src" );
    }

    # Deduplicate identical zone files into symlinks (optional)
    my $rdfind = _has_tool('rdfind');
    if( $rdfind )
    {
        _message( 1, "Deduplicating with <green>$rdfind</>..." );
        _message( 3, "$rdfind -outputname /dev/null -makesymlinks true -removeidentinode false $target" );
        system( $rdfind,
            '-outputname',       '/dev/null',
            '-makesymlinks',     'true',
            '-removeidentinode', 'false',
            $target
        ) == 0 || die( "Error running $rdfind for target directory $target" );
    }
    else
    {
        _message( 1, "  rdfind is not available; skipping deduplication (not critical)." );
    }

    # Ensure symlinks are relative (optional)
    my $symlinks = _has_tool('symlinks');
    if( $symlinks )
    {
        _message( 1, "Fixing symlinks with $symlinks -rsc $target" );
        system( $symlinks, '-rsc', $target ) == 0 ||
            die( "Error running $symlinks on target directory $target, exit with ", ( $? >> 8 ) );
    }
    else
    {
        _message( 1, "  symlinks not available; skipping (not critical)." );
    }

    # Copy tzdata.zi into the compiled target dir (needed for zone/link list)
    foreach my $file ( @{+TZINFO_EXTRA_FILES} )
    {
        my $src = $tmpdir->child( $file );
        next unless( $src->exists );
        my $dst = $target->child( $file );
        if( $src->exists )
        {
            _message( 3, "Copy $src -> $dst" );
            $src->copy( $dst ) || die( "Error copy $src to $dst: ", $src->error );
        }
        else
        {
            warn( "Could not find $src" );
        }
    }
    $cwd->chdir;
    return( $target );
}

# _download( $url, $dest )
# Downloads $url to $dest using curl or wget.
sub _download_ftp
{
    my( $url, $dest ) = @_;
    if( $dest->exists && !$dest->is_empty )
    {
        _message( 2, "Found an existing file $dest, using it." );
        return( $dest );
    }
    require URI;
    my $uri = URI->new( $url );
    my $path = $uri->path;
    my $ftp = Net::FTP->new( $iana_host, Passive => 1 ) ||
        die( "Unable to connect to host $iana_host: $@" );
    $ftp->login ||
        die( "Cannot login: ", $ftp->message );
    $ftp->cwd( $iana_dir ) ||
        die( "Cannot cwd to $iana_dir: ", $ftp->message );
    $ftp->binary;
    $ftp->get( $path, $dest ) ||
        die( "Unable to get the file $path: ", $ftp->message );
    $ftp->quit;
    die( "Downloaded file '$dest' is empty.\n" ) if( $dest->is_empty );
    return( $dest );
}

sub _download_ftp_latest
{
    my( $dest ) = @_;
    my $year = [localtime(time)]->[5] + 1900;
    my $ftp = Net::FTP->new( $iana_host, Passive => 1 ) ||
        die( "Unable to connect to host $iana_host: $@" );
    $ftp->login ||
        die( "Cannot login: ", $ftp->message );
    $ftp->cwd( $iana_dir ) ||
        die( "Cannot cwd to $iana_dir: ", $ftp->message );
    # The Net::FTP doc says:
    # "In an array context, returns a list of lines returned from the server. In a scalar context, returns a reference to a list."
    # Example: tzdata2026a.tar.gz
    my $all = $ftp->ls( "tzdata${year}.*.tar.gz" );
    if( !scalar( @$all ) )
    {
        my $code = $ftp->code;
        my $msg = $ftp->message;
        if( $code == 550 && $msg =~ /(?:No such file|not found)/i )
        {
            # Likely no files match OR globbing not supported; fallback to local filtering.
            $all = [grep{ /tzdata2026.*\.tar\.gz/ } $ftp->ls];
        }
        else
        {
            # Some other error occurred.
            die( "FTP error $code: $msg" );
        }
    }
    my $latest = [reverse( sort( @$all ) )]->[0];
    if( !$latest )
    {
        die( "No timezone data file could be found." );
    }
    $ftp->binary;
    $ftp->get( $latest, $dest ) ||
        die( "Unable to get the file $latest: ", $ftp->message );
    $ftp->quit;
    die( "Downloaded file '$dest' is empty.\n" ) if( $dest->is_empty );
}

# Using HTTP::Promise->mirror
sub _download_web
{
    my( $url, $dest ) = @_;
    if( $dest->exists && !$dest->is_empty )
    {
        _message( 2, "Found an existing file $dest, using it." );
        return( $dest );
    }
    require HTTP::Promise;
    my $ua = HTTP::Promise->new(
        auto_switch_https       => 1,
        ext_vary                => 1,
        max_body_in_memory_size => 1024,
        max_redirect            => 3,
        timeout                 => 10,
        use_promise             => 0,
        use_content_file        => 1,
        ( $opts->{http_debug} ? ( debug => $opts->{http_debug} ) : () ),
    ) || die( "Error instantiating a HTTP::Promise object: ", HTTP::Promise->error );
    _message( 3, "Fetching remote URL <green>$url</>, and saving to <green>$dest</>" );
    my $resp = $ua->get( $url ) ||
        die( "Error fetching remote URL $url: ", $ua->error );
    # Should be a HTTP::Promise::Entity::Body::File
    my $file = $resp->entity->body ||
        die( "No response body found." );
    unless( $file->isa( 'HTTP::Promise::Body::File' ) )
    {
        die( "I was expecting a HTTP::Promise::Body::File object, but got $file (", $opt->_str_val( $file // 'undef' ), ")." );
    }
    if( $file->is_empty )
    {
        die( "Downloaded file '$file' is empty." );
    }
    $file->copy( $dest ) || die( $file->error );
    return( $dest );
}

# This is used if we want to rebuild the database, but without removing it entirely first.
sub _drop_schema
{
    my $schema_file = shift( @_ ) ||
        die( "No schema file provided." );
    my $sql = $schema_file->load_utf8 ||
        die( $schema_file->error );
    my @parts = split( /\n(?=CREATE\s)/, $sql );
    for( my $i = 0; $i < scalar( @parts ); $i++ )
    {
        # $out->print( "Loading part $i\n", $parts[$i], "\n" ) if( $DEBUG );
        if( $parts[$i] =~ /^CREATE[[:blank:]\h]+(TABLE|VIEW)[[:blank:]\h]+(\S+)/ )
        {
            my $type   = $1;
            my $object = $2;
            if( !$dbh->do( "DROP $type IF EXISTS $object" ) )
            {
                warn( "Could not drop the \L$type\E $object: ", $dbh->errstr, "\n", $parts[$i] );
            }
            next;
        }
        # The rest (indexes) get removed automatically with their associated object
    }
}

# _fetch_latest_version()
# Queries the IANA releases page to find the latest tzdata version string.
sub _fetch_latest_version
{
    _message( 1, "Querying IANA for latest tzdata version..." );

    # Try the releases index page first
    # my $page = _fetch_url( IANA_RELEASES . '/' );
    my $page = _fetch_mirror( IANA_RELEASES . '/' => $cache_dir->child( 'iana_releases.html' ) );
    _message( 2, "Retrieved <green>", length( $page ), "</> bytes of html data." );
    # We limit the collect of data files found to the current year
    my $year = [localtime(time)]->[5] + 1900;
    if( defined( $page ) )
    {
        my @versions;
        while( $page =~ /href="tzdata(${year}[a-z]+)\.tar\.gz"/gi )
        {
            push( @versions, $1 );
        }
        _message( 3, "Found ", scalar( @versions ), " candidate files." );
        if( @versions )
        {
            my( $latest ) = sort {
                my( $ya, $la ) = $a =~ /^(\d{4})([a-z]+)$/;
                my( $yb, $lb ) = $b =~ /^(\d{4})([a-z]+)$/;
                $yb <=> $ya || $lb cmp $la;
            } @versions;
            _message( 3, "Latest version found is '", ( $latest // 'undef' ), "'" );
            return( $latest );
        }
    }

    # Fallback: download tzdata-latest.tar.gz, read the VERSION from Makefile
    _message( 1, "  Falling back to tzdata-latest.tar.gz..." );
    my $tmp = $cache_dir->child( 'tzdata-latest.tar.gz' );
    # _download_ftp( IANA_LATEST_DATA, $tmp );
    _download_web( IANA_LATEST_DATA, $tmp );

    my $version = _version_from_tarball( $tmp );

    # Rename to versioned name in cache
    my $dest = $cache_dir->child( "tzdata${version}.tar.gz" );
    $tmp->rename( $dest ) ||
        die( "Cannot rename '$tmp' to '$dest': ", $tmp->error, "\n" );
    return( $version );
}

sub _fetch_mirror
{
    my( $url, $local ) = @_;
    require HTTP::Promise;
    my $ua = HTTP::Promise->new(
        auto_switch_https       => 1,
        ext_vary                => 1,
        max_body_in_memory_size => 102400,
        max_redirect            => 3,
        timeout                 => 10,
        use_promise             => 0,
        ( $opts->{http_debug} ? ( debug => $opts->{http_debug} ) : () ),
    ) || die( "Error instantiating a HTTP::Promise object: ", HTTP::Promise->error );
    my $resp = $ua->mirror( $url => $local ) ||
        die( "Failed to get the remote file $url and cache it locally to $local: ", $ua->error );
    if( $resp->code == 304 )
    {
        _message( 2, "Local copy is already up to date (304 Not Modified)." );
    }
    elsif( $resp->is_success )
    {
        _message( 2, sprintf( "Downloaded fresh copy (HTTP %d); saved to %s",
                              $resp->code,
                              $local
                    ) );
    }
    else
    {
        _message( 2, sprintf( "Unexpected response: HTTP %d %s",
                              $resp->code,
                              $resp->message
                     ) );
    }
    my $out = $resp->decoded_content_utf8;
    return( $out ) if( defined( $out ) && length( $out ) );
    return;
}

sub _fetch_url
{
    my $url = shift( @_ );
    require HTTP::Promise;
    my $ua = HTTP::Promise->new(
        auto_switch_https       => 1,
        ext_vary                => 1,
        max_body_in_memory_size => 102400,
        max_redirect            => 3,
        timeout                 => 10,
        use_promise             => 0,
        ( $opts->{http_debug} ? ( debug => $opts->{http_debug} ) : () ),
    ) || die( "Error instantiating a HTTP::Promise object: ", HTTP::Promise->error );
    my $resp = $ua->get( $url ) ||
        die( "Error fetching remote URL $url: ", $ua->error );
    my $out = $resp->decoded_content_utf8;
    return( $out ) if( defined( $out ) && length( $out ) );
    return;
}

my %_tool_cache;
sub _has_tool
{
    my $t = shift( @_ );
    return( $_tool_cache{ $t } ) if( exists( $_tool_cache{ $t } ) );
    my $bin = which( $t );
    return( $_tool_cache{ $t } = $bin );
}

# This version triggers the warning:
# "Hexadecimal number > 0xffffffff non-portable"
# sub _i32be
# {
#     my( $s ) = @_;
# 
#     my $u = unpack( 'N', $s );
#     return( $u >= 0x80000000 ) ? $u - 0x100000000 : $u;
# }
sub _i32be
{
    my( $s ) = @_;

    return( unpack( 'l>', $s ) );
}

# sub _i64be
# {
#     my( $s ) = @_;
# 
#     my( $hi, $lo ) = unpack( 'NN', $s );
#     my $u = ( $hi * 4294967296 ) + $lo;
# 
#     return( $hi >= 0x80000000 ) ? $u - 18446744073709551616 : $u;
# }
sub _i64be
{
    my( $s ) = @_;

    if( $HAS_NATIVE_I64 )
    {
        return( unpack( 'q>', $s ) );
    }

    my( $hi, $lo ) = unpack( 'NN', $s );
    my $u = ( $hi * 4294967296 ) + $lo;

    # return( unpack( 'q>', $s ) );
    return( $hi >= 2147483648 ) ? $u - 18446744073709551616 : $u;
}

sub _load_schema
{
    my $schema_file = shift( @_ ) ||
        die( "No schema file provided." );
    my $sql = $schema_file->load_utf8 ||
        die( $schema_file->error );
    my @parts = split( /\n(?=CREATE\s)/, $sql );
    my $ref = { tables => [], views => [] };
    my $tables = [];
    for( my $i = 0; $i < scalar( @parts ); $i++ )
    {
        # $out->print( "Loading part $i\n", $parts[$i], "\n" ) if( $DEBUG );
        if( $parts[$i] =~ /^CREATE[[:blank:]\h]+(TABLE|VIEW)[[:blank:]\h]+(\S+)/ )
        {
            my $type   = lc( $1 );
            my $object = $2;
            if( $type eq 'table' )
            {
                push( @{$ref->{tables}}, $object );
            }
            elsif( $type eq 'view' )
            {
                push( @{$ref->{views}}, $object );
            }
        }
        if( !defined( $dbh->do( $parts[$i] ) ) )
        {
            die( "Error loading part $i: ", $dbh->errstr, "\n", $parts[$i] );
        }
    }
    return( $ref );
}

sub _message
{
    my $required_level;
    if( $_[0] =~ /^\d{1,2}$/ )
    {
        $required_level = shift( @_ );
    }
    else
    {
        $required_level = 0;
    }
    return if( !$LOG_LEVEL || $LOG_LEVEL < $required_level );
    my $msg = join( '', map( ref( $_ ) eq 'CODE' ? $_->() : $_, @_ ) );
    if( index( $msg, '</>' ) != -1 )
    {
        $msg =~ s
        {
            <([^\>]+)>(.*?)<\/>
        }
        {
            my $colour = $1;
            my $txt = $2;
            my $obj = color( $txt );
            my $code = $obj->can( $colour ) ||
                die( "Colour '$colour' is unsupported by Term::ANSIColor::Simple" );
            $code->( $obj );
        }gexs;
    }
    my $frame = 0;
    my( $pkg, $file, $line ) = caller( $frame );
    my $sub = ( caller( $frame + 1 ) )[3] // '';
    my $sub2;
    if( length( $sub ) )
    {
        $sub2 = substr( $sub, rindex( $sub, '::' ) + 2 );
    }
    else
    {
        $sub2 = 'main';
    }
    return( $err->print( "${pkg}::${sub2}() [$line]: $msg\n" ) );
}

# Used by _read_zone1970_tab()
sub _parse_compact_coordinates
{
    my $coords = shift( @_ );
    my( $lat_raw, $lon_raw );

    if( $coords =~ /^([+-]\d{4})([+-]\d{5})$/ )
    {
        ( $lat_raw, $lon_raw ) = ( $1, $2 );
    }
    elsif( $coords =~ /^([+-]\d{6})([+-]\d{7})$/ )
    {
        ( $lat_raw, $lon_raw ) = ( $1, $2 );
    }
    elsif( $coords =~ /^([+-]\d{4})([+-]\d{7})$/ )
    {
        ( $lat_raw, $lon_raw ) = ( $1, $2 );
    }
    elsif( $coords =~ /^([+-]\d{6})([+-]\d{5})$/ )
    {
        ( $lat_raw, $lon_raw ) = ( $1, $2 );
    }
    else
    {
        die( "Unsupported coordinate format: $coords" );
    }

    my $latitude  = _compact_coord_to_decimal( $lat_raw,  1 );
    my $longitude = _compact_coord_to_decimal( $lon_raw,  0 );

    return( $latitude, $longitude );
}

# _read_tzif( $file ) - RFC 9636 TZif v1/v2/v3/v4 parser
sub _parse_tzif
{
    my $file = shift( @_ );
    my $blob = $file->load( binmode => 'raw' ) ||
        die( "Unable to read binary data from zone file $file: ", $file->error );
    my $len = length( $blob );
    die( "TZif file $file is too short ($len bytes vs expected >=44)" ) if( $len < 44 );

    my $head1 = _parse_tzif_header_at( \$blob, 0 );

    die( "Invalid TZif magic" ) if( $head1->{magic} ne 'TZif' );

    if( $head1->{version} == 1 )
    {
        my( $block1, $next1 ) = _parse_tzif_data_block_at( \$blob, 44, $head1, 4 );

        if( $next1 != $len )
        {
            die( "Trailing data after v1 block" );
        }

        return({
            tzif_version => 1,
            header       => $head1,
            data         => $block1,
            footer_tz    => undef,
        });
    }

    my $offset = 44 + _tzif_data_block_size( $head1, 4 );

    if( $offset + 44 > $len )
    {
        die( "Missing second header" );
    }

    my $head2 = _parse_tzif_header_at( \$blob, $offset );

    if( $head2->{magic} ne 'TZif' )
    {
        die( "Invalid second TZif magic" );
    }

    if( $head2->{version} < 2 || $head2->{version} > 4 )
    {
        die( "Invalid second TZif version" );
    }

    $offset += 44;

    my( $block2, $after_block2 ) = _parse_tzif_data_block_at( \$blob, $offset, $head2, 8 );

    my $footer_tz = undef;
    if( $after_block2 < $len )
    {
        $footer_tz = _parse_tzif_footer_at( \$blob, $after_block2 );
    }

    # Mark v4 leap expiration
    unless( $head2->{version} < 4 || scalar( @{$block2->{leaps}} ) < 2 )
    {
        my $last = $block2->{leaps}->[-1];
        my $prev = $block2->{leaps}->[-2];

        if( $last->{correction} == $prev->{correction} )
        {
            $last->{is_expiration} = 1;
        }
    }

    return(
    {
        tzif_version => $head2->{version},
        header       => $head2,
        data         => $block2,
        footer_tz    => $footer_tz,
    });
}

sub _parse_tzif_data_block_at
{
    my( $blob, $offset, $h, $time_size ) = @_;

    my $need = _tzif_data_block_size( $h, $time_size );

    if( $offset + $need > length( $$blob ) )
    {
        die( "Incomplete data block at offset $offset" );
    }

    my $p = $offset;

    my @transition_times;
    for( my $i = 0; $i < $h->{timecnt}; $i++ )
    {
        push( @transition_times, _parse_tzif_time( $blob, \$p, $time_size ) );
    }

    my @transition_type_indexes;
    for( my $i = 0; $i < $h->{timecnt}; $i++ )
    {
        push( @transition_type_indexes, _u8( substr( $$blob, $p++, 1 ) ) );
    }

    my @types;
    for( my $i = 0; $i < $h->{typecnt}; $i++ )
    {
        my $utc_offset        = _i32be( substr( $$blob, $p,     4 ) );
        my $is_dst            = _u8( substr( $$blob, $p + 4, 1 ) ) ? 1 : 0;
        my $designation_index = _u8( substr( $$blob, $p + 5, 1 ) );

        $p += 6;

        push( @types, 
        {
            type_index        => $i,
            utc_offset        => $utc_offset,
            is_dst            => $is_dst,
            designation_index => $designation_index,
        });
    }

    my $designations = substr( $$blob, $p, $h->{charcnt} );
    $p += $h->{charcnt};

    foreach my $type ( @types )
    {
        my $offset = $type->{designation_index};
        # Reading C-string from buffer $designations at offset $offset
        if( $offset < 0 || $offset >= length( $designations ) )
        {
            die( "Designation offset out of range" );
        }
        my $nul = index( $designations, "\0", $offset );
        if( $nul < 0 )
        {
            die( "Missing NUL terminator in designation table" );
        }
        my $abbr = substr( $designations, $offset, $nul - $offset );

        $type->{abbreviation}   = $abbr;
        $type->{is_placeholder} = ( defined( $abbr ) && $abbr eq '-00' ) ? 1 : 0;
    }

    my @leaps;
    for( my $i = 0; $i < $h->{leapcnt}; $i++ )
    {
        my $occurrence_time = _parse_tzif_time( $blob, \$p, $time_size );
        my $corr            = _i32be( substr( $$blob, $p, 4 ) );

        $p += 4;

        push( @leaps,
        {
            leap_index      => $i,
            occurrence_time => $occurrence_time,
            correction      => $corr,
            is_expiration   => 0,
        });
    }

    my @isstd;
    for( my $i = 0; $i < $h->{isstdcnt}; $i++ )
    {
        push( @isstd, _u8( substr( $$blob, $p++, 1 ) ) ? 1 : 0 );
    }

    my @isut;
    for( my $i = 0; $i < $h->{isutcnt}; $i++ )
    {
        push( @isut, _u8( substr( $$blob, $p++, 1 ) ) ? 1 : 0 );
    }

    for( my $i = 0; $i < @types; $i++ )
    {
        $types[$i]->{is_standard_time} = $h->{isstdcnt} ? $isstd[$i] : undef;
        $types[$i]->{is_ut_time}       = $h->{isutcnt}  ? $isut[$i]  : undef;
    }

    my @transitions;
    for( my $i = 0; $i < $h->{timecnt}; $i++ )
    {
        my $type_index = $transition_type_indexes[$i];

        if( $type_index >= $h->{typecnt} )
        {
            die( "Transition type index out of range: $type_index" );
        }

        push( @transitions,
        {
            transition_index => $i,
            transition_time  => $transition_times[$i],
            type_index       => $type_index,
        });
    }

    return(
    {
        transitions => \@transitions,
        types       => \@types,
        leaps       => \@leaps,
    },
    $p );
}

sub _parse_tzif_footer_at
{
    my( $blob, $offset ) = @_;

    my $rest = substr( $$blob, $offset );

    return( undef ) if( !length( $rest ) );

    if( substr( $rest, 0, 1 ) ne "\n" )
    {
        die( "Invalid TZif footer start" );
    }

    if( substr( $rest, -1, 1 ) ne "\n" )
    {
        die( "Invalid TZif footer end" );
    }

    my $tz = substr( $rest, 1, length( $rest ) - 2 );
    return( length( $tz ) ? $tz : '' );
}

sub _parse_tzif_header_at
{
    my( $blob, $offset ) = @_;

    my $hdr = substr( $$blob, $offset, 44 );

    if( length( $hdr ) != 44 )
    {
        die( "Incomplete header at offset $offset" );
    }

    my $magic = substr( $hdr, 0, 4 );
    my $verch = substr( $hdr, 4, 1 );

    my $version;
    if( $verch eq "\0" )
    {
        $version = 1;
    }
    elsif( $verch =~ /^[234]$/ )
    {
        $version = int( $verch );
    }
    else
    {
        die( "Unsupported TZif version byte at offset $offset" );
    }

    my $isutcnt  = _u32be( substr( $hdr, 20, 4 ) );
    my $isstdcnt = _u32be( substr( $hdr, 24, 4 ) );
    my $leapcnt  = _u32be( substr( $hdr, 28, 4 ) );
    my $timecnt  = _u32be( substr( $hdr, 32, 4 ) );
    my $typecnt  = _u32be( substr( $hdr, 36, 4 ) );
    my $charcnt  = _u32be( substr( $hdr, 40, 4 ) );

    my $head =
    {
        magic    => $magic,
        version  => $version,
        isutcnt  => $isutcnt,
        isstdcnt => $isstdcnt,
        leapcnt  => $leapcnt,
        timecnt  => $timecnt,
        typecnt  => $typecnt,
        charcnt  => $charcnt,
    };

    if( !$head->{typecnt} )
    {
        die( "TZif typecnt must not be zero" );
    }

    if( $head->{isutcnt} != 0 &&
        $head->{isutcnt} != $head->{typecnt} )
    {
        die( "TZif isutcnt must be 0 or equal to typecnt" );
    }

    if( $head->{isstdcnt} != 0 &&
        $head->{isstdcnt} != $head->{typecnt} )
    {
        die( "TZif isstdcnt must be 0 or equal to typecnt" );
    }

    return( $head );
}

sub _parse_tzif_time
{
    my( $blob, $pos_ref, $time_size ) = @_;
    my $v;

    if( $time_size == 4 )
    {
        $v = _i32be( substr( $$blob, $$pos_ref, 4 ) );
    }
    elsif( $time_size == 8 )
    {
        $v = _i64be( substr( $$blob, $$pos_ref, 8 ) );
    }
    else
    {
        die( "Unsupported time size: $time_size" );
    }

    $$pos_ref += $time_size;
    return( $v );
}

sub _read_iso3166_tab
{
    my $file = shift( @_ );
    $file->open( '<', { binmode => 'utf-8' } ) || die( "Unable to read $file: ", $file->error );
    my $ref;
    while( my $line = $file->getline( chomp => 1 ) )
    {
        next if( $line =~ /^[[:blank:]\h]*#/ );
        next if( $line =~ /^[[:blank:]\h]*$/ );

        my( $code, $name ) = split( /\t/, $line, 2 );

        unless( defined( $code ) && defined( $name ) )
        {
            die( "Malformed iso3166.tab line: $line" );
        }

        $ref->{ $code } =
        {
            code => uc( $code ),  # Ensure the code is in upper case, which should already be the case.
            name => $name,
        };
    }
    $file->close;
    return( $ref );
}

# L = link
# R = rule
# Z = timezone
#
# The long documented forms are:
# Rule  NAME  FROM  TO  TYPE  IN  ON  AT   SAVE  LETTER/S
# Zone  NAME  STDOFF  RULES   FORMAT [UNTIL]
# Link  TARGET LINK-NAME
sub _read_tzdata_zi
{
    my $file = shift( @_ );
    $file->open( '<', { binmode => 'utf-8' } ) || die( "Unable to read $file: ", $file->error );
    my $zones = {};
    my $links = {};
    while( my $line = $file->getline( chomp => 1 ) )
    {
        $line =~ s/\r$//;
        next if( $line =~ /^[[:blank:]\h]*#/ );
        next if( $line =~ /^[[:blank:]\h]*$/ );

        my $work = $line;
        $work =~ s/\s+#.*$//;

        if( $work =~ /^Z\s+(\S+)/ )
        {
            $zones->{ $1 } = 1
        }
        elsif( $work =~ /^L\s+(\S+)\s+(\S+)/ )
        {
            $links->{ $2 } = $1;
        }
    }
    $file->close;

    # Also collect symlink aliases created by zic / rdfind
    $zoneinfo_dir->find(sub
    {
        my $real = shift( @_ );
        return unless( $real->is_link );
        my $alias = $real->relative( "$zoneinfo_dir" );
        return if( $alias =~ m{^(?:posix|right)/|^\.} );
        my $target = $real->readlink->relative( "$zoneinfo_dir" );
        $links->{ $alias } //= $target if( exists( $zones->{ $target } ) );
    });

    return(
    {
        zones => $zones,
        links => $links,
    });
}

# _read_tz_version( $dir )
sub _read_tz_version
{
    my $dir = shift( @_ );
    foreach my $candidate ( $dir->child( 'tzdata.zi' ), $dir->child( 'version' ) )
    {
        next unless( $candidate->exists );
        $candidate->open( '<' ) || next;
        while( defined( $_ = $candidate->getline( chomp => 1 ) ) )
        {
            # Example: # version 2025b
            return( $1 ) if( /^#[[:blank:]\h]*version[[:blank:]\h]+(\S+)/ );
            return( $1 ) if( /^(\d{4}[a-z]+)$/ );
        }
        $candidate->close;
    }
    return( 'unknown' );
}

sub _read_zone1970_tab
{
    my $file  = shift( @_ );
    $file->open( '<', { binmode => 'utf-8' } ) || die( "Unable to read $file: ", $file->error );
    my $zones = {};
    # For more meaningful error reporting
    my $n = 0;
    while( my $line = $file->getline( chomp => 1 ) )
    {
        $n++;
        next if( $line =~ /^[[:blank:]\h]*#/ );
        next if( $line =~ /^[[:blank:]\h]*$/ );

        my @cols = split( /\t/, $line, 4 );

        my $country_list = $cols[0];
        my $coords       = $cols[1];
        my $zone_name    = $cols[2];
        my $comment      = defined( $cols[3] ) ? $cols[3] : undef;

        unless( defined( $country_list ) &&
                defined( $coords ) &&
                defined( $zone_name ) )
        {
            die( "Malformed zone1970.tab at line $n: $line" );
        }

        my( $latitude, $longitude ) = _parse_compact_coordinates( $coords );
        my @countries  = split( /,/, $country_list );
        my $country_re = qr/^[A-Za-z]{2}$/;
        for( my $i = 0; $i < scalar( @countries ); $i++ )
        {
            unless( $countries[$i] =~ $country_re )
            {
                die( "Invalid ISO country code at line $n: ", $countries[$i] );
            }
            # Although, it should already be the case, we ensure the country codes are in uppercase.
            $countries[$i] = uc( $countries[$i] );
        }

        $zones->{ $zone_name } =
        {
            name        => $zone_name,
            countries   => \@countries,
            coordinates => $coords,
            latitude    => $latitude,
            longitude   => $longitude,
            comment     => $comment,
        };
    }
    $file->close;
    return( $zones );
}

# _resolve_tarball()
# Returns path to a local .tar.gz file, downloading from IANA if needed.
sub _resolve_tarball
{
    my $file = shift( @_ );
    my $type;
    $type = shift( @_ ) if( @_ );
    if( $file )
    {
        if( $file->exists )
        {
            _message( 1, "Tarball      : <green>$file</> (provided)" );
            return( $file );
        }
        elsif( !$file && $file->basename =~ /^tz(code|data)/ )
        {
            $type = $1;
        }
        else
        {
            die( "Unknown tarball file provided '$file'" );
        }
    }


    $cache_dir->mkpath unless( $cache_dir->exists );    
    my $version = $opts->{tz_version};
    unless( $tz_version )
    {
        if( $file && $file->basename =~ /^tz(?:code|data)(\d{4}[a-z])\./ )
        {
            $version = $1;
            _message( 3, "Derived timezone version from filename -> <green>$tz_version</>" );
        }
        # Maybe the filename is tzdata-latest.tar.gz or tzcode-latest.tar.gz
        else
        {
            _message( 3, "Fetching the latest version information." );
            $version = _fetch_latest_version() ||
                die( "Failed to get the latest version of tz code and data." );
        }
    }

    _message( 1, "TZ version   : <green>$version</> (target) and type <green>$type</>" );
    unless( $type )
    {
        die( "No type found or provided." );
    }

    my $filename = "tz${type}${version}.tar.gz";
    my $cached   = $cache_dir->child( $filename );

    # Do we have a cached version already, maybe from previous attempts?
    if( $cached->exists && !$cached->is_empty )
    {
        _message( 1, "Cache hit    : <green>$cached</>" );
        _verify_signature( $cached ) unless( $opts->{skip_verify} );
        return( $cached );
    }

    # Download tarball
    my $url = IANA_RELEASES . "/$filename";
    _message( 1, "Downloading  : <green>$url</>" );
    if( $opts->{proto} eq 'ftp' )
    {
        _download_ftp( $url, $cached );
    }
    else
    {
        _download_web( $url, $cached );
    }

    # Download and verify GPG signature
    unless( $opts->{skip_verify} )
    {
        my $asc = file( "$cached.asc" );
        _message( 1, "Downloading  : <green>$url.asc</>" );
        if( $opts->{proto} eq 'ftp' )
        {
            _download_ftp( "$url.asc", $asc );
        }
        else
        {
            _download_web( "$url.asc", $asc );
        }
        _verify_signature( $cached );
    }

    return( $cached );
}

sub _resolve_tarball_code { return( _resolve_tarball( $opts->{tarball_code}, 'code' ) ); }

sub _resolve_tarball_data { return( _resolve_tarball( $opts->{tarball_data}, 'data' ) ); }

sub _signal_handler
{
    my( $sig ) = @_;
    &_message( "Caught a $sig signal, terminating process $$" );
    if( uc( $sig ) eq 'TERM' )
    {
        &_cleanup_and_exit(0);
    }
    else
    {
        &_cleanup_and_exit(1);
    }
}

sub _to_array
{
    my $ref = shift( @_ );
    if( defined( $ref ) &&
        ref( $ref ) ne 'ARRAY' )
    {
        die( "Value provided (", overload::StrVal( $ref ), ") is not an array." );
    }
    # Translated as NULL in SQLite
    elsif( !defined( $ref ) )
    {
        return( undef );
    }
    elsif( !scalar( @$ref ) )
    {
        return( undef );
    }
    else
    {
        # return( '{' . join( ', ', map( ( looks_like_number( $_ ) ? $_ : q{"} . $_ . q{"} ), @$ref ) ) . '}' );
        # return( '[' . join( ', ', map( ( q{"} . $_ . q{"} ), @$ref ) ) . ']' );
        local $@;
        my $encoded = eval{
            $json->encode( $ref );
        } || die( "Unable to encode array to JSON for array values @$ref: $@" );
        return( $encoded );
    }
}

sub _tzif_data_block_size
{
    my( $h, $time_size ) = @_;

    return(
        $h->{timecnt} * $time_size +
        $h->{timecnt} +
        $h->{typecnt} * 6 +
        $h->{charcnt} +
        $h->{leapcnt} * ( $time_size + 4 ) +
        $h->{isstdcnt} +
        $h->{isutcnt}
    );
}

sub _u8
{
    my( $s ) = @_;
    return( unpack( 'C', $s ) );
}

sub _u32be
{
    my( $s ) = @_;
    return( unpack( 'N', $s ) );
}

# _version_from_tarball( $tarball )
# Extracts the tzdata version string from the Makefile inside the tarball.
sub _version_from_tarball
{
    my $tarball = file( shift( @_ ) );

    my $tar = _has_tool('tar') ||
        die( "Unable to find tar on your system." );
    # VERSION= line in the Makefile
    my $makefile = qx( $tar -xOf "$tarball" Makefile 2>/dev/null ) // '';
    if( $makefile =~ /^VERSION[[:blank:]\h]*=[[:blank:]\h]*(\S+)/m )
    {
        return( $1 );
    }

    # Fallback: parse from the tarball filename
    my $basename = $tarball->basename;
    if( $basename =~ /tzdata(\d{4}[a-z]+)\.tar\.gz/ )
    {
        return( $1 );
    }

    die( "Cannot determine tzdata version from '$tarball'.\n" );
}

# _verify_signature( $tarball )
# Verifies the GPG signature $tarball.asc against $tarball.
# Non-fatal if gpg is absent or the key cannot be fetched.
sub _verify_signature
{
    my $tarball = shift( @_ );
    my $asc     = file( "$tarball.asc" );
    _message( 2, "Verifying tarball signature with <green>$asc</>" );

    my $gpg = _has_tool('gpg');
    unless( $gpg )
    {
        warn( "  gpg not found; skipping signature verification.\n" );
        return;
    }
    unless( $asc->exists )
    {
        warn( "  Signature file '$asc' not found; skipping verification.\n" );
        return;
    }

    # Try to ensure the IANA signing key is available.
    # Paul Eggert's current key: ED97E90E62AA7E34
    my $key_id = 'ED97E90E62AA7E34';
    unless( qx( gpg --list-keys "$key_id" 2>/dev/null ) =~ /$key_id/i )
    {
        _message( 1, "  Importing IANA signing key $key_id..." );
        system( $gpg,
            '--keyserver', 'keys.openpgp.org',
            '--recv-keys', $key_id
        ) == 0 || warn( "Warning only: error calling $gpg to import IANA public key: exit ", ( $? >> 8 ) );
        # Non-fatal: key servers may be unreachable
    }

    _message( 1, "  Verifying GPG signature with: $gpg --verify $asc $tarball" );
    if( system( $gpg, '--verify', $asc, $tarball ) )
    {
        warn( "  GPG signature verification FAILED for '$tarball'.\n"
            . "  Proceeding; verify manually if this concerns you.\n" );
    }
    else
    {
        _message( 1, "  Signature OK." );
    }
}

__END__

=encoding utf8

=head1 NAME

build_tz_database.pl - Build the DateTime::Lite::TimeZone SQLite database

=head1 SYNOPSIS

    # Fetch latest tzdata from IANA, compile, build database:
    perl scripts/build_tz_database.pl [--verbose]

    # Specific version:
    perl scripts/build_tz_database.pl --tz-version 2026a

    # Already-downloaded tarball:
    perl scripts/build_tz_database.pl --tarball /path/to/tzdata2026a.tar.gz

    # Use system zoneinfo (no download):
    perl scripts/build_tz_database.pl --zoneinfo /usr/share/zoneinfo

=head1 DESCRIPTION

Builds the SQLite timezone database bundled with L<DateTime::Lite::TimeZone>.

B<Primary mode> downloads the latest (or specified) tzdata release directly from IANA (L<https://ftp.iana.org/tz/releases/>), verifies the GPG signature, compiles the Olson source files with C<zic(1)>, and parses the resulting TZif binary files (RFC 8536). Downloaded tarballs are cached under C<~/.cache/dtl-tzdata/> to avoid redundant downloads.

B<Fallback mode> (C<--zoneinfo>) reads TZif files from a local compiled zoneinfo directory instead of downloading. Useful when IANA is unreachable or for quick local rebuilds from the installed system timezone data.

Run this script whenever a new tzdata release is available, then commit the updated C<lib/DateTime/Lite/tz.sqlite3>.

=head1 OPTIONS

=over 4

=item C<--tz-version> I<version>

Target a specific tzdata version such as C<2026a>. Defaults to the latest version found on the IANA releases page.

=item C<--tarball> I<file>

Use an already-downloaded C<tzdata*.tar.gz> file, skipping the download.

=item C<--zoneinfo> I<directory>

Use a local compiled zoneinfo directory instead of downloading from IANA.

=item C<--db> I<file>

Output database path. Defaults to C<lib/DateTime/Lite/tz.sqlite3> relative to the distribution root.

=item C<--cache-dir> I<directory>

Where to store cached tarballs. Defaults to C<~/.cache/dtl-tzdata/>.

=item C<--skip-verify>

Skip GPG signature verification. Not recommended for production.

=item C<--verbose>

Print one line per timezone as it is processed.

=back

=head1 REQUIREMENTS

Always required: C<zic(1)> (from the C<tzdata> or C<tz-utils> system package), L<DBI>, L<DBD::SQLite> >= 1.27.

For primary mode: C<curl(1)> or C<wget(1)>.

Recommended: C<gpg(1)> for signature verification.

Optional (non-fatal if absent): C<rdfind(1)> for deduplication, C<symlinks(1)> for relative symlink conversion.

=head1 EPOCH CONVERSION

TZif transition times are stored as seconds since the Unix epoch (1970-01-01T00:00:00 UTC). L<DateTime> uses seconds since the Rata Die epoch (0001-01-01T00:00:00). The constant C<UNIX_TO_RD = 62_135_683_200> converts between them.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
