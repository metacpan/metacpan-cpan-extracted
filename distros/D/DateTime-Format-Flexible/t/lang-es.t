#!/usr/bin/perl

use strict;
use warnings;
use lib '.';

use Test::More tests => 15;
use DateTime;

use t::lib::helper;

use DateTime::Format::Flexible;

my $curr_year = DateTime->now->year;

{
    my $dt = DateTime::Format::Flexible->parse_datetime(
        '12/10/54' , lang => ['es'], european => 1,
    );
    is( $dt->datetime , '2054-10-12T00:00:00' , '12/10/54 => 2054-10-12T00:00:00' );
}

{
    my $dt = DateTime::Format::Flexible->parse_datetime(
        '29.2.96' , lang => ['es'], european => 1,
    );
    is( $dt->datetime , '1996-02-29T00:00:00' , '29.2.96 => 1996-02-29T00:00:00' );
}

t::lib::helper::run_tests(
    '29 de febrero de 1996 => 1996-02-29T00:00:00',
    'Mayo 24 2009 => 2009-05-24T00:00:00',
    'martes 12 de octubre de 1954 => 1954-10-12T00:00:00',
    '8 de abril 2000 => 2000-04-08T00:00:00',
    '30 de octubre de 1977 => 1977-10-30T00:00:00',
    '2 de enero de 2000 => 2000-01-02T00:00:00',
    "4 de julio => $curr_year-07-04T00:00:00",
    '25 de diciembre de 2000 => 2000-12-25T00:00:00',
    "3 de agosto => $curr_year-08-03T00:00:00",
    'epoca => 1970-01-01T00:00:00',
);

{
    my $dt = DateTime::Format::Flexible->parse_datetime( '-infinito' );
    ok ( $dt->is_infinite() , "-infinito is infinite" );
}

{
    my $dt = DateTime::Format::Flexible->parse_datetime( 'infinito' );
    ok ( $dt->is_infinite() , "infinito is infinite" );
}

{
    my ( $base_dt ) = DateTime::Format::Flexible->parse_datetime( '2005-06-07T13:14:15' );
    DateTime::Format::Flexible->base( $base_dt );
    my $dt = DateTime::Format::Flexible->parse_datetime( 'Hace 3 años' );
    is( $dt->datetime, '2002-06-07T13:14:15', 'Hace 3 años => 3 years ago' );
}
