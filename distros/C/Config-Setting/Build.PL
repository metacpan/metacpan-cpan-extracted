# @(#) $Id: Build.PL 763 2005-08-31 20:00:00Z dom $

use strict;
use Module::Build;

Module::Build->new(
    module_name => 'Config::Setting',
    license     => 'bsd',
    requires    => {
        'Test::More' => 0,
    },
    recommends  => {
        'Test::Pod' => 1.00,
    },
    create_makefile_pl => 'passthrough',
)->create_build_script;
