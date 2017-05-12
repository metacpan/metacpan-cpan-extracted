#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use utf8;

use Test::More;
use JSON qw();

use_ok('App::yajg::Hooks');

subtest 'boolean_to_scalar_ref' => sub {
    my $true  = JSON::true;
    my $false = JSON::false;
    App::yajg::Hooks::boolean_to_scalar_ref($true);
    App::yajg::Hooks::boolean_to_scalar_ref($false);
    isa_ok $true,  'SCALAR', 'true becomes scalar ref';
    isa_ok $false, 'SCALAR', 'false becomes scalar ref';
    ok $$true,     'True ref to 1';
    ok not($$false), 'False ref to 0';
    done_testing();
};

subtest 'boolean_to_int' => sub {
    my $true  = JSON::true;
    my $false = JSON::false;
    App::yajg::Hooks::boolean_to_int($true);
    App::yajg::Hooks::boolean_to_int($false);
    is $true,  1, 'True is 1';
    is $false, 0, 'False is 0';
    done_testing();
};

subtest 'boolean_to_str' => sub {
    my $true  = JSON::true;
    my $false = JSON::false;
    App::yajg::Hooks::boolean_to_str($true);
    App::yajg::Hooks::boolean_to_str($false);
    is $true,  'true',  'True';
    is $false, 'false', 'False';
    done_testing();
};

subtest 'uri_parse' => sub {
    my %tests = (
        'abc.com'       => 'abc.com',
        '/d/d'          => '/d/d',
        '//example.com' => {
            'fragment' => undef,
            'host'     => 'example.com',
            'path'     => [],
            'query'    => {},
            'scheme'   => undef,
            'uri'      => '//example.com'
        },
        'http://example.com/1/2/3//4?sd=33&a&b&c#123' => {
            'fragment' => 123,
            'host'     => 'example.com',
            'path'     => [
                1,
                2,
                3,
                '',
                4
            ],
            'query' => {
                'a'  => undef,
                'b'  => undef,
                'c'  => undef,
                'sd' => 33
            },
            'scheme' => 'http',
            'uri'    => 'http://example.com/1/2/3//4?sd=33&a&b&c#123'
        },
        'someproto://?e=%D1%85' => {
            'fragment' => undef,
            'host'     => '',
            'path'     => [],
            'query'    => {
                'e' => 'х'
            },
            'scheme' => 'someproto',
            'uri'    => 'someproto://?e=%D1%85'
          },
        'http://example.com/1/2/3//4/%D1%8B?sd=33&a&b&c&=23&=13&%D1%8B=%D1%8B#123%D1%8B' => {
            'fragment' => '123ы',
            'host'     => 'example.com',
            'path'     => [
                1,
                2,
                3,
                '',
                4,
                'ы',
            ],
            'query' => {
                'a'  => undef,
                'b'  => undef,
                'c'  => undef,
                'sd' => 33,
                ''   => 13,
                'ы'  => 'ы',
            },
            'scheme' => 'http',
            'uri'    => 'http://example.com/1/2/3//4/%D1%8B?sd=33&a&b&c&=23&=13&%D1%8B=%D1%8B#123%D1%8B',
        },
    );
    for (keys %tests) {
        my $uri    = $_;
        my $parsed = $tests{$_};
        App::yajg::Hooks::uri_parse($uri);
        is_deeply $uri, $parsed, "parsing $_";
    }
    done_testing();
};

subtest 'make_code_hook' => sub {
    my $code = '$_ = uc($_ . "ыыы")';
    my $hook = App::yajg::Hooks::make_code_hook($code);
    isa_ok $hook, 'CODE';
    my $string   = 'ээ';
    my $expected = 'ЭЭЫЫЫ';
    $hook->($string);
    is $string, $expected;
    done_testing();
};

done_testing();
