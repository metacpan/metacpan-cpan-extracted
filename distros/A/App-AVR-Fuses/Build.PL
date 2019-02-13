use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'App::AVR::Fuses',
   dist_abstract => "a commandline fuse value calculator for AVR microcontrollers",
   requires => {
      'File::ShareDir' => 0,
      'Getopt::Long' => 0,
      'List::Util' => 0,
      'YAML' => 0,

      'perl' => '5.010',
   },
   test_requires => {
      'Test::More' => '0.88', # done_testing
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   share_dir => {
      module => { "App::AVR::Fuses" => "share" },
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
