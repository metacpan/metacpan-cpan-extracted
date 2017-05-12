#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg = 'Catmandu::Fix::start_week';
use_ok($pkg);
use_ok('POSIX');

my $s_day = 3600*24;
my $s_week = $s_day * 7;
#default
{
    my $time = time;
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($time);
    unless($wday == 0){

        $time -= ($wday - 1) * $s_day;

    }else{

        $time -= 6 * $s_day;

    }

    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($time);

    $sec = 0;
    $min = 0;
    $hour = 0;
    $isdst = 0;

    my $expected = { start_week => POSIX::strftime('%Y-%m-%dT%H:%M:%SZ',$sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) };
    my $got = ${pkg}->new('start_week', 'pattern' => '%FT%TZ', time_zone => 'UTC')->fix({});
    is_deeply(
        $got,
        $expected
    );
}
#add
{
    my $add = -2;
    my $time = time;
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($time);
    unless($wday == 0){

        $time -= ($wday - 1) * $s_day;

    }else{

        $time -= 6 * $s_day;

    }

    $time += $add * $s_week;

    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($time);

    $sec = 0;
    $min = 0;
    $hour = 0;
    $isdst = 0;

    my $expected = { start_week => POSIX::strftime('%Y-%m-%dT%H:%M:%SZ',$sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) };
    my $got = ${pkg}->new('start_week', 'pattern' => '%FT%TZ', time_zone => 'UTC', add => $add)->fix({});
    is_deeply(
        $got,
        $expected
    );
}

done_testing 4;
