#!/usr/bin/perl
use Module::Build;
use strict;
my $build = Module::Build->new(
    module_name => "CPANPLUS::Shell::Default::Plugins::Repo",
    dist_author      => 'Alexey Melezhik / melezhik@gmail.com',
    license          => 'perl',
    configure_requires => { 'Module::Build' => '0' },
    requires         => {
        'version'    => '0',
        'Test::More' => '0',
    },
    dist_abstract => 'This is CPANPLUS pluggin. Provides interface to CPAN::Repo server',
);

$build->create_build_script();



