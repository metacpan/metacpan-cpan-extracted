#!/usr/bin/perl
use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'Block::NamedVar',
    license     => 'perl',
    dist_author => 'Chad Granum <exodist7@gmail.com>',
    create_readme => 1,
    requires => {
        'Devel::Declare::Parser' => 0.014,
    },
    build_requires => {
        'Fennec' => 2.017,
    },
    meta_merge => {
        resources => {
            repository  => 'http://github.com/exodist/Block-NamedVar',
            bugtracker  => 'http://github.com/exodist/Block-NamedVar/issues',
        },
    }
);

$build->create_build_script;
