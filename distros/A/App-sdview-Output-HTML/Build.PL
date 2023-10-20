use v5;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'App::sdview::Output::HTML',
   requires => {
      perl => '5.026',
      'Object::Pad' => '0.800',

      'App::sdview::Output' => '0.13',
      'String::Tagged::HTML' => 0,
   },
   test_requires => {
      'App::sdview::Parser::Pod' => '0.13',
      'App::sdview::Parser::Markdown' => '0.13',
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
