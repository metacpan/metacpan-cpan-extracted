#!/usr/bin/perl

use strict;
use warnings;

use 5.008008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'App-SilverSplash',
    VERSION_FROM => 'lib/App/SilverSplash.pm',
    PREREQ_PM    => {
        'Config::SL'                         => 0.01,
        'Template'                           => 2.18,
        'URI::Escape'                        => 3.30,
        'Apache2::Connection::XForwardedFor' => 0.01,
        'Business::PayPal'                   => 0.04,
    },
    EXE_FILES => [
        qw( bin/sl_splash bin/sl_splash_bouncer )
    ],
    ABSTRACT => 'SilverSplash Captive Portal',
    AUTHOR   => 'Fred Moyer <fred@slwifi.com>',

);
