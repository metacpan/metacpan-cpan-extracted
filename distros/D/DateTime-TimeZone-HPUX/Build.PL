#!/usr/bin/env perl
use utf8;  # vim:set ts=4 sw=4:

use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
    module_name         => 'DateTime::TimeZone::HPUX',
    dist_author         => 'Olivier Mengué <dolmen@cpan.org>',
    license             => 'perl',
    requires => {
        # Minimum version required for this module to work is 0.87
        # But an out of date DateTime::Time is useless, so we force
        # an upgrade
        'DateTime::TimeZone' => '>=1.05',
        'Carp' => 0,
    },
    build_requires => {
        'DateTime::TimeZone' => '>=0.87',
        'Test::More' => 0,
        'File::Basename' => 0,
    },
    PL_files => {
        'JavaMap.PL' => 'lib/DateTime/TimeZone/HPUX/Map.pm',
    },
    dynamic_config => 1,
    add_to_cleanup => [ 'cover_db', '*~', '.*~', 'Makefile', 'MANIFEST.bak' ],
);
# Install Java class files (lib/DateTime/TimeZone/HPUX/TZ.class)
$build->add_build_element('class');
$build->create_build_script();
