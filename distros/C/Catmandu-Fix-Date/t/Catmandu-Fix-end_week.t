#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg = 'Catmandu::Fix::end_week';
use_ok($pkg);
use_ok('POSIX');

my $s_day = 3600*24;
my $s_week = $s_day * 7;
#default
{
    my $time = time;
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($time);

    #truncate to end of week
    unless($wday == 0){

        $time += (7 - $wday) * $s_day;

    }

    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($time);

    #truncate to start of day
    $sec = 0;
    $min = 0;
    $hour = 0;
    $isdst = 0;

    my $expected = { end_week => POSIX::strftime('%Y-%m-%dT%H:%M:%SZ',$sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) };
    my $got = ${pkg}->new('end_week', 'pattern' => '%FT%TZ', time_zone => 'UTC')->fix({});
    is_deeply(
        $got,
        $expected
    );
}
#add
{
    my $add = 2;
    my $time = time;
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($time);

    #truncate to end of week
    unless($wday == 0){

        $time += (7 - $wday) * $s_day;

    }

    #add $add weeks
    $time += $add * $s_week;

    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($time);

    #truncate to start of day
    $sec = 0;
    $min = 0;
    $hour = 0;
    $isdst = 0;

    my $expected = { end_week => POSIX::strftime('%Y-%m-%dT%H:%M:%SZ',$sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) };
    my $got = ${pkg}->new('end_week', 'pattern' => '%FT%TZ', time_zone => 'UTC', add => $add)->fix({});
    is_deeply(
        $got,
        $expected
    );
}

done_testing 4;
