#!/usr/bin/perl

use v5;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'App::Device::Chip::sensor',
   requires => {
      'perl' => '5.026',
      'Feature::Compat::Defer' => 0,
      'Feature::Compat::Try' => 0,
      'Future::AsyncAwait' => 0,
      'Object::Pad' => '0.805',
      'Sublike::Extended' => 0,

      'Device::Chip::Adapter' => 0,
      'Device::Chip::Sensor' => '0.19',
      'Future::IO' => '0.08',
      'Future::IO::Impl::IOAsync' => 0,
      'List::Util' => '1.29',
   },
   test_requires => {
      'Test2::V0' => 0,
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
