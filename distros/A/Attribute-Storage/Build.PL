use v5;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Attribute::Storage',
   configure_requires => {
      'Module::Build' => 0,
   },
   requires => {
      'perl' => '5.014',

      'XSLoader' => 0,
   },
   build_requires => {
      'Test::More'       => '0.88', # done_testing
      'Test::NoWarnings' => 0,
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
