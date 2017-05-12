#!/usr/bin/perl -w

use strict;

use Test::More tests => 73;

use DateTime::Format::LDAP;

my $ldap = 'DateTime::Format::LDAP';

# YYYYMMDDHHMMSS	$fraction?	Z|DIFF
# YYYYMMDDHHMM		$fraction?	Z|DIFF
# YYYYMMDDHH		$fraction?	Z|DIFF

# YYYYMMDDHHMMSS Z
{
    my $dt = $ldap->parse_datetime( '19920405160708Z' );
    is( $dt->sec, 8, "second accessor read is correct" );
    is( $dt->minute, 7, "minute accessor read is correct" );
    is( $dt->hour, 16, "hour accessor read is correct" );
    is( $dt->day, 5, "day accessor read is correct" );
    is( $dt->month, 4, "month accessor read is correct" );
    is( $dt->year, 1992, "year accessor read is correct" );

    is( $dt->time_zone->name, 'UTC', 'time zone should be UTC' );

    is( $ldap->format_datetime($dt), '19920405160708Z', 'output should match input' );
}

# YYYYMMDDHHMM Z
{
    my $dt = $ldap->parse_datetime( '197610160903Z' );
    is( $dt->year, 1976, "year accessor read is correct" );
    is( $dt->month, 10, "month accessor read is correct" );
    is( $dt->day, 16, "day accessor read is correct" );
    is( $dt->hour, 9, "hour accessor read is correct" );
    is( $dt->minute, 3, "minute accessor read is correct" );
    is( $dt->sec, 0, "second accessor read is correct" );

    is( $dt->time_zone->name, 'UTC', 'time zone should be UTC' );

    is( $ldap->format_datetime($dt), '19761016090300Z',
        'output should match input (except as a datetime)' );
}

# YYYYMMDDHH Z
{
    my $dt = $ldap->parse_datetime( '0024112103Z' );
    is( $dt->year, 24, "hour-only year" );
    is( $dt->month, 11, "hour-only month" );
    is( $dt->day, 21, "hour-only day" );
    is( $dt->hour, 3, "hour-only hour" );
    is( $dt->minute, 0, "hour-only minute" );
    is( $dt->sec, 0, "hour-only second" );

    is( $dt->time_zone->name, 'UTC', 'time zone should be UTC' );

    is( $ldap->format_datetime($dt), '00241121030000Z',
        'output should match input (except as a datetime)' );
}

# YYYYMMDDHHMMSS DIFF
{
    my $dt = $ldap->parse_datetime( '19930512152347-0600' );

    is( $dt->time_zone->name, '-0600', 'should be -0600 time zone' );

    is( $ldap->format_datetime($dt), '19930512212347Z',
        'offset time zone should be formatted as UTC' );
}

# YYYYMMDDHHMM DIFF
{
    my $dt = $ldap->parse_datetime( '199912312359+0200' );

    is( $dt->time_zone->name, '+0200', 'should be +0200 time zone' );

    is( $ldap->format_datetime($dt), '19991231215900Z',
        'offset time zone should be formatted as UTC' );
}

# YYYYMMDDHH DIFF
{
    my $dt = $ldap->parse_datetime( '2000010100+0000' );

    is( $dt->time_zone->name, 'UTC', 'time zone should be UTC' );

    is( $ldap->format_datetime($dt), '20000101000000Z',
        'offset time zone should be formatted as UTC' );
}

# YYYYMMDDHHMMSS fraction Z
{
    my $dt = $ldap->parse_datetime( '19920405160708.1234Z' );
    is( $dt->year, 1992, "year accessor read is correct" );
    is( $dt->month, 4, "month accessor read is correct" );
    is( $dt->day, 5, "day accessor read is correct" );
    is( $dt->hour, 16, "hour accessor read is correct" );
    is( $dt->minute, 7, "minute accessor read is correct" );
    is( $dt->second, 8, "second accessor read is correct" );
    is( $dt->nanosecond, 123400000, "nanosecond accessor read is correct" );

    is( $dt->time_zone->name, 'UTC', 'time zone should be UTC' );

    is( $ldap->format_datetime($dt), '19920405160708.1234Z', 'output should match input' );
}

# YYYYMMDDHHMM fraction Z
{
    my $dt = $ldap->parse_datetime( '197610160903.1234Z' );
    is( $dt->year, 1976, "no-seconds year" );
    is( $dt->month, 10, "no-seconds month" );
    is( $dt->day, 16, "no-seconds day" );
    is( $dt->hour, 9, "no-seconds hour" );
    is( $dt->minute, 3, "no-seconds minute" );
    is( $dt->sec, 7, "no-seconds second" );
    is( $dt->nanosecond, 404000000, "no-seconds nanosecond" );
    is( $dt->time_zone->name, 'UTC', 'time zone should be UTC' );

    is( $ldap->format_datetime($dt), '19761016090307.404Z',
        'output should match input (except as a datetime)' );
}

# YYYYMMDDHH fraction Z
{
    my $dt = $ldap->parse_datetime( '0024112103.1234Z' );
    is( $dt->year, 24, "hour-only year" );
    is( $dt->month, 11, "hour-only month" );
    is( $dt->day, 21, "hour-only day" );
    is( $dt->hour, 3, "hour-only hour" );
    is( $dt->minute, 7, "hour-only minute" );
    is( $dt->sec, 24, "hour-only second" );
    is( $dt->nanosecond, 240000000, "hour-only nanosecond" );

    is( $dt->time_zone->name, 'UTC', 'time zone should be UTC' );

    is( $ldap->format_datetime($dt), '00241121030724.24Z',
        'output should match input (except as a datetime)' );
}

# from new DateTime object
{
    my $dt = DateTime->new( year => 1900, hour => 15, time_zone => '-0100' );

    is( $ldap->format_datetime($dt), '19000101160000Z',
        'offset only time zone should be formatted as UTC' );
}

# canonical compare
{
    my $dt = $ldap->parse_datetime( '199412160532-0500' );
    my $dt2 = $ldap->parse_datetime( '199412161032Z');

    is( $ldap->format_datetime($dt), $ldap->format_datetime($dt2),
        'RFC 4517 canonical example' );
}

# Pre-epoch
{
    my $dt = $ldap->parse_datetime( '18700523164702Z' );
    is( $dt->year, 1870, 'Pre-epoch year' );
    is( $dt->month, 5, 'Pre-epoch month' );
    is( $dt->sec, 2, 'Pre-epoch seconds' );

    is( $dt->time_zone->name, 'UTC', 'time zone should be UTC' );

    is( $ldap->format_datetime($dt), '18700523164702Z', 'output should match input' );
}

# Post-epoch
{
    my $dt = $ldap->parse_datetime( '23481016041612Z' );
    is( $dt->year, 2348, "Post-epoch year" );
    is( $dt->day, 16, "Post-epoch day");
    is( $dt->hour, 04, "Post-epoch hour");

    is( $dt->time_zone->name, 'UTC', 'time zone should be UTC' );

    is( $ldap->format_datetime($dt), '23481016041612Z', 'output should match input' );
}

$ldap = DateTime::Format::LDAP->new(offset => 1, asn1 => 1);

# ASN.1 local
{
    my $dt = $ldap->parse_datetime( '19941216053207' );
    is( $dt->time_zone->name, 'floating', 'should be floating time zone' );
    is( $ldap->format_datetime($dt), '19941216053207', 'ASN.1 local time zone');
}

# format with offset
{
    my $dt = $ldap->parse_datetime( '19941216053207-0500' );

    is( $dt->time_zone->name, '-0500', 'should be -0500 time zone' );

    is( $ldap->format_datetime($dt), '19941216053207-0500',
        'format with offset' );
}

