#!/usr/bin/perl

use strict; use warnings;

use JSON ();
use Test::More;
use Plack::Test;
use HTTP::Request::Common;

{
    package TestApp;

    use Dancer2;
    use Dancer2::Plugin::Paginator;

    set session => 'Simple';
    set plugins => {
        Paginator => {
            new => {
                frame_size => 3,
                page_size  => 3,
            }
        }
    };

    get '/config' => sub {
        my $paginator = paginator(
            curr     => 5,
            items    => 100,
            base_url => '/foo/bar',
        );

        to_json { %{$paginator} };
    };

    get '/custom' => sub {
        my $paginator = paginator(
            frame_size => 3,
            page_size  => 7,
            curr       => 5,
            items      => 100,
            base_url   => '/foo/bar',
        );

        to_json { %{$paginator} };
    };
}

my $url  = 'http://localhost';
my $test = Plack::Test->create( TestApp->to_app );

my ($got, $exp);

subtest 'Get config' => sub {
    my $req = GET "$url/config";
    my $res = $test->request( $req );

    ok $res->is_success, "get /config";

    $got = JSON::from_json($res->content);
    $exp = {
        'next'       => 6,
        'first'      => 1,
        'prev'       => 4,
        'curr'       => 5,
        'base_url'   => '/foo/bar',
        'last'       => 10,
        'frame_size' => 5,
        'end'        => 7,
        'page_size'  => 10,
        'begin'      => 3,
        'items'      => 100,
        'mode'       => 'path',
    };
    is_deeply($got, $exp, 'Testing config data');
};

subtest 'Get custom' => sub {
    my $req = GET "$url/custom";
    my $res = $test->request( $req );

    ok $res->is_success, "get /custom";
    $got = JSON::from_json($res->content);
    $exp = {
        'next'       => 6,
        'first'      => 1,
        'prev'       => 4,
        'curr'       => 5,
        'base_url'   => '/foo/bar',
        'last'       => 15,
        'frame_size' => 3,
        'end'        => 6,
        'page_size'  => 7,
        'begin'      => 4,
        'items'      => 100,
        'mode'       => 'path',
    };
    is_deeply($got, $exp, 'Testing custom data');
};

done_testing();
