use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Commandable',
   configure_requires => {
      'Module::Build' => "0.4004", # test_requires
   },
   requires => {
      'perl' => '5.010', # //
   },
   test_requires => {
      'Test::More' => '0.88', # done_testing
      'Test::Warnings' => 0,
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
