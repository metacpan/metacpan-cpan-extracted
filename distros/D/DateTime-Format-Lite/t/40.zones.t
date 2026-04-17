# -*- perl -*-
##----------------------------------------------------------------------------
## DateTime Format Lite - t/40.zones.t
##----------------------------------------------------------------------------
use strict;
use warnings;
use lib './lib';
use utf8;
use Test::More qw( no_plan );

use_ok( 'DateTime::Format::Lite' ) or BAIL_OUT( 'Cannot load DateTime::Format::Lite' );

# NOTE: Ambiguous abbreviation without zone_map -> error
# IST maps to multiple UTC offsets (India +05:30, Ireland +00:00/+01:00,
# Israel +02:00/+03:00) and is therefore genuinely ambiguous.
subtest 'ambiguous abbreviation IST without zone_map' => sub
{
    my $fmt = DateTime::Format::Lite->new(
        pattern  => '%Y %Z',
        on_error => 'undef',
    );
    ok( defined( $fmt ), 'constructor succeeded' );

    my $warning = '';
    local $SIG{__WARN__} = sub{ $warning = join( '', @_ ) };
    my $dt = $fmt->parse_datetime( '2015 IST' );
    ok( !defined( $dt ), 'parse returns undef for ambiguous zone' );
    ok( defined( $fmt->error ), 'error object is set' );
    like( $fmt->error->message, qr/ambiguous/i, 'error mentions ambiguous' );
};

# NOTE: zone_map resolves ambiguous abbreviation
subtest 'zone_map resolves EST to -0500' => sub
{
    my $fmt = DateTime::Format::Lite->new(
        pattern  => '%Y %Z',
        zone_map => { EST => '-0500' },
        on_error => 'undef',
    );
    ok( defined( $fmt ), 'constructor succeeded' );

    my $dt = $fmt->parse_datetime( '2015 EST' );
    if( ok( defined( $dt ), 'parse succeeded with zone_map' ) )
    {
        is( $dt->offset, -18000, 'offset is -18000 (-05:00)' );
    }
    else
    {
        diag( 'Error: ' . ( $fmt->error // 'unknown' ) );
    }
};

# NOTE: zone_map with IANA name
subtest 'zone_map maps abbreviation to IANA name' => sub
{
    my $fmt = DateTime::Format::Lite->new(
        pattern  => '%Y-%m-%d %Z',
        zone_map => { JST => 'Asia/Tokyo' },
        on_error => 'undef',
    );
    ok( defined( $fmt ), 'constructor succeeded' );

    my $dt = $fmt->parse_datetime( '2026-04-15 JST' );
    if( ok( defined( $dt ), 'parse succeeded' ) )
    {
        is( $dt->time_zone->name, 'Asia/Tokyo', 'timezone is Asia/Tokyo' );
        is( $dt->offset, 32400, 'offset is +09:00' );
    }
    else
    {
        diag( 'Error: ' . ( $fmt->error // 'unknown' ) );
    }
};

# NOTE: %z numeric offset
subtest '%z +0900 sets correct offset' => sub
{
    my $fmt = DateTime::Format::Lite->new( pattern => '%Y-%m-%dT%H:%M:%S%z', on_error => 'undef' );
    ok( defined( $fmt ), 'constructor succeeded' );

    my $dt = $fmt->parse_datetime( '2026-04-15T09:00:00+0900' );
    if( ok( defined( $dt ), 'parsed' ) )
    {
        is( $dt->offset, 32400, 'offset is 32400 (+09:00)' );
    }
    else
    {
        diag( 'Error: ' . ( $fmt->error // 'unknown' ) );
    }
};

# NOTE: %Z and %z together: %z takes precedence
subtest '%Z PST disambiguated by co-parsed %z -0800' => sub
{
    my $fmt = DateTime::Format::Lite->new(
        pattern  => '%Y-%m-%d %Z %z',
        on_error => 'undef',
    );
    ok( defined( $fmt ), 'constructor succeeded' );

    my $dt = $fmt->parse_datetime( '2026-01-15 PST -0800' );
    if( ok( defined( $dt ), 'parsed' ) )
    {
        is( $dt->offset, -28800, 'offset is -28800 (-08:00), %z wins over %Z lookup' );
    }
    else
    {
        diag( 'Error: ' . ( $fmt->error // 'unknown' ) );
    }
};

# NOTE: %O Olson name - case normalisation
subtest '%O Olson name case-insensitive' => sub
{
    foreach my $input ( qw( America/New_York AMERICA/NEW_YORK america/new_york ) )
    {
        my $fmt = DateTime::Format::Lite->new( pattern => '%Y %O', on_error => 'undef' );
        my $dt  = $fmt->parse_datetime( "2026 $input" );
        if( !ok( defined( $dt ), "parsed '$input'" ) )
        {
            diag( 'Error: ' . ( $fmt->error // 'unknown' ) );
            next;
        }
        is( $dt->time_zone->name, 'America/New_York', "normalised to America/New_York" );
    }
};

done_testing();

__END__
