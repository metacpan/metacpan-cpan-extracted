#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 5;
use Data::Dumper;
use API::ParallelsWPB;
use API::ParallelsWPB::Response;
use utf8;

my %transfered_params = ();

{
    no warnings 'redefine';

    *API::ParallelsWPB::_send_request = sub {
        my ( $self, $data, $url, $post_data ) = @_;
        %transfered_params = (
            self      => $self,
            data      => $data,
            url       => $url,
            post_data => $post_data
        );
    };
}

my $client = API::ParallelsWPB->new(
    username => 'test',
    password => 'passw0rd',
    server   => '127.0.0.1'
);

subtest 'Test GET request' => sub {

    plan tests => 2;

    $client->f_request( [qw/ system version /], { req_type => 'get' } );

    is( $transfered_params{url}, 'https://127.0.0.1/api/5.3/system/version/',
        'URL is ok' );

    is_deeply(
        $transfered_params{data},
        { req_type => 'GET' },
        'Request type is GET'
    );

};

subtest 'Test POST request' => sub {

    plan tests => 3;

    $client->f_request(
        ['sites'],
        {
            req_type  => 'post',
            post_data => [ { state => 'trial' } ]
        }
    );

    is(
        $transfered_params{url},
        'https://127.0.0.1/api/5.3/sites/',
        'Url for post is ok'
    );

    is( $transfered_params{post_data},
        qq/[{"state":"trial"}]/, 'POST data is ok' );

    is_deeply(
        $transfered_params{data},
        { req_type => 'POST', post_data => [ { state => 'trial' } ] },
        'Request type is POST'
    );
};

subtest 'Test POST request with uuid' => sub {

    plan tests => 4;

    $client->f_request(
        [ 'sites', '123', 'token' ],
        {
            req_type  => 'post',
            post_data => [
                {
                    localeCode      => 'de_DE',
                    sessionLifeTime => 1000
                }
            ],
        }
    );

    is(
        $transfered_params{url},
        'https://127.0.0.1/api/5.3/sites/123/token/',
        'Url for post with uuid is ok'
    );

    like( $transfered_params{post_data},
        qr/"sessionLifeTime":1000/, 'sessionLifeTime param trasfered' );

    like( $transfered_params{post_data},
        qr/"localeCode":"de_DE"/, 'LocaleCode trasfered' );

    is_deeply(
        $transfered_params{data},
        {
            req_type  => 'POST',
            post_data => [
                {
                    localeCode      => 'de_DE',
                    sessionLifeTime => 1000
                }
            ]
        },
        'Request type with uuid is POST'
    );
};


subtest 'Test unicode chars' => sub {
    plan tests => 1;

    $client->f_request(
        [ 'sites', '123' ],
        {
            req_type  => 'put',
            post_data => [
                {
                    ownerInfo => {
                        personalName => 'Василиус Пупкинус'
                    }
                }
            ],
        }
    );

    like(
        $transfered_params{post_data},
        qr/Василиус Пупкинус/,
        'Unicode char is ok in request'
    );
};


subtest 'Test utf-8' => sub {
    no utf8;
    plan tests => 1;

    $client->f_request(
        [ 'sites', '123' ],
        {
            req_type  => 'put',
            post_data => [
                {
                    ownerInfo => {
                        personalName => 'Василиус Пупкинус'
                    }
                }
            ],
        }
    );

    like(
        $transfered_params{post_data},
        qr/Василиус Пупкинус/,
        'utf8 char is ok in request'
    );
};
