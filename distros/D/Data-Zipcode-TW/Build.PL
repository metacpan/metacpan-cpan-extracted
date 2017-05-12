
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601",
    "Test::More" => 0,
    "warnings" => 0
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Taiwan zipcode data in a box.",
  "dist_author" => [
    "Kang-min Liu <gugod\@gugod.org>"
  ],
  "dist_name" => "Data-Zipcode-TW",
  "dist_version" => "1.0",
  "license" => "mit",
  "module_name" => "Data::Zipcode::TW",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "strict" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
