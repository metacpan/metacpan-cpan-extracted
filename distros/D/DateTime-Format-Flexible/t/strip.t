#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 33;

my $base = 'DateTime::Format::Flexible';

use DateTime::Format::Flexible;

{
    my $dt = DateTime::Format::Flexible->parse_datetime(
        '2011-04-26 00:00:00 (registry time)' ,
        strip => [qr{\(registry time\)\z}] ,
    );
    is( $dt->datetime , '2011-04-26T00:00:00' , 'strip arrayref works' );
}

{
    my $dt = DateTime::Format::Flexible->parse_datetime(
        '2011-04-26 00:00:00 (registry time)' ,
        strip => qr{\(registry time\)\z} ,
    );
    is( $dt->datetime , '2011-04-26T00:00:00' , 'strip no arrayref works' );
}

{
    my $dt = eval {DateTime::Format::Flexible->parse_datetime(
        '2011-04-26 00:00:00 (registry time)' ,
        strip => '(registry time)' ,
    )};
    like( $@ , qr{strip requires a regular expression} , 'correct error thrown on bad strip parameter' );
}


foreach my $line ( <DATA> )
{
    chomp $line;
    my ( $given , $wanted ) = split m{\s+=>\s+}mx , $line;
    compare( $given , $wanted );
}

sub compare
{
    my ( $given , $wanted ) = @_;
    my $dt = $base->parse_datetime( $given , strip => qr{\(registry time\)\z} );
    is( $dt->datetime , $wanted , "$given => $wanted" );
}

__DATA__
2010-03-24 00:00:00 (registry time) => 2010-03-24T00:00:00
2009-10-01 00:00:00 (registry time) => 2009-10-01T00:00:00
2009-10-06 00:00:00 (registry time) => 2009-10-06T00:00:00
2009-06-06 00:00:00 (registry time) => 2009-06-06T00:00:00
2009-04-10 00:00:00 (registry time) => 2009-04-10T00:00:00
2009-09-14 00:00:00 (registry time) => 2009-09-14T00:00:00
2009-12-18 00:00:00 (registry time) => 2009-12-18T00:00:00
2010-02-19 00:00:00 (registry time) => 2010-02-19T00:00:00
2010-07-31 00:00:00 (registry time) => 2010-07-31T00:00:00
2010-01-08 00:00:00 (registry time) => 2010-01-08T00:00:00
2009-06-25 00:00:00 (registry time) => 2009-06-25T00:00:00
2009-07-01 00:00:00 (registry time) => 2009-07-01T00:00:00
2009-11-21 00:00:00 (registry time) => 2009-11-21T00:00:00
2009-06-25 00:00:00 (registry time) => 2009-06-25T00:00:00
2009-04-01 00:00:00 (registry time) => 2009-04-01T00:00:00
2009-04-19 00:00:00 (registry time) => 2009-04-19T00:00:00
2010-04-04 00:00:00 (registry time) => 2010-04-04T00:00:00
2009-07-08 00:00:00 (registry time) => 2009-07-08T00:00:00
2009-09-09 00:00:00 (registry time) => 2009-09-09T00:00:00
2009-12-12 00:00:00 (registry time) => 2009-12-12T00:00:00
2009-11-25 00:00:00 (registry time) => 2009-11-25T00:00:00
2009-11-22 00:00:00 (registry time) => 2009-11-22T00:00:00
2010-02-02 00:00:00 (registry time) => 2010-02-02T00:00:00
2009-11-06 00:00:00 (registry time) => 2009-11-06T00:00:00
2010-03-23 00:00:00 (registry time) => 2010-03-23T00:00:00
2009-05-27 00:00:00 (registry time) => 2009-05-27T00:00:00
2012-02-20 00:00:00 (registry time) => 2012-02-20T00:00:00
2010-11-25 00:00:00 (registry time) => 2010-11-25T00:00:00
2009-09-16 00:00:00 (registry time) => 2009-09-16T00:00:00
2011-04-26 00:00:00 (registry time) => 2011-04-26T00:00:00
