use v5;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Conduit',
   requires => {
      'perl' => '5.036',

      'Future::AsyncAwait' => 0,
      'Future::Buffer' => 0,
      'Future::IO' => '0.17',
      'Future::Selector' => 0,
      'HTTP::Request' => 0,
      'HTTP::Response' => 0,
      'IO::Socket::IP' => 0,
      'Metrics::Any' => '0.05',
      'Object::Pad' => '0.800',
   },
   test_requires => {
      'Test::Future::IO' => 0,
      'Test::Metrics::Any' => 0,
      'Test2::V0' => 0,
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
