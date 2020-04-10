use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'App::eachperl',
   requires => {
      'perl' => 5.010,  # //

      'Config::Tiny' => 0,
      'Struct::Dumb' => 0,
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
