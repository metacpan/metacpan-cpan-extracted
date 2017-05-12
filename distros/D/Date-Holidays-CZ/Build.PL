#!/usr/bin/perl
use 5.010000; # CPAN Testers
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $build = Module::Build->new(
    module_name        => 'Date::Holidays::CZ',
    dist_author        => q{Smithfarm <presnypreklad@gmail.com>},
    dist_abstract      => 'determine Czech Republic bank holidays',
    dist_version_from  => 'lib/Date/Holidays/CZ.pm',
    license            => 'bsd',
    create_license     => 0,
    create_readme      => 0,
    configure_requires => {
        'Module::Build'      => 0,
        'Software::License'  => 0,
    },
    build_requires     => { 
        'Date::Calc'         => 5.0,
    },
    requires           => {
        'perl'               => 5.010,
        'Date::Calc'         => 5.0,
    },
    meta_merge => {
        resources => {
            repository => 'https://github.com/smithfarm/date-holidays-cz.git',
            bugtracker => 'https://github.com/smithfarm/date-holidays-cz/issues',
        }
    },
    add_to_cleanup     => [ 'Date-Holidays-CZ-*' ],
);

$build->create_build_script;
