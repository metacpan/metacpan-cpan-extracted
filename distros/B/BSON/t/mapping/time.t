use 5.008001;
use strict;
use warnings;
use utf8;

use Test::More 0.96;

binmode( Test::More->builder->$_, ":utf8" )
  for qw/output failure_output todo_output/;

use lib 't/lib';
use lib 't/pvtlib';
use CleanEnv;
use TestUtils;

use BSON qw/encode decode/;
use BSON::Types ':all';

my ( $bson, $expect, $hash );

my $now = time;

# test constructor
ok( bson_time() >= $now, "empty bson_time() is current time (or so)" );
ok( BSON::Time->new >= $now, "empty BSON::Time constructor is curren time (or so)" );

# test overloading
is( bson_time($now),    $now, "BSON::Time string overload" );
is( 0+ bson_time($now), $now, "BSON::Time string overload" );

# BSON::Time -> BSON::Time
$bson = $expect = encode( { A => bson_time($now) } );
$hash = decode($bson);
is( ref( $hash->{A} ), 'BSON::Time', "BSON::Time->BSON::Time" );
is( "$hash->{A}",      $now,         "value correct" );

# DateTime -> BSON::Time
SKIP: {
    eval { require DateTime };
    skip( "DateTime not installed", 1 )
      unless $INC{'DateTime.pm'};
    $bson = encode( { A => DateTime->from_epoch( epoch => $now ) } );
    $hash = decode($bson);
    is( ref( $hash->{A} ), 'BSON::Time', "DateTime->BSON::Time" );
    is( "$hash->{A}",      $now,         "value correct" );
    is( $bson,             $expect,      "BSON correct" );

    # conversion
    my $obj = $hash->{A}->as_datetime;
    isa_ok( $obj, 'DateTime', 'as_datetime' );
    is($obj->epoch, $now, "epoch");
}

# DateTime::Tiny -> BSON::Time
SKIP: {
    eval { require DateTime::Tiny };
    skip( "DateTime::Tiny not installed", 1 )
      unless $INC{'DateTime/Tiny.pm'};
    my ($s,$m,$h,$D,$M,$Y) = gmtime($now);
    my $dt = DateTime::Tiny->new(
        year => $Y + 1900, month => $M + 1, day => $D,
        hour => $h, minute => $m, second => $s
    );
    $bson = encode( { A => $dt } );
    $hash = decode($bson);
    is( ref( $hash->{A} ), 'BSON::Time', "DateTime::Tiny->BSON::Time" );
    is( "$hash->{A}",      $now,         "value correct" );
    is( $bson,             $expect,      "BSON correct" );

    # conversion
    my $obj = $hash->{A}->as_datetime_tiny;
    isa_ok( $obj, 'DateTime::Tiny', 'as_datetime_tiny' );
    is($obj->as_string . "Z", $hash->{A}->as_iso8601, "iso8601");
}

# Time::Moment -> BSON::Time
SKIP: {
    eval { require Time::Moment };
    skip( "Time::Moment not installed", 1 )
      unless $INC{'Time/Moment.pm'};
    $bson = encode( { A => Time::Moment->from_epoch( $now ) } );
    $hash = decode($bson);
    is( ref( $hash->{A} ), 'BSON::Time', "Time::Moment->BSON::Time" );
    is( "$hash->{A}",      $now,         "value correct" );
    is( $bson,             $expect,      "BSON correct" );

    # conversion
    my $obj = $hash->{A}->as_time_moment;
    isa_ok( $obj, 'Time::Moment', 'as_time_moment' );
    is($obj->epoch, $now, "epoch");
}

# Mango::BSON::Time -> BSON::Time
SKIP: {
    eval { require Mango::BSON::Time };
    skip( "Mango::BSON::Time not installed", 1 )
      unless $INC{'Mango/BSON/Time.pm'};
    $bson = encode( { A => Mango::BSON::Time->new( $now * 1000 ) } );
    $hash = decode($bson);
    is( ref( $hash->{A} ), 'BSON::Time', "Mango::BSON::Time->BSON::Time" );
    is( "$hash->{A}",      $now,         "value correct" );
    is( $bson,             $expect,      "BSON correct" );

    # conversion
    my $obj = $hash->{A}->as_mango_time;
    isa_ok( $obj, 'Mango::BSON::Time', 'as_mango_time' );
    is( $obj->to_epoch, $now, "to_epoch" );
}

# conversion to float
my $small_t = BSON::Time->new( value => 2 );
my $float = $small_t->epoch;
ok( $float > 0, "epoch handles small values without rounding to zero" );

# to JSON
is( to_myjson({a=>bson_time(0)}), q[{"a":"1970-01-01T00:00:00Z"}], 'json: bson_time(0)' );
is( to_myjson({a=>BSON::Time->new(value => "1356351330500")}), q[{"a":"2012-12-24T12:15:30.500Z"}], 'json: bson_time(1356351330.5)' );

# to extended JSON
is( to_extjson({a=>bson_time(0)}), q[{"a":{"$date":{"$numberLong":"0"}}}], 'extjson: bson_time(0)' );
is( to_extjson({a=>BSON::Time->new(value => "1356351330500")}), q[{"a":{"$date":{"$numberLong":"1356351330500"}}}], 'extjson: bson_time(1356351330.5)' );

done_testing;

#
# This file is part of BSON
#
# This software is Copyright (c) 2019 by Stefan G. and MongoDB, Inc.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
#
# vim: set ts=4 sts=4 sw=4 et tw=75:
