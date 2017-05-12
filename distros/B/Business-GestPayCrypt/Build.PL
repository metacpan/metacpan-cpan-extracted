#!/usr/bin/perl -w

use strict;

use Module::Build;
Module::Build->new(
    module_name        => 'Business::GestPayCrypt',
    create_makefile_pl => 'traditional',
    license            => 'perl',
    create_readme      => 0,
    dist_author        => 'Marco Gazerro <gazerro@open2b.com>',
    dist_abstract      => 'Perl interface to the italian online payment system GestPay',
    dist_version_from  => 'lib/Business/GestPayCrypt.pm',
)->create_build_script;
