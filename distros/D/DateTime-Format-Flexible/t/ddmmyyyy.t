#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;

use DateTime::Format::Flexible;

foreach my $line ( <DATA> )
{
    chomp $line;
    my ( $given , $wanted ) = split m{\s+=>\s+}mx , $line;
    compare( $given , $wanted );
}

sub compare
{
    my ( $given , $wanted ) = @_;
    my $dt = DateTime::Format::Flexible->parse_datetime(
        $given ,
        european => 1 ,
    );
    is( $dt->datetime , $wanted , "$given => $wanted" );
}


__DATA__
16/06/2010 => 2010-06-16T00:00:00
11/09/2010 => 2010-09-11T00:00:00
04/03/2011 => 2011-03-04T00:00:00
09/11/2012 => 2012-11-09T00:00:00
