#!/usr/bin/perl

use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
    module_name => 'API::Plesk',
    license     => 'perl',
    dist_author => 'Ivan Sokolov <ivsokolov@cpan.org>',
    requires    => {
        'Module::Build'   => 0,
        'Data::Dumper'    => 0,
        'LWP::UserAgent'  => 0,
        'HTTP::Request'   => 0,
        'Carp'            => 0,
        'XML::Fast'       => 0,
        'version'         => 0,
    },
    build_requires => {
        'Test::More'       => 0,
        'Test::LongString' => 0,
        'URI'              => 0,
    },
    create_makefile_pl => 'traditional',
);

$build->create_build_script;

