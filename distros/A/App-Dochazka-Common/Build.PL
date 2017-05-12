#!/usr/bin/perl
use 5.012000; # CPAN Testers
use strict;
use warnings FATAL => 'all';
use Module::Build 0.37;

my $build = Module::Build->new(
    module_name        => 'App::Dochazka::Common',
    dist_author        => q{Smithfarm <presnypreklad@gmail.com>},
    dist_abstract      => 'Dochazka ATT system shared modules',
    dist_version_from  => 'lib/App/Dochazka/Common.pm',
    license            => 'bsd',
    create_license     => 0,
    create_readme      => 0,
    configure_requires => {
        'Module::Build'      => 0.37,
        'Software::License'  => 0,
    },
    build_requires     => { 
        'Test::Fatal'        => 0,
        'Params::Validate'   => 1.06,
        'Test::Deep::NoTest' => 0,
    },
    requires           => {
        'perl'               => 5.012,
        'Params::Validate'   => 1.06,
        'Test::Deep::NoTest' => 0,
        'Time::Piece'        => 0,
        'Time::Seconds'      => 0,
    },
    meta_merge => {
        resources => {
            repository => 'https://github.com/smithfarm/dochazka-common',
            bugtracker => 'https://github.com/smithfarm/dochazka-common/issues',
        }
    },
    add_to_cleanup     => [ 'App-Dochazka-Common-*' ],
);

$build->create_build_script;
