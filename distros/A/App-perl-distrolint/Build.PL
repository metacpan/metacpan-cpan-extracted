use v5;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'App::perl::distrolint',
   dist_abstract => 'Linting tests for perl distributions',
   requires => {
      perl => '5.036',
      'Object::Pad' => '0.807',
      'Syntax::Keyword::Match' => '0.13',

      'Config::Tiny' => 0,
      'File::Basename' => 0,
      'File::Find' => 0,
      'File::Slurper' => 0,
      'List::Util' => '1.29',
      'Module::Pluggable::Object' => 0,
      'String::Tagged::Terminal' => 0,
      'Text::Treesitter' => '0.11',
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   test_requires => {
      'Test2::V0' => 0,
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
