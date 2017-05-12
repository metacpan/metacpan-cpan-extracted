#!/usr/bin/perl
use 5.012000; # CPAN Testers
use strict;
use warnings;
use Module::Build 0.37;

my $build = Module::Build->new(
    module_name        => 'App::Dochazka::CLI',
    dist_author        => q{Smithfarm <presnypreklad@gmail.com>},
    dist_abstract      => 'Dochazka ATT system command line client',
    dist_version_from  => 'lib/App/Dochazka/CLI.pm',
    license            => 'bsd',
    create_license     => 0,
    create_readme      => 0,
    share_dir          => {
        dist => [ 'config' ],
    },
    script_files       => [
        'bin/dochazka-cli',
    ],
    configure_requires => {
        'Module::Build'      => 0.37,
        'Software::License'  => 0,
    },
    build_requires     => { 
        'App::CELL'          => 0.209,
        'App::Dochazka::Common'      => 0.199,
        'Date::Calc'         => 0,
        'Test::Deep'         => 0,
        'Test::Fatal'        => 0,
        'Test::Warnings'     => 0,
        'Params::Validate'   => 1.06,
        'Web::MREST::CLI'    => 0.280,
    },
    requires           => {
        'perl'               => 5.012,
        'App::CELL'          => 0.209,
        'App::Dochazka::Common'      => 0.199,
        'Date::Calc'         => 0,
        'File::HomeDir'      => 0,
        'File::Slurp'        => 0,
        'File::Temp'         => 0,
        'HTTP::Cookies'      => 0,
        'HTTP::Request'      => 0,
        'Getopt::Long'       => 2.32,
        'JSON'               => 0,
        'LWP::UserAgent'     => 0,
        'Params::Validate'   => 1.06,
        'Term::ReadKey'      => 0,
        'Term::ReadLine::Gnu' => 0,
        'Text::Table'        => 0,
        'Web::MREST::CLI'    => 0.281,
    },
    meta_merge => {
        resources => {
            repository => 'https://github.com/smithfarm/dochazka-cli',
            bugtracker => 'https://github.com/smithfarm/dochazka-cli/issues',
        }
    },
    add_to_cleanup       => [ 'App-Dochazka-CLI-*' ],
#    create_makefile_pl   => 'traditional',
    recursive_test_files => 1,
);

$build->create_build_script;
