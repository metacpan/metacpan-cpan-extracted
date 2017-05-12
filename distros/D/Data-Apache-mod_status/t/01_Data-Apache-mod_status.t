#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Differences;
use Test::Exception;

use File::Slurp 'read_file';
use File::Which 'which';

use FindBin qw($Bin);
use lib "$Bin/lib";

use Data::Apache::mod_status;

exit main();

my $status_page;

sub main {
    plan 'skip_all' => 'tidy executable not found'
        if not defined which('tidy');

    #plan 'no_plan';
    plan 'tests' => 30;
    
    throws_ok(sub { Data::Apache::mod_status->new()->refresh() }, qr/failed to fetch test/, 'check test mockup');
    
    $status_page = read_file($Bin.'/data/server-status.html');
    lives_ok(sub { Data::Apache::mod_status->new()->refresh() }, 'check test mockup')
        or die 'hmm';
    
    my $info = Data::Apache::mod_status->new->refresh->info;
    
    is($info->server_version, 'Apache/2.2.9 (Debian) mod_ssl/2.2.9 OpenSSL/0.9.8g', 'server version');
    is($info->server_build_str, 'Oct 1 2008 09:56:11', 'server build string');
    eq_or_diff(
        {
            'month'  => $info->server_build->month,
            'day'    => $info->server_build->day,
            'year'   => $info->server_build->year,
            'hour'   => $info->server_build->hour,
            'minute' => $info->server_build->minute,
            'second' => $info->server_build->second,
        }, {
            'month'  => 10,
            'day'    => 1,
            'year'   => 2008,
            'hour'   => 9,
            'minute' => 56,
            'second' => 11,
        }, 'server build datetime'
    );
    is($info->current_time_str, 'Tuesday, 11-Nov-2008 14:05:49 CET', 'current time string');
    eq_or_diff(
        {
            'month'  => $info->current_time->month,
            'day'    => $info->current_time->day,
            'year'   => $info->current_time->year,
            'hour'   => $info->current_time->hour,
            'minute' => $info->current_time->minute,
            'second' => $info->current_time->second,
            'zone'   => $info->current_time->offset,
        }, {
            'month'  => 11,
            'day'    => 11,
            'year'   => 2008,
            'hour'   => 14,
            'minute' => 5,
            'second' => 49,
            'zone'   => 3600,
        }, 'server current datetime'
    );
    is($info->restart_time_str, 'Tuesday, 11-Nov-2008 08:45:45 CET', 'restart time string');
    eq_or_diff(
        {
            'month'  => $info->restart_time->month,
            'day'    => $info->restart_time->day,
            'year'   => $info->restart_time->year,
            'hour'   => $info->restart_time->hour,
            'minute' => $info->restart_time->minute,
            'second' => $info->restart_time->second,
            'zone'   => $info->restart_time->offset,
        }, {
            'month'  => 11,
            'day'    => 11,
            'year'   => 2008,
            'hour'   => 8,
            'minute' => 45,
            'second' => 45,
            'zone'   => 3600,
        }, 'server restart datetime'
    );
    is($info->parent_server_generation, 3, 'parent server generation');
    is($info->server_uptime_str, '5 hours 20 minutes 4 seconds', 'server uptime string');
    is($info->server_uptime, 19204, 'server uptime');
    is($info->total_accesses, 522647, 'total accesses');
    is($info->total_traffic_str, '27.7 MB', 'total traffic string');
    is($info->total_traffic, 29045555, 'total traffic');
    is($info->cpu_usage_str, 'u2.77 s2.6 cu0 cs0 - .028% CPU load', 'cpu usage string');
    is($info->current_requests, 3, 'current requests');
    is($info->idle_workers, 49, 'idle workers');
    
    my $workers = Data::Apache::mod_status->new->refresh->workers;
    ok($workers->workers_tag, 'workers pre tag');
    is($workers->waiting, 49, 'waiting workers');
    is($workers->starting, 2, 'starting workers');
    is($workers->reading, 3, 'reading workers');
    is($workers->sending, 1, 'sending workers');
    is($workers->keepalive, 4, 'keepalive workers');
    is($workers->dns_lookup, 5, 'dns lookup workers');
    is($workers->closing, 6, 'closing workers');
    is($workers->logging, 7, 'logging workers');
    is($workers->finishing, 8, 'finishing workers');
    is($workers->idle_cleanup, 9, 'idle cleanup workers');
    is($workers->open_slot, 930, 'open slot workers');
    
    
    return 0;
}

no warnings 'redefine';

sub Data::Apache::mod_status::_fetch_mod_status_page {
    die 'failed to fetch test'
        if not defined $status_page;
    
    return $status_page;
}
