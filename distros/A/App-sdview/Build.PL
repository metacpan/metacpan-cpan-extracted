use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'App::sdview',
   requires => {
      perl => '5.026',

      'Convert::Color' => 0,
      'Convert::Color::XTerm' => '0.06',
      'File::Slurper' => 0,
      'List::Keywords' => 0,
      'List::Util' => 0,
      'Object::Pad' => '0.41',
      'Pod::Simple' => 0,
      'String::Tagged' => 0,
      'String::Tagged::Terminal' => 0,
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
