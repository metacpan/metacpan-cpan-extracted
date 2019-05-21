use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'CPS',
   recommends => {
      'Sub::Name' => 0,
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   test_requires => {
      'Test::Identity' => 0,
      'Test::Fatal' => 0,
      'Test::More' => 0,
      'Test::Refcount' => 0,
   },
   requires => {
      'Future' => 0,
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
