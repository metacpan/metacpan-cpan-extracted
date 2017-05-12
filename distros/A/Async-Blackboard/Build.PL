#!/usr/bin/perl

use Module::Build;

my $build = Module::Build->new(
    module_name  => "Async::Blackboard",
    version_from => "Async::Blackboard",

    requires     => {
        "Mouse"        => 0,
        "Scalar::Util" => 0,
    },

    build_requires => {
        # For test....
        "EV"            => 0,
        "BSD::Resource" => 0,
        "Devel::Leak"   => 0,
    },
);

$build->create_build_script;
