
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Dancer" => 0,
    "Dancer::Test" => 0,
    "English" => 0,
    "File::Find" => 0,
    "File::Spec" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Text::Xslate wrapper for Dancer",
  "dist_author" => [
    "franck cuny <franck\@lumberjaph.net>"
  ],
  "dist_name" => "Dancer-Template-Xslate",
  "dist_version" => "0.03",
  "license" => "perl",
  "module_name" => "Dancer::Template::Xslate",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Dancer::App" => 0,
    "Dancer::Template::Abstract" => 0,
    "File::Spec::Functions" => 0,
    "Text::Xslate" => 0,
    "base" => 0,
    "perl" => "5.006",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
