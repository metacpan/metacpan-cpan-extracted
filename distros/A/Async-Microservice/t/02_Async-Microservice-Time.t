#! /usr/bin/env perl
use strict;
use warnings;
use utf8;

use JSON::XS;
use Time::HiRes qw(time);

use Test::Most;
use Test::Time time => 1672164098;  # 2022-12-27T18:01:38
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
    like($dt_data->{time_zone_name}, qr{(CEST|CET)}, 'time zone name');

    $mech->get_ok($service_url . 'datetime/Europe/London');
    lives_ok(sub {$dt_data = $json->decode($mech->content)}, 'json content');
    like($dt_data->{time_zone_name}, qr{(BST|GMT)}, 'time zone name');

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

note(sprintf('test "now" is %s', DateTime->now(time_zone => 'UTC')));

subtest '/datetime/span/:s_date (1 year)' => sub {
    my $weeks_data;
    $mech->get_ok($service_url . 'datetime/span/19581227?m_income=100');
    lives_ok(sub {$weeks_data = $json->decode($mech->content)}, 'json content')
        or diag $mech->content;
    is($weeks_data->{years},  1,        '1 year left');
    is($weeks_data->{months}, 12,       '12 months left');
    is($weeks_data->{weeks},  52,       '52 weeks left');
    is($weeks_data->{days},   365,      '365 days left');
    is($weeks_data->{income}, 12 * 100, '1200 as income');
    note($weeks_data->{msg});
    #~ note(Data::Dumper::Dumper($weeks_data));
};

subtest '/datetime/span/:s_date ("now")' => sub {
    my $weeks_data;
    $mech->get_ok($service_url . 'datetime/span/now?r_age=4');
    lives_ok(sub {$weeks_data = $json->decode($mech->content)}, 'json content')
        or diag $mech->content;
    is($weeks_data->{years},  4,           '4 year left');
    is($weeks_data->{months}, 4 * 12,      '4*12 months left');
    is($weeks_data->{weeks},  4 * 52,      '4*52 weeks left');
    is($weeks_data->{days},   4 * 365 + 1, '4*365+1 days left');
    note($weeks_data->{msg});
    #~ note(Data::Dumper::Dumper($weeks_data));
};

subtest '/datetime/span/:s_date (expired)' => sub {
    my $weeks_data;
    $mech->get_ok($service_url . 'datetime/span/19581227?r_age=10&m_income=100');
    lives_ok(sub {$weeks_data = $json->decode($mech->content)}, 'json content')
        or diag $mech->content;
    is($weeks_data->{years},  0, '0 year left');
    is($weeks_data->{months}, 0, '0 months left');
    is($weeks_data->{weeks},  0, '0 weeks left');
    is($weeks_data->{days},   0, '0 days left');
    is($weeks_data->{income}, 0, '0 as income');
    note($weeks_data->{msg});
    #~ note(Data::Dumper::Dumper($weeks_data));
};

done_testing();
