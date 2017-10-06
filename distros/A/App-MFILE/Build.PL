#!/usr/bin/perl
use 5.012000; # CPAN Testers
use strict;
use warnings FATAL => 'all';
use Module::Build 0.37;

my $build = Module::Build->new(
    module_name        => 'App::MFILE',
    dist_author        => q{Smithfarm <presnypreklad@gmail.com>},
    dist_abstract      => 'Generalized REST forwarder for MFILE-based frontends',
    dist_version_from  => 'lib/App/MFILE.pm',
    license            => 'bsd',
    create_license     => 0,
    create_readme      => 0,
    configure_requires => {
        'Module::Build'      => 0.37,
        'Software::License'  => 0,
    },
    build_requires     => { 
        'App::CELL'          => 0.222,
        'Params::Validate'   => 1.06,
        'Test::Fatal'        => 0,
    },
    requires           => {
        'perl'               => 5.012,
        'App::CELL'          => 0.222,
        'HTTP::Request::Common' => 0,
        'JSON'               => 0,
        'LWP::UserAgent'     => 0,
        'Params::Validate'   => 1.06,
    },
    meta_merge => {
        resources => {
            homepage => 'https://sourceforge.net/projects/mfile/',
            repository => 'https://sourceforge.net/p/mfile/code/',
        }
    },
    add_to_cleanup     => [ 'App-MFILE-*' ],
);

$build->create_build_script;
