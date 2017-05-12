#!/usr/bin/env perl
use strict;
use warnings;
use Module::Build;

Module::Build->new(
    module_name => 'Acme::Aheui',
    license => 'perl',
    release_status => 'stable',
    create_readme => 1,
    requires => {
        'perl' => '5.10.0',
        'Term::ReadKey' => 0,
        'Term::Encoding' => 0,
    },
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
        'Capture::Tiny' => 0,
    },
    meta_merge => {
        resources => {
            repository => 'https://github.com/rakjin/aheui-perl.git',
        },
    },
)->create_build_script;
