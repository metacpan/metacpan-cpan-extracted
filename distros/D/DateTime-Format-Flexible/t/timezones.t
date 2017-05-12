#!/usr/bin/perl

use strict;
use warnings;

use DateTime::Format::Flexible;
use DateTime::TimeZone;

use Test::More;

my $num_tests = 4;

my @DATA = <DATA>;
$num_tests += scalar( @DATA ) * 2;

my @TZS = DateTime::TimeZone->all_names;
$num_tests += scalar( @TZS ) * 2;

plan tests => $num_tests;

{
    my $dt = DateTime::Format::Flexible->parse_datetime( '2009-10-06 GMT.' , strip => qr{\.\z} );
    is( $dt->datetime , '2009-10-06T00:00:00' , 'GMT. timezone parsed/stripped' );
    is( $dt->time_zone->name , 'UTC' , 'GMT. timezone set correctly' );
}

{
    my $dt = DateTime::Format::Flexible->parse_datetime( '2010-08-01 14:25:14+09.' , strip => qr{\.\z} );
    is( $dt->datetime , '2010-08-01T14:25:14' , '+09. timezone parsed/stripped' );
    is( $dt->time_zone->name , '+0900' , '+09. timezone set correctly' );
}

foreach my $tz ( DateTime::TimeZone->all_names )
{
    my $dt = DateTime::Format::Flexible->parse_datetime( '2010-01-24T04:58:23 '.$tz );
    is( $dt->datetime , '2010-01-24T04:58:23' , "$tz parsed" );
    is( $dt->time_zone->name , $tz , "$tz timezone set correctly" );
}

foreach my $line ( @DATA )
{
    chomp $line;
    my ( $given , $wanted , $tz ) = split m{\s+=>\s+}mx , $line;
    compare( $given , $wanted , $tz );
}

sub compare
{
    my ( $given , $wanted , $tz ) = @_;
    my $dt = DateTime::Format::Flexible->parse_datetime( $given , strip => qr{\.\z} );
    is( $dt->datetime , $wanted , "$given => $wanted" );
    is( $dt->time_zone->name , $tz , "$tz timezone set correctly" );
}


__DATA__
2016-08-23 01:56:57+09. => 2016-08-23T01:56:57 => +0900
2012-04-13 23:33:44+09. => 2012-04-13T23:33:44 => +0900
2014-02-23 17:48:32+09. => 2014-02-23T17:48:32 => +0900
2011-06-08 13:00:00+09. => 2011-06-08T13:00:00 => +0900
2013-09-20 02:25:41+09. => 2013-09-20T02:25:41 => +0900
2010-01-07 11:42:46+09. => 2010-01-07T11:42:46 => +0900
2012-01-06 14:00:00+09. => 2012-01-06T14:00:00 => +0900
2009-07-28 19:04:26+09. => 2009-07-28T19:04:26 => +0900
2010-03-18 14:00:00+09. => 2010-03-18T14:00:00 => +0900
2009-11-17 11:27:58+09. => 2009-11-17T11:27:58 => +0900
2010-02-14 20:42:33+09. => 2010-02-14T20:42:33 => +0900
2013-04-14 13:00:00+09. => 2013-04-14T13:00:00 => +0900
2010-02-02 12:06:45+09. => 2010-02-02T12:06:45 => +0900
2009-05-21 01:27:48+09. => 2009-05-21T01:27:48 => +0900
2010-08-01 14:25:14+09. => 2010-08-01T14:25:14 => +0900
Mon Apr 05 17:25:35 +0000 2010 => 2010-04-05T17:25:35 => UTC
Mon Apr 05 17:25:35 +0100 2010 => 2010-04-05T17:25:35 => +0100
Mon Apr 05 17:25:35 -0100 2010 => 2010-04-05T17:25:35 => -0100
2010-08-01 14:25:14 +09:00 => 2010-08-01T14:25:14 => +0900
2010-08-01 14:25:14 -06:00 => 2010-08-01T14:25:14 => -0600
00241121 America/Chicago => 0024-11-21T00:00:00 => America/Chicago
