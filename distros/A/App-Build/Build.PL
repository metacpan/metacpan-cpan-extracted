#!/usr/bin/perl -w

use Module::Build;
use File::Spec;

my $build = Module::Build->new (
    module_name       => "App::Build",
    dist_author       => [ "Mattia Barbon <mbarbon\@cpan.org>", "spadkins\@gmail.com" ],
    dist_abstract     => "extends Module::Build to build/install/configure entire applications (i.e. web applications), not just modules and programs",
    license           => "perl",
    requires => {
        "App::Options"    => 0,  # configuration
        "File::Spec"      => 0,  # platform-neutral directory manipulation
        "Module::Build"   => 0.28,
    },
    build_requires => {
        "Module::Build"     => 0.28,
        "Test::Differences" => 0.47,
    },
    create_makefile_pl    => 'passthrough',
    add_to_cleanup        => [ 't/test_install', 't/*/Build', 't/*/_build',
                               't/*/blib', 'unpack', 'archive' ],
);

$build->create_build_script;
