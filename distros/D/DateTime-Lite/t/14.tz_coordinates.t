#!perl
##----------------------------------------------------------------------------
## Lightweight DateTime Alternative - t/14.tz_coordinates.t
## Tests for timezone resolution from GPS coordinates (latitude/longitude)
##----------------------------------------------------------------------------
use strict;
use warnings;
use lib './lib';
use Test::More;

use_ok( 'DateTime::Lite::TimeZone' ) or BAIL_OUT( 'Cannot load DateTime::Lite::TimeZone' );

# NOTE: Basic coordinate resolution - well-known cities
subtest 'Tokyo coordinates resolve to Asia/Tokyo' => sub
{
    # Tokyo Tower
    my $tz = DateTime::Lite::TimeZone->new(
        latitude  => 35.658558,
        longitude => 139.745504,
    );
    if( ok( defined( $tz ), 'new() succeeds with Tokyo coordinates' ) )
    {
        is( $tz->name, 'Asia/Tokyo', 'Tokyo coordinates resolve to Asia/Tokyo' );
        ok( $tz->is_olson, 'resolved zone is_olson' );
        ok( !$tz->is_floating, 'resolved zone is not floating' );
    }
};

subtest 'Paris coordinates resolve to Europe/Paris' => sub
{
    # Eiffel Tower
    my $tz = DateTime::Lite::TimeZone->new(
        latitude  => 48.858258,
        longitude => 2.294488,
    );
    if( ok( defined( $tz ), 'new() succeeds with Paris coordinates' ) )
    {
        is( $tz->name, 'Europe/Paris', 'Paris coordinates resolve to Europe/Paris' );
    }
};

subtest 'New York coordinates resolve to America/New_York' => sub
{
    # Empire State Building
    my $tz = DateTime::Lite::TimeZone->new(
        latitude  => 40.748443,
        longitude => -73.985650,
    );
    if( ok( defined( $tz ), 'new() succeeds with New York coordinates' ) )
    {
        is( $tz->name, 'America/New_York', 'New York coordinates resolve to America/New_York' );
    }
};

# NOTE: Southern hemisphere negative latitude
subtest 'Taipei coordinates resolve to Asia/Taipei' => sub
{
    # Taipei 101
    my $tz = DateTime::Lite::TimeZone->new(
        latitude  => 25.033649,
        longitude => 121.564824,
    );
    if( ok( defined( $tz ), 'new() succeeds with Taipei coordinates' ) )
    {
        is( $tz->name, 'Asia/Taipei',
            'Taipei coordinates resolve to Asia/Taipei' );
    }
};

# NOTE: Southern hemisphere negative latitude
subtest 'Sydney coordinates resolve to Australia/Sydney' => sub
{
    # Sydney Opera House
    my $tz = DateTime::Lite::TimeZone->new(
        latitude  => -33.856867,
        longitude => 151.215285,
    );
    if( ok( defined( $tz ), 'new() succeeds with Sydney coordinates' ) )
    {
        is( $tz->name, 'Australia/Sydney', 'Sydney coordinates resolve to Australia/Sydney' );
    }
};

subtest 'Buenos Aires coordinates resolve to America/Argentina/Buenos_Aires' => sub
{
    my $tz = DateTime::Lite::TimeZone->new(
        latitude  => -34.6037,
        longitude => -58.3816,
    );
    if( ok( defined( $tz ), 'new() succeeds with Buenos Aires coordinates' ) )
    {
        is( $tz->name, 'America/Argentina/Buenos_Aires',
            'Buenos Aires coordinates resolve to America/Argentina/Buenos_Aires' );
    }
};

# NOTE: Coordinate resolution integrates with DateTime::Lite
subtest 'DateTime::Lite->now() with coordinate-based timezone' => sub
{
    require DateTime::Lite;
    # Tokyo Tower
    my $tz = DateTime::Lite::TimeZone->new(
        latitude  => 35.658558,
        longitude => 139.745504,
    );
    if( ok( defined( $tz ), 'TimeZone object created from coordinates' ) )
    {
        my $dt = DateTime::Lite->now( time_zone => $tz );
        ok( defined( $dt ), 'DateTime::Lite->now() succeeds with coordinate-resolved timezone' );
        is( $dt->time_zone_long_name, 'Asia/Tokyo',
            'datetime carries the coordinate-resolved timezone' );
    }
};

# NOTE: Input validation - missing longitude
subtest 'Missing longitude returns error, not die' => sub
{
    local $SIG{__WARN__} = sub {};
    my $tz = DateTime::Lite::TimeZone->new(
        latitude => 35.658558,
    );
    ok( !defined( $tz ), 'new() returns undef when longitude is missing' );
    ok( defined( DateTime::Lite::TimeZone->error ), 'error is set' );
};

# NOTE: Input validation - latitude out of range
subtest 'Out-of-range latitude returns error' => sub
{
    local $SIG{__WARN__} = sub {};
    my $tz = DateTime::Lite::TimeZone->new(
        latitude  => 91.0,
        longitude => 139.745504,
    );
    ok( !defined( $tz ), 'new() returns undef for latitude > 90' );
    ok( defined( DateTime::Lite::TimeZone->error ), 'error is set' );
};

# NOTE: Input validation - longitude out of range
subtest 'Out-of-range longitude returns error' => sub
{
    local $SIG{__WARN__} = sub {};
    my $tz = DateTime::Lite::TimeZone->new(
        latitude  => 35.658558,
        longitude => 181.0,
    );
    ok( !defined( $tz ), 'new() returns undef for longitude > 180' );
    ok( defined( DateTime::Lite::TimeZone->error ), 'error is set' );
};

# NOTE: Input validation - non-numeric values
subtest 'Non-numeric coordinates return error' => sub
{
    local $SIG{__WARN__} = sub {};
    my $tz = DateTime::Lite::TimeZone->new(
        latitude  => 'north',
        longitude => 139.745504,
    );
    ok( !defined( $tz ), 'new() returns undef for non-numeric latitude' );
    ok( defined( DateTime::Lite::TimeZone->error ), 'error is set' );
};

done_testing;

__END__
