#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg = 'Catmandu::Fix::end_day';
use_ok($pkg);
use_ok('POSIX');

#default
{
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time);
    #truncate to end of day
    $sec = 59;
    $min = 59;
    $hour = 23;
    $isdst = 0;
    my $expected = { end_day => POSIX::strftime('%Y-%m-%dT%H:%M:%SZ',$sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) };
    my $got = ${pkg}->new('end_day', 'pattern' => '%FT%TZ', time_zone => 'UTC')->fix({});
    is_deeply(
        $got,
        $expected
    );
}
#add
{
    my $add = 2;
    #add seconds of $add days
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time + $add*3600*24);
    #truncate to end of day
    $sec = 59;
    $min = 59;
    $hour = 23;
    $isdst = 0;
    my $expected = { end_day => POSIX::strftime('%Y-%m-%dT%H:%M:%SZ',$sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) };
    my $got = ${pkg}->new('end_day', 'pattern' => '%FT%TZ', time_zone => 'UTC', add => $add)->fix({});
    is_deeply(
        $got,
        $expected
    );
}

done_testing 4;
