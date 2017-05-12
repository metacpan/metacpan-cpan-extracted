
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Dancer::Test" => 0,
    "Data::Dumper" => 0,
    "JSON::Syck" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => 0,
    "YAML::Syck" => 0
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Easy validates user input (usually from an HTML form) based on input profile for Dancer applications.",
  "dist_author" => [
    "Natal Ng\303\251tal"
  ],
  "dist_name" => "Dancer-Plugin-FormValidator",
  "dist_version" => "1.131620",
  "license" => "perl",
  "module_name" => "Dancer::Plugin::FormValidator",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Dancer" => "1.2001",
    "Dancer::Exception" => 0,
    "Dancer::Plugin" => 0,
    "Data::FormValidator" => 0,
    "Module::Load" => 0,
    "perl" => "5.010",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
