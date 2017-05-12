#!/usr/bin/perl
use 5.012000; # CPAN Testers
use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name        => 'App::CELL',
    dist_author        => q{Smithfarm <presnypreklad@gmail.com>},
    dist_version_from  => 'lib/App/CELL.pm',
    license            => 'bsd',
    create_license     => 0,
    create_readme      => 0,
    share_dir          => { 
        dist => [ 'config' ], 
    },
    configure_requires => {
        'Module::Build'      => 0,
        'Software::License'  => 0,
    },
    build_requires     => { 
        'Log::Any::Test'     => 0,
        'File::ShareDir::Install' => 0.11,
        'File::Spec'         => 0,
        'File::Temp'         => 0,
        'Params::Validate'   => 0,
        'Test::Warnings'     => 0,
        'Try::Tiny'          => 0,
    },
    requires           => {
        'perl'                  => 5.012,
        'Date::Format'          => 0,
        'File::HomeDir'         => 0,
        'File::ShareDir'        => 1.0,
        'File::Next'            => 0,
        'Log::Any'              => 0,
        'Log::Any::Adapter'     => 0.10,
        'Params::Validate'      => 0,
        'Try::Tiny'             => 0,
    },
    meta_merge => {
        resources => {
            repository => 'https://github.com/smithfarm/cell',
            bugtracker => 'https://github.com/smithfarm/cell/issues',
        }
    },
    add_to_cleanup     => [ 'App-CELL-*' ],
    # create_makefile_pl => 'traditional',
);

$build->create_build_script;
