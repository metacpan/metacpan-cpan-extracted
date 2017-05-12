#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 100;

use DateTime::Format::Flexible;

{
    my $dt = DateTime::Format::Flexible->parse_datetime(
        '25-Jun-2009 EDT.' ,
        strip => qr{\.\z} ,
        tz_map => { EDT => 'America/New_York' } ,
    );
    is( $dt->datetime , '2009-06-25T00:00:00' , 'EDT. timezone parsed/stripped' );
    is( $dt->time_zone->name , 'America/New_York' , 'EDT. timezone set correctly' );
}

foreach my $line ( <DATA> )
{
    chomp $line;
    my ( $given , $wanted , $tz ) = split m{\s+=>\s+}mx , $line;
    compare( $given , $wanted , $tz );
}

sub compare
{
    my ( $given , $wanted , $tz ) = @_;
    my $dt = DateTime::Format::Flexible->parse_datetime(
        $given ,
        strip => [qr{\.\z},qr{\(JST\)}] ,
        tz_map => { EDT => 'America/New_York' }
    );
    is( $dt->datetime , $wanted , "$given => $wanted" );
    if ( $tz )
    {
        is( $dt->time_zone->name , $tz , "$tz timezone set correctly" );
    }
}


__DATA__
2009-12-04 03:14:54(JST) => 2009-12-04T03:14:54
2009-11-02 19:49:10(JST) => 2009-11-02T19:49:10
2009-06-11 17:13:59(JST) => 2009-06-11T17:13:59
2010-01-18 17:59:57(JST) => 2010-01-18T17:59:57
2009-07-22 13:19:22(JST) => 2009-07-22T13:19:22
2009-04-17 11:29:58(JST) => 2009-04-17T11:29:58
2009-11-13 13:01:26(JST) => 2009-11-13T13:01:26
2010-02-16 15:36:25(JST) => 2010-02-16T15:36:25
2011-08-11 GMT. => 2011-08-11T00:00:00 => UTC
2009-08-18 GMT. => 2009-08-18T00:00:00 => UTC
2014-04-18 GMT. => 2014-04-18T00:00:00 => UTC
2010-02-25 GMT. => 2010-02-25T00:00:00 => UTC
2009-11-26 GMT. => 2009-11-26T00:00:00 => UTC
2010-01-25 GMT. => 2010-01-25T00:00:00 => UTC
2010-02-17 GMT. => 2010-02-17T00:00:00 => UTC
2009-05-03 GMT. => 2009-05-03T00:00:00 => UTC
2009-10-20 GMT. => 2009-10-20T00:00:00 => UTC
2009-11-13 GMT. => 2009-11-13T00:00:00 => UTC
2016-11-14 GMT. => 2016-11-14T00:00:00 => UTC
2010-03-06 GMT. => 2010-03-06T00:00:00 => UTC
2014-07-07 GMT. => 2014-07-07T00:00:00 => UTC
2010-11-08 GMT. => 2010-11-08T00:00:00 => UTC
2009-12-27 GMT. => 2009-12-27T00:00:00 => UTC
2009-05-04 GMT. => 2009-05-04T00:00:00 => UTC
2009-05-08 GMT. => 2009-05-08T00:00:00 => UTC
2010-05-08 GMT. => 2010-05-08T00:00:00 => UTC
2010-01-27 GMT. => 2010-01-27T00:00:00 => UTC
2009-12-10 GMT. => 2009-12-10T00:00:00 => UTC
2010-04-18 GMT. => 2010-04-18T00:00:00 => UTC
2010-03-21 GMT. => 2010-03-21T00:00:00 => UTC
2010-09-24 GMT. => 2010-09-24T00:00:00 => UTC
2009-08-20 GMT. => 2009-08-20T00:00:00 => UTC
2009-11-27 GMT. => 2009-11-27T00:00:00 => UTC
2009-11-05 GMT. => 2009-11-05T00:00:00 => UTC
2009-09-05 GMT. => 2009-09-05T00:00:00 => UTC
2009-09-02 GMT. => 2009-09-02T00:00:00 => UTC
2009-11-27 GMT. => 2009-11-27T00:00:00 => UTC
2011-07-17 GMT. => 2011-07-17T00:00:00 => UTC
2010-08-03 GMT. => 2010-08-03T00:00:00 => UTC
2012-03-06 GMT. => 2012-03-06T00:00:00 => UTC
2009-08-08 GMT. => 2009-08-08T00:00:00 => UTC
2010-03-19 GMT. => 2010-03-19T00:00:00 => UTC
2011-06-15 GMT. => 2011-06-15T00:00:00 => UTC
2012-09-21 GMT. => 2012-09-21T00:00:00 => UTC
2011-03-17 GMT. => 2011-03-17T00:00:00 => UTC
2009-10-29 GMT. => 2009-10-29T00:00:00 => UTC
2009-10-06 GMT. => 2009-10-06T00:00:00 => UTC
12-Nov-2009 EDT. => 2009-11-12T00:00:00 => America/New_York
06-Mar-2011 EDT. => 2011-03-06T00:00:00 => America/New_York
09-May-2009 EDT. => 2009-05-09T00:00:00 => America/New_York
26-May-2009 EDT. => 2009-05-26T00:00:00 => America/New_York
25-Jun-2009 EDT. => 2009-06-25T00:00:00 => America/New_York
01-Oct-2009 EDT. => 2009-10-01T00:00:00 => America/New_York
