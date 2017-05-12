
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601",
    "Module::Load" => 0,
    "Test::Exception" => "0.31",
    "Test::More" => "0.98"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Base class for alternate module",
  "dist_author" => [
    "Steven Haryanto <stevenharyanto\@gmail.com>"
  ],
  "dist_name" => "Alt-Base",
  "dist_version" => "0.02",
  "license" => "perl",
  "module_name" => "Alt::Base",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Alt" => "0.04",
    "perl" => "5.008000"
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
