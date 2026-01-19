#!/usr/bin/perl

use strict;
use warnings;

use DateTime::Format::Natural;
use DateTime::Format::Natural::Test qw(_result_string);
use Test::More tests => 65;

my @iso8601 = (
    { '2016T12'                   => { result => '01.01.2016 12:00:00', tz => 'floating' } },
    { '2016T12:12'                => { result => '01.01.2016 12:12:00', tz => 'floating' } },
    { '2016T12:12:11'             => { result => '01.01.2016 12:12:11', tz => 'floating' } },
    { '2016-06T12'                => { result => '01.06.2016 12:00:00', tz => 'floating' } },
    { '2016-06T12:12'             => { result => '01.06.2016 12:12:00', tz => 'floating' } },
    { '2016-06T12:12:11'          => { result => '01.06.2016 12:12:11', tz => 'floating' } },
    { '2016-06-19T12'             => { result => '19.06.2016 12:00:00', tz => 'floating' } },
    { '2016-06-19T12:12'          => { result => '19.06.2016 12:12:00', tz => 'floating' } },
    { '2016-06-19T12:12:11'       => { result => '19.06.2016 12:12:11', tz => 'floating' } },
    { '2016-06-19T12:12:11-0500'  => { result => '19.06.2016 12:12:11', tz => '-0500' } },
    { '2016-06-19T12:12:11+0500'  => { result => '19.06.2016 12:12:11', tz => '+0500' } },
    { '2016-06-19T12:12:11-05:00' => { result => '19.06.2016 12:12:11', tz => '-0500' } },
    { '2016-06-19T12:12:11+05:00' => { result => '19.06.2016 12:12:11', tz => '+0500' } },
    { '2016-06-19T12:12:11+05:30' => { result => '19.06.2016 12:12:11', tz => '+0530' } },
    { '2016-06-19T12:12:11-05:30' => { result => '19.06.2016 12:12:11', tz => '-0530' } },
    { '2016-06-19T12:12:11-05'    => { result => '19.06.2016 12:12:11', tz => '-0500' } },
    { '2016-06-19T12:12:11+05'    => { result => '19.06.2016 12:12:11', tz => '+0500' } },
    { '2016-06-19T12:12+05'       => { result => '19.06.2016 12:12:00', tz => '+0500' } },
    { '2016-06-19T12:12+00'       => { result => '19.06.2016 12:12:00', tz => 'UTC' } },
    { '2016-06-19T12:12-00'       => { result => '19.06.2016 12:12:00', tz => 'UTC' } },
    { '2016-06-19T12:12:11Z'      => { result => '19.06.2016 12:12:11', tz => 'UTC' } },
    { '2016-06-19T12:12Z'         => { result => '19.06.2016 12:12:00', tz => 'UTC' } },
);

my @iso8601_fractional = (
    { '2016-06-19T12:12:11.5'          => { result => '19.06.2016 12:12:11', tz => 'floating', ns => 500_000_000 } },
    { '2016-06-19T12:12,5'             => { result => '19.06.2016 12:12:00', tz => 'floating', ns => 500_000_000 } },
    { '2016-06-19T12:12:11.50000'      => { result => '19.06.2016 12:12:11', tz => 'floating', ns => 500_000_000 } },
    { '2016-06-19T12:12:11,5'          => { result => '19.06.2016 12:12:11', tz => 'floating', ns => 500_000_000 } },
    { '2016-06-19T12:12:11,5Z'         => { result => '19.06.2016 12:12:11', tz => 'UTC',      ns => 500_000_000 } },
    { '2016-06-19T12:12:11,5-5000'     => { result => '19.06.2016 12:12:11', tz => '-5000',    ns => 500_000_000 } },
    { '2016-06-19T12:12:11.1000000000' => { result => '19.06.2016 12:12:12', tz => 'floating', ns => 0 } },
);

compare(\@iso8601);
compare_fractional(\@iso8601_fractional);

sub compare
{
    my $aref = shift;

    foreach my $href (@$aref) {
        my $key = (keys %$href)[0];
        compare_strings($key, @{$href->{$key}}{qw(result tz)});
    }
}

sub compare_fractional
{
    my $aref = shift;
    foreach my $href (@$aref) {
        my $key = (keys %$href)[0];
        compare_with_fractional($key, @{$href->{$key}}{qw(result tz ns)});
    }
}

sub compare_strings
{
    my ($string, $result, $expected_tz) = @_;

    my $parser = DateTime::Format::Natural->new;

    my $dt = $parser->parse_datetime($string);

    if ($parser->success) {
        is(_result_string($dt), $result, $string);
        is($dt->time_zone->name, $expected_tz, "$string - timezone");
    }
    else {
        fail($string);
    }
}

sub compare_with_fractional
{
    my ($string, $result, $expected_tz, $expected_ns) = @_;

    my $parser = DateTime::Format::Natural->new;

    my $dt = $parser->parse_datetime($string);

    if ($parser->success) {
        is(_result_string($dt), $result, $string);
        is($dt->time_zone->name, $expected_tz, "$string - timezone");
        is($dt->nanosecond, $expected_ns, "$string - nanoseconds");
    }
    else {
        fail($string);
    }
}
