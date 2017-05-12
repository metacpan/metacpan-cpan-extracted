#! /usr/bin/perl

use strict;
use warnings;
use Browsermob::Proxy;
use JSON;
use List::Util;
use LWP::UserAgent;
use Test::Spec;

use File::Basename qw/dirname/;
use lib dirname(__FILE__);
use tlib::MockBrowsermobServer qw/generate_mock_server/;

describe 'Request/Response filters' => sub {
    my ($proxy, $ua, $mock_server);
    my $mock_port = 9999;

    before each => sub {
        $mock_server = generate_mock_server($mock_port);

        $proxy = Browsermob::Proxy->new(
            mock => $mock_server
        );

        $ua = LWP::UserAgent->new;
    };

    it 'should inject request headers via javascript rhino payload ' => sub {
        my $env;
        $mock_server->{'/proxy/' . $mock_port . '/filter/request'} = sub {
            my $req = shift;

            eval { $env = $req->env };

            return $req->new_response(
                200,
                ['Content-Type' => 'application/json'],
                ''
            );
        };

        $proxy->set_request_header('User-Agent', 'My-Custom-User-Agent-String 1.0');
        is($env->{'spore.payload'}, "
request.headers().remove('User-Agent');
request.headers().add('User-Agent', 'My-Custom-User-Agent-String 1.0');
"
       );
    };


    xit 'should inject request headers (e2e)' => sub {
        my $proxy = Browsermob::Proxy->new;
        my $port = $proxy->port;

        $proxy->set_request_header('User-Agent', 'My-Custom-User-Agent-String 1.0');

        $ua->proxy($proxy->ua_proxy(1));
        $proxy->create_new_har(
            captureHeaders => 'true',
        );

        $ua->get('http://' . $proxy->server_addr . ':' . $proxy->server_port);

        my $har = $proxy->har;
        my $headers = $har->{log}->{entries}->[0]->{request}->{headers};

        # $headers is an array of hashrefs with name/value as
        # keys. Takes a bit of manipulation, but we're asserting that
        # we're overwriting the user agent.
        my $useragent_value = '';
        foreach (@$headers) {
            my ($name, $value) = ($_->{name}, $_->{value});
            if ($name eq 'User-Agent') {
                $useragent_value = $value;
                last;
            }
        }
        is($useragent_value, 'My-Custom-User-Agent-String 1.0');
    };
};

runtests;
