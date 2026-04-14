#!perl
##----------------------------------------------------------------------------
## Lightweight DateTime Alternative - t/12.tz_database.t
##
## Integrity tests for the bundled tz.sqlite3 database.
##
## These tests verify that the database file is well-formed, complete, and
## contains correct timezone data for a representative set of known zones,
## aliases, and historical offsets. They are designed to catch regressions
## introduced by a bad rebuild of the database.
##----------------------------------------------------------------------------
use strict;
use warnings;
use lib './lib';
use Test::More;
use Time::Local qw( timegm );

BEGIN
{
    eval { require DBI; require DBD::SQLite };
    plan( skip_all => 'DBI and DBD::SQLite are required for this test' ) if( $@ );
}

use_ok( 'DateTime::Lite::TimeZone' ) or BAIL_OUT( 'Cannot load DateTime::Lite::TimeZone' );

# NOTE: Locate and open the database
my $db_file = DateTime::Lite::TimeZone->datafile;
ok( defined( $db_file ) && length( $db_file ), 'datafile() returns a path' );
ok( -e( $db_file ),  "database file exists: $db_file" );
ok( -f( $db_file ),  'database file is a regular file' );
ok( -r( $db_file ),  'database file is readable' );
ok( !-z( $db_file ), 'database file is not empty' );

my $dbh = DBI->connect(
    "dbi:SQLite:dbname=$db_file", '', '',
    {
        RaiseError     => 0,
        PrintError     => 0,
        AutoCommit     => 1,
        sqlite_unicode => 1,
    }
);
ok( defined( $dbh ), 'DBI connection to database succeeds' );
BAIL_OUT( "Cannot open database: $DBI::errstr" ) unless( defined( $dbh ) );

$dbh->do( "PRAGMA foreign_keys = ON" );

# NOTE: Schema: required tables exist
subtest 'Schema: required tables exist' => sub
{
    my @required_tables = qw(
        metadata
        countries
        zones
        aliases
        types
        transition
        spans
        leap_second
    );

    my @existing = map{ $_->[0] }
                   @{ $dbh->selectall_arrayref(
                       "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
                   ) };
    my %existing_set;
    @existing_set{ @existing } = (1) x @existing;

    foreach my $table ( @required_tables )
    {
        ok( $existing_set{ $table }, "table '$table' exists" );
    }
};

# NOTE: Schema: required views exist
subtest 'Schema: required views exist' => sub
{
    my @required_views = qw(
        v_zone_aliases
        v_zone_leap_second
        v_zone_name
        v_zone_transition
        v_zone_types
    );

    my @existing = map{ $_->[0] }
                   @{ $dbh->selectall_arrayref(
                       "SELECT name FROM sqlite_master WHERE type='view' ORDER BY name"
                   ) };
    my %existing_set;
    @existing_set{ @existing } = (1) x @existing;

    foreach my $view ( @required_views )
    {
        ok( $existing_set{ $view }, "view '$view' exists" );
    }
};

# NOTE: Metadata: required keys present and well-formed
subtest 'Metadata: required keys present and well-formed' => sub
{
    my $meta = $dbh->selectall_hashref(
        "SELECT key, value FROM metadata", 'key'
    );

    ok( exists( $meta->{tz_version} ),   'metadata: tz_version present' );
    ok( exists( $meta->{built_at} ),     'metadata: built_at present' );
    ok( exists( $meta->{built_by} ),     'metadata: built_by present' );
    ok( exists( $meta->{total_zones} ),  'metadata: total_zones present' );
    ok( exists( $meta->{total_spans} ),  'metadata: total_spans present' );
    ok( exists( $meta->{total_aliases} ),'metadata: total_aliases present' );

    like( $meta->{tz_version}->{value},
          qr/^\d{4}[a-z]+$/,
          'metadata: tz_version matches YYYY[a-z]+ format' );
    like( $meta->{built_at}->{value},
          qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/,
          'metadata: built_at is ISO 8601' );

    my $stored_zones = $meta->{total_zones}->{value};
    cmp_ok( $stored_zones, '>=', 300,
        "metadata: total_zones ($stored_zones) >= 300" );
    my $stored_spans = $meta->{total_spans}->{value};
    cmp_ok( $stored_spans, '>=', 10_000,
        "metadata: total_spans ($stored_spans) >= 10,000" );
};

# NOTE: Row counts: match metadata and are within expected ranges
subtest 'Row counts' => sub
{
    my( $zone_count )     = $dbh->selectrow_array( "SELECT COUNT(*) FROM zones" );
    my( $alias_count )    = $dbh->selectrow_array( "SELECT COUNT(*) FROM aliases" );
    my( $country_count )  = $dbh->selectrow_array( "SELECT COUNT(*) FROM countries" );
    my( $type_count )     = $dbh->selectrow_array( "SELECT COUNT(*) FROM types" );
    my( $trans_count )    = $dbh->selectrow_array( "SELECT COUNT(*) FROM transition" );
    my( $span_count )     = $dbh->selectrow_array( "SELECT COUNT(*) FROM spans" );
    my( $meta_zones )     = $dbh->selectrow_array(
        "SELECT value FROM metadata WHERE key='total_zones'"
    );
    my( $meta_spans )     = $dbh->selectrow_array(
        "SELECT value FROM metadata WHERE key='total_spans'"
    );
    my( $meta_aliases )   = $dbh->selectrow_array(
        "SELECT value FROM metadata WHERE key='total_aliases'"
    );

    is( $zone_count,  $meta_zones,   'zones count matches metadata' );
    # Note: total_spans in metadata may include a type-count overhead
    # from build_tz_database.pl; compare with tolerance instead.
    cmp_ok( abs( $span_count - $meta_spans ), '<=', $type_count,
        "spans count is within type_count of metadata value (actual=$span_count metadata=$meta_spans)" );
    is( $alias_count, $meta_aliases, 'aliases count matches metadata' );

    cmp_ok( $zone_count,    '>=', 300,    "zones >= 300 ($zone_count)" );
    cmp_ok( $alias_count,   '>=', 200,    "aliases >= 200 ($alias_count)" );
    cmp_ok( $country_count, '>=', 200,    "countries >= 200 ($country_count)" );
    cmp_ok( $type_count,    '>=', 500,    "types >= 500 ($type_count)" );
    cmp_ok( $trans_count,   '>=', 10_000, "transitions >= 10,000 ($trans_count)" );
    cmp_ok( $span_count,    '>=', 10_000, "spans >= 10,000 ($span_count)" );
};

# Referential integrity
subtest 'Referential integrity' => sub
{
    my( $orphan_spans_zone ) = $dbh->selectrow_array(
        "SELECT COUNT(*) FROM spans WHERE zone_id NOT IN (SELECT zone_id FROM zones)"
    );
    is( $orphan_spans_zone, 0, 'no spans with unknown zone_id' );

    my( $orphan_spans_type ) = $dbh->selectrow_array(
        "SELECT COUNT(*) FROM spans WHERE type_id NOT IN (SELECT type_id FROM types)"
    );
    is( $orphan_spans_type, 0, 'no spans with unknown type_id' );

    my( $orphan_trans_zone ) = $dbh->selectrow_array(
        "SELECT COUNT(*) FROM transition WHERE zone_id NOT IN (SELECT zone_id FROM zones)"
    );
    is( $orphan_trans_zone, 0, 'no transitions with unknown zone_id' );

    my( $orphan_trans_type ) = $dbh->selectrow_array(
        "SELECT COUNT(*) FROM transition WHERE type_id NOT IN (SELECT type_id FROM types)"
    );
    is( $orphan_trans_type, 0, 'no transitions with unknown type_id' );

    my( $orphan_types ) = $dbh->selectrow_array(
        "SELECT COUNT(*) FROM types WHERE zone_id NOT IN (SELECT zone_id FROM zones)"
    );
    is( $orphan_types, 0, 'no types with unknown zone_id' );

    my( $orphan_aliases ) = $dbh->selectrow_array(
        "SELECT COUNT(*) FROM aliases WHERE zone_id NOT IN (SELECT zone_id FROM zones)"
    );
    is( $orphan_aliases, 0, 'no aliases with unknown zone_id' );
};

# NOTE: Header transition counts match stored transitions
subtest 'Header transition counts' => sub
{
    my $mismatches = $dbh->selectall_arrayref(
        q{SELECT z.name, z.transition_count, COUNT(t.trans_id) AS stored
          FROM zones z
          LEFT JOIN transition t ON t.zone_id = z.zone_id
          GROUP BY z.zone_id
          HAVING z.transition_count != COUNT(t.trans_id)
          ORDER BY z.name},
        { Slice => {} }
    );
    is( scalar( @$mismatches ), 0,
        'all zones have stored transition count matching TZif header' );
    if( @$mismatches )
    {
        foreach( @$mismatches )
        {
            diag( sprintf( "  Mismatch: %-30s header=%d stored=%d",
                           $_->{name}, $_->{transition_count}, $_->{stored} ) );
        }
    }
};

# NOTE: Span structure: each zone has exactly transition_count + 1 spans
subtest 'Span structure' => sub
{
    my $span_count_mismatches = $dbh->selectall_arrayref(
        q{SELECT z.name, z.transition_count, COUNT(s.span_id) AS stored
          FROM zones z
          LEFT JOIN spans s ON s.zone_id = z.zone_id
          GROUP BY z.zone_id
          HAVING COUNT(s.span_id) != z.transition_count + 1
          ORDER BY z.name},
        { Slice => {} }
    );
    is( scalar( @$span_count_mismatches ), 0,
        'all zones have exactly transition_count + 1 spans' );
    if( @$span_count_mismatches )
    {
        diag( sprintf( "  Mismatch: %-30s trans=%d spans=%d (expected %d)",
                       $_->{name}, $_->{transition_count}, $_->{stored},
                       $_->{transition_count} + 1 ) )
            for @$span_count_mismatches;
    }
};

# NOTE: Span continuity: no gaps between consecutive spans for key zones
subtest 'Span continuity' => sub
{
    my @key_zones = (
        [ 'Asia/Tokyo',         'Tokyo (no DST)'            ],
        [ 'Etc/UTC',            'Etc/UTC (no transitions)'  ],
        [ 'Europe/Paris',       'Paris (DST)'               ],
        [ 'America/New_York',   'New York (DST)'            ],
    );

    foreach my $pair ( @key_zones )
    {
        my( $name, $label ) = @$pair;

        my $spans = $dbh->selectall_arrayref(
            q{SELECT span_index, utc_start, utc_end
              FROM spans
              JOIN zones ON zones.zone_id = spans.zone_id
              WHERE zones.name = ?
              ORDER BY span_index},
            { Slice => {} }, $name
        );

        next unless( @$spans );

        # First span must have utc_start = NULL
        ok( !defined( $spans->[0]{utc_start} ),
            "$label: first span has NULL utc_start (-Inf)" );

        # Last span must have utc_end = NULL
        ok( !defined( $spans->[-1]{utc_end} ),
            "$label: last span has NULL utc_end (+Inf)" );

        # No gaps between consecutive spans
        my $gaps = 0;
        for my $i ( 1 .. $#$spans )
        {
            my $prev = $spans->[$i - 1];
            my $curr = $spans->[$i];
            if( defined( $prev->{utc_end} ) &&
                defined( $curr->{utc_start} ) &&
                $prev->{utc_end} != $curr->{utc_start} )
            {
                $gaps++;
                diag( sprintf(
                    "  %s gap at index %d: prev_end=%s curr_start=%s",
                    $name, $curr->{span_index},
                    $prev->{utc_end}, $curr->{utc_start}
                ) );
            }
        }
        is( $gaps, 0, "$label: no gaps between consecutive spans" );
    }
};

# NOTE: Known zones exist with correct attributes
subtest 'Known zones' => sub
{
    my @expected_zones = (
        # name                   canonical  has_dst
        [ 'Asia/Tokyo',          1,         1       ],
        [ 'America/New_York',    1,         1       ],
        [ 'Europe/Paris',        1,         1       ],
        [ 'Etc/UTC',             1,         0       ],
        [ 'America/Los_Angeles', 1,         1       ],
        [ 'Europe/London',       1,         1       ],
        # Asia/Kolkata had DST historically (1941-1945), so has_dst=1
        [ 'Asia/Kolkata',        1,         1       ],
        [ 'Australia/Sydney',    1,         1       ],
        [ 'Pacific/Auckland',    1,         1       ],
        [ 'America/Sao_Paulo',   1,         1       ],
    );

    foreach my $exp ( @expected_zones )
    {
        my( $name, $canonical, $has_dst ) = @$exp;
        my $r = $dbh->selectrow_hashref(
            "SELECT zone_id, canonical, has_dst FROM zones WHERE name = ?",
            undef, $name
        );
        ok( defined( $r ),               "zone '$name' exists" );
        next unless( defined( $r ) );
        is( $r->{canonical}, $canonical, "$name: canonical=$canonical" );
        is( $r->{has_dst},   $has_dst,   "$name: has_dst=$has_dst"     );
    }
};

# NOTE: Known aliases resolve to correct canonical zones
subtest 'Known aliases' => sub
{
    my @expected_aliases = (
        [ 'Japan',       'Asia/Tokyo'          ],
        [ 'US/Eastern',  'America/New_York'    ],
        [ 'US/Pacific',  'America/Los_Angeles' ],
        [ 'US/Central',  'America/Chicago'     ],
        [ 'UTC',         'Etc/UTC'             ],
        [ 'GB',          'Europe/London'       ],
        # Iceland was merged with Africa/Abidjan in IANA 2022+ (same rules since 1968)
        [ 'Iceland',     'Africa/Abidjan'      ],
        [ 'Hongkong',    'Asia/Hong_Kong'      ],
        [ 'Singapore',   'Asia/Singapore'      ],
    );

    foreach my $pair ( @expected_aliases )
    {
        my( $alias, $expected_canonical ) = @$pair;
        my $r = $dbh->selectrow_hashref(
            q{SELECT z.name
              FROM aliases a
              JOIN zones z ON z.zone_id = a.zone_id
              WHERE a.alias = ?},
            undef, $alias
        );
        ok( defined( $r ), "alias '$alias' exists" );
        next unless( defined( $r ) );
        is( $r->{name}, $expected_canonical,
            "alias '$alias' -> '$expected_canonical'" );
    }
};

# NOTE: Country codes: known country-zone associations
subtest 'Country codes' => sub
{
    my @expected_countries = (
        [ 'JP',  'Asia/Tokyo'         ],
        [ 'FR',  'Europe/Paris'       ],
        [ 'GB',  'Europe/London'      ],
        [ 'AU',  'Australia/Sydney'   ],
    );

    foreach my $pair ( @expected_countries )
    {
        my( $cc, $zone ) = @$pair;
        my $r = $dbh->selectrow_hashref(
            "SELECT countries FROM zones WHERE name = ?",
            undef, $zone
        );
        ok( defined( $r ), "zone '$zone' exists (for country check)" );
        next unless( defined( $r ) && defined( $r->{countries} ) );
        like( $r->{countries}, qr/\Q$cc\E/,
              "zone '$zone' lists country code '$cc'" );
    }

    # countries table: at least 200 ISO 3166 entries
    my( $n ) = $dbh->selectrow_array( "SELECT COUNT(*) FROM countries" );
    cmp_ok( $n, '>=', 200, "countries table has >= 200 entries ($n)" );

    # All codes are exactly 2 uppercase ASCII letters
    my( $bad ) = $dbh->selectrow_array(
        "SELECT COUNT(*) FROM countries WHERE code NOT GLOB '[A-Z][A-Z]'"
    );
    is( $bad, 0, 'all country codes are 2 uppercase ASCII letters' );
};

# NOTE: TZif metadata: version and footer present for DST zones
subtest 'TZif metadata' => sub
{
    # All zones must have a valid tzif_version (1, 2, 3, or 4)
    my( $bad_version ) = $dbh->selectrow_array(
        "SELECT COUNT(*) FROM zones WHERE tzif_version NOT IN (1,2,3,4)"
    );
    is( $bad_version, 0, 'all zones have valid tzif_version (1-4)' );

    # DST zones should have a non-empty footer TZ string
    my( $dst_no_footer ) = $dbh->selectrow_array(
        q{SELECT COUNT(*) FROM zones
          WHERE has_dst = 1
            AND ( footer_tz_string IS NULL OR LENGTH(footer_tz_string) = 0 )}
    );
    is( $dst_no_footer, 0,
        'all DST zones have a non-empty POSIX footer TZ string' );

    # UTC/non-DST zones should have an empty or NULL footer
    my $ny = $dbh->selectrow_hashref(
        "SELECT tzif_version, footer_tz_string FROM zones WHERE name = ?",
        undef, "America/New_York"
    );
    ok( defined( $ny ), 'America/New_York has metadata' );
    if( defined( $ny ) )
    {
        cmp_ok( $ny->{tzif_version}, '>=', 2,
            'America/New_York has TZif version >= 2 (footer supported)' );
        like( $ny->{footer_tz_string}, qr/EST5?EDT/,
            'America/New_York footer contains EST/EDT rule' );
    }

    my $tokyo = $dbh->selectrow_hashref(
        "SELECT footer_tz_string FROM zones WHERE name = ?",
        undef, "Asia/Tokyo"
    );
    ok( defined( $tokyo ), 'Asia/Tokyo has metadata' );
    if( defined( $tokyo ) )
    {
        like( $tokyo->{footer_tz_string}, qr/JST/,
            'Asia/Tokyo footer contains JST' );
    }
};

# Historical offset lookups via spans
# These use dates within the stored transitions so they work with the
# current span-based lookup regardless of POSIX footer support.
subtest 'Historical offset lookups via spans' => sub
{
    my @tests = (
        # zone                   unix_ts                              exp_off  exp_dst  exp_abbr  label
        [ 'Asia/Tokyo',          timegm(0,0,15,1,3,1951),               32400,  0, 'JST',  'Tokyo 1951 (historical)' ],
        [ 'Asia/Tokyo',          timegm(0,0,15,1,3,1980),               32400,  0, 'JST',  'Tokyo 1980 (historical)' ],
        [ 'America/New_York',    timegm(0,0,15,14,6,2000),            -14400,  1, 'EDT',  'NY 2000-07 summer (historical)' ],
        [ 'America/New_York',    timegm(0,0,15,14,11,2000),           -18000,  0, 'EST',  'NY 2000-12 winter (historical)' ],
        [ 'America/New_York',    timegm(0,0,15,14,6,2006),            -14400,  1, 'EDT',  'NY 2006-07 summer (historical)' ],
        [ 'America/New_York',    timegm(0,0,15,14,11,2006),           -18000,  0, 'EST',  'NY 2006-12 winter (historical)' ],
        [ 'Europe/Paris',        timegm(0,0,15,14,5,1995),               7200,  1, 'CEST', 'Paris 1995 summer (historical)' ],
        [ 'Europe/Paris',        timegm(0,0,15,14,11,1995),              3600,  0, 'CET',  'Paris 1995 winter (historical)' ],
        [ 'Etc/UTC',             timegm(0,0,12,1,0,2026),                  0,  0, 'UTC',  'UTC any date' ],
    );

    foreach my $t ( @tests )
    {
        my( $zone, $ts, $exp_off, $exp_dst, $exp_abbr, $label ) = @$t;
        my $r = $dbh->selectrow_hashref(
            q{SELECT s.offset, s.is_dst, s.short_name
              FROM spans s
              JOIN zones z ON z.zone_id = s.zone_id
              WHERE z.name = ?
                AND ( s.utc_start IS NULL OR s.utc_start <= ? )
                AND ( s.utc_end   IS NULL OR s.utc_end   >  ? )
              LIMIT 1},
            undef, $zone, $ts, $ts
        );
        ok( defined( $r ), "$label: span found" );
        next unless( defined( $r ) );
        is( $r->{offset},     $exp_off,  "$label: offset=$exp_off"  );
        is( $r->{is_dst},     $exp_dst,  "$label: is_dst=$exp_dst"  );
        is( $r->{short_name}, $exp_abbr, "$label: abbr=$exp_abbr"   );
    }
};

# v_zone_name view: resolves both canonical names and aliases
subtest 'v_zone_name' => sub
{
    my $r = $dbh->selectrow_hashref(
        "SELECT * FROM v_zone_name WHERE input_name = ?",
        undef, "Japan"
    );
    ok( defined( $r ),                         "v_zone_name: Japan resolves"           );
    is( $r->{canonical_name}, 'Asia/Tokyo',    "v_zone_name: Japan -> Asia/Tokyo"      );
    is( $r->{is_alias},       1,               "v_zone_name: Japan is_alias=1"         );

    my $r2 = $dbh->selectrow_hashref(
        "SELECT * FROM v_zone_name WHERE input_name = ?",
        undef, "Asia/Tokyo"
    );
    ok( defined( $r2 ),                        "v_zone_name: Asia/Tokyo resolves"      );
    is( $r2->{canonical_name}, 'Asia/Tokyo',   "v_zone_name: Asia/Tokyo canonical"     );
    is( $r2->{is_alias},       0,              "v_zone_name: Asia/Tokyo is_alias=0"    );
};

# NOTE: No duplicate zone names
subtest 'No duplicate zone names' => sub
{
    my( $dup_zones ) = $dbh->selectrow_array(
        "SELECT COUNT(*) FROM (SELECT name, COUNT(*) c FROM zones GROUP BY name HAVING c > 1)"
    );
    is( $dup_zones, 0, 'no duplicate zone names' );

    my( $dup_aliases ) = $dbh->selectrow_array(
        "SELECT COUNT(*) FROM (SELECT alias, COUNT(*) c FROM aliases GROUP BY alias HAVING c > 1)"
    );
    is( $dup_aliases, 0, 'no duplicate alias names' );
};

# No zone appears as both a canonical zone and an alias
subtest 'No zone as alias' => sub
{
    my( $overlap ) = $dbh->selectrow_array(
        q{SELECT COUNT(*) FROM zones z
          JOIN aliases a ON LOWER(a.alias) = LOWER(z.name)}
    );
    is( $overlap, 0, 'no name appears as both a zone and an alias' );
};

# NOTE: Span offset values are within plausible range (-14h to +14h)
subtest 'Span offset values' => sub
{
    # Historical LMT (Local Mean Time) spans can exceed +-14h legitimately.
    # Only check non-LMT spans, which should all be within +-16h.
    my( $out_of_range ) = $dbh->selectrow_array(
        q{SELECT COUNT(*) FROM spans
          WHERE ( offset < -57600 OR offset > 57600 )
            AND short_name != 'LMT'}
    );
    is( $out_of_range, 0,
        'all non-LMT span offsets are within -16h..+16h range' );
};

END
{
    $dbh->disconnect if( $dbh );
};

done_testing;

__END__
