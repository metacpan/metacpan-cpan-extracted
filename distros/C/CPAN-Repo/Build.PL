#!/usr/bin/perl
use Module::Build;
use strict;
my $build =  Module::Build->new(
    license            => 'perl',
    module_name        => 'CPAN::Repo',
    dist_abstract      => 'cpan repository server',
    requires           => {
        'Dancer'       => '0',
        'Test::More'   => '0',
    },
    build_requires     => {
        'Module::Build' => 0,
    },
    scripts => 'scripts/cpan_repo'
);
$build->create_build_script();
