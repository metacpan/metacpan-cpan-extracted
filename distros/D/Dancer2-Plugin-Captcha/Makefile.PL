#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Dancer2::Plugin::Captcha',
    AUTHOR             => q{Mohammad Sajid Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/Dancer2/Plugin/Captcha.pm',
    ABSTRACT_FROM      => 'lib/Dancer2/Plugin/Captcha.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'            => '0.94',
        'HTTP::Cookies'         => 0,
        'HTTP::Request::Common' => 0,
        'Plack'                 => '1.0029',
    },
    PREREQ_PM => {
        'Dancer2'           => '2.3.0',
        'Dancer2::Plugin'   => '2.3.0',
        'GD::SecurityImage' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Dancer2-Plugin-Captcha-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        'Dancer2::Plugin::Captcha' => {
            file    => 'lib/Dancer2/Plugin/Captcha.pm',
            version => MM->parse_version('lib/Dancer2/Plugin/Captcha.pm'),
        },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Dancer2-Plugin-Captcha.git',
                web  => 'https://github.com/manwar/Dancer2-Plugin-Captcha',
            },
            bugtracker => {
                web => 'https://github.com/manwar/Dancer2-Plugin-Captcha/issues',
            },
        },
    },
);
