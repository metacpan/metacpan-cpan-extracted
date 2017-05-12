#!/usr/bin/perl

use strict;
use warnings;
use lib '.';

use Test::More tests => 144;

use DateTime::Format::Flexible;
my $base = 'DateTime::Format::Flexible';

my ( $base_dt ) = $base->parse_datetime( '2005-06-07T13:14:15' );
$base->base( $base_dt );

use t::lib::helper;

my $now = DateTime->now;

t::lib::helper::run_tests(
    [lang => 'en'],
    'now => 2005-06-07T13:14:15',
    'Now => 2005-06-07T13:14:15',
    'Today => 2005-06-07T00:00:00',
    'yesterday => 2005-06-06T00:00:00',
    'tomorrow => 2005-06-08T00:00:00',
    'overmorrow => 2005-06-09T00:00:00',
    'today at 4:00 => 2005-06-07T04:00:00',
    'today at 16:00:00:05 => 2005-06-07T16:00:00',
    'today at 12:00 am => 2005-06-07T00:00:00',
    'today at 12:00 GMT => 2005-06-07T12:00:00 => UTC',
    'today at 4:00 -0800 => 2005-06-07T04:00:00 => -0800',
    'today at noon => 2005-06-07T12:00:00',
    'tomorrow at noon => 2005-06-08T12:00:00',
    '1 month ago => 2005-05-07T13:14:15',
    '1 month ago at 4pm => 2005-05-07T16:00:00',

    '1 month from now => 2005-07-07T13:14:15',
    '1 month from now at 4pm => 2005-07-07T16:00:00',

    '3 years ago => 2002-06-07T13:14:15',
    '3 years from now => 2008-06-07T13:14:15',

    'monday => 2005-06-13T00:00:00',
    'tuesday => 2005-06-07T00:00:00',
    'wednesday => 2005-06-08T00:00:00',
    'thursday => 2005-06-09T00:00:00',
    'friday => 2005-06-10T00:00:00',
    'saturday => 2005-06-11T00:00:00',
    'sunday => 2005-06-12T00:00:00',
    'sunday at 3p => 2005-06-12T15:00:00',
    'mon => 2005-06-13T00:00:00',
    'tue => 2005-06-07T00:00:00',
    'wed => 2005-06-08T00:00:00',
    'thu => 2005-06-09T00:00:00',
    'fri => 2005-06-10T00:00:00',
    'sat => 2005-06-11T00:00:00',
    'sun => 2005-06-12T00:00:00',
    'sunday at 3p => 2005-06-12T15:00:00',
    'next sunday at 3p => 2005-06-12T15:00:00',
    'january => 2005-01-01T00:00:00',
    'february => 2005-02-01T00:00:00',
    'march => 2005-03-01T00:00:00',
    'april => 2005-04-01T00:00:00',
    'may => 2005-05-01T00:00:00',
    'june => 2005-06-01T00:00:00',
    'july => 2005-07-01T00:00:00',
    'august => 2005-08-01T00:00:00',
    'september => 2005-09-01T00:00:00',
    'october => 2005-10-01T00:00:00',
    'november => 2005-11-01T00:00:00',
    'december => 2005-12-01T00:00:00',
    'allballs => 2005-06-07T00:00:00',
    'epoch => 1970-01-01T00:00:00',

    'today midnight => 2005-06-07T00:00:00',

    'next Monday => 2005-06-13T00:00:00',
    'next Tuesday => 2005-06-14T00:00:00',
    'next Wednesday => 2005-06-08T00:00:00',
    'next Thursday => 2005-06-09T00:00:00',
    'next Friday => 2005-06-10T00:00:00',
    'next Saturday => 2005-06-11T00:00:00',
    'next Sunday => 2005-06-12T00:00:00',

    'next Mon => 2005-06-13T00:00:00',
    'next Tue => 2005-06-14T00:00:00',
    'next Wed => 2005-06-08T00:00:00',
    'next Thu => 2005-06-09T00:00:00',
    'next Fri => 2005-06-10T00:00:00',
    'next Sat => 2005-06-11T00:00:00',
    'next Sun => 2005-06-12T00:00:00',

    'next January => 2006-01-01T00:00:00',
    'next February => 2006-02-01T00:00:00',
    'next March => 2006-03-01T00:00:00',
    'next April => 2006-04-01T00:00:00',
    'next May => 2006-05-01T00:00:00',
    'next June => 2006-06-01T00:00:00',
    'next July => 2005-07-01T00:00:00',
    'next August => 2005-08-01T00:00:00',
    'next September => 2005-09-01T00:00:00',
    'next October => 2005-10-01T00:00:00',
    'next November => 2005-11-01T00:00:00',
    'next December => 2005-12-01T00:00:00',

    'next Jan => 2006-01-01T00:00:00',
    'next Feb => 2006-02-01T00:00:00',
    'next Mar => 2006-03-01T00:00:00',
    'next Apr => 2006-04-01T00:00:00',
    'next Jun => 2006-06-01T00:00:00',
    'next Jul => 2005-07-01T00:00:00',
    'next Aug => 2005-08-01T00:00:00',
    'next Sep => 2005-09-01T00:00:00',
    'next Sept => 2005-09-01T00:00:00',
    'next Oct => 2005-10-01T00:00:00',
    'next Nov => 2005-11-01T00:00:00',
    'next Dec => 2005-12-01T00:00:00',

    'last January => 2005-01-01T00:00:00',
    'last February => 2005-02-01T00:00:00',
    'last March => 2005-03-01T00:00:00',
    'last April => 2005-04-01T00:00:00',
    'last May => 2005-05-01T00:00:00',
    'last June => 2004-06-01T00:00:00',
    'last July => 2004-07-01T00:00:00',
    'last August => 2004-08-01T00:00:00',
    'last September => 2004-09-01T00:00:00',
    'last October => 2004-10-01T00:00:00',
    'last November => 2004-11-01T00:00:00',
    'last December => 2004-12-01T00:00:00',

    'last Jan => 2005-01-01T00:00:00',
    'last Feb => 2005-02-01T00:00:00',
    'last Mar => 2005-03-01T00:00:00',
    'last Apr => 2005-04-01T00:00:00',
    'last Jun => 2004-06-01T00:00:00',
    'last Jul => 2004-07-01T00:00:00',
    'last Aug => 2004-08-01T00:00:00',
    'last Sep => 2004-09-01T00:00:00',
    'last Sept => 2004-09-01T00:00:00',
    'last Oct => 2004-10-01T00:00:00',
    'last Nov => 2004-11-01T00:00:00',
    'last Dec => 2004-12-01T00:00:00',

    'last Monday => 2005-06-06T00:00:00',
    'last Tuesday => 2005-05-31T00:00:00',
    'last Wednesday => 2005-06-01T00:00:00',
    'last Thursday => 2005-06-02T00:00:00',
    'last Friday => 2005-06-03T00:00:00',
    'last Saturday => 2005-06-04T00:00:00',
    'last Sunday => 2005-06-05T00:00:00',

    'last Mon => 2005-06-06T00:00:00',
    'last Tue => 2005-05-31T00:00:00',
    'last Wed => 2005-06-01T00:00:00',
    'last Thu => 2005-06-02T00:00:00',
    'last Fri => 2005-06-03T00:00:00',
    'last Sat => 2005-06-04T00:00:00',
    'last Sun => 2005-06-05T00:00:00',

    '-3 months => 2005-03-07T13:14:15',
    '+3 months => 2005-09-07T13:14:15',

    '-3 days => 2005-06-04T13:14:15',
    '+3 days => 2005-06-10T13:14:15',

    '-3 months noon => 2005-03-07T12:00:00',
    '-3 months at 4pm => 2005-03-07T16:00:00',

    '+3 months noon => 2005-09-07T12:00:00',
    '+3 months at 4pm => 2005-09-07T16:00:00',

    '-1 week => 2005-05-31T13:14:15',
    '+2 weeks midnight => 2005-06-21T00:00:00',

);


#######################
{
    my $str = ( 'today at 16:00:00:05' );
    my $dt = $base->parse_datetime( $str );
    is ( $dt->nanosecond , '05' , "nanoseconds are set ($str)" );
}

{
    my ( $str , $wanted ) = ( 'today at 4:00 PST' , '2005-06-07T04:00:00' );
    my $dt = $base->parse_datetime( $str , tz_map => { PST => 'America/Los_Angeles' } );
    is ( $dt->datetime , $wanted , "$str => $wanted ($dt)" );
    is ( $dt->time_zone->name , 'America/Los_Angeles' , "timezone set ($str)" );
}

{
    my $dt = DateTime::Format::Flexible->parse_datetime( '-infinity' );
    ok ( $dt->is_infinite() , "-infinity is infinite" );
}

{
    my $dt = DateTime::Format::Flexible->parse_datetime( 'infinity' );
    ok ( $dt->is_infinite() , "infinity is infinite" );
}
