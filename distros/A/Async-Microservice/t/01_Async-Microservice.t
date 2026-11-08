#! /usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::Most;
use Test::WWW::Mechanize;
use Plack::Builder;
use Plack::Test::Server;

use FindBin     qw($Bin);
use Path::Class qw(file dir);
use lib file( $Bin, 'tlib' )->stringify;
use JSON::XS;

use_ok('Async::Microservice::HelloWorld')       or die;
use_ok('Test::Async::Microservice::HelloWorld') or die;

$ENV{STATIC_DIR} = dir( $Bin, '..', 'root', 'static' )->stringify;

my $asmi_time_srv = Test::Async::Microservice::HelloWorld->start;
my $service_url   = $asmi_time_srv->url;
my $mech          = Test::WWW::Mechanize->new();

subtest 'response headers' => sub {
    $mech->get_ok($service_url);
    is( $mech->ct, 'text/html', 'content type is html' );
    ok( $mech->response->header('Cache-Control'),
        'cache control header present' );
};

subtest '/hcheck' => sub {
    $mech->get_ok( $service_url . 'hcheck', 'get hcheck' )
        or diag( $mech->content );
    $mech->content_like( qr/API-Version:/, 'hcheck content' )
        or diag( $mech->content );

    $mech->post( $service_url . 'hcheck' );
    is( $mech->status, 405, 'method not allowed returns 405' );
    is( $mech->res->header('allow'),
        'GET', 'method not allowed returns allow header' );
};

subtest '/static' => sub {
    $mech->get_ok(
        $service_url . 'static/async-microservice-time_openapi.yaml',
        'get OpenAPI config' );
    $mech->get( $service_url . 'static/non-existing-file' );
    is( $mech->status, 404, 'non-existing file returns 404' );
};

subtest 'OpenAPI' => sub {
    note($service_url);
    $mech->get_ok($service_url);
    $mech->content_contains( '<div id="swagger-ui">',
        'OpenAPI documentation in /' ) or return;
    $mech->content_contains( '<title>OpenAPI - asmi-helloworld</title>',
        'OpenAPI documentation updated' );
    $mech->get_ok( $service_url . 'edit' );
    $mech->content_contains( '<div id="swagger-editor">',
        'OpenAPI editor in /edit' );
};

subtest 'redirect' => sub {
    my $root_url = URI->new($service_url)->clone;
    $root_url->path('/');
    $mech->get( $root_url, host => 'hackme.example' );
    is( $mech->base, $service_url, 'redirected to root path' );
};

subtest 'custom api_prefix' => sub {
    {
        package Test::Async::Microservice::CustomPrefix;
        use Moose;
        with qw(Async::Microservice);

        sub service_name {'asmi-custom-prefix'}
        sub get_routes {
            return (
                'hello' => { defaults => { GET => 'GET_hello' } },
            );
        }
        sub GET_hello {
            return [ 200, [], 'hello custom prefix' ];
        }

        __PACKAGE__->meta->make_immutable;
    }

    my $service = Test::Async::Microservice::CustomPrefix->new(
        api_prefix => '/search_1'
    );
    my $app = sub { $service->plack_handler(@_) };
    my $srv = Plack::Test::Server->new(
        builder {
            enable 'Plack::Middleware::ContentLength';
            $app;
        }
    );
    my $custom_base = 'http://127.0.0.1:' . $srv->port . '/search_1/';

    my $custom_mech = Test::WWW::Mechanize->new();
    $custom_mech->get('http://127.0.0.1:' . $srv->port . '/');
    is( $custom_mech->base, $custom_base,
        'redirected to configured api_prefix' );

    $custom_mech->get_ok( $custom_base . 'hello',
        'route matched under configured api_prefix' )
        or diag( $custom_mech->content );
    is( $custom_mech->content, 'hello custom prefix',
        'expected route response' );
};

subtest 'want_json' => sub {
    subtest 'accept application/json' => sub {
        my $dt_data;
        $mech->get( $service_url . 'non-existing',
            accept => 'application/json;q=1, text/html;q=0.9' );
        is( $mech->res->header('Content-Type'),
            'application/json', 'content type is application/json' )
            or return;
        lives_ok( sub { $dt_data = JSON::XS->new->decode( $mech->content ) },
            'json content' )
            or diag( $mech->content );
    };
    subtest 'accept text/html' => sub {
        my $dt_data;
        $mech->get( $service_url . 'non-existing', accept => 'text/html' );
        is( $mech->res->header('Content-Type'),
            'text/plain', 'content type is text/plain' )
            or diag( $mech->content );
    };
};

done_testing();
