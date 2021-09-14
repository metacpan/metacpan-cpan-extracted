use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'App::eachperl',
   requires => {
      'perl' => 5.026,
      'Object::Pad' => '0.41',

      'Config::Tiny' => 0,
      'Convert::Color::XTerm' => '0.06',
      'IO::Term::Status' => 0,
      'IPC::Run' => 0,
      'String::Tagged' => '0.17',
      'Struct::Dumb' => 0,
      'Syntax::Keyword::Dynamically' => 0,
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
