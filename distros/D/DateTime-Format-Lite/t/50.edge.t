# -*- perl -*-
##----------------------------------------------------------------------------
## DateTime Format Lite - t/50.edge.t
##----------------------------------------------------------------------------
use strict;
use warnings;
use lib './lib';
use utf8;
use Test::More qw( no_plan );

use_ok( 'DateTime::Format::Lite' ) or BAIL_OUT( 'Cannot load DateTime::Format::Lite' );

# NOTE: Leading/trailing whitespace
subtest 'leading and trailing whitespace in input' => sub
{
    my $fmt = DateTime::Format::Lite->new( pattern => '%Y%m%d', on_error => 'undef' );
    ok( defined( $fmt ), 'constructor succeeded' );

    my $dt = $fmt->parse_datetime( '  20151222' );
    if( ok( defined( $dt ), 'parsed with leading whitespace' ) )
    {
        is( $dt->year,  2015, 'year' );
        is( $dt->month,   12, 'month' );
        is( $dt->day,     22, 'day' );
    }
    else
    {
        diag( 'Error: ' . ( $fmt->error // 'unknown' ) );
    }
};

# NOTE: Trailing text after match (non-strict)
subtest 'trailing text after match (non-strict)' => sub
{
    my $fmt = DateTime::Format::Lite->new( pattern => '%Y-%m-%d', on_error => 'undef' );
    ok( defined( $fmt ), 'constructor succeeded' );

    my $dt = $fmt->parse_datetime( '2016-01-13 in the afternoon' );
    if( ok( defined( $dt ), 'parsed with trailing text' ) )
    {
        is( $dt->year,  2016, 'year' );
        is( $dt->month,    1, 'month' );
        is( $dt->day,     13, 'day' );
    }
    else
    {
        diag( 'Error: ' . ( $fmt->error // 'unknown' ) );
    }
};

# NOTE: Leading text before match (non-strict)
subtest 'leading text before match (non-strict)' => sub
{
    my $fmt = DateTime::Format::Lite->new( pattern => '%Y-%m-%d', on_error => 'undef' );
    ok( defined( $fmt ), 'constructor succeeded' );

    my $dt = $fmt->parse_datetime( 'log entry: 2016-03-31.bak' );
    if( ok( defined( $dt ), 'parsed with surrounding text' ) )
    {
        is( $dt->year,  2016, 'year' );
        is( $dt->month,    3, 'month' );
        is( $dt->day,     31, 'day' );
    }
    else
    {
        diag( 'Error: ' . ( $fmt->error // 'unknown' ) );
    }
};

# NOTE: Strict mode: no match with surrounding text when boundary fails
subtest 'strict mode rejects partial match at start' => sub
{
    my $fmt = DateTime::Format::Lite->new( pattern => '%d-%m-%y', on_error => 'undef', strict => 1 );
    ok( defined( $fmt ), 'constructor succeeded' );

    my $warning = '';
    local $SIG{__WARN__} = sub{ $warning = join( '', @_ ) };
    my $dt = $fmt->parse_datetime( '2016-11-30' );
    ok( !defined( $dt ), 'strict mode rejects non-matching input' );
};

subtest 'strict mode rejects partial match at end' => sub
{
    my $fmt = DateTime::Format::Lite->new( pattern => '%d-%m-%y', on_error => 'undef', strict => 1 );
    ok( defined( $fmt ), 'constructor succeeded' );

    my $warning = '';
    local $SIG{__WARN__} = sub{ $warning = join( '', @_ ) };
    my $dt = $fmt->parse_datetime( '30-11-2016' );
    ok( !defined( $dt ), 'strict mode rejects trailing digits' );
};

# NOTE: Month name match is not too greedy
subtest 'month name match not greedy' => sub
{
    my $fmt = DateTime::Format::Lite->new( pattern => '%d%b%y', on_error => 'undef' );
    ok( defined( $fmt ), 'constructor succeeded' );

    my $dt = $fmt->parse_datetime( '15Aug07' );
    if( ok( defined( $dt ), 'parsed' ) )
    {
        is( $dt->year,  2007, 'year' );
        is( $dt->month,    8, 'month' );
        is( $dt->day,     15, 'day' );
    }
    else
    {
        diag( 'Error: ' . ( $fmt->error // 'unknown' ) );
    }
};

# NOTE: ISO8601 with trailing Z (treated as literal suffix in non-strict)
subtest 'ISO8601 with trailing Z ignored in non-strict' => sub
{
    my $fmt = DateTime::Format::Lite->new( pattern => '%Y%m%d%H%M%S', on_error => 'undef' );
    ok( defined( $fmt ), 'constructor succeeded' );

    my $dt = $fmt->parse_datetime( '20161214233712Z' );
    if( ok( defined( $dt ), 'parsed' ) )
    {
        is( $dt->year,   2016, 'year' );
        is( $dt->month,    12, 'month' );
        is( $dt->day,      14, 'day' );
        is( $dt->hour,     23, 'hour' );
        is( $dt->minute,   37, 'minute' );
        is( $dt->second,   12, 'second' );
    }
    else
    {
        diag( 'Error: ' . ( $fmt->error // 'unknown' ) );
    }
};

# NOTE: parser time zone set on returned object takes precedence over parsed %Z
subtest 'formatter time_zone overrides parsed %Z' => sub
{
    my $fmt = DateTime::Format::Lite->new(
        pattern   => '%Y %H:%M:%S %Z',
        time_zone => 'America/New_York',
        on_error  => 'undef',
    );
    ok( defined( $fmt ), 'constructor succeeded' );

    my $dt = $fmt->parse_datetime( '2003 23:45:56 MDT' );
    if( ok( defined( $dt ), 'parsed' ) )
    {
        is( $dt->time_zone->name, 'America/New_York', 'formatter time_zone wins' );
    }
    else
    {
        diag( 'Error: ' . ( $fmt->error // 'unknown' ) );
    }
};

done_testing();

__END__
