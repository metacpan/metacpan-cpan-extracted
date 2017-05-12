#!/usr/bin/env perl

use strict;
use warnings;
use Test::More qw/no_plan/;

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

BEGIN { use_ok("Test::WWW::Mechanize::Catalyst" => "TestApp") }
    

my $mech = Test::WWW::Mechanize::Catalyst->new;

$mech->get_ok("http://localhost/", "get captcha image");

ok ($mech->content_type eq "image/jpeg", "Captcha image received");

my $invalid_captcha_text = '12345';

$mech->get_ok("http://localhost/check/$invalid_captcha_text", "Validating Captcha");

# obviously we can't test success automatically :/
ok ($mech->content eq "FAIL", "Captcha validation failed as expected");


