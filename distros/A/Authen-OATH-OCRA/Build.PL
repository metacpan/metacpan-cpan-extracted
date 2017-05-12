#!/usr/bin/perl

use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Authen::OATH::OCRA',
    license           => 'perl',
    dist_author       => q{Pascual De Ruvo <pderuvo@gmail.com>},
    dist_version_from => 'lib/Authen/OATH/OCRA.pm',
    build_requires    => {
        'Test::More'      => 0,
        'Test::Simple'    => 0,
        'Test::Exception' => 0,
        'Moose'           => 0,
        'Math::BigInt'    => 0,
        'Digest::SHA'     => 0,
        'Carp'            => 0
    },
    add_to_cleanup     => ['Authen-OATH-OCRA*'],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
