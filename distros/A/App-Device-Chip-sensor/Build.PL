#!/usr/bin/perl

use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'App::Device::Chip::sensor',
   requires => {
      'perl' => '5.026',
      'Object::Pad' => '0.32',

      'Device::Chip::Adapter' => 0,
      'Future::IO' => '0.08',
   },
   test_requires => {
      'Test::More' => '0.88', # done_testing
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
