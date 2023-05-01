use v5;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Commandable',
   configure_requires => {
      'Module::Build' => "0.4004", # test_requires
   },
   requires => {
      'perl' => '5.014',

      'Module::Pluggable::Object' => 0,
   },
   test_requires => {
      'Test::NoWarnings' => 0,
      'Test2::V0' => 0,
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
