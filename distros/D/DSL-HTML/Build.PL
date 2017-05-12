#!/usr/bin/perl
use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'DSL::HTML',
    license     => 'perl',
    dist_author => 'Chad Granum <exodist7@gmail.com>',
    create_readme => 1,
    requires => {
        'perl'         => '5.10.0',
        'Carp'         => 0,
        'Scalar::Util' => 0,

        'HTML::Tree' => '5.00',

        'Devel::Declare::Parser'         => '0.017',
        'Exporter::Declare'              => '0.113',
        'Exporter::Declare::Magic'       => '0.107',
    },
    build_requires => {
        'Fennec'          => '2.010',
        'Mock::Quick'     => '1.106',
        'Fennec::Declare' => '1.001',
    },
    meta_merge => {
        resources => {
            repository  => 'http://github.com/exodist/DSL-HTML',
            bugtracker  => 'http://github.com/exodist/DSL-HTML/issues',
            homepage    => 'http://github.com/exodist/DSL-HTML'
        },
    },
);

$build->create_build_script;
