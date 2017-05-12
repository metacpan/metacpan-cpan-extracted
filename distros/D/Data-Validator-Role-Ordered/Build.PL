#!/usr/bin/perl

use Module::Build;

my $build = Module::Build->new(
    module_name => "Data::Validator::Role::Ordered",
    dist_version => 0.03,
    requires    => {
        "Data::Validator" => 0
    },
);

$build->create_build_script;
