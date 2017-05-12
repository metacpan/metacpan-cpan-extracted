#!/usr/bin/perl

use Module::Build;

my $build = Module::Build->new(
    module_name  => "AnyEvent::Blackboard",
    version_from => "AnyEvent::Blackboard",

    requires     => {
        "AnyEvent"          => 0,
        "Async::Blackboard" => "0.3.10",
        "Mouse"             => 0,
    },

    build_requires => {
        # For test....
        "EV"            => 0,
        "BSD::Resource" => 0,
        "Devel::Leak"   => 0,
    },
);

$build->create_build_script;
