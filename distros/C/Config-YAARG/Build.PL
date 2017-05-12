#!/bin/perl



use strict;
use warnings;


use Module::Build;
my $build = Module::Build->new(
    module_name => 'Config::YAARG',
    dist_abstract => 'Yet-another argument processor, designed to provide a standard method for parsing constructor arguments',
    requires => {
        'TAP::Harness' => 0,
        'Class::ISA' => 0
    },
    use_tap_harness => 1,
    create_makefile_pl => 'passthrough'
);


$build->create_build_script();



