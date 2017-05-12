#!/usr/bin/perl -w

use strict;
use warnings;

use Module::Build;

require 5.008003;

my $build = Module::Build->new(
    module_name        => 'Bundle::BricolagePlus',
    license            => 'perl',
    create_makefile_pl => 'passthrough',
    requires           => { perl            => 5.008_003 },
    configure_requires => { 'Module::Build' => '0.30'    },
    build_requires     => { 'Module::Build' => '0.30'    },
);
$build->create_build_script;

