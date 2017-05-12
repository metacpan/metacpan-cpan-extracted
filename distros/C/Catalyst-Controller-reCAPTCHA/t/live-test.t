#!/usr/bin/env perl

use strict;
use warnings;
use Test::More qw/no_plan/;

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

# make sure testapp works
use ok 'TestApp';

# a live test against TestApp, the test application - can't get the
# form submission working right now :-/ and doing this too much gets
# your local machine blacklisted from the recaptcha server for a bit
# anyway :-/

use Test::WWW::Mechanize::Catalyst 'TestApp';
my $mech = Test::WWW::Mechanize::Catalyst->new;
$mech->get_ok('http://localhost/', 'get main page');
# $mech->submit_form(
#     form_name => 'recaptcha',
#     fields => {    recaptcha_response_field => 'wrong',
#                });
# $mech->content_lacks('recaptcha error: 1'); # obviously we can't test success automatically :/





