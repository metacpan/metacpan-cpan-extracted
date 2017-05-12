#!/usr/bin/perl

use strict;
use warnings;
use lib '.';

use Test::More tests => 8;

use t::lib::helper;

use DateTime::Format::Flexible;

{
    my $dt = DateTime::Format::Flexible->parse_datetime(
        'Wed Nov 11 13:55:48 PST 2009' ,
        tz_map => { PST => 'America/Los_Angeles' } ,
    );
    is( $dt->datetime , '2009-11-11T13:55:48' ,
        'internal PST timezone parsed/stripped' );
    is( $dt->time_zone->name , 'America/Los_Angeles' ,
        'internal PST timezone set correctly' );
}

{
    my $dt = DateTime::Format::Flexible->parse_datetime(
        '17:37:03 MST 03/04/2013', lang => ['en'],
    );
    is( $dt->datetime , '2013-03-04T17:37:03' ,
        'internal timezone mm/dd/yyyy, lang timezone map' );
    is( $dt->time_zone->name , 'America/Denver' ,
        'internal timezone set correctly lang timezone map' );
}

{
    my $dt = DateTime::Format::Flexible->parse_datetime(
        '17:47:07 MST 2013/03/04', lang => ['en'],
    );
    is( $dt->datetime , '2013-03-04T17:47:07' ,
        'internal timezone yyyy/mm/dd works, lang timezone map' );
    is( $dt->time_zone->name , 'America/Denver' ,
        'internal timezone yyyy/mm/dd, lang timezone map' );
}


t::lib::helper::run_tests(
   'Wed Nov 11 13:55:48 PST 2009 => 2009-11-11T13:55:48',
   'Wed Nov 11 18:55:16 PST 2009 => 2009-11-11T18:55:16',
);
