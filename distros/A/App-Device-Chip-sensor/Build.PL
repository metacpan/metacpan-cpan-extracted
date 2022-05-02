#!/usr/bin/perl

use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'App::Device::Chip::sensor',
   requires => {
      'perl' => '5.026',
      'Feature::Compat::Defer' => 0,
      'Future::AsyncAwait' => 0,
      'Object::Pad' => '0.57',

      'Device::Chip::Adapter' => 0,
      'Device::Chip::Sensor' => '0.19',
      'Future::IO' => '0.08',
      'Future::IO::Impl::IOAsync' => 0,
   },
   test_requires => {
      'Test::More' => '0.88', # done_testing
      'Test::Deep' => 0,
      'Test::Future::Deferred' => 0,
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
