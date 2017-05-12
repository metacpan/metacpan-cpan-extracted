use utf8;
use strict;
use warnings;
use Module::Build;

Module::Build->new(
    module_name         => 'Acme::PM::Paris::Meetings',
    license             => 'perl',
    dist_author         => 'Olivier Mengué <dolmen@cpan.org>',
    dist_version_from   => 'lib/Acme/PM/Paris/Meetings.pm',
    script_files        => 'script/paris-pm',
    requires => {
        'DateTime::TimeZone' => 0,
        ($^O eq 'hpux' ? ('DateTime::TimeZone::HPUX' => '0.08') : ()),
        'DateTime::Format::ICal' => 0,
        'Exporter' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Acme-PM-Paris-Meetings-*' ],
    create_makefile_pl => 'traditional',
)->create_build_script();
