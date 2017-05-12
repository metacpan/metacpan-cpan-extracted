#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg = 'Catmandu::Fix::start_day';
use_ok($pkg);
use_ok('POSIX');

#default
{
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time);
    $sec = 0;
    $min = 0;
    $hour = 0;
    $isdst = 0;
    my $expected = { start_day => POSIX::strftime('%Y-%m-%dT%H:%M:%SZ',$sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) };
    my $got = ${pkg}->new('start_day', 'pattern' => '%FT%TZ', time_zone => 'UTC')->fix({});
    is_deeply(
        $got,
        $expected
    );
}
#add
{
    my $add = 2;
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time + $add*3600*24);
    $sec = 0;
    $min = 0;
    $hour = 0;
    $isdst = 0;
    my $expected = { start_day => POSIX::strftime('%Y-%m-%dT%H:%M:%SZ',$sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) };
    my $got = ${pkg}->new('start_day', 'pattern' => '%FT%TZ', time_zone => 'UTC', add => $add)->fix({});
    is_deeply(
        $got,
        $expected
    );
}

done_testing 4;
