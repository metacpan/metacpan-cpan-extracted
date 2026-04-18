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
        aliases          => "INSERT INTO aliases          (alias, zone_id) VALUES(?, ?)",
        countries        => "INSERT INTO countries        (code, name) VALUES(?, ?)",
        extended_aliases => "INSERT INTO extended_aliases (abbreviation, zone_id, is_primary, comment) SELECT ?, zone_id, ?, ? FROM zones WHERE name = ?",
        leap_second      => "INSERT INTO leap_second      (zone_id, leap_index, occurrence_time, correction, is_expiration) VALUES(?, ?, ?, ?, ?)",
        metadata         => "INSERT INTO metadata         (key, value) VALUES(?, ?)",
        spans            => "INSERT INTO spans            (zone_id, type_id, span_index, utc_start, utc_end, local_start, local_end, offset, is_dst, short_name) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
        transition       => "INSERT INTO transition       (zone_id, trans_index, trans_time, type_id) VALUES(?, ?, ?, ?)",
        types            => "INSERT INTO types            (zone_id, type_index, utc_offset, is_dst, abbreviation, designation_index, is_standard_time, is_ut_time, is_placeholder) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?)",
        zones            => "INSERT INTO zones            (name, canonical, has_dst, countries, coordinates, latitude, longitude, comment, tzif_version, footer_tz_string, transition_count, type_count, leap_count, isstd_count, isut_count, designation_charcount, category, subregion, location) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
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

    # NOTE: Timezones aliases, including historic outdated ones
    my $aliases = 
    {
        # NOTE: A
        A     => { comment => "Alpha Military Time Zone", timezones => ['Etc/GMT-1'] },
        ACDT  => { comment => "Australian Central Daylight Saving Time", timezones => ['Australia/Adelaide', 'Australia/Darwin'] },
        ACST  => { comment => "Australian Central Standard Time", timezones => ['Australia/Darwin', 'Australia/Adelaide'] },
        ACT   => { comment => "ASEAN Common Time", timezones => ['Asia/Singapore'] },
        ACWST => { comment => "Australian Central Western Standard Time", timezones => ['Australia/Eucla'] },
        ADT   => { comment => "Atlantic Daylight Time", timezones => ['America/Halifax', 'America/Glace_Bay', 'America/Moncton', 'America/Thule', 'Atlantic/Bermuda'] },
        AEDT  => { comment => "Australian Eastern Daylight Saving Time", timezones => ['Australia/Sydney', 'Australia/Melbourne', 'Australia/Hobart', 'Australia/Lord_Howe'] },
        AES   => { comment => "Australian Eastern Standard Time", timezones => ['Australia/Brisbane'] },
        AEST  => { comment => "Australian Eastern Standard Time", timezones => ['Australia/Brisbane', 'Australia/Sydney', 'Australia/Melbourne'] },
        AET   => { comment => "Australian Eastern Time", timezones => ['Australia/Sydney', 'Australia/Brisbane'] },
        AFT   => { comment => "Afghanistan Time", timezones => ['Asia/Kabul'] },
        AHDT  => { comment => "Alaska-Hawaii Daylight Time", timezones => ['America/Adak'] },
        AHST  => { comment => "Alaska-Hawaii Standard Time", timezones => ['Pacific/Honolulu'] },
        AKDT  => { comment => "Alaska Daylight Time", timezones => ['America/Anchorage', 'America/Juneau', 'America/Nome', 'America/Sitka', 'America/Yakutat'] },
        AKST  => { comment => "Alaska Standard Time", timezones => ['America/Anchorage', 'America/Juneau', 'America/Nome', 'America/Sitka', 'America/Yakutat'] },
        ALMT  => { comment => "Alma-Ata Time", timezones => ['Asia/Almaty'] },
        AMST  => { comment => "Amazon Summer Time (Brazil)", timezones => ['America/Manaus', 'America/Boa_Vista'] },
        AMT   => { comment => "Armenia Time", timezones => ['America/Manaus', 'Asia/Yerevan'] },
        ANAST => { comment => "Anadyr Summer Time", timezones => ['Asia/Anadyr'] },
        ANAT  => { comment => "Anadyr Time", timezones => ['Asia/Anadyr'] },
        AQTT  => { comment => "Aqtobe Time", timezones => ['Asia/Aqtau'] },
        ART   => { comment => "Argentina Time", timezones => ['America/Argentina/Buenos_Aires'] },
        AST   => { comment => "Atlantic Standard Time", timezones => ['America/Halifax', 'America/Puerto_Rico', 'America/Santo_Domingo', 'America/Barbados', 'Asia/Riyadh', 'Asia/Kuwait', 'Asia/Baghdad'] },
        AT    => { comment => "Azores Time", timezones => ['Atlantic/Azores'] },
        AWST  => { comment => "Australian Western Standard Time", timezones => ['Australia/Perth'] },
        AZOST => { comment => "Azores Summer Time", timezones => ['Atlantic/Azores'] },
        AZOT  => { comment => "Azores Standard Time", timezones => ['Atlantic/Azores'] },
        AZST  => { comment => "Azerbaijan Summer Time", timezones => ['Asia/Baku'] },
        AZT   => { comment => "Azerbaijan Time", timezones => ['Asia/Baku'] },

        # NOTE: B
        B     => { comment => "Bravo Military Time Zone", timezones => ['Etc/GMT-2'] },
        BADT  => { comment => "Baghdad Daylight Time", timezones => ['Asia/Baghdad'] },
        BAT   => { comment => "Baghdad Time", timezones => ['Asia/Baghdad'] },
        BDST  => { comment => "British Double Summer Time", timezones => ['Europe/London'] },
        BDT   => { comment => "Bangladesh Time", timezones => ['Asia/Dhaka'] },
        BET   => { comment => "Bering Standard Time", timezones => ['Etc/GMT+11'] },
        BIOT  => { comment => "British Indian Ocean Time", timezones => ['Indian/Chagos'] },
        BIT   => { comment => "Baker Island Time", timezones => ['Etc/GMT+12'] },
        BNT   => { comment => "Brunei Time", timezones => ['Asia/Brunei'] },
        BORT  => { comment => "Borneo Time (Indonesia)", timezones => ['Asia/Kuching'] },
        BOT   => { comment => "Bolivia Time", timezones => ['America/La_Paz'] },
        BRA   => { comment => "Brazil Time", timezones => ['America/Sao_Paulo'] },
        BRST  => { comment => "Brasília Summer Time", timezones => ['America/Sao_Paulo', 'America/Fortaleza'] },
        BRT   => { comment => "Brasília Time", timezones => ['America/Sao_Paulo', 'America/Fortaleza', 'America/Belem', 'America/Recife', 'America/Maceio'] },
        BST   => { comment => "British Summer Time (British Standard Time from Feb 1968 to Oct 1971)", timezones => ['Europe/London', 'Pacific/Pago_Pago'] },
        BTT   => { comment => "Bhutan Time", timezones => ['Asia/Thimphu'] },

        # NOTE: C
        C     => { comment => "Charlie Military Time Zone", timezones => ['Etc/GMT-3'] },
        CAST  => { comment => "Casey Time Zone", timezones => ['Antarctica/Casey'] },
        CAT   => { comment => "Central Africa Time", timezones => ['Africa/Harare', 'Africa/Maputo', 'Africa/Lusaka', 'Africa/Blantyre', 'Africa/Bujumbura', 'Africa/Gaborone', 'Africa/Kigali', 'Africa/Lubumbashi'] },
        CCT   => { comment => "Cocos Islands Time", timezones => ['Indian/Cocos'] },
        CDT   => { comment => "Cuba Daylight Time", timezones => ['America/Chicago', 'America/Winnipeg', 'America/Havana'] },
        CEST  => { comment => "Central European Summer Time", timezones => ['Europe/Paris', 'Europe/Berlin', 'Europe/Rome', 'Europe/Madrid', 'Europe/Warsaw', 'Europe/Amsterdam', 'Europe/Brussels', 'Europe/Copenhagen', 'Europe/Oslo', 'Europe/Stockholm', 'Europe/Vienna', 'Europe/Zurich'] },
        CETDST=> { comment => "Central Europe Summer Time", timezones => ['Europe/Paris', 'Europe/Berlin'] },
        CET   => { comment => "Central European Time", timezones => ['Europe/Paris', 'Europe/Berlin', 'Europe/Rome', 'Europe/Madrid', 'Europe/Warsaw', 'Europe/Amsterdam'] },
        CHADT => { comment => "Chatham Daylight Time", timezones => ['Pacific/Chatham'] },
        CHAST => { comment => "Chatham Standard Time", timezones => ['Pacific/Chatham'] },
        CHOST => { comment => "Choibalsan Summer Time", timezones => ['Asia/Choibalsan'] },
        CHOT  => { comment => "Choibalsan Standard Time", timezones => ['Asia/Choibalsan'] },
        CHST  => { comment => "Chamorro Standard Time", timezones => ['Pacific/Guam', 'Pacific/Saipan'] },
        CHUT  => { comment => "Chuuk Time", timezones => ['Pacific/Chuuk'] },
        CIST  => { comment => "Clipperton Island Standard Time", timezones => ['Pacific/Pitcairn'] },
        CKT   => { comment => "Cook Island Time", timezones => ['Pacific/Rarotonga'] },
        CLST  => { comment => "Chile Summer Time", timezones => ['America/Santiago'] },
        CLT   => { comment => "Chile Standard Time", timezones => ['America/Santiago'] },
        COST  => { comment => "Colombia Summer Time", timezones => ['America/Bogota'] },
        COT   => { comment => "Colombia Time", timezones => ['America/Bogota'] },
        CST   => { comment => "Cuba Standard Time", timezones => ['America/Chicago', 'America/Winnipeg', 'Asia/Shanghai', 'Asia/Taipei', 'Asia/Macau', 'Asia/Hong_Kong', 'America/Havana', 'Australia/Darwin', 'Australia/Adelaide'] },
        # Australian Central Daylight (variant of ACDT)
        CSUT  => { comment => "Australian Central Daylight", timezones => ['Australia/Adelaide'] },
        CT    => { comment => "Central Time", timezones => ['America/Chicago', 'America/Winnipeg'] },
        CUT   => { comment => "Coordinated Universal Time", timezones => ['Etc/UTC'] },
        CVT   => { comment => "Cape Verde Time", timezones => ['Atlantic/Cape_Verde'] },
        CWST  => { comment => "Central Western Standard Time (Australia)", timezones => ['Australia/Eucla'] },
        CXT   => { comment => "Christmas Island Time", timezones => ['Indian/Christmas'] },

        # NOTE: D
        D     => { comment => "Delta Military Time Zone", timezones => ['Etc/GMT-4'] },
        DAVT  => { comment => "Davis Time", timezones => ['Antarctica/Davis'] },
        DDUT  => { comment => "Dumont d'Urville Time", timezones => ['Antarctica/DumontDUrville'] },
        DFT   => { comment => "AIX-specific equivalent of Central European Time", timezones => ['Europe/Paris'] },
        DNT   => { comment => "Dansk Normal", timezones => ['Europe/Oslo'] },
        DST   => { comment => "Dansk Summer", timezones => ['Europe/Copenhagen'] },

        # NOTE: E
        E     => { comment => "Echo Military Time Zone", timezones => ['Etc/GMT-5'] },
        EASST => { comment => "Easter Island Summer Time", timezones => ['Pacific/Easter'] },
        EAST  => { comment => "Easter Island Standard Time", timezones => ['Pacific/Easter'] },
        EAT   => { comment => "East Africa Time", timezones => ['Africa/Nairobi', 'Africa/Addis_Ababa', 'Africa/Asmara', 'Africa/Dar_es_Salaam', 'Africa/Djibouti', 'Africa/Kampala', 'Africa/Mogadishu', 'Indian/Antananarivo', 'Indian/Comoro', 'Indian/Mayotte'] },
        ECT   => { comment => "Ecuador Time", timezones => ['America/Guayaquil', 'Pacific/Galapagos'] },
        EDT   => { comment => "Eastern Daylight Time (North America)", timezones => ['America/New_York', 'America/Detroit', 'America/Toronto', 'America/Montreal'] },
        EEST  => { comment => "Eastern European Summer Time", timezones => ['Europe/Athens', 'Europe/Helsinki', 'Europe/Kyiv', 'Europe/Tallinn', 'Europe/Vilnius', 'Europe/Riga', 'Europe/Sofia', 'Europe/Bucharest', 'Europe/Chisinau', 'Europe/Istanbul', 'Asia/Nicosia', 'Asia/Beirut', 'Asia/Damascus', 'Asia/Amman', 'Asia/Jerusalem', 'Africa/Cairo'] },
        EETDST=> { comment => "European Eastern Summer", timezones => ['Europe/Athens', 'Europe/Helsinki'] },
        EET   => { comment => "Eastern European Time", timezones => ['Europe/Athens', 'Europe/Helsinki', 'Europe/Kyiv', 'Europe/Tallinn', 'Europe/Vilnius', 'Europe/Riga', 'Europe/Sofia', 'Europe/Bucharest', 'Europe/Chisinau', 'Europe/Istanbul', 'Asia/Nicosia', 'Africa/Cairo', 'Africa/Tripoli'] },
        EGST  => { comment => "Eastern Greenland Summer Time", timezones => ['America/Scoresbysund'] },
        EGT   => { comment => "Eastern Greenland Time", timezones => ['America/Scoresbysund'] },
        EMT   => { comment => "Norway Time", timezones => ['Europe/Oslo'] },
        EST   => { comment => "Eastern Standard Time (North America)", timezones => ['America/New_York', 'America/Detroit', 'America/Toronto', 'America/Indiana/Indianapolis', 'America/Kentucky/Louisville', 'America/Jamaica', 'America/Panama'] },
        ESUT  => { comment => "Australian Eastern Daylight", timezones => ['Australia/Sydney'] },
        ET    => { comment => "Eastern Time (North America)", timezones => ['America/New_York'] },

        # NOTE: F
        F     => { comment => "Foxtrot Military Time Zone", timezones => ['Etc/GMT-6'] },
        FET   => { comment => "Further-eastern European Time", timezones => ['Europe/Kaliningrad', 'Europe/Minsk'] },
        FJST  => { comment => "Fiji Summer Time", timezones => ['Pacific/Fiji'] },
        FJT   => { comment => "Fiji Time", timezones => ['Pacific/Fiji'] },
        FKST  => { comment => "Falkland Islands Summer Time", timezones => ['Atlantic/Stanley'] },
        FKT   => { comment => "Falkland Islands Time", timezones => ['Atlantic/Stanley'] },
        FNT   => { comment => "Fernando de Noronha Time", timezones => ['America/Noronha'] },
        FWT   => { comment => "French Winter Time", timezones => ['Europe/Paris'] },

        # NOTE: G
        G     => { comment => "Golf Military Time Zone", timezones => ['Etc/GMT-7'] },
        GALT  => { comment => "Galapagos Time", timezones => ['Pacific/Galapagos'] },
        GAMT  => { comment => "Gambier Islands Time", timezones => ['Pacific/Gambier'] },
        GEST  => { comment => "Georgia Summer Time", timezones => ['Asia/Tbilisi'] },
        GET   => { comment => "Georgia Standard Time", timezones => ['Asia/Tbilisi'] },
        GFT   => { comment => "French Guiana Time", timezones => ['America/Cayenne'] },
        GILT  => { comment => "Gilbert Island Time", timezones => ['Pacific/Tarawa'] },
        GIT   => { comment => "Gambier Island Time", timezones => ['Pacific/Gambier'] },
        GMT   => { comment => "Greenwich Mean Time", timezones => ['Etc/GMT', 'Europe/London', 'Africa/Abidjan', 'Africa/Accra', 'Africa/Monrovia', 'Atlantic/Reykjavik'] },
        GST   => { comment => "Gulf Standard Time", timezones => ['Asia/Dubai', 'Asia/Muscat', 'Atlantic/South_Georgia'] },
        GT    => { comment => "Greenwich Time", timezones => ['Etc/GMT'] },
        GYT   => { comment => "Guyana Time", timezones => ['America/Guyana'] },
        GZ    => { comment => "Greenwichzeit", timezones => ['Etc/GMT'] },

        # NOTE: H
        H     => { comment => "Hotel Military Time Zone", timezones => ['Etc/GMT-8'] },
        HAA   => { comment => "Heure Avancée de l'Atlantique", timezones => ['America/Halifax'] },
        HAC   => { comment => "Heure Avancee du Centre", timezones => ['America/Winnipeg'] },
        HAE   => { comment => "Heure Avancee de l'Est", timezones => ['America/New_York'] },
        HAEC  => { comment => "Heure Avancée d'Europe Centrale", timezones => ['Europe/Paris'] },
        HAP   => { comment => "Heure Avancee du Pacifique", timezones => ['America/Vancouver'] },
        HAR   => { comment => "Heure Avancee des Rocheuses", timezones => ['America/Denver'] },
        HAT   => { comment => "Heure Avancee de Terre-Neuve", timezones => ['America/St_Johns'] },
        HAY   => { comment => "Heure Avancee du Yukon", timezones => ['America/Anchorage'] },
        HDT   => { comment => "Hawaii–Aleutian Daylight Time", timezones => ['America/Adak'] },
        HFE   => { comment => "Heure Fancais d'Ete", timezones => ['Europe/Paris'] },
        HFH   => { comment => "Heure Fancais d'Hiver", timezones => ['Europe/Paris'] },
        HG    => { comment => "Heure de Greenwich", timezones => ['Etc/GMT'] },
        HKT   => { comment => "Hong Kong Time", timezones => ['Asia/Hong_Kong'] },
        # HL is skipped, because there is no IANA equivalent
        HMT   => { comment => "Heard and McDonald Islands Time", timezones => ['Indian/Kerguelen'] },
        HNA   => { comment => "Heure Normale de l'Atlantique", timezones => ['America/Halifax'] },
        HNC   => { comment => "Heure Normale du Centre", timezones => ['America/Winnipeg'] },
        HNE   => { comment => "Heure Normale de l'Est", timezones => ['America/New_York'] },
        HNP   => { comment => "Heure Normale du Pacifique", timezones => ['America/Vancouver'] },
        HNR   => { comment => "Heure Normale des Rocheuses", timezones => ['America/Denver'] },
        HNT   => { comment => "Heure Normale de Terre-Neuve", timezones => ['America/St_Johns'] },
        HNY   => { comment => "Heure Normale du Yukon", timezones => ['America/Anchorage'] },
        HOE   => { comment => "Spain Time", timezones => ['Europe/Madrid'] },
        HOVST => { comment => "Hovd Summer Time (not used from 2017-present)", timezones => ['Asia/Hovd'] },
        HOVT  => { comment => "Hovd Time", timezones => ['Asia/Hovd'] },
        HST   => { comment => "Hawaii–Aleutian Standard Time", timezones => ['Pacific/Honolulu', 'Pacific/Johnston'] },

        # NOTE: I
        I     => { comment => "India Military Time Zone", timezones => ['Etc/GMT-9'] },
        ICT   => { comment => "Indochina Time", timezones => ['Asia/Bangkok', 'Asia/Ho_Chi_Minh', 'Asia/Phnom_Penh', 'Asia/Vientiane'] },
        IDLE  => { comment => "Internation Date Line East", timezones => ['Etc/GMT-12'] },
        IDLW  => { comment => "International Day Line West time zone", timezones => ['Etc/GMT+12'] },
        IDT   => { comment => "Israel Daylight Time", timezones => ['Asia/Jerusalem'] },
        IOT   => { comment => "Indian Ocean Time", timezones => ['Indian/Chagos'] },
        IRDT  => { comment => "Iran Daylight Time", timezones => ['Asia/Tehran'] },
        IRKST => { comment => "Irkutsk Summer Time", timezones => ['Asia/Irkutsk'] },
        IRKT  => { comment => "Irkutsk Time", timezones => ['Asia/Irkutsk'] },
        IRST  => { comment => "Iran Standard Time", timezones => ['Asia/Tehran'] },
        IRT   => { comment => "Iran Time", timezones => ['Asia/Tehran'] },
        IST   => { comment => "Israel Standard Time", timezones => ['Asia/Kolkata', 'Europe/Dublin', 'Asia/Jerusalem'] },
        IT    => { comment => "Iran Time", timezones => ['Asia/Tehran'] },
        ITA   => { comment => "Italy Time", timezones => ['Europe/Rome'] },

        # NOTE: J
        JAVT  => { comment => "Java Time", timezones => ['Asia/Jakarta'] },
        JAYT  => { comment => "Jayapura Time (Indonesia)", timezones => ['Asia/Jayapura'] },
        JST   => { comment => "Japan Standard Time", timezones => ['Asia/Tokyo'] },
        JT    => { comment => "Java Time", timezones => ['Asia/Jakarta'] },

        # NOTE: K
        K     => { comment => "Kilo Military Time Zone", timezones => ['Etc/GMT-10'] },
        KALT  => { comment => "Kaliningrad Time", timezones => ['Europe/Kaliningrad'] },
        KDT   => { comment => "Korean Daylight Time", timezones => ['Asia/Seoul'] },
        KGST  => { comment => "Kyrgyzstan Summer Time", timezones => ['Asia/Bishkek'] },
        KGT   => { comment => "Kyrgyzstan Time", timezones => ['Asia/Bishkek'] },
        KOST  => { comment => "Kosrae Time", timezones => ['Pacific/Kosrae'] },
        KRAST => { comment => "Krasnoyarsk Summer Time", timezones => ['Asia/Krasnoyarsk'] },
        KRAT  => { comment => "Krasnoyarsk Time", timezones => ['Asia/Krasnoyarsk'] },
        KST   => { comment => "Korea Standard Time", timezones => ['Asia/Seoul', 'Asia/Pyongyang'] },

        # NOTE: L
        L     => { comment => "Lima Military Time Zone", timezones => ['Etc/GMT-11'] },
        LHDT  => { comment => "Lord Howe Daylight Time", timezones => ['Australia/Lord_Howe'] },
        LHST  => { comment => "Lord Howe Summer Time", timezones => ['Australia/Lord_Howe'] },
        LIGT  => { comment => "Melbourne, Australia", timezones => ['Australia/Melbourne'] },
        LINT  => { comment => "Line Islands Time", timezones => ['Pacific/Kiritimati'] },
        LKT   => { comment => "Lanka Time", timezones => ['Asia/Colombo'] },
        # LST (Local Sidereal Time) is skipped, because there is no IANA equivalent
        # LST   => { comment => "Local Sidereal Time", timezones => [] },   # local
        # LT (Local Time) is skipped, because there is no IANA equivalent
        # LT    => { comment => "Local Time", timezones => [] },            # local

        # NOTE: M
        M     => { comment => "Mike Military Time Zone", timezones => ['Etc/GMT-12'] },
        MAGST => { comment => "Magadan Summer Time", timezones => ['Asia/Magadan'] },
        MAGT  => { comment => "Magadan Time", timezones => ['Asia/Magadan'] },
        MAL   => { comment => "Malaysia Time", timezones => ['Asia/Kuala_Lumpur'] },
        MART  => { comment => "Marquesas Islands Time", timezones => ['Pacific/Marquesas'] },
        MAT   => { comment => "Turkish Standard Time", timezones => ['Europe/Istanbul'] },
        MAWT  => { comment => "Mawson Station Time", timezones => ['Antarctica/Mawson'] },
        MDT   => { comment => "Mountain Daylight Time (North America)", timezones => ['America/Denver', 'America/Boise', 'America/Edmonton', 'America/Calgary'] },
        MED   => { comment => "Middle European Daylight", timezones => ['Europe/Paris'] },
        MEDST => { comment => "Middle European Summer", timezones => ['Europe/Paris'] },
        MEST  => { comment => "Middle European Summer Time", timezones => ['Europe/Paris', 'Europe/Berlin'] },
        MESZ  => { comment => "Mitteieuropaische Sommerzeit", timezones => ['Europe/Berlin'] },
        MET   => { comment => "Middle European Time", timezones => ['Europe/Paris', 'Europe/Berlin'] },
        MEWT  => { comment => "Middle European Winter Time", timezones => ['Europe/Paris'] },
        MEX   => { comment => "Mexico Time", timezones => ['America/Mexico_City'] },
        MEZ   => { comment => "Mitteieuropaische Zeit", timezones => ['Europe/Berlin'] },
        MHT   => { comment => "Marshall Islands Time", timezones => ['Pacific/Majuro', 'Pacific/Kwajalein'] },
        MIST  => { comment => "Macquarie Island Station Time", timezones => ['Antarctica/Macquarie'] },
        MIT   => { comment => "Marquesas Islands Time", timezones => ['Pacific/Marquesas'] },
        MMT   => { comment => "Myanmar Standard Time", timezones => ['Asia/Yangon'] },
        MPT   => { comment => "North Mariana Islands Time", timezones => ['Pacific/Saipan'] },
        MSD   => { comment => "Moscow Summer Time", timezones => ['Europe/Moscow'] },
        MSK   => { comment => "Moscow Time", timezones => ['Europe/Moscow', 'Europe/Kirov', 'Europe/Volgograd', 'Europe/Simferopol'] },
        MSKS  => { comment => "Moscow Summer Time", timezones => ['Europe/Moscow'] },
        MST   => { comment => "Mountain Standard Time", timezones => ['America/Denver', 'America/Boise', 'America/Edmonton', 'America/Calgary', 'America/Phoenix'] },
        MT    => { comment => "Moluccas", timezones => ['Asia/Jayapura'] },
        MUT   => { comment => "Mauritius Time", timezones => ['Indian/Mauritius'] },
        MVT   => { comment => "Maldives Time", timezones => ['Indian/Maldives'] },
        MYT   => { comment => "Malaysia Time", timezones => ['Asia/Kuala_Lumpur', 'Asia/Kuching'] },

        # NOTE: N
        N     => { comment => "November Military Time Zone", timezones => ['Etc/GMT+1'] },
        NCT   => { comment => "New Caledonia Time", timezones => ['Pacific/Noumea'] },
        NDT   => { comment => "Newfoundland Daylight Time", timezones => ['America/St_Johns'] },
        NFT   => { comment => "Norfolk Island Time", timezones => ['Pacific/Norfolk'] },
        NOR   => { comment => "Norway Time", timezones => ['Europe/Oslo'] },
        NOVST => { comment => "Novosibirsk Summer Time (Russia)", timezones => ['Asia/Novosibirsk'] },
        NOVT  => { comment => "Novosibirsk Time", timezones => ['Asia/Novosibirsk'] },
        NPT   => { comment => "Nepal Time", timezones => ['Asia/Kathmandu'] },
        NRT   => { comment => "Nauru Time", timezones => ['Pacific/Nauru'] },
        NST   => { comment => "Newfoundland Standard Time", timezones => ['America/St_Johns'] },
        NSUT  => { comment => "North Sumatra Time", timezones => ['Asia/Jakarta'] },
        NT    => { comment => "Newfoundland Time", timezones => ['America/St_Johns'] },
        NUT   => { comment => "Niue Time", timezones => ['Pacific/Niue'] },
        NZDT  => { comment => "New Zealand Daylight Time", timezones => ['Pacific/Auckland', 'Antarctica/McMurdo'] },
        NZST  => { comment => "New Zealand Standard Time", timezones => ['Pacific/Auckland', 'Antarctica/McMurdo'] },
        NZT   => { comment => "New Zealand Standard Time", timezones => ['Pacific/Auckland'] },

        # NOTE: O
        O     => { comment => "Oscar Military Time Zone", timezones => ['Etc/GMT+2'] },
        OESZ  => { comment => "Osteuropaeische Sommerzeit", timezones => ['Europe/Athens'] },
        OEZ   => { comment => "Osteuropaische Zeit", timezones => ['Europe/Athens'] },
        OMSST => { comment => "Omsk Summer Time", timezones => ['Asia/Omsk'] },
        OMST  => { comment => "Omsk Time", timezones => ['Asia/Omsk'] },
        ORAT  => { comment => "Oral Time", timezones => ['Asia/Oral'] },
        # OZ (Ortszeit) is skipped, because there is no IANA equivalent

        # NOTE: P
        P     => { comment => "Papa Military Time Zone", timezones => ['Etc/GMT+3'] },
        PDT   => { comment => "Pacific Daylight Time (North America)", timezones => ['America/Los_Angeles', 'America/Vancouver', 'America/Tijuana'] },
        PET   => { comment => "Peru Time", timezones => ['America/Lima'] },
        PETST => { comment => "Kamchatka Summer Time", timezones => ['Asia/Kamchatka'] },
        PETT  => { comment => "Kamchatka Time", timezones => ['Asia/Kamchatka'] },
        PGT   => { comment => "Papua New Guinea Time", timezones => ['Pacific/Port_Moresby'] },
        PHOT  => { comment => "Phoenix Island Time", timezones => ['Pacific/Enderbury'] },
        PHST  => { comment => "Philippine Standard Time", timezones => ['Asia/Manila'] },
        PHT   => { comment => "Philippine Time", timezones => ['Asia/Manila'] },
        PKT   => { comment => "Pakistan Standard Time", timezones => ['Asia/Karachi'] },
        PMDT  => { comment => "Saint Pierre and Miquelon Daylight Time", timezones => ['America/Miquelon'] },
        PMST  => { comment => "Saint Pierre and Miquelon Standard Time", timezones => ['America/Miquelon'] },
        PMT   => { comment => "Pierre & Miquelon Standard Time", timezones => ['America/Miquelon'] },
        PNT   => { comment => "Pitcairn Time", timezones => ['Pacific/Pitcairn'] },
        PONT  => { comment => "Pohnpei Standard Time", timezones => ['Pacific/Pohnpei'] },
        PST   => { comment => "Pacific Standard Time (North America)", timezones => ['America/Los_Angeles', 'America/Vancouver', 'America/Tijuana', 'Pacific/Pitcairn'] },
        PWT   => { comment => "Palau Time", timezones => ['Pacific/Palau'] },
        PYST  => { comment => "Paraguay Summer Time", timezones => ['America/Asuncion'] },
        PYT   => { comment => "Paraguay Time", timezones => ['America/Asuncion'] },

        # NOTE: Q
        Q     => { comment => "Quebec Military Time Zone", timezones => ['Etc/GMT+4'] },
        QYZT  => { comment => "Qyzylorda Time (Kazakhstan, UTC+6)", timezones => ['Asia/Qyzylorda'] },

        # NOTE: R
        R     => { comment => "Romeo Military Time Zone", timezones => ['Etc/GMT+5'] },
        R1T   => { comment => "Russia Zone 1", timezones => ['Europe/Kaliningrad'] },
        R2T   => { comment => "Russia Zone 2", timezones => ['Europe/Moscow'] },
        RET   => { comment => "Réunion Time", timezones => ['Indian/Reunion'] },
        ROK   => { comment => "Korean Standard Time", timezones => ['Asia/Seoul'] },
        ROTT  => { comment => "Rothera Research Station Time", timezones => ['Antarctica/Rothera'] },

        # NOTE: S
        S     => { comment => "Sierra Military Time Zone", timezones => ['Etc/GMT+6'] },
        SADT  => { comment => "Australian South Daylight Time", timezones => ['Australia/Adelaide'] },
        SAKT  => { comment => "Sakhalin Island Time", timezones => ['Asia/Sakhalin'] },
        SAMT  => { comment => "Samara Time", timezones => ['Europe/Samara'] },
        SAST  => { comment => "South African Standard Time", timezones => ['Africa/Johannesburg', 'Africa/Maseru', 'Africa/Mbabane'] },
        SBT   => { comment => "Solomon Islands Time", timezones => ['Pacific/Guadalcanal'] },
        SCT   => { comment => "Seychelles Time", timezones => ['Indian/Mahe'] },
        SDT   => { comment => "Samoa Daylight Time", timezones => ['Pacific/Apia', 'Pacific/Pago_Pago'] },
        SET   => { comment => "Prague, Vienna Time", timezones => ['Europe/Prague', 'Europe/Vienna'] },
        SGT   => { comment => "Singapore Time", timezones => ['Asia/Singapore'] },
        SLST  => { comment => "Sri Lanka Standard Time", timezones => ['Asia/Colombo'] },
        SRET  => { comment => "Srednekolymsk Time", timezones => ['Asia/Srednekolymsk'] },
        SRT   => { comment => "Suriname Time", timezones => ['America/Paramaribo'] },
        SST   => { comment => "Singapore Standard Time", timezones => ['Asia/Singapore'] },
        SWT   => { comment => "Swedish Winter", timezones => ['Europe/Stockholm'] },
        SYOT  => { comment => "Showa Station Time", timezones => ['Antarctica/Syowa'] },

        # NOTE: T
        T     => { comment => "Tango Military Time Zone", timezones => ['Etc/GMT+7'] },
        TAHT  => { comment => "Tahiti Time", timezones => ['Pacific/Tahiti'] },
        TFT   => { comment => "French Southern and Antarctic Time", timezones => ['Indian/Kerguelen'] },
        THA   => { comment => "Thailand Standard Time", timezones => ['Asia/Bangkok'] },
        THAT  => { comment => "Tahiti Time", timezones => ['Pacific/Tahiti'] },
        TJT   => { comment => "Tajikistan Time", timezones => ['Asia/Dushanbe'] },
        TKT   => { comment => "Tokelau Time", timezones => ['Pacific/Fakaofo'] },
        TLT   => { comment => "Timor Leste Time", timezones => ['Asia/Dili'] },
        TMT   => { comment => "Turkmenistan Time", timezones => ['Asia/Ashgabat'] },
        TOT   => { comment => "Tonga Time", timezones => ['Pacific/Tongatapu'] },
        TRT   => { comment => "Turkey Time", timezones => ['Europe/Istanbul'] },
        TRUT  => { comment => "Truk Time", timezones => ['Pacific/Chuuk'] },
        TST   => { comment => "Turkish Standard Time", timezones => ['Europe/Istanbul'] },
        TVT   => { comment => "Tuvalu Time", timezones => ['Pacific/Funafuti'] },

        # NOTE: U
        U     => { comment => "Uniform Military Time Zone", timezones => ['Etc/GMT+8'] },
        ULAST => { comment => "Ulaanbaatar Summer Time", timezones => ['Asia/Ulaanbaatar'] },
        ULAT  => { comment => "Ulaanbaatar Standard Time", timezones => ['Asia/Ulaanbaatar'] },
        USZ1  => { comment => "Russia Zone 1", timezones => ['Europe/Kaliningrad'] },
        USZ1S => { comment => "Kaliningrad Summer Time (Russia)", timezones => ['Europe/Kaliningrad'] },
        USZ3  => { comment => "Volga Time (Russia)", timezones => ['Europe/Samara'] },
        USZ3S => { comment => "Volga Summer Time (Russia)", timezones => ['Europe/Samara'] },
        USZ4  => { comment => "Ural Time (Russia)", timezones => ['Asia/Yekaterinburg'] },
        USZ4S => { comment => "Ural Summer Time (Russia)", timezones => ['Asia/Yekaterinburg'] },
        USZ5  => { comment => "West-Siberian Time (Russia)", timezones => ['Asia/Novosibirsk', 'Asia/Omsk'] },
        USZ5S => { comment => "West-Siberian Summer Time", timezones => ['Asia/Novosibirsk'] },
        USZ6  => { comment => "Yenisei Time (Russia)", timezones => ['Asia/Krasnoyarsk'] },
        USZ6S => { comment => "Yenisei Summer Time (Russia)", timezones => ['Asia/Krasnoyarsk'] },
        USZ7  => { comment => "Irkutsk Time (Russia)", timezones => ['Asia/Irkutsk'] },
        USZ7S => { comment => "Irkutsk Summer Time", timezones => ['Asia/Irkutsk'] },
        USZ8  => { comment => "Amur Time (Russia)", timezones => ['Asia/Yakutsk'] },
        USZ8S => { comment => "Amur Summer Time (Russia)", timezones => ['Asia/Yakutsk'] },
        USZ9  => { comment => "Vladivostok Time (Russia)", timezones => ['Asia/Vladivostok'] },
        USZ9S => { comment => "Vladivostok Summer Time (Russia)", timezones => ['Asia/Vladivostok'] },
        UTC   => { comment => "Coordinated Universal Time", timezones => ['Etc/UTC'] },
        UTZ   => { comment => "Greenland Western Standard Time", timezones => ['America/Nuuk'] },
        UYST  => { comment => "Uruguay Summer Time", timezones => ['America/Montevideo'] },
        UYT   => { comment => "Uruguay Standard Time", timezones => ['America/Montevideo'] },
        UZ10  => { comment => "Okhotsk Time (Russia)", timezones => ['Asia/Srednekolymsk'] },
        UZ10S => { comment => "Okhotsk Summer Time (Russia)", timezones => ['Asia/Srednekolymsk'] },
        UZ11  => { comment => "Kamchatka Time (Russia)", timezones => ['Asia/Kamchatka', 'Asia/Magadan'] },
        UZ11S => { comment => "Kamchatka Summer Time (Russia)", timezones => ['Asia/Kamchatka'] },
        UZ12  => { comment => "Chukot Time (Russia)", timezones => ['Asia/Anadyr'] },
        UZ12S => { comment => "Chukot Summer Time (Russia)", timezones => ['Asia/Anadyr'] },
        UZT   => { comment => "Uzbekistan Time", timezones => ['Asia/Tashkent', 'Asia/Samarkand'] },

        # NOTE: V
        V     => { comment => "Victor Military Time Zone", timezones => ['Etc/GMT+9'] },
        VET   => { comment => "Venezuelan Standard Time", timezones => ['America/Caracas'] },
        VLAST => { comment => "Vladivostok Summer Time", timezones => ['Asia/Vladivostok'] },
        VLAT  => { comment => "Vladivostok Time", timezones => ['Asia/Vladivostok'] },
        VOLT  => { comment => "Volgograd Time", timezones => ['Europe/Volgograd'] },
        VOST  => { comment => "Vostok Station Time", timezones => ['Antarctica/Vostok'] },
        VTZ   => { comment => "Greenland Eastern Standard Time", timezones => ['America/Noronha'] },
        VUT   => { comment => "Vanuatu Time", timezones => ['Pacific/Efate'] },

        # NOTE: W
        W     => { comment => "Whiskey Military Time Zone", timezones => ['Etc/GMT+10'] },
        WAKT  => { comment => "Wake Island Time", timezones => ['Pacific/Wake'] },
        WAST  => { comment => "West Africa Summer Time", timezones => ['Africa/Windhoek'] },
        WAT   => { comment => "West Africa Time", timezones => ['Africa/Lagos', 'Africa/Bangui', 'Africa/Brazzaville', 'Africa/Douala', 'Africa/Kinshasa', 'Africa/Libreville', 'Africa/Luanda', 'Africa/Malabo', 'Africa/Ndjamena', 'Africa/Niamey', 'Africa/Porto-Novo', 'Africa/Tunis'] },
        WEST  => { comment => "Western European Summer Time", timezones => ['Europe/Lisbon', 'Atlantic/Canary', 'Atlantic/Madeira', 'Atlantic/Faroe'] },
        WESZ  => { comment => "Westeuropaische Sommerzeit", timezones => ['Europe/Lisbon', 'Atlantic/Canary'] },
        WET   => { comment => "Western European Time", timezones => ['Europe/Lisbon', 'Atlantic/Canary', 'Atlantic/Madeira', 'Atlantic/Faroe'] },
        WETDST=> { comment => "European Western Summer", timezones => ['Europe/Lisbon'] },
        WEZ   => { comment => "Western Europe Time", timezones => ['Europe/Lisbon'] },
        WFT   => { comment => "Wallis and Futuna Time", timezones => ['Pacific/Wallis'] },
        WGST  => { comment => "West Greenland Summer Time", timezones => ['America/Nuuk'] },
        WGT   => { comment => "West Greenland Time", timezones => ['America/Nuuk'] },
        WIB   => { comment => "Western Indonesian Time", timezones => ['Asia/Jakarta', 'Asia/Pontianak'] },
        WIT   => { comment => "Eastern Indonesian Time", timezones => ['Asia/Jayapura'] },
        WITA  => { comment => "Central Indonesia Time", timezones => ['Asia/Makassar'] },
        WST   => { comment => "Western Standard Time", timezones => ['Pacific/Apia'] },
        # Western Sahara Standard Time (UTC+0). This seems to be very rare and often mistaken with other significations of "WT".
        # So not Atlantic/St_Helena, but instead Africa/El_Aaiun
        WT    => { comment => "Western Sahara Standard Time", timezones => ['Africa/El_Aaiun'] },
        WTZ   => { comment => "Greenland Eastern Daylight Time", timezones => ['America/Nuuk'] },
        WUT   => { comment => "Austria Time", timezones => ['Europe/Vienna'] },

        # NOTE: X
        X     => { comment => "X-ray Military Time Zone", timezones => ['Etc/GMT+11'] },

        # NOTE: Y
        Y     => { comment => "Yankee Military Time Zone", timezones => ['Etc/GMT+12'] },
        YAKST => { comment => "Yakutsk Summer Time", timezones => ['Asia/Yakutsk'] },
        YAKT  => { comment => "Yakutsk Time", timezones => ['Asia/Yakutsk'] },
        YAPT  => { comment => "Yap Time (Micronesia)", timezones => ['Pacific/Chuuk'] },
        YDT   => { comment => "Yukon Daylight Time", timezones => ['America/Anchorage'] },
        YEKST => { comment => "Yekaterinburg Summer Time", timezones => ['Asia/Yekaterinburg'] },
        YEKT  => { comment => "Yekaterinburg Time", timezones => ['Asia/Yekaterinburg'] },
        YST   => { comment => "Yukon Standard Time", timezones => ['America/Anchorage'] },

        # NOTE: Z
        Z     => { comment => "Zulu", timezones => ['Etc/UTC'] },
    };
    # An alias of an alias...
    # Faute de frappe / variante rare de HAEC (Heure Avancée d’Europe Centrale = CEST).
    $aliases->{HADC} = $aliases->{HAEC};
    # Variante ancienne ou alternative de HDT (Hawaii–Aleutian Daylight Time). L’abréviation courante et reconnue est HDT.
    $aliases->{HADT} = $aliases->{HDT};
    # Variante de HST (Hawaii–Aleutian Standard Time). L’abréviation principale est HST.
    $aliases->{HAST} = $aliases->{HST};
    # Abréviation espagnole/portugaise pour Hora Legal de Venezuela (= VET).
    $aliases->{HLV} = $aliases->{VET};
    # Kuybyshev Time (ancien nom de la zone de Samara, UTC+4). C’est un alias historique de SAMT (Samara Time).
    $aliases->{KUYT} = $aliases->{SAMT};
    # Sri Lanka Time. L’abréviation officielle et actuelle est SLST (Sri Lanka Standard Time).
    $aliases->{SLT} = $aliases->{SLST};
    # TOST : Tonga Summer Time (UTC+14, utilisé seulement pendant une courte période dans le passé). Tonga utilise maintenant TOT (UTC+13) toute l’année.
    $aliases->{TOST} = $aliases->{TOT};

    $dbh->begin_work;
    my( $total_spans, $total_types, $total_zones, $total_aliases, $total_extended_aliases, $errors ) = ( 0, 0, 0, 0, 0, 0 );

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

        _message( 3, "Processing extended aliases.. " );
        # NOTE: Extended aliases
        # Skipped (local/solar time - no fixed IANA zone):
        #   HL   = Heure locale
        #   LST  = Local Sidereal Time
        #   LT   = Local Time
        #   OZ   = Ortszeit (German for local time)
        my $total_abbr  = scalar( keys( %$aliases ) );
        my $total_pairs = 0;
        my $ambiguous   = 0;
        $total_pairs   += scalar( @{$aliases->{ $_ }->{timezones}} ) for( keys( %$aliases ) );
        $ambiguous++  for grep{ scalar( @{$aliases->{ $_ }->{timezones}} ) > 1 } keys( %$aliases );
        $out->printf( "Total abbreviations : %d\n",  $total_abbr ) if( $LOG_LEVEL );
        $out->printf( "Total pairs         : %d\n",  $total_pairs ) if( $LOG_LEVEL );
        $out->printf( "Ambiguous (>1 zone) : %d\n",  $ambiguous ) if( $LOG_LEVEL );
        $out->printf( "Unambiguous         : %d\n",  $total_abbr - $ambiguous ) if( $LOG_LEVEL );
        $out->printf( "Skipped (local TZ)  : 4  (HL, LST, LT, OZ)\n" ) if( $LOG_LEVEL );
        local $" = ', ';

        my $n = 0;
        $out->printf( "$total_abbr / %03d (%.2f%%)\r", $n, ( ( $n / $total_abbr ) * 100 ) ) if( $LOG_LEVEL );
        foreach my $abbr ( sort( keys( %$aliases ) ) )
        {
            my @zones   = @{$aliases->{ $abbr }->{timezones}};
            my $comment = $aliases->{ $abbr }->{comment};
            die( "Alias $abbr is missing a comment." ) if( !defined( $comment ) );
            my $first = 1;
            foreach my $zone ( @zones )
            {
                $sths->{extended_aliases}->execute(
                    $abbr,              # abbreviation
                    ( $first ? 1 : 0 ), # is_primary
                    $comment,           # comment
                    $zone,              # zones.name
                ) || die( "Error adding extended alias(es) @zones for abbreviated timezone $abbr: ", $sths->{extended_aliases}->errstr );
                $first = 0;
            }
            $out->printf( "$total_abbr / %03d (%.2f%%)\r", ++$n, ( ( $n / $total_abbr ) * 100 ) ) if( $LOG_LEVEL );
        }
        $out->print( "\n" ) if( $LOG_LEVEL );
        $total_extended_aliases = $n;

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
    _message( 1, sprintf( "  Ext. Alias  : <green>%d</>",    $total_extended_aliases ) );
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
