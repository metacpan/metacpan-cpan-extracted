#!/usr/bin/perl
use Module::Build;
use strict;
my $build = Module::Build->new(
    module_name => "Bundler",
    dist_author      => 'Alexey Melezhik / melezhik@gmail.com',
    license          => 'perl',
    configure_requires => { 'Module::Build' => '0' },
    requires         => {
        'version'    => '0',
        'Test::More' => '0',
        'CPAN::Version' => '0',
    },
    dist_abstract => 'perl bunlder, inspired by ruby bundler',
);

$build->create_build_script();



