#! /usr/bin/perl

use strict;
use warnings;
use Browsermob::Server;
use JSON;
use Test::Spec;
use Test::LWP::UserAgent;

describe 'BMP Server' => sub {
    my ($server, $tua);

    before each => sub {
        $tua = Test::LWP::UserAgent->new;
        $server = Browsermob::Server->new( ua => $tua );
    };

    it 'should find the lowest available port' => sub {
        mock_get_proxies( $tua, [ 0, 2 ] );

        is( $server->find_open_port(0..10) , 1);
    };

    it 'should choose the first port when all are open' => sub {
        mock_get_proxies( $tua, [ ] );

        is( $server->find_open_port(0..10), 0 );
    };

    it 'should always choose a port in the range' => sub {
        mock_get_proxies( $tua, [ 1, 2, 3 ] );

        is( $server->find_open_port( 10 .. 20 ), 10 );
    };

    # Skip this e2e test since we don't keep a copy of the browsermob
    # binary in the repo
    xit 'should start a server' => sub {
        my $binary = 'bin/browsermob-proxy';
        my $port = 8080;

        my $server = Browsermob::Server->new(
            path => $binary,
            port => $port
        );

        ok( $server->_is_listening );
    };

};

sub mock_get_proxies {
    my ($tua, $used_ports) = @_;

    my @proxy_list = map { { port => $_ } } @$used_ports;

    $tua->map_response(
        qr/proxy/,
        HTTP::Response->new(
            '200',
            'OK',
            ['Content-Type' => 'text/json'],
            '{"proxyList":' . to_json(\@proxy_list) . '}'
        ));
}

runtests;
