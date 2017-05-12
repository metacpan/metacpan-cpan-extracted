#!/usr/bin/perl

use strict;
use Module::Build;

my $build=Module::Build->new(
    module_name         => 'ChainMake',
    version_from        => 'lib/ChainMake.pm',
    license             => 'perl',
    build_requires      => {
        'Test::More'  => 0,
        'File::Touch' => 0,
        'Config'      => 0,
        'Time::HiRes' => 0,
    },
    requires            => {
        'Clone'       => 0,
        'Tie::File'   => 0,
        'Fcntl'       => 0,
    },
    recommends          => {
        'threads'     => 0,
    },
    script_files    	=> [],
    create_readme   	=> 0,
    create_makefile_pl	=> 'passthrough',
    dist_author     	=> 'Daniel Schroeer <schroeer@cpan.org>');

$build->create_build_script;
