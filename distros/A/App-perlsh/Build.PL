use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'App::perlsh',
   requires => {
      'Getopt::Long' => 0,
      'Lexical::Persistence' => '0.98',
      'List::Util' => 0,
      'Term::ReadLine' => 0,
      'Term::Size' => 0,
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
