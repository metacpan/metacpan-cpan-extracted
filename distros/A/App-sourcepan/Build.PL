use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'App::sourcepan',
   dist_abstract => 'fetch source archives from CPAN',
   requires => {
      'Getopt::Long' => 0,
      'IPC::Run'     => 0,
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   test_requires => {
      'Test::More' => '0.88', # done_testing
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
