#!/usr/bin/perl
use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'Child::Socket',
    license     => 'perl',
    dist_author => 'Chad Granum <exodist7@gmail.com>',
    create_readme => 1,
    requires => {
        'POSIX'            => 0,
        'Child'            => '0.007',
        'IO::Socket::UNIX' => 0,
    },
    build_requires => {
        'Test::More'      => 0,
    },
    meta_merge => {
        resources => {
            repository => 'http://github.com/exodist/Child-Socket',
            bugtracker => 'http://github.com/exodist/Child-Socket/issues',
        },
    }
);

$build->create_build_script;
