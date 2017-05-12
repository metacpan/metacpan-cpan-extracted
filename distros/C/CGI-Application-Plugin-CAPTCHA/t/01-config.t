#!/usr/bin/env perl -T

use strict;
use warnings;
use Test::More tests => 7;
use Test::Exception;

# Bring in testing hierarchy
use lib './t';

# Set up testing webapp
use TestApp;
$ENV{CGI_APP_RETURN_ONLY} = 1;

CONFIG_TESTING:
{
    my $app = TestApp->new();

    $app->captcha_config(
        IMAGE_OPTIONS    => {
            width   => 150,
            height  => 40,
            lines   => 10,
            gd_font => "giant",
            bgcolor => "#FFFF00",
        },
        CREATE_OPTIONS   => [ 'normal', 'rect' ],
        PARTICLE_OPTIONS => [ 300 ],
        SECRET          => 'vbCrfzMCi45TD7Uz4C6fjWvX6us',
    );

    ok($app->{__CAP__CAPTCHA_CONFIG}->{IMAGE_OPTIONS},    "IMAGE_OPTIONS defined"   );
    ok($app->{__CAP__CAPTCHA_CONFIG}->{CREATE_OPTIONS}  , "CREATE_OPTIONS defined"  );
    ok($app->{__CAP__CAPTCHA_CONFIG}->{PARTICLE_OPTIONS}, "PARTICLE_OPTIONS defined");

    dies_ok { $app->captcha_config( IMAGE_OPTIONS    => "invalid") } "IMAGE_OPTIONS should be a hashref";
    dies_ok { $app->captcha_config( CREATE_OPTIONS   => "invalid") } "CREATE_OPTIONS should be an arrayref";
    dies_ok { $app->captcha_config( PARTICLE_OPTIONS => "invalid") } "PARTICLE_OPTIONS should be an arrayref";
    dies_ok { $app->captcha_config( INVALID_OPTIONS  => "invalid") } "CAP::CAPTCHA died when given invalid options";
}

