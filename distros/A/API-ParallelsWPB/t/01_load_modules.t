#!/usr/bin/perl

use strict;
use warnings;

use Test::More  tests => 51;
use FindBin qw/ $Bin /;
use lib "$Bin/../lib";

use_ok('API::ParallelsWPB');
use_ok('API::ParallelsWPB::Requests');
use_ok('API::ParallelsWPB::Response');

my @basic_methods = qw/
    new
    f_request
    get_version
    create_site
    gen_token
    deploy
    get_site_info
    get_sites_info
    change_site_properties
    publish
    delete_site
    get_promo_footer
    get_site_custom_variable
    set_site_custom_variable
    get_sites_custom_variables
    set_sites_custom_variables
    set_custom_trial_messages
    get_custom_trial_messages
    change_promo_footer
    set_site_promo_footer_visible
    set_site_promo_footer_invisible
    _get_uuid
    _send_request
/;

for my $basic_method ( @basic_methods ) {
    can_ok('API::ParallelsWPB', $basic_method);
}

my @request_methods = qw/
    get_version
    create_site
    gen_token
    deploy
    get_site_info
    get_sites_info
    change_site_properties
    publish
    delete_site
    get_promo_footer
    get_site_custom_variable
    set_site_custom_variable
    get_sites_custom_variables
    set_sites_custom_variables
    set_custom_trial_messages
    get_custom_trial_messages
    change_promo_footer
    set_site_promo_footer_visible
    set_site_promo_footer_invisible
    _get_uuid
/;

for my $request_method ( @request_methods ) {
    can_ok('API::ParallelsWPB::Requests', $request_method);
}

my @response_methods = qw/
    new
    json
    success
    response
    status
/;

for my $response_method ( @response_methods ) {
    can_ok('API::ParallelsWPB::Response', $response_method);
}

done_testing();