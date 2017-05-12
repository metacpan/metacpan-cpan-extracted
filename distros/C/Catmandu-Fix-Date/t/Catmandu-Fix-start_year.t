#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg = 'Catmandu::Fix::start_year';
use_ok($pkg);
use_ok('DateTime');
use_ok('POSIX');

#default
{
    my $d = DateTime->now->set_time_zone('UTC')->truncate(to => "day");
    $d->set_month(1);
    $d->set_day(1);

    my $expected = { start_year => POSIX::strftime('%Y-%m-%dT%H:%M:%SZ',gmtime($d->epoch())) };
    my $got = ${pkg}->new('start_year', 'pattern' => '%FT%TZ', time_zone => 'UTC')->fix({});
    is_deeply( $got, $expected );
}
#add
{
    my $add = 2;
    my $d = DateTime->now->set_time_zone('UTC')->truncate(to => "day");
    $d->set_month(1);
    $d->set_day(1);
    $d->add(years => $add);

    my $expected = { start_year => POSIX::strftime('%Y-%m-%dT%H:%M:%SZ',gmtime($d->epoch())) };
    my $got = ${pkg}->new('start_year', 'pattern' => '%FT%TZ', time_zone => 'UTC', add => $add)->fix({});
    is_deeply( $got, $expected );
}

done_testing 5;
