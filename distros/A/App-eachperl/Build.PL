use v5;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'App::eachperl',
   requires => {
      'perl' => 5.026,
      'Object::Pad' => '0.800',
      'Object::Pad::FieldAttr::Checked' => '0.04',
      'Data::Checks' => '0.08',

      'Attribute::Storage' => 0,
      'Commandable::Finder::MethodAttributes' => 0,
      'Commandable::Invocation' => 0,
      'Config::Tiny' => 0,
      'Convert::Color::XTerm' => '0.06',
      'IO::Term::Status' => 0,
      'IPC::Run' => 0,
      'String::Tagged' => '0.17',
      'Syntax::Keyword::Dynamically' => 0,
   },
   test_requires => {
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
