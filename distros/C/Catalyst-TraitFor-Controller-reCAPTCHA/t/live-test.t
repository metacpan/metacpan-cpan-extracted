#!/usr/bin/env perl

use strict;
use warnings;
use Test::More qw/no_plan/;

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

BEGIN { use_ok("Test::WWW::Mechanize::Catalyst" => "TestApp") }
    
# a live test against TestApp, the test application - can't get the
# form submission working right now :-/ and doing this too much gets
# your local machine blacklisted from the recaptcha server for a bit
# anyway :-/

my $mech = Test::WWW::Mechanize::Catalyst->new;
$mech->get_ok('http://localhost/', 'get main page');
$mech->content_contains('name="recaptcha_challenge_field"', 'Looks like recaptcha code exists'); 

$mech->submit_form(
    form_name => 'recaptcha',
    fields    => { 
        recaptcha_response_field  => 'wrong',
        recaptcha_challenge_field => 'false'
    }
);

# obviously we can't test success automatically :/
$mech->content_lacks('OK:', 'Failed wrong answer'); 


## Test reCaptcha version 2
$mech->get_ok('http://localhost/?test=v2', 'get main page with parameter set reCaptcha version 2');
$mech->content_contains('class="g-recaptcha"', 'Looks like recaptcha code exists'); 
