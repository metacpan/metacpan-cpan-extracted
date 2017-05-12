#! /usr/bin/perl

use strict;
use warnings;
use Test::Spec;

use Browsermob::Proxy;
use File::Basename qw/dirname/;
use lib dirname(__FILE__);
use tlib::MockBrowsermobServer qw/generate_mock_server/;

describe 'Proxy Timeouts' => sub {
    my ($proxy, $mock_server);
    my $mock_port = 9999;
    my $called;

    before each => sub {
        $mock_server = generate_mock_server($mock_port);

        $called = 0;
        $mock_server->{'/proxy/' . $mock_port . '/timeout'} = sub {
            $called++;

            my ($req) = shift;
            return $req->new_response(
                200,
                ['Content-Type' => 'application/json'],
                '{}'
            );
        };

        $proxy = Browsermob::Proxy->new(
            mock => $mock_server
        );
    };

    it 'should set without throwing' => sub {
        eval { $proxy->set_timeout(
            requestTimeout => 12345,
            dnsCacheTimeout => 54321
        ) };
        ok( ! $@ );
    };

    it 'should go to /proxy/:port/timeout' => sub {
        $proxy->set_timeout( requestTimeout => 12345 );
        ok( $called );
    };

};

runtests;
