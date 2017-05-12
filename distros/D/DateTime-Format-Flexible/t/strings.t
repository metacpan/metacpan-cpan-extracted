#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 23;

use DateTime::Format::Flexible;
my $base = 'DateTime::Format::Flexible';

my $now = DateTime->now;

# these wont be exact on slow computers so lets just make sure they parse
foreach my $string ( qw( now Now Today yesterday tomorrow overmorrow ) )
{
    my $dt = eval { $base->parse_datetime( $string ) };
    fail( $@ ) if ( $@ );
    is ( ref( $dt ) , 'DateTime' , "can parse '$string' => $dt " );
}

{
    my ( $str , $method , $wanted ) = ( 'today' , 'hms' , '00:00:00' );
    my $dt = $base->parse_datetime( $str );
    is ( $dt->$method , $wanted , "$str => $wanted with ->$method ($dt)" );
}

{
    my ( $str , $method , $wanted ) = ( 'today at 4:00' , 'hms' , '04:00:00' );
    my $dt = $base->parse_datetime( $str );
    is ( $dt->$method , $wanted , "$str => $wanted with ->$method ($dt)" );
}

{
    my ( $str , $method , $wanted ) = ( 'today at 16:00:00:05' , 'hms' , '16:00:00' );
    my $dt = $base->parse_datetime( $str );
    is ( $dt->$method , $wanted , "$str => $wanted with ->$method ($dt)" );
    is ( $dt->nanosecond , '05' , "nanoseconds are set ($str)" );
}

{
    my ( $str , $method , $wanted ) = ( 'today at 12:00 am' , 'hms' , '00:00:00' );
    my $dt = $base->parse_datetime( $str );
    is ( $dt->$method , $wanted , "$str => $wanted with ->$method ($dt)" );
}

{
    my ( $str , $method , $wanted ) = ( 'today at 12:00 GMT' , 'hms' , '12:00:00' );
    my $dt = $base->parse_datetime( $str );
    is ( $dt->$method , $wanted , "$str => $wanted with ->$method ($dt)" );
    is ( $dt->time_zone->name , 'UTC' , "timezone set ($str)" );
}

{
    my ( $str , $method , $wanted ) = ( 'today at 4:00 PST' , 'hms' , '04:00:00' );
    my $dt = $base->parse_datetime( $str , tz_map => { PST => 'America/Los_Angeles' } );
    is ( $dt->$method , $wanted , "$str => $wanted with ->$method ($dt)" );
    is ( $dt->time_zone->name , 'America/Los_Angeles' , "timezone set ($str)" );
}

{
    my ( $str , $method , $wanted ) = ( 'today at 4:00 -0800' , 'hms' , '04:00:00' );
    my $dt = $base->parse_datetime( $str );
    is ( $dt->$method , $wanted , "$str => $wanted with ->$method ($dt)" );
    is ( $dt->time_zone->name , '-0800' , "timezone set ($str)" );
}

{
    my ( $str , $method , $wanted )  = ( 'today at noon' , 'hms' , '12:00:00' );
    my $dt = $base->parse_datetime( $str );
    is ( $dt->$method , $wanted , "$str => $wanted with ->$method ($dt)" );
}

{
    my ( $str , $method , $wanted )  = ( 'tomorrow at noon' , 'hms' , '12:00:00' );
    my $dt = $base->parse_datetime( $str );
    is ( $dt->$method , $wanted , "$str => $wanted with ->$method ($dt)" );
}

{
    my ( $str )  = ( '1 month ago' );
    my $dt = eval { $base->parse_datetime( $str ) };
    fail( $@ ) if ( $@ );
    SKIP:
    {
        skip 'no reason to check length if not valid DT object' if ! ref( $dt ) eq 'DateTime';
        my $seconds_diff = $now->subtract_datetime_absolute( $dt )->seconds;
        cmp_ok( $seconds_diff , '>' , 60 * 60 * 24 * 28 , "we have subtracted at least 28 days ($str => $dt)" );
    };
}

{
    my ( $str )  = ( '1 month ago' );
    my $dt = eval { $base->parse_datetime( $str ) };
    fail( $@ ) if ( $@ );
    SKIP:
    {
        skip 'no reason to check length if not valid DT object' if ! ref( $dt ) eq 'DateTime';
        my $seconds_diff = $now->subtract_datetime_absolute( $dt )->seconds;
        cmp_ok( $seconds_diff , '>' , 60 * 60 * 24 * 28 , "we have subtracted at least 28 days ($str => $dt)" );
    };
}

{
    my ( $str , $method , $wanted )  = ( '1 month ago at 4pm' , 'hms' , '16:00:00' );
    my $dt = eval { $base->parse_datetime( $str ) };
    SKIP:
    {
        skip "no reason to check length if not valid DT object: $@" if ! ref( $dt ) eq 'DateTime';
        my $seconds_diff = $now->subtract_datetime_absolute( $dt )->seconds;
        is ( $dt->$method , $wanted , "$str => $wanted with ->$method ($dt)" );
        cmp_ok( $seconds_diff , '>' , 60 * 60 * 24 * 27 , "we have subtracted at least 27 days ($str => $dt)" );

    };
}
