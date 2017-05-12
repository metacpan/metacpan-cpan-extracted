#!/usr/bin/perl

use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
    module_name => 'API::PleskExpand',
    license     => 'perl',
    dist_author => 'NRG <pavel.odintsov@googlemail.com>',
    requires    => {
        'API::Plesk'      => '1.06',
        'Data::Dumper'    => 0,
        'LWP::UserAgent'  => 0,
        'Getopt::Long'    => 0,
        'HTTP::Request'   => 0,
        'Carp'            => 0,
        'URI'             => 0,
    },
    build_requires => {
        'Test::More'       => 0,
        'Test::LongString' => 0,
        'URI'              => 0,
    },
    create_makefile_pl => 'traditional',
);

$build->create_build_script;

