#!/usr/bin/perl -w

use strict;

use Test::More tests => 10;

use DateTimeX::Lite;

my $dt1 = DateTimeX::Lite->new( year => 1970, hour => 1, nanosecond => 100 );

my $dt2 = DateTimeX::Lite->from_object( object => $dt1 );

is( $dt1->year, 1970, 'year is 1970' );
is( $dt1->hour, 1, 'hour is 1' );
is( $dt1->nanosecond, 100, 'nanosecond is 100' );

{
    my $t1 =
	DateTimeX::Lite::Calendar::_Test::WithoutTZ->new
	    ( rd_days => 1, rd_secs => 0 );

    # Tests creating objects from other calendars (without time zones)
    my $t2 = DateTimeX::Lite->from_object( object => $t1 );

    isa_ok( $t2, 'DateTimeX::Lite' );
    is( $t2->iso8601, '0001-01-01T00:00:00', 'convert from object without tz');
    ok( $t2->time_zone->is_floating, 'time_zone is floating');
}


{
    my $tz = DateTimeX::Lite::TimeZone->load( name => 'America/Chicago');
    my $t1 =
	DateTimeX::Lite::Calendar::_Test::WithTZ->new
	    ( rd_days => 1, rd_secs => 0, time_zone => $tz );

    # Tests creating objects from other calendars (with time zones)
    my $t2 = DateTimeX::Lite->from_object( object => $t1 );

    isa_ok( $t2, 'DateTimeX::Lite' );
    is( $t2->time_zone->name, 'America/Chicago', 'time_zone is preserved');
}

{
    my $tz = DateTimeX::Lite::TimeZone->load( name => 'UTC' );
    my $t1 =
	DateTimeX::Lite::Calendar::_Test::WithTZ->new
	    ( rd_days => 720258, rd_secs => 86400, time_zone => $tz );

    my $t2 = DateTimeX::Lite->from_object( object => $t1 );

    isa_ok( $t2, 'DateTimeX::Lite' );
    is( $t2->second, 60, 'new DateTimeX::Lite from_object with TZ which is a leap second' );
}



# Set up two simple test packages

package DateTimeX::Lite::Calendar::_Test::WithoutTZ;

sub new
{
    my $class = shift;
    bless {@_}, $class;
}

sub utc_rd_values
{
    return $_[0]{rd_days}, $_[0]{rd_secs}, 0;
}

package DateTimeX::Lite::Calendar::_Test::WithTZ;

sub new
{
    my $class = shift;
    bless {@_}, $class;
}

sub utc_rd_values
{
    return $_[0]{rd_days}, $_[0]{rd_secs}, 0;
}

sub time_zone
{
    return $_[0]{time_zone};
}

