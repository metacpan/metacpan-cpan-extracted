# -*- perl -*-
##----------------------------------------------------------------------------
## DateTime Format Lite - t/89.tz_abbr_resolution.t
## Tests for timezone abbreviation resolution via the IANA SQLite DB,
## including disambiguation by co-parsed %z offset and zone_map overrides.
##----------------------------------------------------------------------------
use strict;
use warnings;
use lib './lib';
use Test::More qw( no_plan );

use_ok( 'DateTime::Format::Lite' ) or BAIL_OUT( 'Cannot load DateTime::Format::Lite' );
use_ok( 'DateTime::Lite::TimeZone' ) or BAIL_OUT( 'Cannot load DateTime::Lite::TimeZone' );

# NOTE: resolve_abbreviation returns arrayref for unambiguous abbreviation
subtest 'resolve_abbreviation unambiguous (JST)' => sub
{
    my $results = DateTime::Lite::TimeZone->resolve_abbreviation( 'JST' );
    ok( defined( $results ), 'resolve_abbreviation returns defined value' );
    ok( ref( $results ) eq 'ARRAY', 'result is arrayref' );
    ok( scalar( @$results ) > 0, 'at least one result' );
    is( $results->[0]{ambiguous}, 0, 'JST is not ambiguous (same offset)' );
    is( $results->[0]{utc_offset}, 32400, 'JST offset = +09:00' );
    is( $results->[0]{is_dst}, 0, 'JST is not DST' );
};

# NOTE: resolve_abbreviation returns error for unknown abbreviation
subtest 'resolve_abbreviation unknown' => sub
{
    my $warning = '';
    local $SIG{__WARN__} = sub{ $warning = join( '', @_ ) };
    my $results = DateTime::Lite::TimeZone->resolve_abbreviation( 'XYZ' );
    ok( !defined( $results ), 'returns undef for unknown abbreviation' );
    ok( defined( DateTime::Lite::TimeZone->error ), 'error is set' );
};

# NOTE: resolve_abbreviation ambiguous (IST has multiple offsets)
subtest 'resolve_abbreviation ambiguous (IST)' => sub
{
    my $results = DateTime::Lite::TimeZone->resolve_abbreviation( 'IST' );
    ok( defined( $results ), 'returns defined value' );
    is( $results->[0]{ambiguous}, 1, 'IST is ambiguous (multiple offsets)' );
};

# NOTE: resolve_abbreviation with utc_offset filter narrows PST
subtest 'resolve_abbreviation with utc_offset filter' => sub
{
    # PST maps to both -28800 (Pacific) and +28800 (Philippines historically)
    my $results = DateTime::Lite::TimeZone->resolve_abbreviation(
        'PST', utc_offset => -28800
    );
    ok( defined( $results ), 'filter returns defined value' );
    foreach my $r ( @$results )
    {
        is( $r->{utc_offset}, -28800, "zone $r->{zone_name} has offset -28800" );
    }
};

# NOTE: parse_datetime with %Z JST (unambiguous, DB resolution)
subtest 'parse %Z JST via DB resolution' => sub
{
    my $fmt = DateTime::Format::Lite->new(
        pattern  => '%Y-%m-%d %H:%M:%S %Z',
        on_error => 'croak',
    );
    my $dt = $fmt->parse_datetime( '2026-04-14 09:00:00 JST' );
    ok( defined( $dt ), 'parse succeeded' );
    is( $dt->offset, 32400, 'JST -> +09:00' );
};

# NOTE: parse %Z with co-parsed %z disambiguates PST
subtest 'parse %Z PST disambiguated by co-parsed %z' => sub
{
    my $fmt = DateTime::Format::Lite->new(
        pattern  => '%Y-%m-%d %H:%M:%S %Z%z',
        on_error => 'undef',
    );
    # PST with explicit -0800 offset -> Pacific Standard Time
    my $dt = $fmt->parse_datetime( '2026-01-15 12:00:00 PST-0800' );
    ok( defined( $dt ), 'parse succeeded with co-parsed offset' );
    is( $dt->offset, -28800, 'PST with -0800 -> Pacific' );
};

# NOTE: zone_map takes priority over DB
subtest 'zone_map overrides DB for known abbreviation' => sub
{
    my $fmt = DateTime::Format::Lite->new(
        pattern  => '%Y-%m-%d %Z',
        zone_map => { JST => 'America/New_York' },
        on_error => 'croak',
    );
    my $dt = $fmt->parse_datetime( '2026-04-14 JST' );
    ok( defined( $dt ), 'parse succeeded' );
    # zone_map overrides JST to New York
    is( $dt->time_zone_long_name, 'America/New_York', 'zone_map overrides DB' );
};

# NOTE: zone_map for abbreviation not in DB
subtest 'zone_map for custom abbreviation not in DB' => sub
{
    my $fmt = DateTime::Format::Lite->new(
        pattern  => '%Y-%m-%d %Z',
        zone_map => { NZDT => 'Pacific/Auckland' },
        on_error => 'croak',
    );
    my $dt = $fmt->parse_datetime( '2026-04-14 NZDT' );
    ok( defined( $dt ), 'parse succeeded with custom zone_map entry' );
    is( $dt->time_zone_long_name, 'Pacific/Auckland', 'custom zone_map applied' );
};

# NOTE: ambiguous abbreviation IST without zone_map returns error
subtest 'ambiguous IST without zone_map returns error' => sub
{
    my $warning = '';
    local $SIG{__WARN__} = sub{ $warning = join( '', @_ ) };
    my $fmt = DateTime::Format::Lite->new(
        pattern  => '%Y-%m-%d %Z',
        on_error => 'undef',
    );
    my $dt = $fmt->parse_datetime( '2026-04-14 IST' );
    ok( !defined( $dt ), 'returns undef for ambiguous IST' );
    like( $fmt->error . '', qr/ambiguous/i, 'error mentions ambiguous' );
};

# NOTE: ambiguous IST resolved via zone_map
subtest 'ambiguous IST resolved via zone_map' => sub
{
    my $fmt = DateTime::Format::Lite->new(
        pattern  => '%Y-%m-%d %Z',
        zone_map => { IST => 'Asia/Kolkata' },
        on_error => 'croak',
    );
    my $dt = $fmt->parse_datetime( '2026-04-14 IST' );
    ok( defined( $dt ), 'parse succeeded with IST in zone_map' );
    is( $dt->time_zone_long_name, 'Asia/Kolkata', 'IST -> India via zone_map' );
};

# NOTE: %O case normalisation
subtest '%O case normalisation' => sub
{
    my $fmt = DateTime::Format::Lite->new(
        pattern  => '%Y %O',
        on_error => 'croak',
    );
    for my $name ( 'Asia/Tokyo', 'asia/tokyo', 'ASIA/TOKYO' )
    {
        my $dt = $fmt->parse_datetime( "2026 $name" );
        ok( defined( $dt ), "$name parses" );
        is( $dt->time_zone_long_name, 'Asia/Tokyo', "$name -> Asia/Tokyo" );
    }
};

done_testing;

__END__
