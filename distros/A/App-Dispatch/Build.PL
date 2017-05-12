#!/usr/bin/perl -w

use strict;
use warnings;

use lib 'inc';
use MyBuild;

my $builder = MyBuild->new(
    module_name => 'App::Dispatch',
    license     => 'perl',
    dist_author => 'Chad Granum <exodist7@gmail.com>',

    create_readme  => 1,

    build_requires => {
        'Test::Simple' => 0.88,
    },

    configure_requires => {
        "Module::Build" => '0.36',
    },

    script_files => [
        'bin/dispatch',
        'bin/app_dispatch',
    ],

    meta_merge => {
        resources => {
            repository  => 'http://github.com/exodist/App-Dispatch',
            bugtracker  => 'http://github.com/exodist/App-Dispatch/issues',
        },
    },
);

$builder->create_build_script();
