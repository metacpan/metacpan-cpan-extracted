#! /usr/bin/env perl
use strict;
use warnings;
use utf8;

use JSON::XS;
use Time::HiRes qw(time);

use Test::Most;
use Test::WWW::Mechanize;

use FindBin qw($Bin);
use Path::Class qw(file);
use lib file($Bin, 'tlib')->stringify;

my $json = JSON::XS->new();

use_ok('Async::Microservice::Time')       or die;
use_ok('Test::Async::Microservice::Time') or die;

my $asmi_time_srv = Test::Async::Microservice::Time->start;
my $service_url   = $asmi_time_srv->url;
my $mech          = Test::WWW::Mechanize->new();
$mech->add_header(content_type => 'application/json');
$mech->add_header(accept       => 'application/json');

subtest '/datetime' => sub {
    my $dt_data;
    $mech->get_ok($service_url . 'datetime?time_zone=Europe/Vienna');
    lives_ok(sub {$dt_data = $json->decode($mech->content)}, 'json content');
    eq_or_diff_data(
        [sort keys %{$dt_data}],
        [   sort
                qw(second year minute datetime hour time_zone_name time epoch month day time_zone date)
        ],
        'datetime'
    );
    is($dt_data->{time_zone_name}, 'CEST');

    $mech->get_ok($service_url . 'datetime/Europe/London');
    lives_ok(sub {$dt_data = $json->decode($mech->content)}, 'json content');
    is($dt_data->{time_zone_name}, 'BST');

    $mech->get_ok($service_url . 'datetime/EST');
    lives_ok(sub {$dt_data = $json->decode($mech->content)}, 'json content');
    is($dt_data->{time_zone}, '-0500');

    $mech->post($service_url . 'datetime', content => $json->encode({epoch => 10}));
    ok($mech->success, 'post with epoch timestamp');
    lives_ok(sub {$dt_data = $json->decode($mech->content)}, 'json content');
    eq_or_diff_data(
        $dt_data,
        {   'second'         => '10',
            'year'           => '1970',
            'minute'         => '00',
            'datetime'       => '1970-01-01 00:00:10 +0000',
            'hour'           => '00',
            'time_zone_name' => 'UTC',
            'time'           => '00:00:10',
            'epoch'          => 10,
            'month'          => '01',
            'day'            => '01',
            'time_zone'      => '+0000',
            'date'           => '1970-01-01'
        },
        'epoch calculated'
    );

    $mech->post($service_url . 'datetime', content => $json->encode({epoch => 'x'}));
    is($mech->status, 405, 'post with invalid epoch');
    lives_ok(sub {$dt_data = $json->decode($mech->content)}, 'json content');
    is($dt_data->{err_status}, 405, 'error returned');
};

subtest '/epoch' => sub {
    my $dt_data;
    $mech->get_ok($service_url . 'epoch');
    lives_ok(sub {$dt_data = $json->decode($mech->content)}, 'json content');
    cmp_ok($dt_data->{epoch}, '>', 1586458888, 'epoch returned');
};

subtest '/sleep' => sub {
    my $dt_data;
    my $start_time = time();
    $mech->get_ok($service_url . 'sleep?duration=0.1');
    cmp_ok(time() - $start_time, '>', 0.09, 'duration waited');
    lives_ok(sub {$dt_data = $json->decode($mech->content)}, 'json content') or diag $mech->content;
    cmp_ok($dt_data->{duration}, '>', 0.09, 'duration returned back in json');
};

done_testing();
