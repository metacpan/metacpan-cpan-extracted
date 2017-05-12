#!perl

####################
# LOAD MODULES
####################
use strict;
use warnings FATAL => 'all';
use Module::Build;

# Autoflush ON
local $| = 1;

####################
# INIT BUILDER
####################

my $builder = Module::Build->new(
    module_name        => 'CASCM::Wrapper',
    license            => 'perl',
    dist_author        => 'Mithun Ayachit <mithun@cpan.org>',
    configure_requires => { 'Module::Build' => 0.38 },
    build_requires     => {
        'Test::More' => 0,
        'version'    => 0,
    },
    requires => {
        'perl'       => '5.006001',
        'File::Temp' => '0.16',
    },
    recommends => {
        'Config::Tiny'      => 0,
        'Log::Any'          => 0,
        'Log::Any::Adapter' => 0,
    },
    add_to_cleanup     => ['CASCM-Wrapper-*'],
    create_license     => 1,
    create_makefile_pl => 'traditional',
    meta_merge         => {
        keywords  => [qw(cascm harvest vci version-control scm)],
        resources => {
            bugtracker =>
              'https://github.com/mithun/perl-cascm-wrapper/issues',
            repository => 'git://github.com/mithun/perl-cascm-wrapper.git',
            homepage   => 'https://github.com/mithun/perl-cascm-wrapper',
        },
    },
);

####################
# CREATE BUILD SCRIPT
####################
$builder->create_build_script();
