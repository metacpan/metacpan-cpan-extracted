#!/usr/bin/perl

use Module::Build;

my $build = Module::Build->new(
    module_name    => "Async::ResourcePool",
    version_from   => "Async::ResourcePool",

    requires       => { },
    build_requires => {
        "common::sense" => 0,
        "Test::More"    => 0,
    },
);

$build->create_build_script;
