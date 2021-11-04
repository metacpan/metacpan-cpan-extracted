#!/usr/bin/env perl

use strict;
use warnings;

use Module::Build;

Module::Build->new(
    module_name => 'Astro::VEX',
    dist_abstract => 'VEX (VLBI Experiment Definition) file handling module',
    license => 'gpl2',
    requires => {
        'Parse::RecDescent' => 0,
    },
)->create_build_script();
