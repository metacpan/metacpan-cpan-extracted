#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Data::Dumper;
use API::ParallelsWPB;
use API::ParallelsWPB::Response;

use t::lib::Mock;

my $client = t::lib::Mock->new(
    username => 'test',
    password => 'passw0rd',
    server   => '127.0.0.1'
);

subtest 'get_version' => sub {
    plan tests => 2;

    $client->get_version;
    my $p = $client->get_request_params;

    like( $p->{url}, qr{/api/5.3/system/version/},
        'URL for get version is ok' );

    is( $p->{data}->{req_type}, 'GET', 'Reqtype for get_version is ok' );
};

subtest 'create_site' => sub {
    plan tests => 3;

    # after site creation uuid goes to $client, and methods with uuid required can be called without uuid in params
    my $client = t::lib::Mock->new(
        username => 'test',
        password => 'passw0rd',
        server   => '127.0.0.1'
    );

    $client->create_site( state => 'regular' );
    my $p = $client->get_request_params;

    like( $p->{url}, qr{/api/5.3/sites/}, 'URL for create_site is ok' );
    like( $p->{post_data}, qr{"state":"regular"},
        'post_data for create_site is ok' );
    is( $p->{data}->{req_type}, 'POST', 'Reqtype for create_site is ok' );
};

subtest 'gen_token' => sub {
    $client->gen_token( uuid => '6d3f6f9f-55b2-899f-5fb4-ae04b325e360' );
    my $p = $client->get_request_params;

    like(
        $p->{url},
        qr{/api/5.3/sites/[\d\w\-]+/token/},
        'URL for gen_token is ok'
    );
    like( $p->{post_data}, qr{"sessionLifeTime":"1800"},
        'post_data for gen_token is ok' );
    is( $p->{data}->{req_type}, 'POST', 'Reqtype for gen_token is ok' );
};

# URI: /api/5.3/sites/{site_uuid}/deploy
subtest 'deploy' => sub {
    $client->deploy(
        uuid  => '6d3f6f9f-55b2-899f-5fb4-ae04b325e360',
        title => 'Tiitle'
    );
    my $p = $client->get_request_params;

    like(
        $p->{url},
        qr{/api/5.3/sites/[\d\w\-]+/deploy},
        'URL for deploy is ok'
    );

    like( $p->{post_data}, qr{"generic","en_US","Tiitle"}, 'post_data for deploy is ok' );

    is( $p->{data}->{req_type}, 'POST', 'Reqtype for deploy is ok' );
};

# /api/5.3/sites/{site_uuid}/
subtest 'get_site_info' => sub {
    $client->get_site_info(
        uuid  => '6d3f6f9f-55b2-899f-5fb4-ae04b325e360',
    );
    my $p = $client->get_request_params;

    like(
        $p->{url},
        qr{/api/5.3/sites/[\d\w\-]+/},
        'URL for get_site_info is ok'
    );

    is( $p->{data}->{req_type}, 'GET', 'Reqtype for get_site_info is ok' );

};


#  /api /5.3/sites/
subtest 'get_sites_info' => sub {
    $client->get_sites_info;
    my $p = $client->get_request_params;

    like(
        $p->{url},
        qr{/api/5.3/sites/},
        'URL for get_sites_info is ok'
    );

    is( $p->{data}->{req_type}, 'GET', 'Reqtype for get_sites_info is ok' );
};

# /api/5.3/sites/{site_uuid}/
subtest 'change_site_properties' => sub {
    $client->change_site_properties(
        uuid  => '6d3f6f9f-55b2-899f-5fb4-ae04b325e360',
        state => 'trial'
    );
    my $p = $client->get_request_params;

    like(
        $p->{url},
        qr{/api/5.3/sites/[\d\w\-]+/},
        'URL for change_site_properties is ok'
    );

    like( $p->{post_data}, qr{"state":"trial"}, 'post_data for change_site_properties is ok' );

    is( $p->{data}->{req_type}, 'PUT', 'Reqtype for change_site_properties is ok' );
};


# /api/5.3/sites/{siteUuid}/publish
subtest 'publish' => sub {
    $client->publish(
        uuid  => '6d3f6f9f-55b2-899f-5fb4-ae04b325e360',
    );
    my $p = $client->get_request_params;

    like(
        $p->{url},
        qr{/api/5.3/sites/[\d\w\-]+/publish/},
        'URL for publish is ok'
    );

    is( $p->{data}->{req_type}, 'POST', 'Reqtype for publish is ok' );
};



# /api/5.3/sites/{siteUuid}/
subtest 'delete_site' => sub {
    $client->delete_site(
        uuid  => '6d3f6f9f-55b2-899f-5fb4-ae04b325e360',
    );
    my $p = $client->get_request_params;

    like(
        $p->{url},
        qr{/api/5.3/sites/[\d\w\-]+/},
        'URL for delete_site is ok'
    );

    is( $p->{data}->{req_type}, 'DELETE', 'Reqtype for delete_site is ok' );
};


# /api/5.3/system/promo-footer
subtest 'get_promo_footer' => sub {
    $client->get_promo_footer;
    my $p = $client->get_request_params;

    like(
        $p->{url},
        qr{/api/5.3/system/promo-footer},
        'URL for get_promo_footer is ok'
    );

    is( $p->{data}->{req_type}, 'GET', 'Reqtype for get_promo_footer is ok' );
};


#  /api/5.3/sites/{site_uuid}/custom-properties
subtest 'get_site_custom_variable' => sub {
    $client->get_site_custom_variable(
        uuid  => '6d3f6f9f-55b2-899f-5fb4-ae04b325e360',
    );
    my $p = $client->get_request_params;

    like(
        $p->{url},
        qr{/api/5.3/sites/[\d\w\-]+/custom-properties},
        'URL for get_site_custom_variable is ok'
    );

    is( $p->{data}->{req_type}, 'GET', 'Reqtype for get_site_custom_variable is ok' );
};


#  /api/5.3/sites/{site_uuid}/custom-properties
subtest 'set_site_custom_variable' => sub {
    $client->set_site_custom_variable(
        uuid  => '6d3f6f9f-55b2-899f-5fb4-ae04b325e360',
    );
    my $p = $client->get_request_params;

    like(
        $p->{url},
        qr{/api/5.3/sites/[\d\w\-]+/custom-properties},
        'URL for set_site_custom_variable is ok'
    );

    is( $p->{data}->{req_type}, 'PUT', 'Reqtype for set_site_custom_variable is ok' );
};

#  /api/5.3/sites/{site_uuid}/custom-properties
subtest 'get_sites_custom_variables' => sub {
    $client->get_sites_custom_variables;
    my $p = $client->get_request_params;

    like(
        $p->{url},
        qr{/api/5.3/system/custom-properties},
        'URL for get_sites_custom_variables is ok'
    );

    is( $p->{data}->{req_type}, 'GET', 'Reqtype for get_sites_custom_variables is ok' );
};

#  /api/5.3/sites/{site_uuid}/custom-properties
subtest 'get_sites_custom_variables' => sub {
    $client->get_sites_custom_variables;
    my $p = $client->get_request_params;

    like(
        $p->{url},
        qr{/api/5.3/system/custom-properties},
        'URL for get_sites_custom_variables is ok'
    );

    is( $p->{data}->{req_type}, 'GET', 'Reqtype for get_sites_custom_variables is ok' );
};

#  /api/5.3/sites/{site_uuid}/custom-properties
subtest 'set_sites_custom_variables' => sub {
    $client->set_sites_custom_variables;
    my $p = $client->get_request_params;

    like(
        $p->{url},
        qr{/api/5.3/system/custom-properties},
        'URL for set_sites_custom_variables is ok'
    );

    is( $p->{data}->{req_type}, 'PUT', 'Reqtype for set_sites_custom_variables is ok' );
};

#  /api/5.3/sites/{site_uuid}/custom-properties
subtest 'set_custom_trial_messages' => sub {
    $client->set_custom_trial_messages;
    my $p = $client->get_request_params;

    like(
        $p->{url},
        qr{/api/5.3/system/trial-mode/messages},
        'URL for set_custom_trial_messages is ok'
    );

    is( $p->{data}->{req_type}, 'PUT', 'Reqtype for set_custom_trial_messages is ok' );
};

#  /api/5.3/sites/{site_uuid}/custom-properties
subtest 'get_custom_trial_messages' => sub {
    $client->get_custom_trial_messages;
    my $p = $client->get_request_params;

    like(
        $p->{url},
        qr{/api/5.3/system/trial-mode/messages},
        'URL for get_custom_trial_messages is ok'
    );

    is( $p->{data}->{req_type}, 'GET', 'Reqtype for get_custom_trial_messages is ok' );
};

#  /api/5.3/sites/{site_uuid}/custom-properties
subtest 'change_promo_footer' => sub {
    $client->change_promo_footer( message => 'test' );
    my $p = $client->get_request_params;

    like(
        $p->{url},
        qr{/api/5.3/system/promo-footer},
        'URL for change_promo_footer is ok'
    );

    is( $p->{post_data}, q/["test"]/, 'Post data for change_promo_footer is ok');

    is( $p->{data}->{req_type}, 'PUT', 'Reqtype for change_promo_footer is ok' );
};


done_testing;
